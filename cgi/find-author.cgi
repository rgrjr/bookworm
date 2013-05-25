#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Author;

my $q = ModGen::CGI->new();
Bookworm::Author->web_search($q);
