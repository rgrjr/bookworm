#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '../modest'; ### hack ###

use ModGen::CGI;
use Bookworm::Publisher;

# set up the CGI object.
my $q = ModGen::CGI->new();
Bookworm::Publisher->web_add_or_update($q);
