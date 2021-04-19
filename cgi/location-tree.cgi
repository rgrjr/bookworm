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

my $q = ModGen::CGI->new();
Bookworm::Location->web_hierarchical_browser
    ($q, cookie_name => 'bookworm_open_locations');

__END__

=head1 DESCRIPTION

Browse the hierarchy of locations.

This page lets you see all locations as a nested "tree" (in the
computer geek sense).  Each location name is a link that brings you to
that location's home page where you can see the books that are stored
directly there and change its name and notes (see L<location.cgi>).

If the location has other locations nested inside it (such as a house
with rooms, or a bookcase with shelves), then it has a note to the
right with the number of location children it has (though only direct
children are counted), and a button to the left that lets you open or
close the contents so that you can view and maybe open the location
children in turn.  The state of all such buttons is remembered using a
cookie so that the page remains as you left it when you return.

=cut
