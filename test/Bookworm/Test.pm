# Testing helper class for Bookworm pages.
#
# [created.  -- rgr, 8-Jun-21.]
#

package Bookworm::Test;

use strict;
use warnings;

BEGIN {
    # We need these now in order to load ModGen::Test.
    unshift(@INC, split(':', $ENV{HARNESS_EXTRA_LIBS}));
}

use parent qw(ModGen::Test);

# This is a permanent renaming.
$ENV{HARNESS_CGI_DIR} = './cgi';

### Object destruction methods.

package Bookworm::Location;

sub destroy_utterly {
    my $self = shift;

    my $location_id = $self->location_id;
    my $dbh = $self->db_connection();
    # warn "destroy location $location_id";
    return
	if ! $location_id;

    # Get rid of our books.
    for my $book (@{$self->book_children}) {
	# These must be destroyed because they require locations.
	$book->destroy_utterly();
    }
    # Get rid of child locations recursively.
    for my $location (@{$self->location_children}) {
	$location->destroy_utterly();
    }
    # Get rid of the location row.
    $dbh->do(qq(delete from location where location_id=?),
	     undef, $location_id)
	or die $dbh->errstr;
}

package Bookworm::Publisher;

sub destroy_utterly {
    my ($self) = @_;
    use Bookworm::Book;

    my $publisher_id = $self->publisher_id;
    my $dbh = $self->db_connection();
    return
	if ! $publisher_id;
    # warn "destroy publisher $publisher_id";

    # Get rid of our books, which must be destroyed because they require
    # publishers.
    my $book_ids = $dbh->selectcol_arrayref
	(q{select book_id from book where publisher_id = ?},
	 undef, $publisher_id)
	or die "bug:  ", $dbh->errstr;
    for my $book_id (@$book_ids) {
	my $book = Bookworm::Book->fetch($book_id);
	$book->destroy_utterly()
	    if $book;
    }
    # Get rid of the publisher row.
    $dbh->do(qq(delete from publisher where publisher_id=?),
	     undef, $publisher_id)
	or die $dbh->errstr;
}

package Bookworm::Author;

sub destroy_utterly {
    # Deleting authors is easy, because they are only referenced through the
    # book_author_map.
    my ($self) = @_;

    my $author_id = $self->author_id;
    return
	unless $author_id;
    my $dbh = $self->db_connection();
    for my $table (qw{book_author_map author}) {
	$dbh->do(qq{delete from $table where author_id = ?}, undef, $author_id)
	    or die $dbh->errstr;
    }
}

package Bookworm::Book;

sub destroy_utterly {
    # Deleting books is also easy, because they only point to things (including
    # through the book_author_map), rather than the other way around.
    my ($self) = @_;

    my $book_id = $self->book_id;
    return
	unless $book_id;
    my $dbh = $self->db_connection();
    for my $table (qw{book_author_map book}) {
	$dbh->do(qq{delete from $table where book_id = ?}, undef, $book_id)
	    or die $dbh->errstr;
    }
}

1;
