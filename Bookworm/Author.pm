# The Bookworm "Author" class.
#
# [created.  -- rgr, 29-Jan-11.]
#

use strict;
use warnings;

package Bookworm::Author;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Author->build_field_accessors
	([ qw(author_id first_name mid_name last_name notes) ]);
    # These are created during search.
    Bookworm::Author->define_class_slots(qw(author_sort_name n_books));
}

sub table_name { 'author'; }
sub primary_key { 'author_id'; }

sub pretty_name { shift()->author_name(); }
sub home_page_name { 'update-author.cgi'; }
sub search_page_name { 'find-author.cgi'; }

sub books {
    my $self = shift;

    if (@_) {
	$self->{_books} = shift;
    }
    elsif ($self->{_books}) {
	return $self->{_books};
    }
    else {
	require Bookworm::Book;
	my $books = [ ];
	my $query = qq(select bam.book_id
		       from book_author_map as bam
                            join book on bam.book_id = book.book_id
		       where author_id = ?
                       order by title);
	my $dbh = $self->connect_to_database;
	my $ids = $dbh->selectcol_arrayref($query, undef, $self->author_id)
	    or die $dbh->errstr;
	for my $id (@$ids) {
	    push(@$books, Bookworm::Book->fetch($id));
	}
	$self->{_books} = $books;
	return $books;
    }
}

sub validate {
    my ($self, $interface) = @_;

    $interface->_error("Authors must have at least a last name.\n")
	unless $self->last_name;
}

sub author_name {
    my $self = shift;

    my $result = '';
    for my $field (qw(first_name mid_name last_name)) {
	my $name = $self->$field();
	next
	    unless $name;
	$result .= ' '
	    if $result;
	$result .= $name;
    }
    return $result;
}

my @field_descriptors
    = ({ accessor => 'author_id', pretty_name => 'Author', verbosity => 2 },
       { accessor => 'first_name', pretty_name => 'First name',
	 type => 'string' },
       { accessor => 'mid_name', pretty_name => 'Middle name',
	 type => 'string' },
       { accessor => 'last_name', pretty_name => 'Last name',
	 type => 'string', default_sort => 'asc' },
       { accessor => 'notes', pretty_name => 'Notes',
	 type => 'text' }
    );

sub local_display_fields { return \@field_descriptors };

sub default_search_fields {
    return [ { accessor => 'last_name', pretty_name => 'Author name',
	       type => 'string',
	       search_field => [ qw(first_name mid_name last_name) ] },
	     'notes' ];
}

sub default_display_columns {
    return [ { accessor => 'author_sort_name', pretty_name => 'Author name',
	       type => 'return_address_link',
	       return_address => 'update-author.cgi',
	       order_by => '_author_sort_name' },
	     { accessor => 'n_books', pretty_name => '# books',
	       order_by => '_n_books' },
	     qw(notes) ];
}

my $web_search_base_query
    = q{select author.*, 
	       concat(last_name, ', ', first_name, ' ', mid_name)
		   as _author_sort_name,
	       count(bam.author_id) as _n_books
	from author
	     left join book_author_map as bam
		  on bam.author_id = author.author_id};

sub web_search {
    # Add "left join" & "group by" so we can count books.  This must be a left
    # join so we include authors without books (yet).
    my ($class, $q, @options) = @_;

    return $class->SUPER::web_search
	($q,
	 base_query => $web_search_base_query,
	 extra_clauses => 'group by author.author_id',
	 @options);
}

my $book_columns
    = [ { accessor => 'title', pretty_name => 'Book',
	  type => 'return_address_link',
	  return_address => 'add-book.cgi' },
	qw(publication_year category notes date_read location_id) ];

sub post_web_update {
    my ($self, $q) = @_;

    my @stuff;
    my $author_book_link
	= $q->oligo_query('add-book.cgi',
			  author_id => $self->author_id);
    push(@stuff,
	 $q->a({ href => $author_book_link }, '[Add book]'));
    my $books = $self->books;
    join("\n", $q->ul(map { $q->li($_); } @stuff),
	 $self->present_object_content($q, 'Books by this author',
				       $book_columns, $books));
}

1;
