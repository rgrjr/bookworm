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

use Test::More tests => 18;

my $tester = Bookworm::Test->new();

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
