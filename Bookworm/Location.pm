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
	([ qw(location_id name description bg_color parent_location_id) ]);
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
       { accessor => 'bg_color', pretty_name => 'Background',
	 type => 'enumeration',
	 values => \@background_colors },
       { accessor => 'n_total_books', pretty_name => 'Books',
	 type => 'integer', read_only_p => 1 },
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
		 [ qw(name n_total_books description) ],
		 $child_locations,
		 prefix => 'locations');
    }
    elsif ($prefix eq 'book') {
	my $books = $self->book_children;
	my $book_presenter = @$books ? $books->[0] : $self;
	$messages->{book_content}
	    = $book_presenter->present_sorted_content
		($q, "$unlink books",
		 [ { accessor => 'book_id', label => ' ',
		     pretty_name => 'Select?',
		     type => 'checkbox', checked_p => 0 },
		   { accessor => 'title', pretty_name => 'Title',
		     type => 'self_link' },
		   qw(publication_year authors category notes) ],
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

    my @links;
    if ($self->location_id) {
	my $url = $q->oligo_query('location.cgi',
				  parent_location_id => $self->location_id);
	push(@links, $q->a({ href => $url }, '[Add child location]'));
	$url = $q->oligo_query('move-books.cgi',
			       location_id => $self->location_id);
	push(@links, $q->a({ href => $url }, '[Move book(s) here]'));
	unless (@{$self->location_children} || @{$self->book_children}) {
	    $url = $q->oligo_query('delete-location.cgi',
				   location_id => $self->location_id);
	    push(@links, $q->a({ href => $url }, '[Delete location]'));
	}
    }
    my $unlink = $self->html_link(undef);
    my $child_locations = $self->location_children;
    my $books = $self->book_children;
    my $selection_buttons
	= (@$books
	   ? $q->make_selection_op_buttons(commit => 0, 'Move books')
	   : '');
    my $book_presenter = @$books ? $books->[0] : $self;
    return join("\n",
		$q->ul(map { $q->li($_); } @links),
		$q->div({ id => 'debug' }, ''),
		$q->h3("$unlink contents"),
		$q->div({ id => 'locations_content' },
			(@$child_locations
			 ? ($self->present_sorted_content
			    ($q, "$unlink locations",
			     [ qw(name n_total_books description) ],
			     $child_locations,
			     prefix => 'locations', default_sort => 'name')
			    . "<br>\n")
			 : '')),
		$q->div({ id => 'book_content' },
			$book_presenter->present_sorted_content
			    ($q, "$unlink books",
			     [ { accessor => 'book_id', label => ' ',
				 pretty_name => 'Select?',
				 type => 'checkbox', checked_p => 0 },
			       { accessor => 'title', pretty_name => 'Title',
				 type => 'self_link' },
			       qw(publication_year authors category notes) ],
			     $books,
			     prefix => 'book', default_sort => 'title:up')),
		$selection_buttons, "\n");
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

### Searching.

sub default_search_fields {
    return [ { accessor => 'name',
	       pretty_name => 'Location name',
	       search_type => 'string',
	       search_id => 'location_id' },
	     { accessor => 'description',
	       pretty_name => 'Description',
	       search_type => 'name' },
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
	     qw(description n_total_books parent_location_id) ];
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

=head3 description

Returns or sets a free text description of the location.  This is
usually used to describe the purpose of the location, since I tend to
create locations that are fine-grained enough to be self-describing,
e.g. "Somewhere >> home >> Bedroom >> BR Bookshelf >> BR BS #3".

=head3 display_info

Add the number of books (if we have any) to what the superclass method
provides, used as extra information on the Location Tree page.

=head3 fetch_root

Class method that fetches the "Somewhere" location.  Hierarchy browser
support.

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

=head3 validate

Insist on having a parent location.

=head3 validate_parent_location_id

Validation method used by C<web_update> to ensure that a new
C<parent_location_id> is acceptable as a parent location, mostly that
we're not the root and the new parent doesn't create a cycle.  See the
L<ModGen::DB::Thing/web_update> method.

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

=cut
