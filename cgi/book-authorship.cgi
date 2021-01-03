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
central feature of the page.  The row contains the author's name,
order of presentation, and role; the name is a link to a page that
allows you to pick new values for the order and role.  The "To top",
"To bottom", and "Renumber" buttons below the table also reorder the
authors by changing these values.  

When authors are presented, two authors are joined by " and ", and
three or more authors are joined by ", ".  Here are a few real
examples (title on the first line, authorship on the second):

	Shadow of the Lion, The
	Mercedes Lackey, Eric Flint, David Freer

One or more "with" authors are always shown after the "author" authors:

	Within Reach: My Everest Story
	Mark Pfetzer with Jack Galvin

If there were more than one in each category, they would be separated
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
