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
$q->generate_object_page(ajax_sort_content => 'Bookworm::Location');

__END__

=head1 DESCRIPTION

Sort location content.  This is an internal AJAX page, so the user
would only see it in case of an unusual error.

=cut

