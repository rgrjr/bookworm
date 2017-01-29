#!/usr/bin/perl -T
#
# Show a tree of locations.
#
# [created.  -- rgr, 28-Jan-17.]
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Location;
use ModGen::DB::Thing::web_hierarchical_browser;

# [kludge to get MODEST to use our class.  -- rgr, 28-Jan-17.]
$ModGen::DB::Thing::kind_to_class_and_cookie{bookworm_location}
    = [ qw(Bookworm::Location bookworm_open_locations) ];

my $q = ModGen::CGI->new();
Bookworm::Location->web_hierarchical_browser($q, kind => 'bookworm_location');

__END__

=head1 DESCRIPTION

Search for a location in the database.

=cut

