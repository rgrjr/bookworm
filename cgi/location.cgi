#!/usr/bin/perl -T
#
# Create/update locations.
#
# [created.  -- rgr, 25-May-13.]
#

use strict;
use warnings;

use lib '.'; ### debug ###
use lib '.'; ### hack ###

use ModGen::CGI;
use Bookworm::Location;

my $q = ModGen::CGI->new();
Bookworm::Location->web_add_or_update($q);

__END__

=head1 DESCRIPTION

Create or update a location.

=head2 About locations

Locations may contain books and/or other locations (though they don't
usually contain both).  They must have a parent location, though there
is always a location called "Somewhere" that can be the parent of
anything, so if you lose a book you can create a location called
"Lost" or "Unknown" and put it under "Somewhere", and keep your lost
books there.

When a location contain books, they are sorted by title.  Books can be
selected by ticking the boxes in the leftmosts column and can then be
moved as a group into another location.  When you click "Move books",
you will be redirected to the L<find-location.cgi> page to choose
another location, and then asked to confirm that you want to move
those books there.  If you choose "Skip", you return to the original
location with those books still selected; if you choose "Move", the
books are moved to the new location, and you also return to the
original location (minus the moved books, of course).

Locations can be moved into other locations as needed by clicking the
"Change parent location" button in the dialog.  This is rarely helpful
for rooms within buildings or shelves within bookcases, but is often
necessary for boxes of books, especially the ones for collecting books
to be given away.

=head2 Location dialog items

=over

=item B<Location:>

This is the name of the location, a building, room, shelf, or box.  It
ought to be descriptive by itself, but it will almost always show up
as a link, so abbreviations can always be clarified by clicking on the
link and seeing the full cascade of locations down from "Somewhere" in
the "Parent location:" field, described below.

=item B<Description:>

Contains free text describing the location.  For boxes of books, this
is often about the genre, when I read them, or when I got rid of them.

=item B<Destination:>

If this location is a box packed for moving, then this field may be
filled in with the planned destination for the box, e.g. "Bob's
Office."

=item B<Packed weight:>

Contains the packed weight of the container, normally a box if this is
not zero.

=item B<Background:>

Defines a background color for the location name when it appears in a
mixed collection of locations, as for book search results or for the
books by a single author.  The default background is "inherit", in
which case the containing location's background is used; if that is
also "inherit", then we search upward until we find some actual color.
If the root location background is also "inherit" then we just use the
page background color, which is usually white (unless someone has
tweaked the global style sheet).

This is meant as an aide to categorize books by location, so that it
is easy to see at a glance where they are, if they have been given
away, are still in storage, etc.

=item B<Books:>

Displays the total number of books stored in this location.  This also
includes books stored in all locations contained within this location.

=item B<Parent location:>

Shows the complete placement of this location within its parents,
along with a "Change parent location" button that takes you to the
L<find-location.cgi> page to in order to pick a new location.

=back

=cut
