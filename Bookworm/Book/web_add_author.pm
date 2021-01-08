# Add an author to a book.
#
# [created.  -- rgr, 29-Jan-11.]
#

package Bookworm::Book;

sub web_add_author {
    my ($self, $q) = @_;

    # Validate.
    my @author_ids = $q->param('author_id');
    my $self_address = $q->modified_self_url();
    if (! @author_ids) {
	my $search_url = $q->oligo_query('find-author.cgi',
					 multiple_p => 1,
					 return_address => $self_address);
	print $q->redirect($search_url);
	return;
    }

    # Check for duplication.
    my $caller = $q->param('return_address') || $self->home_page_url($q);
    my $max_order = 0;
    {
	my $msg = '';
	my %author_id_p = map { ($_ => 1); } @author_ids;
	for my $authorship (@{$self->authorships}) {
	    if ($author_id_p{$authorship->author_id}) {
		$msg .= "\n"
		    if $msg;
		$msg .= $authorship->author_name . ' is already an author.';
	    }
	    my $order = $authorship->attribution_order;
	    $max_order = $order
		if $max_order < $order;
	}
	if ($msg) {
	    my $return_address = $q->oligo_query($caller, _messages => $msg);
	    print $q->redirect($return_address);
	    return;
	}
    }

    # Add the thing.
    my $dbh = $q->connect_to_database();
    for my $author_id (@author_ids) {
	$dbh->do(q{insert into book_author_map
 	               (author_id, book_id, attribution_order)
	           values (?, ?, ?)},
		 undef, $author_id, $self->book_id, $max_order + 1)
	    or die $dbh->errstr;
    }
    my $n_authors = scalar(@author_ids);
    my $message = ($n_authors == 1
		   ? 'One new author added.'
		   : "$n_authors authors added.");
    my $return_address = $q->oligo_query($caller, message => $message);
    print $q->redirect($return_address);
}

1;

__END__

=head3 web_add_author

Presents a Web page that adds an author to a book.  If there is no
C<author_id> CGI parameter, we redirect to the C<find-author.cgi>
page.  Otherwise, if the author is not already one of ours, we add a
C<book_author_map> row and redirect back to the book page.

Note that this only works for books that are already in the database,
so we can fetch L</authorships> and initialize C<attribution_order>
correctly.  (We don't know what the user has in mind for C<role>; it's
probably just as an ordinary author, so we'll let that default and let
the user correct it later if need be.)

=cut
