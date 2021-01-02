# The Bookworm "Publisher" class.
#
# [created.  -- rgr, 29-Jan-11.]
#

use strict;
use warnings;

package Bookworm::Publisher;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Publisher->build_field_accessors
	([ qw(publisher_id publisher_name publisher_city) ]);
}

sub table_name { 'publisher'; }
sub primary_key { 'publisher_id'; }

# Autoloaded subs.
#    sub web_search;

sub pretty_name { shift()->publisher_name(); }
sub home_page_name { 'update-publisher.cgi'; }
sub search_page_name { 'find-publisher.cgi'; }

sub validate {
    my ($self, $interface) = @_;

    $interface->_error("Publishers must have a name.\n")
	unless $self->publisher_name;
}

my @field_descriptors
    = ({ accessor => 'publisher_id', verbosity => 2 },
       { accessor => 'publisher_name', pretty_name => 'Publisher',
	 type => 'string', size => 50, default_sort => 'asc' },
       { accessor => 'publisher_city', pretty_name => 'City',
	 type => 'string', size => 50 }
    );

sub local_display_fields { return \@field_descriptors };

1;

__END__

=head1 Bookworm::Publisher

Class for representing Bookworm publishers.  These are pretty
straightforward, because although we require them in order to add a
book to the collection, we don't do much else with them.

=head2 Accessors and methods

=head3 home_page_name

Returns the string "update-publisher.cgi", so that the
C<home_page_url> method of C<Bookworm::Base> can construct a URL for
the publisher.  See the L<ModGen::DB::Thing/html_link> method.

=head3 publisher_city

Returns or sets the name of the city in which the publisher is
located, e.g. "New York", which is free text.

=head3 publisher_id

Returns or sets the primary key of the publisher in the database.

=head3 publisher_name

Returns or sets the name of the publisher, which is free text.

=head3 validate

Given a C<ModGen::Web::Interface>, insists on having a
C<publisher_name> reporting any errors via the interface.

=cut
