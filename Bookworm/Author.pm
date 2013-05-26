# The Bookworm "Author" class.
#
# [created.  -- rgr, 29-Jan-11.]
#
# $Id$

use strict;
use warnings;

package Bookworm::Author;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Author->build_field_accessors
	([ qw(author_id first_name mid_name last_name notes) ]);
}

sub table_name { 'author'; }
sub primary_key { 'author_id'; }

sub pretty_name { shift()->author_name(); }
sub home_page_name { 'update-author.cgi'; }

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

    $interface->_error('Authors must have (at least) ',
		       "a first name and a last name.\n")
	unless $self->first_name && $self->last_name;
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
    = ({ accessor => 'author_id', verbosity => 2 },
       { accessor => 'first_name', pretty_name => 'First name',
	 type => 'string' },
       { accessor => 'mid_name', pretty_name => 'Middle name',
	 type => 'string' },
       { accessor => 'last_name', pretty_name => 'Last name',
	 type => 'string' },
       { accessor => 'notes', pretty_name => 'Notes',
	 type => 'string' }
    );

sub local_display_fields { return \@field_descriptors };

my $book_columns
    = [ { accessor => 'title', pretty_name => 'Book',
	  type => 'return_address_link',
	  return_address => 'add-book.cgi' },
	qw(publication_year category notes) ];

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
