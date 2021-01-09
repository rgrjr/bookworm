#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Publisher;

# set up the CGI object.
my $q = ModGen::CGI->new();
Bookworm::Publisher->web_add_or_update($q);

__END__

=head1 DESCRIPTION

Add or update a publisher.

=head2 About publishers

Publishers are pretty straightforward, because although we do require
them in order to add a book to the collection, we don't do much with
them.  This probably makes things easier, as publishers have undergone
much consolidation in the past few decades, so keeping track of
publishers and imprints and what they may be called now in order to
properly classify an old book is potentially a lot of work.  There are
more than two dozen listed on L<https://wwww.penguin.com> home page
under "Publishers" alone.  So I go for the biggest name list on the
publication data page and leave it at that.

=head2 Publisher dialog items

=over 4

=item B<Publisher:>

Updates the name of the publisher.

=item B<City:>

Updates the city in which the publisher is located.  Major cities are
typically named without the state or country (e.g. "New York",
"London", "Paris") and more precisely qualified for smaller cities
(e.g. "Portland OR", "Sydney Australia").

=back

=cut
