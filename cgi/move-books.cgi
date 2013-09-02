#!/usr/bin/perl -T
#
# Move books into a storage location.
#
# [created.  -- rgr, 2-Sep-13.]
#
# $Id$

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->generate_object_page(web_move_books => 'Bookworm::Location');

__END__

=head1 DESCRIPTION

Move one or more books into a particular storage location.

=cut

