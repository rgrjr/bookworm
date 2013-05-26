#!/usr/bin/perl -T
#
# Allow the user to select a storage location.
#
# [created.  -- rgr, 25-May-07.]
#
# $Id$

use strict;
use warnings;

use lib '/home/rogers/projects/bookworm'; ### debug ###
use lib '/shared.local/mgi/modest'; ### hack ###

use ModGen::CGI;
use Bookworm::Location;

my $q = ModGen::CGI->new();
Bookworm::Location->web_search($q);

__END__

=head1 DESCRIPTION

Search for a location in the database.

=cut

