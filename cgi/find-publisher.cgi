#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Publisher;

my $q = ModGen::CGI->new();
Bookworm::Publisher->web_search($q);

__END__

=head1 DESCRIPTION

Find matching publishers in the database.

Given the search criteria in the dialog, this page finds and displays
all publishers that match all criteria, showing summary information
for each publisher.  The first column contains the publisher name,
which is a link to the publisher's home page.  See L<publisher.cgi>
for (not much) more about publishers.

=head2 Search dialog items

The first two input boxes are for string matching, which is done word
by word without regard to alphabetic case.  A publisher matches if all
words are contained as substrings in that particular field.  The
character "_" (underscore) matches any single character, and "%"
matches any sequence of zero or more characters.  If the word starts
with "^", then the name must start with that word; similarly, if it
ends with "$", then the name must end with the word, so "^foo$" means
"exactly 'foo'".  Any word can be prefixed with "!"; this means that
something is considered only if it does I<not> match the word, with
"_%^$" characters interpreted as above.

=over 4

=item B<Publisher:>

String match to the full publisher name.

=item B<City:>

String match to the publisher city, which is usually without the state
or country for well-known cities (e.g. "New York", "London", "Paris")
and more precisely qualified for smaller cities (e.g. "Portland OR",
"Sydney Australia").

=item B<Max publishers to show:>

Limits the results display to show this many publishers.  The initial
default is 100.

=back

=cut
