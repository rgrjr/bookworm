#!/usr/bin/perl -T
#
# Search for storage locations.
#
# [created.  -- rgr, 26-May-13.]
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Location;

my $q = ModGen::CGI->new();
Bookworm::Location->web_search($q);

__END__

=head1 DESCRIPTION

Search for storage locations.

Given the search criteria in the dialog, this page finds and displays
all locations that match all criteria, showing summary information for
each location.  The first column contains the name of the location,
which is a link to the location's home page where the location can be
updated.  See L<location.cgi> for more about locations.

=head2 Search dialog items

The first three input boxes are for string matching, which is done word
by word without regard to alphabetic case.  A location matches if all
words are contained as substrings in that particular field.  The
character "_" (underscore) matches any single character, and "%"
matches any sequence of zero or more characters.  If the word starts
with "^", then the name or description must start with that word;
similarly, if it ends with "$", then the name or description must end
with the word, so "^foo$" means "exactly 'foo'".  Any word can be
prefixed with "!"; this means that something is considered only if it
does I<not> match the word, with "_%^$" characters interpreted as
above.

=over 4

=item B<Location name:>

Look for locations with names that match these words.

=item B<Description:>

Look for locations with descriptions that match these words.

=item B<Destination:>

Look for locations with destinations that match these words.

=item B<Parent location:>

Look for locations that are in other locations with names that match
these words.

=item B<Packed weight:>

Show only locations with packed weights within this range.  If either
limit is left blank, then that limit is not considered as a search
bound.  Since non-boxes are not given packing weights, use a minimum
limit of "1" to see only boxes, or a maximum limit of "1" to see
everything but boxes.

=item B<Max locations to show:>

Limits the display to show only this many locations.  The initial
default is 100.

=back

=cut

