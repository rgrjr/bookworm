#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Book;

my $q = ModGen::CGI->new();
Bookworm::Book->web_add_or_update($q);

__END__

=head1 DESCRIPTION

Add or update a book.

=head2 About books

In Bookworm, books can include all sorts of printed materials that
have authors and/or editors and publishers.  (A publisher is required,
but you can always create a catch-all "Samizdat" or "Self-published"
publisher if necessary.)  A book can be created first and then have
its author(s) added to it, or the author created first and then add
the book(s).

Books have two operation links at the bottom of the page:  "[Add
similar book]" and "[Update authors]".

"[Add similar book]" lets you add a new book with defaults from the
current book; only the title and the date read are blanked out.

"[Update authors]" takes you to the L<book-authorship.cgi> page which
allows authors to be added and deleted, and provides full control over
how authors, editors, and translators are presented.

=head2 Book dialog items

=over 4

=item B<Title:>

Title of the book, in titlecase (naturally), ready for sorting, as in
"Adventures of Huckleberry Finn, The".

=item B<Authors:>

List of the book's authors.  Unless the book has a single author, this
is easier to get correct after the book has been added.  For the case
of a single author, you can visit the author's home page and click on
the "[Add book]" link, or visit one of the author's other books and
click "[Add similar book]" (which works best for books coauthored by
the same set of authors).

To update the author(s), use the "[Update authors]" link near the
bottom of the page.

=item B<Publisher:>

Link to the book's publisher.  Clicking on "Change publisher" allows
the publisher to be replaced.  It is not possible to have a book
without a publisher.

=item B<Year:>

Shows the four-digit year of publication.  For books that have been
reissued, I usually put the year of original publication here and the
year the edition was published in the notes.

=item B<Category:>

Specifies the category of book, e.g. fiction, history, biography, etc.
The set of choices is not especially wide, but I didn't particularly
want a huge dropdown menu.

=item B<Date read:>

Specifies the date when I finished reading the book, for the last time
I reread if I've read it more than once.

=item B<Notes:>

Contains any notes pertaining to the book, particularly what condition
it is in.  Since most of my books are paperbacks, I will usually note
if it is a hardback or a special edition, and whether it was a present
(if I remember).

=item B<Location:>

Provides a link to the book's last known location.  The location is
not required, so it may not have a known location, but it is not
possible to change the location to nothing, so I have a location
called "misfiled" for when I lose a book.

=back

=cut
