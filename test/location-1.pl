#!/usr/bin/perl
#
# Test script for locations.
#
# [created.  -- rgr, 8-Jun-21.]
#

use strict;
use warnings;

use lib 'test';

use Bookworm::Test;

use Test::More tests => 59;

my $tester = Bookworm::Test->new();
my $dbh = $tester->database_handle;

### Subroutines.

sub check_locations {
    # It is safer to use SQL to check the state in the database, since that
    # will not be confused by local caching.
    my $desired_location_name = shift;

    my $select_base = q(select loc2.name
			from location as loc1
			     join location as loc2 on
			          loc1.parent_location_id = loc2.location_id);
    for my $name (@_) {
	my ($parent_name)
	    = $dbh->selectrow_array(qq($select_base
				       where loc1.name = '$name'));
	if ($desired_location_name) {
	    ok($parent_name eq $desired_location_name,
	       "Location $name should be in '$desired_location_name'.");
	}
	else {
	    ok(! $parent_name,
	       "Location $name should not have a location.");
	}
    }
}

sub test_move {
    # 5 "ok" calls per invocation.
    my ($moved_name, $old_loc_name, $new_loc_name, $fail_p) = @_;

    my $moved = Bookworm::Location->fetch($moved_name, key => 'name');
    ok($moved, "have $moved_name")
	or return;
    check_locations($old_loc_name, $moved_name);
    my $new = Bookworm::Location->fetch($new_loc_name, key => 'name');
    ok($new, "have $new_loc_name")
	or return;
    $tester->run_script('cgi/location.cgi',
			location_id => $moved->location_id,
			parent_location_id => $new->location_id,
			doit => 'Update');
    check_locations($fail_p ? $old_loc_name : $new_loc_name, $moved_name);
}

### Main code.

use_ok('Bookworm::Location');

## Get rid of these test locations.
my @location_names = ('room', 'bookcase', 'shelf');
for my $loc_name (@location_names, qw(bookcase2 shelf2)) {
    my $loc = Bookworm::Location->fetch($loc_name, key => 'name');
    $loc->destroy_utterly()
	if $loc;
}

## Create some locations.
my $root = Bookworm::Location->fetch_root();
ok($root, "have location root")
    or die;
my $shelf = $tester->create_contained_locations($root, @location_names);
my $room = Bookworm::Location->fetch('room', key => 'name');
ok($room, 'have room') or die;

## Test updating fields.
$shelf->description('Updated shelf description');
$shelf->name('top shelf');
$shelf->update();
Bookworm::Location->flush_cache();
$shelf = ref($shelf)->fetch($shelf->location_id);
ok($shelf, 'decached shelf') or die;
is($shelf->description, 'Updated shelf description', 'description updated');
is($shelf->name, 'top shelf', 'name updated');
# Rename back.
$shelf->name('shelf');
$shelf->update();

## Test some creation attempts that should fail.
$tester->run_script
    ('cgi/location.cgi',
     name => 'no parent');
ok(! Bookworm::Location->fetch('no parent', key => 'name'),
   'parentless location not created');
$tester->run_script
    ('cgi/location.cgi',
     parent_location_id => $root->location_id);
$root->location_children(undef);	# decache;
my ($nameless) = grep { ! $_->name; } @{$root->location_children};
ok(! $nameless, 'nameless location not created');

## Create more locations to test some moves.
$tester->create_contained_locations($room, qw(bookcase2 shelf2));
test_move(qw(shelf2 bookcase2 bookcase));
test_move(qw(shelf bookcase bookcase2));

## Test some moves that should not work.
# Can't move the root.
test_move('Somewhere', undef, 'shelf', 1);
# Can't move something into something it contains.
test_move(qw(bookcase2 room shelf), 1);

## Test background color inheritance.
my $case2 = Bookworm::Location->fetch('bookcase2', key => 'name');
ok($case2, 'have bookcase2') or die;
$case2->bg_color('purple');
$case2->update();
my $shelf2 = Bookworm::Location->fetch('shelf2', key => 'name');
ok($shelf2, 'have shelf2') or die;
is($shelf2->bg_color, 'inherit',
   "the background of shelf2 is 'inherit'");
use ModGen::CGI;
my $query = ModGen::CGI->new();
is($case2->_backgroundify($query, 'link'),
   '<span style="background: #fcf;">link</span>',
   "have purple background link");

## All done.
$tester->clean_up;
