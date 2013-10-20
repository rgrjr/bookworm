#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Base;

my $q = ModGen::CGI->new();
Bookworm::Base->web_home_page($q);
