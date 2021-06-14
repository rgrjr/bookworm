#!/usr/bin/perl
#
# Test script for authors.
#
# [created.  -- rgr, 13-Jun-21.]
#

use strict;
use warnings;

use lib 'test';

use Bookworm::Test;

use Test::More tests => 7;

my $tester = Bookworm::Test->new();

### Main code.

use_ok('Bookworm::Author');

## Get rid of these test authors.
for my $author_name ('Baum') {
    my $author = Bookworm::Author->fetch($author_name, key => 'last_name');
    $author->destroy_utterly()
	if $author;
}

## Create an author.
$tester->run_script('cgi/author.cgi',
		    doit => 'Insert',
		    first_name => 'Lyman',
		    mid_name => 'Frank',
		    last_name => 'Baum');
my $baum = Bookworm::Author->fetch('Baum', key => 'last_name');
ok($baum, 'have Baum') or die;
is($baum->first_name, 'Lyman', 'first name matches');

## Test updating fields.
$baum->first_name('L.');
$baum->notes('Author of 14 Oz books.');
$baum->update();
Bookworm::Author->flush_cache();
$baum = ref($baum)->fetch($baum->author_id);
ok($baum, 'decached author') or die;
is($baum->first_name, 'L.', 'first name updated');
is($baum->notes, 'Author of 14 Oz books.', 'notes updated');

## All done.
$tester->clean_up;
