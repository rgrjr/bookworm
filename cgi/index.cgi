#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '../modest'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->_header(title => 'Bookworm home page');
print($q->p('Not much to see here.'), "\n");
$q->_footer();
