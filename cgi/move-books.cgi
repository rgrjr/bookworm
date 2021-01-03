#!/usr/bin/perl -T
#
# Move books into a storage location.
#
# [created.  -- rgr, 2-Sep-13.]
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->generate_object_page(web_move_books => 'Bookworm::Location');

__END__

=head1 DESCRIPTION

Move one or more books into a storage location.  If you click "Skip",
you return to the original location without any changes.  If you
choose "Move", the books you selected are moved to the starting
location from wherever they originally came, and you also return to
that location's page.

=cut
