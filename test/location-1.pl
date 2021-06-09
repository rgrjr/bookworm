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
use Test::More tests => 8;

my $tester = Bookworm::Test->new();
my $test_transcript_file = $tester->test_transcript_file;
my $dbh = $tester->database_handle;

### Subroutines.

sub check_locations {
    # It is safer to use SQL to check the state in the database, since that
    # will not be confused by local caching.
    my $desired_location_barcode = shift;

    my $select_base = q(select loc2.barcode
			from storage_location as loc1
			     join storage_location as loc2 on
			          loc1.parent_location_id = loc2.location_id);
    for my $barcode (@_) {
	my ($parent_barcode)
	    = $dbh->selectrow_array(qq($select_base
				       where loc1.barcode = '$barcode'));
	if ($desired_location_barcode) {
	    ok($parent_barcode eq $desired_location_barcode,
	       "Location $barcode should be in '$desired_location_barcode'.");
	}
	else {
	    ok(! $parent_barcode,
	       "Location $barcode should not have a location.");
	}
    }
}

sub test_failing_move {
    # 8 "ok" calls per invocation, or 5 if $old_loc_barcode is undef.
    my ($moved_barcode, $old_loc_barcode, $new_loc_barcode) = @_;

    my $moved = Bookworm::Location->fetch_barcode($moved_barcode);
    ok($moved, "have $moved_barcode")
	or return;
    check_locations($old_loc_barcode, $moved_barcode);
    my $new = Bookworm::Location->fetch_barcode($new_loc_barcode);
    ok($new, "have $new_loc_barcode")
	or return;
    $tester->run_script('public_html/location/view-location.cgi',
			location_id => $moved->location_id,
			parent_location_id => $new->location_id,
			doit => 'Update');
    check_locations($old_loc_barcode, $moved_barcode);

    # Now test moving via the web_update multiple "Move to new ..." interface.
    return
	unless $old_loc_barcode;
    my $old = Bookworm::Location->fetch_barcode($old_loc_barcode);
    ok($old, "have $old_loc_barcode")
	or return;
    $tester->run_script('public_html/location/view-location.cgi',
			location_id => $old->location_id,
			child_location_id => $moved->location_id,
			destination_container_id => $new->location_id,
			doit => 'Move');
    check_locations($old_loc_barcode, $moved_barcode);
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

## All done.
$tester->clean_up;
