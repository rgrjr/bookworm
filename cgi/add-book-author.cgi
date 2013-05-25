#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Book;

# set up the CGI object.
my $q = ModGen::CGI->new();
$q->generate_object_page(web_add_author => 'Bookworm::Book');
