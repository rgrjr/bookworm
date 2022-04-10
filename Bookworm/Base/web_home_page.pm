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

    # Build @histogram_bins and %destinations.
    my $weight_string = '.';
    my $bin_width = 5;
    my (@histogram_bins, %destinations);
    {
	my ($total_weight, $n_desc) = (0, 0);
	my $sth = $dbh->prepare
	    (q{select weight, destination from location
	           where weight > 0.0})
	    or die $dbh->errstr;
	$sth->execute()
	    or die $dbh->errstr;
	while (my @row = $sth->fetchrow_array) {
	    $n_desc++;
	    my ($weight, $destination) = @row;
	    $total_weight += $weight;
	    # Note that we're making these case-insensitive, but keeping the
	    # case of the first one we encounter.
	    my $dest = ($destinations{lc($destination)}
			||= [ $destination, 0, 0.0 ]);
	    $dest->[1]++;
	    $dest->[2] += $weight;
	    my $bin = int($weight / $bin_width);
	    $histogram_bins[$bin]++;
	}
	if ($total_weight > 0) {
	    my $search_url = $q->oligo_query('find-location.cgi',
					     weight_min => 1);
	    my $search_link
		= $q->a({ href => $search_url }, "in $n_desc",
			($n_desc > 1 ? 'locations' : 'location'));
	    $weight_string
		= (", reported total weight ${total_weight}lb "
		   . "$search_link.");
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

    # Maybe add weight summaries.
    if (@histogram_bins) {

	# Table of weights by destination.
	my @rows
	    = (q{<tr><th>Destination</th><th>Boxes</th><th>Weight</th></tr>});
	for my $dest_name (sort(keys(%destinations))) {
	    my ($dest, $count, $weight) = @{$destinations{$dest_name}};
	    my $search_url = $q->oligo_query('find-location.cgi',
					     destination => $dest);
	    my $search_link
		= $q->a({ href => $search_url }, $q->escapeHTML($dest));
	    push(@rows,
		 $q->Tr($q->td($search_link),
			$q->td({ align => 'right' }, $count),
			$q->td({ align => 'right' },
			       sprintf('%.1f', $weight))));
	}
	print($q->blockquote($q->table(join("\n", @rows))), "\n");

	# Weight histogram distribution plot.
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
