# The Bookworm "Base" class.
#
# This is not a table class; it is used to keep some common methods.
#
# [created.  -- rgr, 29-Jan-11.]
#
# $Id$

use strict;
use warnings;

package Bookworm::Base;

use base qw(ModGen::DB::Thing);

sub connect_to_database {
    # [this is a kludge; we shouldn't need a ModGen::DB::Fetch here, which is
    # too MODEST-centric.  -- rgr, 30-Jan-11.]
    my $self = shift;

    return ModGen::DB::Fetch->config->connect_to_database();
}

sub home_page_url {
    my ($self, $q) = @_;

    my $primary_key = $self->primary_key;
    my $id = $self->$primary_key();
    return $q->oligo_query($self->home_page_name, $primary_key => $id)
	if $id;
}

sub format_location_chain_field {
    # Produces a hierarchical link to the container the ID for which is given in
    # $value.  Used to display and link to parent containers in Web display.
    my ($self, $q, $descriptor, $cgi_param, $read_only_p, $value) = @_;
    require Bookworm::Location;

    my $spew = '';
    my $ancestor_id = $value;
    while ($ancestor_id) {
	my $ancestor = Bookworm::Location->fetch($ancestor_id);
	last
	    unless $ancestor;
	my $link = $ancestor->html_link($q);
	$spew = ($spew ? "$link &gt;&gt; $spew" : $link);
	$ancestor_id = $ancestor->parent_location_id;
    }
    return $spew || 'none';
}

sub web_search {
    my ($class, $q, @options) = @_;
    my %options = @options;

    my $display_columns = $options{columns};
    if ( $display_columns) {
	# Already specified by the caller.
    }
    elsif ($class->can('default_display_columns')) {
	push(@options, columns => $class->default_display_columns);
    }
    else {
	$display_columns = [ ];
	my $primary_key = $class->primary_key;
	push(@$display_columns,
	     { accessor => $primary_key, pretty_name => ucfirst($primary_key),
	       type => 'return_address_link',
	       return_address => $class->home_page_name });
	for my $descriptor (@{$class->display_fields}) {
	    push(@$display_columns, $descriptor->{accessor})
		unless ($descriptor->{verbosity} || 1) > 1;
	}
	push(@options, columns => $display_columns);
    }

    # Default the search fields.
    my $search_fields = $options{search_fields};
    if ($search_fields) {
	# Already specified by the caller.
    }
    elsif ($class->can('default_search_fields')) {
	push(@options, search_fields => $class->default_search_fields);
    }
    else {
	$search_fields = [ ];
	for my $descriptor (@{$class->display_fields}) {
	    push(@$search_fields, $descriptor->{accessor})
		unless ($descriptor->{verbosity} || 1) > 1;
	}
	push(@options, search_fields => $search_fields);
    }
    return $class->SUPER::web_search($q,
				     create_new_page => $class->home_page_name,
				     @options);
}

my %class_from_cookie_name
    = (last_book => 'Bookworm::Book',
       last_author => 'Bookworm::Author',
       last_location => 'Bookworm::Location',
       last_publisher => 'Bookworm::Publisher');

sub class_from_cookie_name {
    # For ajax_last_chosen.
    my ($self, $cookie_name) = @_;

    return $class_from_cookie_name{$cookie_name};
}

1;

=for grins

=cut
