#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Book;

my $q = ModGen::CGI->new();
Bookworm::Book->web_search($q);
