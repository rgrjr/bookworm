#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Book;

# set up the CGI object.
my $q = ModGen::CGI->new();
Bookworm::Book->web_add_or_update($q);
