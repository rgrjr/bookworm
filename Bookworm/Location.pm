# The Bookworm "Location" class.
#
# [created.  -- rgr, 25-May-13.]
#

use strict;
use warnings;

package Bookworm::Location;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Location->build_field_accessors
	([ qw(location_id name description destination weight volume stackable),
	   qw(bg_color parent_location_id) ]);
    Bookworm::Location->define_class_slots(qw(density));  # Search results.
    Bookworm::Location->build_fetch_accessor
	(qw(parent_location parent_location_id Bookworm::Location));
    Bookworm::Location->build_set_fetch_accessor
	('location_children',
	 query => q{select location_id from location
		    where parent_location_id = ?
		    order by name},
	 object_class => 'Bookworm::Location',
	 cache_key => '_location_children');
    Bookworm::Location->build_set_fetch_accessor
	('book_children',
	 query => q{select book_id from book
		    where location_id = ?
		    order by title},
	 object_class => 'Bookworm::Book',
	 cache_key => '_book_children');
}

sub table_name { 'location'; }
sub primary_key { 'location_id'; }
sub pretty_name { shift()->name || 'unknown'; }
sub home_page_name { 'location.cgi'; }
sub search_page_name { 'find-location.cgi'; }

# Enable ModGen::DB::Thing object caching.
use vars qw(%id_to_object_cache);
%id_to_object_cache = ();

sub ancestor_of {
    # Return true iff $self contains $location.
    my ($self, $location) = @_;

    my $location_id = $self->location_id;
    return
	unless $location_id;
    while ($location) {
	return 1
	    if $location->location_id == $location_id;
	$location = $location->parent_location;
    }
}

sub n_local_books {
    my ($self) = @_;

    if ($self->{_book_children}) {
	# If the cache is present, don't bother asking the database.
	return scalar(@{$self->{_book_children}});
    }
    else {
	# Query the database without fetching all the books.
	my $dbh = $self->db_connection();
	my ($n_books) = $dbh->selectrow_array
	    (q{select count(1) from book
	       where location_id = ?
	       group by '1'},
	     undef, $self->location_id);
	# $n_books will be undef if the select return no rows.
	return $n_books // 0;
    }
}

sub n_total_books {
    my ($self) = @_;

    my $total = $self->n_local_books;
    for my $sub_location (@{$self->location_children}) {
	$total += $sub_location->n_total_books;
    }
    return $total;
}

sub total_weight {
    my ($self) = @_;

    my $total = $self->weight;
    for my $child (@{$self->location_children}) {
	$total += $child->total_weight;
    }
    return $total;
}

sub total_weight_p {
    my ($self) = @_;

    return
	if $self->weight > 0;
    return 1
	if @{$self->location_children};
}

sub total_volume {
    my ($self) = @_;

    my $total = $self->volume;
    for my $child (@{$self->location_children}) {
	$total += $child->total_volume;
    }
    return $total;
}

sub has_volume_p {
    # The volume itself is not a boolean, because zero floats are always true.
    my ($self) = @_;

    return 0 != $self->volume;
}

sub has_weight_p {
    # The weight is also not a boolean.
    my ($self) = @_;

    return 0 != $self->weight;
}

sub has_density_p {
    my ($self) = @_;

    $self->has_weight_p && $self->has_volume_p;
}

sub has_stackable_p {
    my ($self) = @_;

    return 0 == @{$self->location_children};
}

sub display_info {
    my ($self, $q) = @_;

    my $n_books = $self->n_local_books;
    return (! $n_books ? ()
	    : $n_books == 1 ? '1 book'
	    : "$n_books books",
	    $self->SUPER::display_info($q));
}

# This allows the text to be seen more easily.
my %pastel_from_color
    = (grey => '#bbb',
       yellow => '#ffc',
       orange => '#fec',
       red => '#fcc',
       purple => '#fcf',
       blue => '#ccf',
       aqua => '#cff',
       green => '#cfc');
my @background_colors = ('inherit', keys(%pastel_from_color));

