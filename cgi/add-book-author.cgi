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

=head1 DESCRIPTION

This page adds an author to an existing book.  After picking an author
from the search page, the author is added to the end of the books'
author list, and you are returned to the book's authorship page.  So
you will only see this page in case of error.

=cut
