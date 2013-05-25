# The Bookworm "Publisher" class.
#
# [created.  -- rgr, 29-Jan-11.]
#
# $Id$

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

sub validate {
    my ($self, $interface) = @_;

    $interface->_error("Publishers must have a name.\n")
	unless $self->publisher_name;
}

my @field_descriptors
    = ({ accessor => 'publisher_id', verbosity => 2 },
       { accessor => 'publisher_name', pretty_name => 'Publisher',
	 type => 'string' },
       { accessor => 'publisher_city', pretty_name => 'City',
	 type => 'string' }
    );

sub local_display_fields { return \@field_descriptors };

1;
