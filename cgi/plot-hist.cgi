#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Base;

my $q = ModGen::CGI->new();
Bookworm::Base->web_plot_histogram($q);

__END__

=head1 Plot Histogram

This page plots a histogram for Bookworm (see L<index.cgi>).  It is
not interactive, so you should only see this help page in case of
error.

=cut
