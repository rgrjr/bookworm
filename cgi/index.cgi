#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Base;

my $q = ModGen::CGI->new();
Bookworm::Base->web_home_page($q);

__END__

=head1 Bookworm

Bookworm is a Web application that lets you keep track of your books.
You can add books, put them in locations, search for them and their
authors, move them around, and update when you've read them.

=cut