sub _backgroundify {
    # Wrap the content in a span with our background color, if we don't inherit
    # the browser background.
    my ($self, $q, $content) = @_;

    # Find our background color.
    my $bg_color = $self->bg_color || 'inherit';
    if ($bg_color eq 'inherit') {
	# Inherit from our parent.
	my $parent = $self->parent_location;
	while ($parent && $bg_color eq 'inherit') {
	    $bg_color = $parent->bg_color;
	    $parent = $parent->parent_location;
	}
    }
    return $content
	# No color (which is the global default).
	if $bg_color eq 'inherit';
    $bg_color = $pastel_from_color{$bg_color} || $bg_color;
    return $q->span({ style => "background: $bg_color;" }, $content);
}

sub html_link {
    # Wrap the link in a span with our background color.
    my ($self, $q) = @_;

    my $link =  $self->SUPER::html_link($q);
    return $link
	unless $q;
    return $self->_backgroundify($q, $link);
}

### Web interface.

my @local_display_fields
    = ({ accessor => 'name', pretty_name => 'Location',
	 type => 'self_link', class => 'Bookworm::Location' },
       { accessor => 'description', pretty_name => 'Description',
	 type => 'text', rows => 8, columns => 80 },
       { accessor => 'destination', pretty_name => 'Destination',
	 type => 'string', size => 80 },
       { accessor => 'weight', pretty_name => 'Packed weight',
	 type => 'number', show_total_p => 1 },
       { accessor => 'total_weight', pretty_name => 'Total weight',
	 verbosity => 2, show_total_p => 1 },
       { accessor => 'volume', pretty_name => 'Volume',
	 type => 'number', show_total_p => 1 },
       { accessor => 'total_volume', pretty_name => 'Total volume',
	 verbosity => 2, show_total_p => 1 },
       { accessor => 'stackable', pretty_name => 'Stack?',
	 skip_if_not => \&has_stackable_p,
	 type => 'enumeration',
	 values => [ qw(yes no never) ],
	 search_multiple => 1,
	 search_field => 'location.stackable',
	 search_default => [ qw(yes no never) ] },
       { accessor => 'bg_color', pretty_name => 'Background',
	 type => 'enumeration',
	 values => \@background_colors },
       { accessor => 'n_total_books', pretty_name => 'Books',
	 type => 'integer', read_only_p => 1, show_total_p => 1 },
       { accessor => 'parent_location_id', pretty_name => 'Parent location',
	 edit_p => 'find-location.cgi',
	 type => 'location_chain',
	 validate => 'validate_parent_location_id' }
    );

sub local_display_fields {
    \@local_display_fields;
}

sub validate_parent_location_id {
    my ($self, $descriptor, $interface, $new_location_id) = @_;

    my $new_parent_location
	= ($new_location_id
	   && Bookworm::Location->fetch($new_location_id));
    my $old_location_id = $self->parent_location_id;
    my $old_parent_location
	= ($old_location_id
	   && Bookworm::Location->fetch($old_location_id));
    if (($old_location_id || 'none') eq ($new_location_id || 'none')) {
	# No change.
    }
    elsif ($self->root_location_p) {
	$interface->_error("Can't move the root.\n")
	    # Naughty, naughty.
	    if $new_location_id;
    }
    elsif (! $new_parent_location) {
	# It's OK to make (or leave) the parent location undefined.
	$interface->_error("Location with ID '$new_location_id' ",
			   "doesn't exist.\n")
	    if $new_location_id;
    }
    elsif ($self->ancestor_of($new_parent_location)) {
	# Make sure we don't create a loop.
	$interface->_error("Can't move a location under itself!\n");
    }
}

sub validate {
    my ($self, $interface) = @_;

    $interface->_error("Locations must have a name.\n")
	unless $self->name;
    $interface->_error("Locations must have a parent location.\n")
	unless $self->parent_location_id || $self->name eq 'Somewhere';
}

### Container API support.

sub contained_item_key {
    return 'book_id';
}

sub contained_item_parent_key {
    return 'location_id';
}

sub container_items {
    my ($self) = @_;

    return $self->book_children;
}

