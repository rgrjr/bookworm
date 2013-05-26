#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Publisher;

my $q = ModGen::CGI->new();
Bookworm::Publisher->web_search($q);
