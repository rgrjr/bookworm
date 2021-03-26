#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Book;

my $q = ModGen::CGI->new();
Bookworm::Book->web_search($q);

__END__

=head1 DESCRIPTION

Find matching books in the database.

Given the search criteria in the dialog, this page finds and displays
all books that match all criteria, showing summary information for
each book.  The first column contains the book title, which is a link
to the book's home page where the books can be updated.  See
L<book.cgi> for more about books.

=head2 Search dialog items

Most input boxes are for string matching, which is done word by word
without regard to alphabetic case.  A book matches if all words are
contained as substrings in that particular field.  The character "_"
(underscore) matches any single character, and "%" matches any
sequence of zero or more characters.  If the word starts with "^",
then the name must start with that word; similarly, if it ends with
"$", then the name must end with the word, so "^foo$" means "exactly
'foo'".  Any word can be prefixed with "!"; this means that something
is considered only if it does I<not> match the word, with "_%^$"
characters interpreted as above.

=over 4

=item B<Title/ID:>

This field does a string match to the book title, but if a word
consists only of digits or is a range of digits (i.e. "500-510"), then
the search is for the internal book ID, and matches if the book is in
any one of multiple IDs or ranges.  Book IDs are assigned
chronologically, so this is occasionally useful to find other books
that were added in the same batch.

To search for all book titles that contain the digit 5 (for example),
use "5%" as the search string.  In my collection, this will find
I<1985> by Anthony Burgess and I<Fahrenheit 451> by Ray Bradbury.

=item B<Authors:>

String search on author names.  This is slightly different than other
string searches in that the authors' first, last, and middle names are
searched for independently.  Don't forget that suffixes are lumped in
with the last name, so searching for "^brooks$" will not find
Frederick P. Brooks Jr, the author of I<The Mythical Man-Month>.

=item B<Year:>

Search bounds on the year of publication.  Two fields allow you to
specify upper and lower bounds for the year in which the book was
published.

=item B<Date read:>

This field does a string match to the "Date read:" field.  Since there
is no competing ID, the hyphens in dates are not treated as ranges.
(Unfortunately that makes this search field much less useful than it
ought to be.)

=item B<Category:>

Searches on book category.  Only one category can be chosen at a time
(though this is a limitation of how I have set up the search
interface, and not the underlying search engine itself).

=item B<Notes:>

String match to the "Notes:" field.

=item B<Max books to show:>

Limits the results display to show this many books.  The initial
default is 100.

=back

=cut
