#!/usr/bin/perl -T
#
# AJAX helper for search pages.
#
# [created.  -- rgr, 8-Jun-13.]
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Base;

my $q = ModGen::CGI->new();
Bookworm::Base->ajax_last_chosen($q);

__END__

=head1 DESCRIPTION

AJAX support for updating the "Last chosen:" line on search pages.  A
user would see this page only in case of a bug or an error.

=cut
