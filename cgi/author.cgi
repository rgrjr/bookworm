#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Author;

# set up the CGI object.
my $q = ModGen::CGI->new();
Bookworm::Author->web_add_or_update($q);

__END__

=head1 DESCRIPTION

Add or update an author.

=head2 About authors

In Bookworm, authors also include editors, "with" authors (sometimes
known as "ghostwriters"), and translators; their role depends upon the
book, since the same person often occupies multiple roles during their
career (see L<book-authorship.cgi>).  A book can be created first and
then have its author(s) added to it, or the author created first and
then add the book(s).

=head2 Author dialog items

=over 4

=item B<First name:>

Updates the author's first name.  This may be left blank.

=item B<Middle name:>

Updates the author's middle name.  This may be left blank.

=item B<Last name:>

Updates the author's last name, possibly with any suffixes such as
"Jr" or "III".  This must not be left blank.

=item B<Notes:>

Updates any notes you may wish to make about this author.  This can be
helpful in searching for authors whose names you have trouble
remembering.

=back
