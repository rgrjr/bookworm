#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '../modest'; ### hack ###

use ModGen::CGI;
use Bookworm::Author;

# set up the CGI object.
my $q = ModGen::CGI->new();
Bookworm::Author->web_add_or_update($q);
