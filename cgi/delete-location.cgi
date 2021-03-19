#!/usr/bin/perl -T
#
# Delete an empty location.
#
# [created.  -- rgr, 19-Mar-21.]
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->generate_object_page(web_delete_location => 'Bookworm::Location');

__END__

=head1 DESCRIPTION

Delete an empty location.

This page confirms deletion of an empty location.  Locations may be
deleted only if they contain no other locations and no books, and are
not the root location (which is named "Somewhere").  If you click the
"Skip" button, the location is kept and you are redirected back to the
location page.  If you click "Delete," the location is deleted and you
are redirected to the location's parent.

=cut
