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
use Test::More tests => 18;

my $tester = Bookworm::Test->new();
my $test_transcript_file = $tester->test_transcript_file;
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

sub test_failing_move {
    # 5 "ok" calls per invocation.
    my ($moved_name, $old_loc_name, $new_loc_name) = @_;

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
    check_locations($old_loc_name, $moved_name);
}

### Main code.

use_ok('Bookworm::Location');

## Get rid of these test locations.
my @location_names = ('room', 'bookcase', 'shelf');
for my $loc_name (@location_names) {
    my $loc = Bookworm::Location->fetch($loc_name, key => 'name');
    $loc->destroy_utterly()
	if $loc;
}

## Create some locations.
my $root = Bookworm::Location->fetch_root();
ok($root, "have location root")
    or die;
{
    my $container = $root;
    for my $loc_name (@location_names) {
	my $parent_id = $container->location_id;
	$tester->run_script('cgi/location.cgi',
			    doit => 'Insert',
			    name => $loc_name,
			    parent_location_id => $parent_id,
			    description => "Test $loc_name");
	# We don't need to check the output or the database, because it is
	# sufficient that this "fetch" succeed.
	$container = Bookworm::Location->fetch($loc_name, key => 'name');
	ok($container, "created location '$loc_name'");
    }
}

## Test some moves that should not work.
# Can't move the root.
test_failing_move('Somewhere', undef, 'shelf');
# Can't move something into something it contains.
test_failing_move(qw(bookcase room shelf));

## All done.
$tester->clean_up;