sub children {
    # Hierarchy browser support.
    return shift()->location_children(@_);
}

sub sorted_children {
    # Hierarchy browser support.
    my ($self) = @_;

    return @{$self->location_children()};
}

### Web page stuff.

sub fetch_root {
    # Hierarchy browser support.
    my ($class) = @_;

    return $class->fetch(1);
}

sub root_location_p {
    my ($self) = @_;

    return ($self->location_id // 0) == 1;
}

my $child_location_display_columns
    = [ qw(name n_total_books description destination),
	qw(total_weight total_volume stackable) ];
my $book_display_columns
    = [ { accessor => 'book_id', label => ' ',
	  pretty_name => 'Select?',
	  type => 'checkbox', checked_p => 0 },
	{ accessor => 'title', pretty_name => 'Title',
	  type => 'self_link' },
	qw(publication_year authors category notes) ];

sub ajax_sort_content {
    # Handle AJAX requests to sort book or location content.
    my ($self, $q) = @_;

    my $prefix = $q->param('prefix') || '';
    my $messages = { debug => '' };
    my $unlink = $self->html_link(undef);
    if ($prefix eq 'locations') {
	my $child_locations = $self->location_children;
	$messages->{locations_content}
	    = $self->present_sorted_content
	        ($q, "$unlink locations",
		 $child_location_display_columns,
		 $child_locations,
		 prefix => 'locations');
    }
    elsif ($prefix eq 'book') {
	my $books = $self->book_children;
	my $book_presenter = @$books ? $books->[0] : $self;
	$messages->{book_content}
	    = $book_presenter->present_sorted_content
		($q, "$unlink books",
		 $book_display_columns,
		 $books, prefix => 'book');
    }
    else {
	$messages->{debug} = "Unknown prefix '$prefix'.";
    }
    $q->send_encoded_xml($messages);
}

sub post_web_update {
    my ($self, $q) = @_;
    require ModGen::CGI::make_selection_op_buttons;

    # Produce links.
    my @links;
    if ($self->location_id) {
	my $url = $q->oligo_query('location.cgi',
				  parent_location_id => $self->location_id);
	push(@links, $q->a({ href => $url }, '[Add child location]'));
	for my $thing (qw(book location)) {
	    $url = $q->oligo_query("move-${thing}s.cgi",
				   location_id => $self->location_id);
	    push(@links, $q->a({ href => $url }, "[Move $thing(s) here]"));
	}
	unless (@{$self->location_children} || @{$self->book_children}) {
	    $url = $q->oligo_query('delete-location.cgi',
				   location_id => $self->location_id);
	    push(@links, $q->a({ href => $url }, '[Delete location]'));
	}
    }
    my @content = ($q->ul(map { $q->li($_); } @links));
    push(@content, $q->div({ id => 'debug' }, ''));

    # Produce child location and book content, but only if we have any.
    my $child_locations = $self->location_children;
    my $books = $self->book_children;
    if (@$books || @$child_locations) {
	my $unlink = $self->html_link(undef);
	push(@content, $q->h3("$unlink contents"));
	if (@$child_locations) {
	    my $location_content
		= $self->present_sorted_content
		    ($q, "$unlink locations",
		     $child_location_display_columns, $child_locations,
		     prefix => 'locations', default_sort => 'name');
	    push(@content,
		 $q->div({ id => 'locations_content' },
			 ($location_content . "<br>\n")));
	}
	if (@$books) {
	    my $book_content =
		$books->[0]->present_sorted_content
		    ($q, "$unlink books",
		     $book_display_columns, $books,
		     prefix => 'book', default_sort => 'title:up');
	    push(@content,
		 $q->div({ id => 'book_content' }, $book_content),
		 $q->make_selection_op_buttons(commit => 0, 'Move books'));
	}
	elsif ($self->name =~ /^pod/i) {
	    # See if we have child locations.

	    # Build @histogram_bins.
	    my $weight_string = '.';
	    my $bin_width = 5;
	    my @histogram_bins;
	    my $dbh = $self->db_connection();
	    {
		my ($total_weight, $n_desc) = (0, 0);
		my $weights = $dbh->selectcol_arrayref
		    (q{select weight from location
			   where weight > 0.0
			   and parent_location_id = ?},
		     undef, $self->location_id)
		    or die $dbh->errstr;
		for my $weight (@$weights) {
		    $n_desc++;
		    $total_weight += $weight;
		    my $bin = int($weight / $bin_width);
		    $histogram_bins[$bin]++;
		}

		# If we have child locations with weight and no books, that
		# makes us a real container.
		if ($total_weight > 0) {
		    my $search_url = $q->oligo_query('find-location.cgi',
						     weight_min => 1);
		    my $search_link
			= $q->a({ href => $search_url }, "in $n_desc",
				($n_desc > 1 ? 'locations' : 'location'));

		    # Weight histogram distribution plot.
		    my @histogram_values;
		    for my $bin (0 .. @histogram_bins-1) {
			# Include zeros, because gnuplot has trouble with
			# missing values.
			my $value = $bin * $bin_width;
			my $count = $histogram_bins[$bin] || 0;
			push(@histogram_values, $value, $count || 0);
		    }

		    my $data = join(';', @histogram_values);
		    my $url = $q->oligo_query('plot-hist.cgi', data => $data);
		    push(@content,
			 $q->p($q->img({ src => $url,
					 alt => 'Histogram of weights' })));
		}
	    }
	}
    }
    return join("\n", @content, "\n");
}

sub web_update {
    my ($self, $q, @options) = @_;

    use ModGen::Web::Interface;
    my $interface = ModGen::Web::Interface->new(store_messages_p => 1,
						query => $q);
    my $message;
    my $doit = $q->param('doit') || '';
    if (! $doit) {
    }
    elsif ($doit eq 'confirm_move' || $doit eq 'Move') {
	$self->move_or_delete_items($q, $interface);
	delete($self->{_book_children});	# decache.
	$q->delete('book_id');
    }
    elsif ($doit ne 'Move books') {
    }
    elsif (my @items = $q->param('book_id')) {
	# Go look for a new folder.
	my $n_items = scalar(@items);
	my $return_url = $q->oligo_query('location.cgi',
					 location_id => $self->location_id,
					 (map { (book_id => $_);
					  } $q->param('book_id')),
					 doit => 'confirm_move');
	my $title = join('', "New location for $n_items ", $self->name,
			 ' book', $self->pluralize($n_items));
	my $search_url
	    = $q->oligo_query('find-location.cgi',
			      title => $title,
			      return_field => 'destination_container_id',
			      return_address => $return_url);
	print $q->redirect(-uri => $search_url);
	return;
    }
    else {
	$message = 'No items selected.';
    }
    $q->param(message => $message)
	if $message;
    my $name = $q->escapeHTML($self->pretty_name);
    my $heading = join(' ', 'Location', $self->_backgroundify($q, $name));

    # Create an onSubmit trigger that supports AJAX book and location content
    # sorting, as well as AJAX container operations on books.
    $q->include_javascript('update-content.js');
    $q->include_javascript('selection.js');
    # This is what book sorting needs . . .
    my $a1 = $q->oligo_query('ajax-location-sort.cgi', prefix => 'book');
    my $on_submit
	= qq{return maybe_update_sort(event, 'book', 'update', '$a1', '&')};
    # . . . this is what location sorting needs . . .
    my $a2 = $q->oligo_query('ajax-location-sort.cgi', prefix => 'locations');
    $on_submit
	.= qq{ && maybe_update_sort(event, 'locations', 'update', '$a2', '&')};
    # . . . and this is what container operations for books need.
    $on_submit .= q{ && submit_or_operate_on_selected(event)};
    $self->SUPER::web_update
	($q, @options,
	 interface => $interface,
	 heading => $heading,
	 onsubmit => $on_submit);
}

sub web_move_books {
    my ($self, $q) = @_;
    require Bookworm::Book;

    my @books = map {
	my $book = Bookworm::Book->fetch($_);
	$book ? ($book) : ();
    } $q->param('book_id');
    my $return_address
	= $q->param('return_address') || $self->home_page_url($q);
    my $location_id = $self->location_id;
    my $doit = $q->param('doit') || '';
    my $error_message;
    if ($doit eq 'Skip') {
	print $q->redirect($return_address);
	return;
    }
    elsif (! @books) {
	# Need to find some books.
	my $return = $q->modified_self_url();
	my $search_url = $q->oligo_query('find-book.cgi',
					 return_address => $return,
					 multiple_p => 1);
	print $q->redirect($search_url);
	return;
    }
    elsif ($doit eq 'Move') {
	# Move the books and redirect.
	my $dbh = $books[0]->db_connection;
	$dbh->begin_work();
	for my $book (@books) {
	    $book->location_id($location_id);
	    $book->update($dbh);
	    $error_message = 'Oops:  ' . $dbh->errstr, last
		if $dbh->errstr;
	}
	if (! $error_message) {
	    $dbh->commit();
	    print $q->redirect($return_address);
	    return;
	}
	$dbh->rollback();
    }

    # Show a confirmation page. 
    $q->_header(title => 'Confirm move');
    print($q->p($q->b($error_message)), "\n")
	if $error_message;
    print($q->h3("Move the following books to ", $self->html_link($q)),
	  $q->start_form(), "\n",
	  $q->hidden(location_id => $location_id),
	  $q->hidden(book_id => $q->param('book_id')),
	  "\n<ul>\n");
    for my $book (@books) {
	my $old_location = $book->location;
	my $where = ($old_location
		     ? ' in ' . $old_location->html_link($q)
		     : '');
	print($q->li($book->html_link($q), $where), "\n");
    }
    print("</ul>\n", $q->commit_button(doit => 'Move'), ' &nbsp; ',
	  $q->submit(doit => 'Skip'),
	  $q->end_form(), "\n");
    $q->_footer();
}

sub web_move_locations {
    my ($self, $q) = @_;

    my @locations = map {
	my $location = Bookworm::Location->fetch($_);
	$location ? ($location) : ();
    } $q->param('new_child_id');
    my $return_address
	= $q->param('return_address') || $self->home_page_url($q);
    my $location_id = $self->location_id;
    my $doit = $q->param('doit') || '';
    my $error_message;
    if ($doit eq 'Skip') {
	print $q->redirect($return_address);
	return;
    }
    elsif (! @locations) {
	# Need to find some locations.
	my $return = $q->modified_self_url();
	my $search_url = $q->oligo_query('find-location.cgi',
					 return_address => $return,
					 return_field => 'new_child_id',
					 multiple_p => 1);
	print $q->redirect($search_url);
	return;
    }
    elsif ($doit eq 'Move') {
	# Move the locations and redirect.
	my $dbh = $self->db_connection;
	$dbh->begin_work();
	for my $location (@locations) {
	    $location->parent_location_id($location_id);
	    $location->update($dbh);
	    $error_message = 'Oops:  ' . $dbh->errstr, last
		if $dbh->errstr;
	}
	if (! $error_message) {
	    $dbh->commit();
	    print $q->redirect($return_address);
	    return;
	}
	$dbh->rollback();
    }

    # Show a confirmation page. 
    $q->_header(title => 'Confirm move');
    print($q->p($q->b($error_message)), "\n")
	if $error_message;
    print($q->h3("Move the following locations to ", $self->html_link($q)),
	  $q->start_form(), "\n",
	  $q->hidden(location_id => $location_id),
	  $q->hidden(new_child_id => $q->param('new_child_id')),
	  "\n<ul>\n");
    for my $location (@locations) {
	my $old_location = $location->parent_location;
	my $where = ($old_location
		     ? ' in ' . $old_location->html_link($q)
		     : '');
	print($q->li($location->html_link($q), $where), "\n");
    }
    print("</ul>\n", $q->commit_button(doit => 'Move'), ' &nbsp; ',
	  $q->submit(doit => 'Skip'),
	  $q->end_form(), "\n");
    $q->_footer();
}

sub web_delete_location {
    my ($self, $q) = @_;

    # Skip if requested.
    my $location_id = $self->location_id;
    my $doit = $q->param('doit') || '';
    my $error_message = '';
    if ($doit eq 'Skip') {
	my $return_address
	    = $q->param('return_address') || $self->home_page_url($q);
	my $url = $q->oligo_query($return_address,
				  message => 'Deletion skipped.');
	print $q->redirect($url);
	return;
    }

    # Do error checking and execute if requested.
    if (@{$self->location_children} || @{$self->book_children}) {
	$error_message
	    = 'Cannot delete a location with books or child locations.';
    }
    elsif (! $self->location_id) {
	$error_message = q{Cannot delete the root location "Somewhere".};
    }
    elsif ($doit eq 'Delete') {
	my $parent = $self->parent_location or die;
	$self->delete_row();
	my $return_address = $parent->home_page_url($q);
	my $message = $self->html_link(undef) . ' deleted.';
	my $url = $q->oligo_query($return_address, message => $message);
	print $q->redirect($url);
	return;
    }

    # Show the page.
    $q->_header(title => 'Delete ' . $self->html_link(undef));
    print($q->start_form(), "\n",
	  $q->hidden(location_id => $location_id), "\n");
    if ($error_message) {
	print($q->h3("Cannot delete ", $self->html_link($q)), "\n");
	print($q->p($q->b($error_message)), "\n");
	print($q->p($q->submit(doit => 'Skip')), "\n");
    }
    else {
	print($q->h3("Confirm:  Delete ", $self->html_link($q) . '?'), "\n");
	print($q->p($q->commit_button(doit => 'Delete'), ' &nbsp; ',
		    $q->submit(doit => 'Skip')), "\n");
    }
    print($q->end_form(), "\n");
    $q->_footer();
}

### Database plumbing.

sub insert {
    # Default the volume and weight.
    my ($self, $dbh) = @_;

    if (! $self->volume) {
	# Maybe default the volume based on a few standard names.
	my $volume;	# volume in cubic inches.
	my $name = $self->name || '';
	if ($name =~ /u-haul/i) {
	    if ($name =~ /medium/i) {
		$volume = 18 * 18 * 16;
	    }
	    elsif ($name =~ /large/i) {
		$volume = 18 * 18 * 25;
	    }
	    else {
		# U-Haul small, typically unlabelled as such.
		$volume = 13 * 16 * 13;
	    }
	}
	elsif ($name =~ /book box/i) {
	    $volume = 19 * 15 * 10
		unless $name =~ /short/i;
	}
	elsif ($name =~ /plastic crate/i) {
	    $volume = 22 * 13 * 15;
	}
	elsif ($name =~ /banker'?s? box/i) {
	    $volume = 16 * 13 * 10;
	}
	$self->volume($volume / (12.0 * 12.0 * 12.0))
	    if $volume;
    }

    # Last-ditch defaults; these are numeric and can't be undefined.
    $self->volume(0)
	unless defined($self->volume);
    $self->weight(0)
	unless defined($self->weight);
    return $self->SUPER::insert($dbh);
}

### Searching.

my $compute_density
    # If location.volume is zero, then density is zero, else compute normally.
    # This is split out so that it can be computed anew in any WHERE clause
    # selection, since computed columns are not yet in scope there.  We don't
    # worry about NULL values here as both columns are declared "NOT NULL".
    = q{if(location.volume = 0, 0, location.weight / location.volume)};

sub default_search_fields {
    return [ { accessor => 'name',
	       pretty_name => 'Location name',
	       search_type => 'string', search_field => 'location.name',
	       search_id => 'location.location_id' },
	     { accessor => 'description',
	       pretty_name => 'Description',
	       search_type => 'name', search_field => 'location.description' },
	     { accessor => 'destination', pretty_name => 'Destination',
	       type => 'string', search_field => 'location.destination' },
	     { accessor => 'weight', pretty_name => 'Packed weight',
	       type => 'number', search_field => 'location.weight' },
	     { accessor => 'volume', pretty_name => 'Volume',
	       type => 'number', search_field => 'location.volume' },
	     { accessor => 'density', pretty_name => 'Density',
	       type => 'number',
	       search_field => $compute_density },
	     'stackable',
	     { accessor => 'parent_name',
	       pretty_name => 'Parent location',
	       search_type => 'name', search_field => 'parent.name' },
	     { accessor => 'limit',
	       search_type => 'limit',
	       pretty_name => 'Max locations to show',
	       default => 100 }
	];
}

sub default_display_columns {
    return [ { accessor => 'name', pretty_name => 'Location',
	       type => 'return_address_link',
	       return_address => 'location.cgi',
	       default_sort => 'asc' },
	     qw(n_total_books description destination weight volume),
	     { accessor => 'density', pretty_name => 'Density',
	       type => 'number', n_digits => 3,
	       skip_if_not => \&has_density_p,
	       search_field => '_density' },
	     qw(stackable parent_location_id) ];
}

my $base_query
    # This needs to be a left join so that the top-level location (which
    # doesn't have a parent) can be returned as the result of a search.
    = qq{select location.*, parent.name as parent_name,
		$compute_density as _density
	 from location
	      left join location as parent
		   on parent.location_id = location.parent_location_id};

sub web_search {
    my ($class, $q, @options) = @_;

    $class->SUPER::web_search($q, base_query => $base_query, @options);
}

1;

__END__

=head1 Bookworm::Location

Class that represents a location which contains books (fetched by
L</book_children>) and possibly other locations (fetched by
L</location_children>).  The graph of L</parent_location_id> links
forms a tree, at the top of which is the root location, which is named
"Somewhere" (so it can include a suitably-named location for lost
books).

=head2 Accessors and methods

=head3 ajax_sort_content

Given a C<Bookworm::Location> and a C<ModGen::CGI> object, handles
AJAX requests to sort book or location content.

=head3 ancestor_of

Given another C<Bookworm::Location> object, returns true iff self
contains the other location.  This is used to prevent cycles by the
user interface that moves locations.

=head3 bg_color

Returns or sets a string that determines the background color of the
location name in most display contexts.  See the C<@background_colors>
array for allowed variables.  The special value "inherit" means to use
the location of our L</parent_location>, or no special background if
no ancestor specifies a color.  The L</backgroundify> method
implements the search.

=head3 book_children

Set fetch accessor that retrieves an arrayref of C<Bookworm::Book>
instances from the database that are stored at this location by virtue
of having their C<location_id> point to us.

=head3 children

Synonym for the L</location_children> accessor, to provide the
location hierarchy browser with something to browse.

=head3 container_items

Synonym for the L</book_children> accessor, so that locations can use
the container API for their books.
See L<ModGen::DB::Thing/The container API>.

=head3 default_display_columns

Returns an arrayref of attribute descriptors and attribute names for
location search result display.

=head3 default_search_fields

Returns an arrayref of attribute descriptors and attribute names that
define location search dialog fields.

=head3 density

Returns or sets a value for the density of the location.  This is
computed in SQL by the search page, so is only valid for search
results.

=head3 description

Returns or sets a free text description of the location.  This is
usually used to describe the purpose of the location, since I tend to
create locations that are fine-grained enough to be self-describing,
e.g. "Somewhere >> home >> Bedroom >> BR Bookshelf >> BR BS #3".

=head3 destination

Returns or sets the value of the database field that records a
free-text string where the user wants the location (usually a packed
box) to go after moving.

=head3 display_info

Add the number of books (if we have any) to what the superclass method
provides, used as extra information on the Location Tree page.

=head3 fetch_root

Class method that fetches the "Somewhere" location.  Hierarchy browser
support.

=head3 has_density_p

Return true if we have a meaningful density.  This is true if both
volume and weight are positive.

=head3 has_stackable_p

Returns true if it makes sense to consider the stackability of this
container.  This is so only if we have no child containers.

=head3 has_volume_p

Returns true if we have non-zero volume (since a zero float is not a
boolean false to Perl).

=head3 has_weight_p

Returns true if we have non-zero weight (since a zero float is not a
boolean false to Perl).

=head3 home_page_name

Returns the string "location.cgi", so that the C<home_page_url> method
of C<Bookworm::Base> can construct a URL for the book.  See the
L<ModGen::DB::Thing/html_link> method.

=head3 location_children

Set fetch accessor that retrieves an arrayref of C<Bookworm::Location>
instances from the database that are contained within this location by
virtue of having their C<location_id> point to us.

=head3 location_id

Returns or sets the primary key for the location.

=head3 n_local_books

Returns the number of books we contain, without fetching the books.
If the books in L</book_children> are already cached, we just count
them; otherwise, we ask the database to count them.

=head3 n_total_books

Returns the number of books contained locally (see L</n_local_books>)
plus all books contained in our L</location_children> recursively.

[This is potentially fairly expensive as it has to fetch all contained
locations, but locations are cached and not so numerous as books, so
it shouldn't be too bad.  -- rgr, 19-Mar-21.]

=head3 name

Returns or sets the location name.  This is not constrained to be
unique.

=head3 parent_location

Returns or sets the parent location, another C<Bookworm::Location>
instance, through the L</parent_location_id> slot.  When changing
this, be careful not to create cycles.

=head3 parent_location_id

Returns or sets the ID of the parent location, another
C<Bookworm::Location> instance.  When changing this, be careful not to
create cycles.

=head3 root_location_p

Returns true if we are the root location, tested by checking that the
C<location_id> is 1.  This is always true because the root location is
installed by the F<database/schema.sql> file, and testing the
C<location_id> rather than the name allows users to change the name.

=head3 sorted_children

Returns L</location_children> as a list (rather than an arrayref), to
provide the location hierarchy browser with something to browse.

=head3 stackable

Returns or sets a database field that records whether the location,
normally a box, is considered stackable.  Possible values are "yes"
(meaning arbitrary things can be stacked on top), "no" (meaning
anything stacked on top would be supported only on the location
container itself and not by the contents), or "never" (meaning do not
attempt to stack anything on this location).

Note that comparing the values as strings to sort them upwards puts
them in the order listed above, which is nicely (and serendipitously)
intuitive in terms of increasing stackability.

=head3 total_volume

Compute the sum of our C<volume> value and the C<total_volume> of each
of our L</location_children> recursively, i.e. the volume of
everything we contain.

=head3 total_weight

Compute the sum of our C<weight> value and the C<total_weight> of each
of our L</location_children> recursively, i.e. the weight of
everything we contain.

=head3 total_weight_p

Return true if we have a zero C<weight> value and at least one member
of L</location_children>.  Used as a C<skip_if_not> control for
whether to display our C<total_weight> value.

=head3 validate

Insist on having a parent location.

=head3 validate_parent_location_id

Validation method used by C<web_update> to ensure that a new
C<parent_location_id> is acceptable as a parent location, mostly that
we're not the root and the new parent doesn't create a cycle.  See the
L<ModGen::DB::Thing/web_update> method.

=head3 volume

Returns or sets the value of the database field that records the
volume of the location, usually a packed box.  The user interface does
not insist on this being in any particular units.

=head3 web_delete_location

Present a Web page that asks for confirmation before deleting an empty
location.

=head3 web_move_books

Presents a page that moves a selection of books to this location.
From a link presented by C<post_web_update>, we redirect to the
C<find-book.cgi> page to select one or more books.  With multiple
C<book_id> parameters in hand, we present a page with the book titles
and their old locations and ask the user to confirm the move.  If the
user clicks the confirm button, the book locations are updated, and
the user is redirected back to the destination location page.

=head3 web_move_locations

Given a C<ModGen::CGI> object, implements the C<move-locations.cgi>
page.  Redirects to C<find-location.cgi> to query the user for a set
of locations to move under C<$self>, presents a confirmation page, and
if told to make the change, updates the C<parent_location_id> of each
selected location to point to ourself, then redirects back to our
C<return_address>, or our home page if not given a C<return_address>.

=head3 weight

Returns or sets the value of the database field that records the
weight of the location, usually a packed box.  The database declares
this field as "decimal(5,1)", i.e. a fixed decimal number with one
fractional place.

=cut
