#!/usr/bin/perl
#
# Another test script for moving books.
#
# [created.  -- rgr, 27-Jun-21.]
#

use strict;
use warnings;

use lib 'test';

use Bookworm::Test;
use Bookworm::Book;
use Bookworm::Author;
use Bookworm::Location;

use Test::More tests => 60;

my $tester = Bookworm::Test->new();

### Subroutine.

sub verify_location_books {
    # One "ok" call for every element in the $expected_titles arrayref, plus
    # one failing "ok" call for every book that is there that shouldn't be.
    # Uses direct SQL so that it can't be confused by caching.
    my ($loc, $expected_titles) = @_;

    my $location_name = $loc->name;
    my %title_expected_p = map { ($_ => 1); } @$expected_titles;
    my $sql = q{select title from book where location_id = ?};
    my $dbh = $tester->database_handle();
    my $titles = $dbh->selectcol_arrayref($sql, undef, $loc->location_id)
	or die $dbh->errstr;
    for my $title (@$titles) {
	if (ok($title_expected_p{$title},
	       "'$title' is in location '$location_name'")) {
	    delete($title_expected_p{$title});
	}
    }
    # There should be nothing left in %title_expected_p.
    for my $extra (keys(%title_expected_p)) {
	ok(0, "'$extra' was not found in location '$location_name'");
    }
}

### Main code.

## Destroy boxes and their contained books.
for my $loc_name (qw(box1 box2)) {
    my $loc = Bookworm::Location->fetch($loc_name, key => 'name');
    $loc->destroy_utterly()
	if $loc;
}
 
## Create some locations.
my $root = Bookworm::Location->fetch_root();
ok($root, "have location root")
    or die;
my $box1 = $tester->create_contained_locations($root, qw(room2 box1));
my $room = Bookworm::Location->fetch('room2', key => 'name');
ok($room, 'have room2') or die;
my $box2 = $tester->create_contained_locations($room, qw(box2));
ok($box1 && $box2, "have a pair of boxes");

## Create some books, and put them in $box1.
my $pub = $tester->find_or_create_publisher
    ('Baen Publishing Enterprises', 'Riverdale NY');
my $basilisk = $tester->test_add_book
    ('On Basilisk Station', $pub, 1993, $box1,
     authors => [ [ qw(David Weber) ] ],
     date_read => '2013-01-21',
     notes => q{"Honor Harrington" series book 1.});
my $honor = $tester->test_add_book
    ('Honor of the Queen, The', $pub, 1993, $box1,
     authors => [ [ qw(David Weber) ] ],
     date_read => '2013-01-25',
     notes => q{"Honor Harrington" series book 2.
The covers have fallen off});
my $war = $tester->test_add_book
    ('Short Victorious War, The', $pub, 1994, $box1,
     authors => [ [ qw(David Weber) ] ],
     date_read => '2012-10-26',
     notes => q{"Honor Harrington" series book 3.});

## Use the book.cgi page to move the first to the other box.
$tester->run_script('cgi/book.cgi',
		    book_id => $basilisk->book_id,
		    location_id => $box2->location_id,
		    doit => 'Update');
verify_location_books($box2, [ 'On Basilisk Station' ]);

## All done.
$tester->clean_up;
