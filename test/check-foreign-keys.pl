#!/usr/bin/perl
#
# Check all DB tables for dangling foreign key references.
#
# [created.  -- rgr, 13-Jun-21.]
#

use strict;
use warnings;

use lib 'test';

use Bookworm::Test;
use Test::More tests => 6;

my $tester = Bookworm::Test->new();
my $dbh = $tester->database_handle();

### Subroutines

sub find_bad {
    # $query selects a list of ids which are bad.
    my ($what, $query) = @_;

    my $ids = $dbh->selectcol_arrayref($query)
	or die $query;
    my $n_bad_ids = @$ids;
    ok($n_bad_ids == 0, "$n_bad_ids $what");
    if ($n_bad_ids) {
	my $message = join('', "bad ids: ", join(' ', @{combine_ranges($ids)}),
			   "\nQuery:   $query");
	$message =~ s/\n/\n# /g;
	warn("# $message\n");
    }
}

sub check_map {
    # Check links for a many-to-many mapping.
    my ($map, $link_key, $link_table, $link_table_id,
	$other_key, $other_table, $other_table_id) = @_;

    my $check = sub {
	my ($name, $link_field, $link_test, $other_field, $other_test) = @_;
	my ($lt, $lt_id, $ot, $ot_id)
	    = ($link_field eq $link_key
	       ? ($link_table, $link_table_id, $other_table, $other_table_id)
	       : ($other_table, $other_table_id, $link_table, $link_table_id));
	find_bad("$name $link_field links from $map",
		 qq{select $map.$link_field from $map
		    left join $lt as r1
			 on r1.$lt_id = $map.$link_field
		    left join $ot as r2
			 on r2.$ot_id = $map.$other_field
		    where r1.$lt_id $link_test
			  and r2.$ot_id $other_test});
    };

    # Check and report dead links to $link_table, dead links to $other_table,
    # and dead links to both separately, since having only one type of dead
    # link is often a clue as to what went wrong.
    $check->('dangling', $link_key => 'is null',
	     $other_key => 'is not null');
    $check->('dangling', $other_key => 'is null',
	     $link_key => 'is not null');
    $check->('orphan', $link_key => 'is null',
	     $other_key => 'is null');
}

### Main code.

$tester->check_table_links(qw(Bookworm::Book publisher_id publisher));
$tester->check_table_links(qw(Bookworm::Book location_id location));
check_map(qw(book_author_map),
	  qw(author_id author author_id book_id book book_id));
$tester->check_table_links(qw(Bookworm::Location parent_location_id location));

## Clean up.
$tester->clean_up();
