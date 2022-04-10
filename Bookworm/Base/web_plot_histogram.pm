# Bookworm histogram plotter.
#
# [created.  -- rgr, 9-Apr-22.
#

use strict;
use warnings;

package Bookworm::Base;

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

__END__

=head3 web_plot_histogram

Given a C<ModGen::CGI> object that has a single C<data> param with
alternating keys and values, run C<gnuplot> to spit an C<image/png>
HTTP response on stdout with a histogram plot.

=cut
