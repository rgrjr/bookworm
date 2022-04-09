# The Bookworm "Base" class.
#
# This is not a table class; it is used to keep some common methods.
#
# [created.  -- rgr, 29-Jan-11.]
#

use strict;
use warnings;

package Bookworm::Base;

use base qw(ModGen::DB::Thing);

# Autoloaded method.
    sub web_home_page;

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
    push(@options, search_fields => $class->default_search_fields)
	if ! $options{search_fields} && $class->can('default_search_fields');
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

sub web_plot_histogram {
    my ($self, $q) = @_;

    my %data = split(';', $q->param('data') || die);
    my $data_file_name = "/scratch/rogers/tmp/bookworm-$$.plot";
    {
	# [insecure.  -- rgr, 2-Apr-22.]
	open(my $out, '>', $data_file_name)
	    or die "oops:  $!";
	for my $bin (sort(keys(%data))) {
	    my $count = $data{$bin};
	    print $out "$bin\t$count\n"
		if $count;
	}
    }
    {
	print $q->header(-type => 'image/png');
	# [insecure?  -- rgr, 2-Apr-22.]
	open(my $cmd, '| /usr/bin/gnuplot');
	print $cmd "set term png\n";
	print $cmd "set boxwidth 0.75 relative\n";
	print $cmd "set style fill solid 1.0\n";
	print $cmd ("plot '$data_file_name' with boxes ",
		    "title 'Weight distribution'\n");
    }
    unlink($data_file_name);
}

1;

=for grins

=cut

__END__

=head1 Bookworm::Base

Base class for Bookworm methods.  This is not itself a table class; it
is just used as a place to keep some common methods.

=head2 Accessors and methods

=head3 class_from_cookie_name

Given a cookie name (e.g. C<last_author>), maps it to a class name
(e.g. C<Bookworm::Author>), for use by search pages.

=head3 connect_to_database

Class or instance method.  Returns the database connection.

=head3 format_location_chain_field

Given a C<ModGen::CGI> query object, an attribute descriptor, the name
of the CGI parameter, a read-only flag, and the value (a location ID),
return a string that represents the complete hierarchical location.
The C<parent_location_id> chain is traced until we get to the top,
producing the list of links to all containing locations separated by
" E<gt>E<gt> ".  The read-only flag is ignored because the value is
always treated as read-only.  See
L<ModGen::Thing/format_accessor_value>.

=head3 web_home_page

Autoloaded.

=cut
