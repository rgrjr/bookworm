#!/usr/bin/perl
#
# Test script for books.
#
# [created.  -- rgr, 13-Jun-21.]
#

use strict;
use warnings;

use lib 'test';

use Bookworm::Test;
use Bookworm::Publisher;
use Bookworm::Author;
use Bookworm::Location;

use Test::More tests => 48;

my $tester = Bookworm::Test->new();

### Subroutines.

my ($author, $shelf, $reilly);

sub add_book_with_author {
    # 9 "ok" calls per invocation.
    my ($title, $pub_year) = @_;

    my @keys = (title => $title,
		publisher_id => $reilly->publisher_id,
		publication_year => $pub_year,
		category => 'fiction',
		location_id => $shelf->location_id);
    $tester->run_script('cgi/book.cgi',
			author_id => $author->author_id,
			@keys,
			doit => 'Insert');
    my $new_book = Bookworm::Book->fetch($title, key => 'title');
    ok($new_book, qq{have '$title'}) or die;
    # use Data::Dumper; warn Dumper($new_book);

    # Make sure the fields contain what we expect.
    my %keys = @keys;
    for my $key (sort(keys(%keys))) {
	my $expected_value = $keys{$key};
	my $actual_value = $new_book->$key();
	is($expected_value, $actual_value, "$key value matches");
    }

    # Check the author.
    my $authorships = $new_book->authorships;
    ok(@$authorships == 1, 'has one authorship');
    my $authorship = $authorships->[0];
    is($authorship->author_id, $author->author_id,
       "authorship has the right author");
    return $new_book;
}

### Main code.

use_ok('Bookworm::Book');

## Get rid of these test books.
for my $title ('The Wizard of Oz', 'The Land of Oz',
	       'Ozma of Oz', 'Dorothy and the Wizard in Oz') {
    my $book = Bookworm::Book->fetch($title, key => 'title');
    $book->destroy_utterly()
	if $book;
}
Bookworm::Book->flush_cache();
ok(! Bookworm::Book->fetch('The Wizard of Oz', key => 'title'), 'no wiz')
    or die "cleanup failed";

## Fetch some prerequisites.
$author = Bookworm::Author->fetch('Baum', key => 'last_name');
ok($author, 'have Baum') or die;
$reilly = Bookworm::Publisher->fetch('Reilly & Lee Company',
					key => 'publisher_name');
ok($reilly, 'have Reilly') or die;
$shelf = Bookworm::Location->fetch('shelf', key => 'name');
ok($shelf, 'have shelf') or die;

## Create a book.
my $wiz = $tester->test_add_object
    ('cgi/book.cgi', 'Bookworm::Book',
     title => 'The Wizard of Oz',
     publisher_id => $reilly->publisher_id,
     publication_year => 1900,
     category => 'fiction',
     date_read => '1963',
     location_id => $shelf->location_id);

## Test updating fields.
$wiz->date_read('1964');
my $new_note = 'My favorite book as a kid.';
$wiz->notes($new_note);
$wiz->update();
Bookworm::Book->flush_cache();
$wiz = ref($wiz)->fetch($wiz->book_id);
ok($wiz, 'decached book') or die;
is($wiz->date_read, '1964', 'date read updated');
is($wiz->notes, $new_note, 'notes updated');

## Give it an author.
my $authorships = $wiz->authorships;
ok(! @$authorships, 'no authorships yet');
$tester->run_script('cgi/add-book-author.cgi',
		    book_id => $wiz->book_id,
		    author_id => $author->author_id);
Bookworm::Book->flush_cache();
$wiz = ref($wiz)->fetch($wiz->book_id);
ok($wiz, 'decached book') or die;
$authorships = $wiz->authorships;
ok(@$authorships == 1, 'now have one authorship');
my $authorship = $authorships->[0];
is($authorship->author_id, $author->author_id,
   "authorship has the right author");

## Add more books.
add_book_with_author('The Land of Oz', 1904);
add_book_with_author('Ozma of Oz', 1907);
add_book_with_author('Dorothy and the Wizard in Oz', 1908);

## All done.
$tester->clean_up;
