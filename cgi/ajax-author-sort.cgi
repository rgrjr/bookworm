#!/usr/bin/perl -T
#
# Sort an author's books.
#
# [created.  -- rgr, 4-Apr-21.]
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->generate_object_page(ajax_sort_content => 'Bookworm::Author');

__END__

=head1 DESCRIPTION

Sort an author's books.  This is an internal AJAX page, so the user
would only see it in case of an unusual error.

=cut

