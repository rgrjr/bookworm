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

use Test::More;

# This is a permanent renaming.
$ENV{HARNESS_CGI_DIR} = './cgi';

### Helper methods.

sub find_or_create_publisher {
    my ($tester, $name, $city) = @_;
    require Bookworm::Publisher;

    my $publisher = Bookworm::Publisher->fetch($name, key => 'publisher_name');
    if ($publisher) {
	ok($publisher, "have '$name'");
    }
    else {
	$tester->run_script('cgi/publisher.cgi',
			    doit => 'Insert',
			    publisher_name => $name,
			    publisher_city => $city);
	$publisher = Bookworm::Publisher->fetch($name, key => 'publisher_name')
	    or die "failed to create '$name'";
    }
    return $publisher;
}

sub test_add_book {
    # 9 "ok" calls per invocation, plus 3 per author.
    my ($tester, $title, $publisher, $pub_year, $location, %keys) = @_;
    my $date_read = $keys{date_read} || '';
    my $category = $keys{category} || 'fiction';
    my $authors = $keys{authors} || [ ];

    my $new_book = $tester->test_add_object
	('cgi/book.cgi', 'Bookworm::Book',
	 title => $title,
	 publisher_id => $publisher->publisher_id,
	 publication_year => $pub_year,
	 category => 'fiction',
	 date_read => $date_read,
	 location_id => $location->location_id);
    # use Data::Dumper; warn Dumper($new_book);

    # Add author(s), creating if necessary.
    for my $author_name (@$authors) {
	my ($first, $last, $mid) = @$author_name;
	# [This is a kludge that we have to assume that last names are unique
	# in the test database.  -- rgr, 14-Jun-21.]
	my $author = Bookworm::Author->fetch($last, key => 'last_name');
	if (! $author) {
	    $tester->run_script('cgi/author.cgi',
				doit => 'Insert',
				first_name => $first,
				mid_name => $mid || '',
				last_name => $last);
	    $author = Bookworm::Author->fetch($last, key => 'last_name')
		or die "failed to create author '$first $last'";
	}
	else {
	    # This must be an "ok" to match the run_script "ok".
	    ok($author, "have " . $author->pretty_name);
	}
	$tester->run_script('cgi/add-book-author.cgi',
			    book_id => $new_book->book_id,
			    author_id => $author->author_id);
    }

    # Check the author(s).
    my $authorships = $new_book->authorships;
    ok(@$authorships == @$authors, 'has the right number of authors');
    for my $i (0 .. @$authors-1) {
	my $authorship = $authorships->[$i];
	is($authorship->author->last_name, $authors->[$i][1],
	   "authorship $i has the right last name");
    }
    return $new_book;
}

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
