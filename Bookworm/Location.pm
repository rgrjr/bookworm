# The Bookworm "Location" class.
#
# [created.  -- rgr, 25-May-13.]
#
# $Id$

use strict;
use warnings;

package Bookworm::Location;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Location->build_field_accessors
	([ qw(location_id name description parent_location_id) ]);
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
sub pretty_name { shift()->name; }
sub home_page_name { 'location.cgi'; }
sub search_page_name { 'find-location.cgi'; }

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

### Web interface.

my @local_display_fields
    = ({ accessor => 'name', pretty_name => 'Location',
	 type => 'self_link', class => 'Bookworm::Location' },
       { accessor => 'description', pretty_name => 'Description',
	 type => 'text' },
       { accessor => 'parent_location_id', pretty_name => 'Parent location',
	 edit_p => 'find-location.cgi',
	 type => 'location_chain',
	 validate => 'validate_parent_location_id' }
    );

sub local_display_fields {
    \@local_display_fields;
}

sub validate_parent_location_id {
    my ($self, $descriptor, $new_location_id) = @_;

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
    elsif ($self->location_id && ! $old_parent_location) {
	# If we are in the database without a parent, then we must be the root.
	return "Can't move the root.\n"
	    # Naughty, naughty.
	    if $new_location_id;
    }
    elsif (! $new_parent_location) {
	# It's OK to make (or leave) the parent location undefined.
	if ($new_location_id) {
	    "Location with ID '$new_location_id' doesn't exist.\n";
	}
    }
    elsif ($self->can('ancestor_of')
	   && $self->ancestor_of($new_parent_location)) {
	# Make sure we don't create a loop.  (If we can't do 'ancestor_of',
	# then we assume we can't contain other locations, which means we can't
	# be involved in a loop no matter where we're put.)
	"Can't move a location under itself!\n";
    }
}

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
    }
    $q->include_javascript('selection.js');
    my $unlink = $self->html_link(undef);
    my $child_locations = $self->location_children;
    return join("\n",
		$q->ul(map { $q->li($_); } @links),
		$q->h3("$unlink contents"),
		(@$child_locations
		 ? ($self->present_object_content
		       ($q, "$unlink locations", [ qw(name description) ],
			$child_locations)
		    . "<br>\n")
		 : ''),
		$self->present_object_content
		       ($q, "$unlink books",
			[ { accessor => 'book_id', pretty_name => 'Select?',
			    type => 'checkbox', checked_p => 0, label => ' ' },
			  { accessor => 'title', pretty_name => 'Title',
			    type => 'self_link' },
			  qw(publication_year authors category notes) ],
			$self->book_children),
		$q->make_selection_op_buttons(commit => 0, 'Move books'),
		"\n");
}

sub web_update {
    my ($self, $q, @options) = @_;

    my $message;
    my $doit = $q->param('doit') || '';
    if ($self->handle_container_selection($q)) {
	# Already done.
    }
    elsif (! $doit) {
    }
    elsif ($doit eq 'confirm_move' || $doit eq 'Move') {
	$message = $self->move_or_delete_items($q);
	return
	    unless $message;
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
    $self->SUPER::web_update
	($q, @options,
	 onsubmit => 'return submit_or_operate_on_selected(event)');
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
	     qw(description parent_location_id) ];
}

1;
