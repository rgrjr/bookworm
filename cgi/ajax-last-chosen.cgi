#!/usr/bin/perl -T
#
# AJAX helper for search pages.
#
# [created.  -- rgr, 8-Jun-13.]
#
# $Id$

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Base;

my $q = ModGen::CGI->new();
Bookworm::Base->ajax_last_chosen($q);
