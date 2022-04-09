# Bookworm home page generator.
#
# [created.  -- rgr, 20-Oct-13.]
#

use strict;
use warnings;

package Bookworm::Base;

sub web_home_page {
    my ($class, $q) = @_;
    my $dbh = $q->connect_to_database;

    my $do_class = sub {
	my ($class) = @_;

	eval "require $class;";
	die $@ if $@;
	my $table = $class->table_name;
	my $query = qq{select count(1) from $table};
	my ($count) = $dbh->selectrow_array($query);
	my $text = join('', $count, ' ', $class->type_pretty_name,
			$class->pluralize($count));
	my $search_page = ($class->can('search_page_name')
			   && $class->search_page_name);
	return $text
	    unless $search_page;
	return $q->a({ href => $search_page }, $text);
    };

    # Find descriptions that may include weight in pounds.
    my $weight_string = '.';
    my $bin_width = 5;
    my @histogram_bins;
    {
	my ($total_weight, $n_desc, $n_match, @fails) = (0, 0, 0);
	my $descriptions = $dbh->selectcol_arrayref
	    (q{select description from location where description like '%lb%'})
	    or die $dbh->errstr;
	for my $desc (@$descriptions) {
	    $n_desc++;
	    if ($desc =~ /\((\d+([.]\d*)?)lb[.]?\)/) {
		$n_match++;
		my $weight = $1;
		$total_weight += $weight;
		my $bin = int($weight / $bin_width);
		$histogram_bins[$bin]++;
	    }
	    else {
		push(@fails, "fail:  '$desc'");
	    }
	}
	if ($total_weight > 0 || $n_desc != $n_match) {
	    $weight_string
		= (", reported total weight ${total_weight}lb in $n_desc"
		   . ($n_desc > 1 ? ' locations' : ' location'));
	    if ($n_desc != $n_match) {
		# We have some excess descriptions that match the SQL pattern
		# but not the Perl regexp.  Report these in case they are typos
		# (though this is mostly useful for debugging).
		$weight_string .= " [n_desc $n_desc, n_match $n_match].\n";
		$weight_string .= $q->ul(map { $q->li($_); } @fails)
		    if @fails;
	    }
	    else {
		$weight_string .= '.';
	    }
	}
    }

    # Print summaries.
    $q->_header(title => 'Bookworm home page');
    print($q->p('Total of ', $do_class->('Bookworm::Book'),
		' by ', $do_class->('Bookworm::Author'),
		' from ', $do_class->('Bookworm::Publisher'),
		' in ', $do_class->('Bookworm::Location')
		. $weight_string),
	  "\n");

    # Maybe add a histogram plot of weights.
    if (@histogram_bins) {
	my %histogram_hash;
	for my $bin (0 .. @histogram_bins-1) {
	    my $count = $histogram_bins[$bin];
	    next
		unless $count;
	    my $value = $bin * $bin_width;
	    $histogram_hash{$value} = $count;
	}
	my $url = $q->oligo_query('plot-hist.cgi',
				  data => join(';', %histogram_hash));
	print($q->p($q->img({ src => $url, alt => 'Histogram of weights' })),
	      "\n");
    }
    $q->_footer();
}

1;

=head3 web_home_page

Produces the home page for the Bookworm application.  This is what you
see when you click on "Home" in the menu bar, which invokes the main
"index.html" page.  It produces a line like:

    Total of 1216 books by 582 authors from 167 publishers in 87 locations.

where (e.g.) "1216 books" is a link to the C<find-book.cgi> page.
This is easy given that there are only four kinds of searchable
objects in the database.

=cut
