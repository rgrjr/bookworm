# The Bookworm "Location" class.
#
# [created.  -- rgr, 25-May-13.]
#
# $Id$

use strict;
use warnings;

package Bookworm::Location;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Location->build_field_accessors
	([ qw(location_id name description parent_location_id) ]);
    Bookworm::Location->build_fetch_accessor
	(qw(parent_location parent_location_id Bookworm::Location));
    Bookworm::Location->build_set_fetch_accessor
	('children',
	 query => q{select location_id
		    from location
		    where parent_location_id = ?
		    order by location_id},
	 object_class => 'Bookworm::Location',
	 cache_key => '_children');
}

sub table_name { 'location'; }
sub primary_key { 'location_id'; }
sub pretty_name { shift()->name; }
sub home_page_name { 'location.cgi'; }

sub ancestor_of {
    # Return true iff $self contains $location.
    my ($self, $location) = @_;

    my $location_id = $self->location_id;
    return
	unless $location_id;
    while ($location) {
	return 1
	    if $location->location_id == $location_id;
	$location = $location->parent_location;
    }
}

### Web interface.

my @local_display_fields
    = ({ accessor => 'name', pretty_name => 'Location',
	 type => 'self_link', class => 'Bookworm::Location' },
       { accessor => 'description', pretty_name => 'Description',
	 type => 'text' },
       { accessor => 'parent_location_id', pretty_name => 'Parent location',
	 edit_p => 'find-location.cgi',
	 type => 'location_chain',
	 validate => 'validate_parent_location_id' }
    );

sub local_display_fields {
    \@local_display_fields;
}

sub validate_parent_location_id {
    my ($self, $descriptor, $new_location_id) = @_;

    my $new_parent_location
	= ($new_location_id
	   && Bookworm::Location->fetch($new_location_id));
    my $old_location_id = $self->parent_location_id;
    my $old_parent_location
	= ($old_location_id
	   && Bookworm::Location->fetch($old_location_id));
    if (($old_location_id || 'none') eq ($new_location_id || 'none')) {
	# No change.
    }
    elsif ($self->location_id && ! $old_parent_location) {
	# If we are in the database without a parent, then we must be the root.
	return "Can't move the root.\n"
	    # Naughty, naughty.
	    if $new_location_id;
    }
    elsif (! $new_parent_location) {
	# It's OK to make (or leave) the parent location undefined.
	if ($new_location_id) {
	    "Location with ID '$new_location_id' doesn't exist.\n";
	}
    }
    elsif ($self->can('ancestor_of')
	   && $self->ancestor_of($new_parent_location)) {
	# Make sure we don't create a loop.  (If we can't do 'ancestor_of',
	# then we assume we can't contain other locations, which means we can't
	# be involved in a loop no matter where we're put.)
	"Can't move a location under itself!\n";
    }
}

sub post_web_update {
    my ($self, $q) = @_;

    my $unlink = $self->html_link(undef);
    return join("\n",
		$q->h3("$unlink contents"),
		$self->present_object_content
		       ($q, $unlink,
			[ qw(name description parent_location_id) ],
			$self->children),
		"\n");
}

### Searching.

sub default_search_fields {
    return [ { accessor => 'name',
	       pretty_name => 'Location name',
	       search_type => 'string',
	       search_id => 'location_id' },
	     { accessor => 'description',
	       pretty_name => 'Description',
	       search_type => 'name' },
	     { accessor => 'limit',
	       search_type => 'limit',
	       pretty_name => 'Max locations to show',
	       default => 100 }
	];
}

sub default_display_columns {
    return [ { accessor => 'name', pretty_name => 'Location',
	       type => 'return_address_link',
	       return_address => 'location.cgi' },
	     qw(description parent_location_id) ];
}

1;
