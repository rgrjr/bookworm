#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->generate_object_page(web_update => 'Bookworm::Authorship');

__END__

=head1 DESCRIPTION

Change a particular author related to a particular book.  This is
known as "authorship" in Bookworm, and affects how the author is
presented on the book home page.  It depends on both the author role
and the the author order, which can be changed here and on the
L<book-authorship.cgi> page.
See the section L<book-authorship.cgi/Presentation of author information>
for details and examples.

=head2 Authorship dialog items

=over 4

=item B<Book:>

Shows the title of the book.

=item B<Author:>

Shows a link to the author.  (It is possible, though somewhat
eccentric, to change the author here.)

=item B<Order:>

Order of the author within their stated role.
This can be changed here or on the L<book-authorship.cgi> page.

=item B<Role:>

Role of the author, as an editor, translator, "with" author (also
known as a ghostwriter), or a "primary" author (the usual case).  The
author role can only be changed on this page.

=back

=cut
