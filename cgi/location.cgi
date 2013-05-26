#!/usr/bin/perl -T
#
# Create/update locations.
#
# [created.  -- rgr, 25-May-13.]
#
# $Id$

use strict;
use warnings;

use lib '/home/rogers/projects/bookworm'; ### debug ###
use lib '/shared.local/mgi/modest'; ### hack ###

use ModGen::CGI;
use Bookworm::Location;

my $q = ModGen::CGI->new();
Bookworm::Location->web_add_or_update($q);

__END__

=head1 DESCRIPTION

Create or update a location.

=head2 About locations

=cut
