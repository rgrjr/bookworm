#!/usr/bin/perl
#
# Test script for publishers.
#
# [created.  -- rgr, 13-Jun-21.]
#

use strict;
use warnings;

use lib 'test';

use Bookworm::Test;

use Test::More tests => 7;

my $tester = Bookworm::Test->new();
my $dbh = $tester->database_handle;

### Subroutines.

### Main code.

use_ok('Bookworm::Publisher');

## Get rid of these test publishers.
for my $pub_name ('Reilly & Lee', 'Reilly & Lee Company') {
    my $pub = Bookworm::Publisher->fetch($pub_name, key => 'publisher_name');
    $pub->destroy_utterly()
	if $pub;
}

## Create a publisher.
$tester->run_script('cgi/publisher.cgi',
		    doit => 'Insert',
		    publisher_name => 'Reilly & Lee',
		    publisher_city => 'Chicago');
my $reilly = Bookworm::Publisher->fetch('Reilly & Lee',
					key => 'publisher_name');
ok($reilly, 'have reilly') or die;
is($reilly->publisher_city, 'Chicago', 'city matches');

## Test updating fields.
$reilly->publisher_city('Chicago IL');
$reilly->publisher_name('Reilly & Lee Company');
$reilly->update();
Bookworm::Publisher->flush_cache();
$reilly = ref($reilly)->fetch($reilly->publisher_id);
ok($reilly, 'decached publisher') or die;
is($reilly->publisher_city, 'Chicago IL', 'city updated');
is($reilly->publisher_name, 'Reilly & Lee Company', 'name updated');

## All done.
$tester->clean_up;
