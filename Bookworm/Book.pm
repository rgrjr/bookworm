# The Bookworm "Book" class.
#
# [created.  -- rgr, 29-Jan-11.]
#
# $Id$

use strict;
use warnings;

package Bookworm::Book;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Book->build_field_accessors
	([ qw(book_id title publisher_id publication_year
              category notes location_id) ]);
}

sub table_name { 'book'; }
sub primary_key { 'book_id'; }

# Autoloaded subs.
    sub web_add_author;

sub pretty_name { shift()->title(); }
sub home_page_name { 'add-book.cgi'; }

sub authors {
    my ($self, @new_value) = @_;

    if (@new_value) {
	$self->{_authors} = $new_value[0];
    }
    elsif ($self->{_authors}) {
	return $self->{_authors};
    }
    else {
	require Bookworm::Author;
	my $authors = [ ];
	my $query = qq(select author_id
		       from book_author_map
		       where book_id = ?);
	my $dbh = $self->connect_to_database;
	my $ids = $dbh->selectcol_arrayref($query, undef, $self->book_id)
	    or die $dbh->errstr;
	for my $id (@$ids) {
	    push(@$authors, Bookworm::Author->fetch($id));
	}
	$self->{_authors} = $authors;
	return $authors;
    }
}

sub validate {
    my ($self, $interface) = @_;

    $interface->_error("Books must have a title.\n")
	unless $self->title;
    $interface->_error("Books must have a publisher.\n")
	unless $self->publisher_id;
}

sub format_authors_field {
    my ($self, $q, $descriptor, $cgi_param, $read_only_p, $value) = @_;

    if ($value && ref($value) && @$value) {
	return join(' ', map {
	    my $id = $_->author_id;
	    ($_->html_link($q)
	     . qq{<input type="hidden" name="author_id" value="$id">});
		    } @$value);
    }
    else {
	return 'none';
    }
}

my @field_descriptors
    = ({ accessor => 'book_id', verbosity => 2 },
       { accessor => 'title', pretty_name => 'Title',
	 type => 'string', size => 50 },
       { accessor => 'authors', pretty_name => 'Authors',
	 type => 'authors' },
       { accessor => 'publisher_id', pretty_name => 'Publisher',
	 type => 'foreign_key', class => 'Bookworm::Publisher',
	 edit_p => 'find-publisher.cgi' },
       { accessor => 'publication_year', pretty_name => 'Year',
	 type => 'string' },
       { accessor => 'category', pretty_name => 'Category',
	 type => 'enumeration',
	 values => [ qw(fiction sf history biography text nonfiction) ] },
       { accessor => 'notes', pretty_name => 'Notes',
	 type => 'text' },
       { accessor => 'location_id', pretty_name => 'Location',
	 edit_p => 'find-location.cgi',
	 type => 'location_chain' }
    );

sub local_display_fields { return \@field_descriptors };

sub default_search_fields {
    my ($class) = @_;

    return [ {  accessor => 'title',
		pretty_name => 'Title/ID',
		search_type => 'string',
		search_id => 'book_id',
		search_field => 'title' },
	     qw(publication_year category notes),
	     { accessor => 'limit',
	       search_type => 'limit',
	       pretty_name => 'Max books to show',
	       default => 100 } ];
}

sub default_display_columns {
    return [ { accessor => 'title', pretty_name => 'Book',
	       type => 'return_address_link',
	       return_address => 'add-book.cgi' },
	     qw(publisher_id publication_year category notes location_id) ];
}

sub web_update {
    my ($self, $q) = @_;

    my @authors = $q->param('author_id');
    if (@authors) {
	# [total hack.  -- rgr, 25-May-13.]
	require Bookworm::Author;
	$self->authors([ map { Bookworm::Author->fetch($_); } @authors ]);
    }
    $self->SUPER::web_update($q);
}

sub post_web_update {
    my ($self, $q) = @_;

    my @links;
    my $similar_book_link
	= $q->oligo_query('add-book.cgi',
			  (map { ($_ => $self->$_());
			   } qw(publisher_id publication_year
				category location_id)),
			  (map { (author_id => $_->author_id);
			   } @{$self->authors}));
    push(@links,
	 $q->a({ href => $similar_book_link }, '[Add similar book]'));
    push(@links,
	 $q->a({ href => $q->oligo_query('add-book-author.cgi',
					 book_id => $self->book_id) },
	       '[Add author]'));
    return $q->ul(map { $q->li($_); } @links);
}

### Database plumbing.

sub _update_author_data {
    # If we have an "authors" arrrayref, update book_author_map to match.
    my ($self, $dbh) = @_;

    my $authors = $self->{_authors};
    return
	# Must not have changed.
	unless $authors;
    my $book_id = $self->book_id || die;
    $dbh->do(q{delete from book_author_map
	       where book_id = ?},
	     undef, $book_id)
	or die $dbh->errstr;
    for my $author (@$authors) {
	$dbh->do(q{insert into book_author_map (book_id, author_id)
		   values (?, ?)},
		 undef, $book_id, $author->author_id)
	    or die $dbh->errstr;
    }
}

sub insert {
    my ($self, $dbh) = @_;

    $self->SUPER::insert($dbh);
    $self->_update_author_data($dbh);
    return $self;
}

1;
