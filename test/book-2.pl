#!/usr/bin/perl
#
# Another test script for books with multiple authors.
#
# [created.  -- rgr, 14-Jun-21.]
#

use strict;
use warnings;

use lib 'test';

use Bookworm::Test;
use Bookworm::Book;
use Bookworm::Author;
use Bookworm::Location;

use Test::More tests => 82;

my $tester = Bookworm::Test->new();

### Main code.

## Get rid of these test books.
for my $title ('Shadow of the Lion, The',
	       'Within Reach: My Everest Story',
	       'Best SF: 1967',
	       'Love In The Time Of Cholera') {
    while (my $book = Bookworm::Book->fetch($title, key => 'title')) {
	$book->destroy_utterly();
    }
}
Bookworm::Book->flush_cache();

## Start with the first book.
my $pub1 = $tester->find_or_create_publisher
    ('Baen Publishing Enterprises', 'Riverdale NY');
my $shelf2 = Bookworm::Location->fetch('shelf2', key => 'name');
my $shadow
    = $tester->test_add_book('Shadow of the Lion, The', $pub1, 2002, $shelf2,
			     authors => [ [ qw(Mercedes Lackey) ],
					  [ qw(Eric Flint) ],
					  [ qw(David Freer) ] ],
			     date_read => '2020-11-15');
my $authors = $shadow->format_authorship_field
    (undef, undef, 'authors', 1, $shadow->authors);
is($authors, 'Mercedes Lackey, Eric Flint, David Freer',
   "formatted authorship matches");

## Do another that has a "with" author.
my $penguin = $tester->find_or_create_publisher
    ('Penguin Books, Ltd.', 'London');
my $reach = $tester->test_add_book('Within Reach: My Everest Story',
				   $penguin, 1998, $shelf2,
				   authors => [ [ qw(Mark Pfetzer) ],
						[ qw(Jack Galvin) ] ],
				   date_read => '2020-07-17');
$authors = $reach->format_authorship_field
    (undef, undef, 'authors', 1, $reach->authors);
is($authors, 'Mark Pfetzer and Jack Galvin',
   "formatted authorship matches");
my $galvin_ship = $reach->authorships->[1];
$tester->run_script('cgi/update-authorship.cgi',
		    authorship_id => $galvin_ship->authorship_id,
		    role => 'with',
		    doit => 'Update');
delete($reach->{_book_authorships});	# decache;
$authors = $reach->format_authorship_field
    (undef, undef, 'authors', 1, $reach->authors);
is($authors, 'Mark Pfetzer with Jack Galvin',
   "new formatted authorship matches");

## And another that with two editors.
my $berkeley = $tester->find_or_create_publisher
    ('Berkeley Publishing Group', 'New York');
my $best_sf = $tester->test_add_book('Best SF: 1967', $berkeley, 1967, $shelf2,
				     authors => [ [ qw(Harry Harrison) ],
						  [ qw(Brian Aldiss W.) ] ],
				     date_read => q{1970's});
$authors = $best_sf->format_authorship_field
    (undef, undef, 'authors', 1, $best_sf->authors);
is($authors, 'Harry Harrison and Brian W. Aldiss',
   "original formatted authorship matches");
for my $ship (@{$best_sf->authorships}) {
    $tester->run_script('cgi/update-authorship.cgi',
			authorship_id => $ship->authorship_id,
			role => 'editor',
			doit => 'Update');
}
delete($best_sf->{_book_authorships});	# decache;
$authors = $best_sf->format_authorship_field
    (undef, undef, 'authors', 1, $best_sf->authors);
is($authors, 'Harry Harrison and Brian W. Aldiss, eds',
   "new formatted authorship matches");

## And finally, one with a translator.
my $knopf = $tester->find_or_create_publisher
    ('Alfred A. Knopf, Inc.', 'New York');
my $love = $tester->test_add_book('Love In The Time Of Cholera', $knopf,
				  1988, $shelf2,
				  authors => [ [ qw(Gabriel Marquez Garcia) ],
					       [ qw(Edith Grossman) ] ],
				  date_read => q{2020-12-27});
$authors = $love->format_authorship_field
    (undef, undef, 'authors', 1, $love->authors);
is($authors, 'Gabriel Garcia Marquez and Edith Grossman',
   "original formatted authorship matches");
my $grossman_ship = $love->authorships->[1];
$tester->run_script('cgi/update-authorship.cgi',
		    authorship_id => $grossman_ship->authorship_id,
		    role => 'translator',
		    doit => 'Update');
delete($love->{_book_authorships});	# decache;
$authors = $love->format_authorship_field
    (undef, undef, 'authors', 1, $love->authors);
is($authors, 'Gabriel Garcia Marquez, translated by Edith Grossman',
   "new formatted authorship matches");

## All done.
$tester->clean_up;
