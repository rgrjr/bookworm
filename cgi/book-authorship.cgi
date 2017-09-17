#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '../modest'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->generate_object_page(web_update_authorship => 'Bookworm::Book');
