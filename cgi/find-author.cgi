#!/usr/bin/perl -T
#
# Find authors.
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Author;

my $q = ModGen::CGI->new();
Bookworm::Author->web_search($q);

__END__

=head1 DESCRIPTION

Find matching authors in the database.

Given the search criteria in the dialog, this page finds and displays
all authors that match all criteria, showing summary information for
each author.  The first column contains the author, which is a link to
the authors' home page where the books can be updated.  See
L<author.cgi> for more about authors.

=head2 Search dialog items

The first two input boxes are for string matching, which is done word
by word without regard to alphabetic case.  An author matches if all
words are contained as substrings in that particular field.  The
character "_" (underscore) matches any single character, and "%"
matches any sequence of zero or more characters.  If the word starts
with "^", then the name or notes must start with that word; similarly,
if it ends with "$", then the name or notes must end with the word, so
"^foo$" means "exactly 'foo'".  Any word can be prefixed with "!";
this means that something is considered only if it does I<not> match
the word, with "_%^$" characters interpreted as above.

=over 4

=item B<Author name:>

String match on author names.  This is slightly different than other
string searches in that the authors' first, last, and middle names are
searched for independently.  Don't forget that suffixes are lumped in
with the last name, so searching for "^brooks$" will not find
Frederick P. Brooks Jr, the author of I<The Mythical Man-Month>.

=item B<Notes:>

String match to the "Notes:" field.

=item B<Max authors to show:>

Limits the results display to show this many authors.  The initial
default is 100.

=back

=cut
