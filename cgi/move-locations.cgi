#!/usr/bin/perl -T
#
# Move locations into a new parent storage location.
#
# [created.  -- rgr, 17-Apr-22.]
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->generate_object_page(web_move_locations => 'Bookworm::Location');

__END__

=head1 DESCRIPTION

Move one or more other locations into this location.  You will be ask
to select locations to move on the L<find-location.cgi> page; clicking
on a name in the second column or ticking boxes in the first column
and clicking "Use selected" at the bottom of the search results causes
those locations to be presented for confirmation.  If you click
"Skip", you return to the original location without any changes.  If
you choose "Move", the other locations you selected are moved directly
here, and you also return to that location's page.  Selecting a
location that is the same as the destination location, or any parent
or ancestor of the destination location, is not allowed.

=cut
