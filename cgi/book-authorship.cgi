#!/usr/bin/perl -T

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;

my $q = ModGen::CGI->new();
$q->generate_object_page(web_update_authorship => 'Bookworm::Book');

__END__

=head1 DESCRIPTION

Update the authorship of a book.

=head2 About authorship

Each author, editor, or translator has a row in the table that is the
central feature of the page.  They are not sortable because they are always
shown in their "presentation order," which is explained in detail below.
The row contains the author's name,
order of presentation, and role; the name is a link to a page that
allows you to pick new values for the order and role.  The "To top",
"To bottom", and "Renumber" buttons below the table also reorder the
authors by changing these values.  

The "[Add author]" link takes you to the L<find-author.cgi> page; as
soon as you pick one, the author is added to the end of the book's
list of authors and you are returned to the authorship page.

The buttons at the bottom of the page provide another way to reorder
the authors; they may also be deleted this way.  Buttons in B<bold>
operate on the database immediately, without further confirmation,
while the other buttons and links have no direct effect on the
database.  The "Delete", "To top", and "To bottom" buttons require you
to select some authors first.  Renumbering a subset of authors tries
to make the numbers consecutive without overlap or changing the order
of authors.  If no authors are selected when you click "Renumber",
then all authors are renumbered starting from one.  Renumbering or
reordering may cause the numbers of unselected authors to change when
necessary to keep the numbers consistent with the desired order; this
happens regardless of author role.

=head2 Presentation of author information

The principal feature of this page is that it gives control over how
authors, editors, and translators are presented, both in terms of
order and attribution.  Authors are always sorted first by role,
with "author", "editor", "translator", and "with" authors appearing in
that order, and then by their order.

When multiple authors with the same role are presented, two are joined
by " and ", and three or more are joined by ", ".  Here are a few real
examples (title on the first line, authorship on the second):

	Shadow of the Lion, The
	Mercedes Lackey, Eric Flint, David Freer

One or more "with" authors are always shown after the "author" authors:

	Within Reach: My Everest Story
	Mark Pfetzer with Jack Galvin

If there were more than one in a given role, they would be separated
with "and" or commas independently.

For an edited collection, the name of the editor(s) are followed by
", ed" or ", eds" as appropriate, using "and" or commas in the same
way to join the names:

	Best SF: 1967
	Harry Harrison and Brian W. Aldiss, eds

And translators are handled in much the same way as "with" authors:

	Love in the Time of Cholera
	Gabriel Garcia Marquez, translated by Edith Grossman

As for "with" authors, the order only matters within translators (if
there is more than one).

=cut
