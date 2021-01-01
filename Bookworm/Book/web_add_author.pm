# Add an author to a book.
#
# [created.  -- rgr, 29-Jan-11.]
#

package Bookworm::Book;

sub web_add_author {
    my ($self, $q) = @_;

    # Validate.
    my $author_id = $q->param('author_id');
    my $self_address = $q->modified_self_url();
    my $search_url = $q->oligo_query('find-author.cgi',
				     return_address => $self_address);
    if (! $author_id) {
	print $q->redirect($search_url);
	return;
    }

    # Check for duplication.
    my $caller = $q->param('return_address') || $self->home_page_url($q);
    for my $author (@{$self->authors}) {
	if ($author->author_id == $author_id) {
	    my $msg = join(' ', $author->author_name, 'is already an author.');
	    my $return_address = $q->oligo_query($caller, _messages => $msg);
	    print $q->redirect($return_address);
	    return;
	}
    }

    # Add the thing.
    my $dbh = $q->connect_to_database();
    $dbh->do('insert into book_author_map (author_id, book_id) values (?, ?)',
	     undef, $author_id, $self->book_id)
	or die $dbh->errstr;
    my $return_address = $q->oligo_query($caller, message => 'Author added');
    print $q->redirect($return_address);
}

1;

__END__

=head3 web_add_author

Presents a Web page that adds an author to a book.  If there is no
C<author_id> CGI parameter, we redirect to the C<find-author.cgi>
page.  Otherwise, if the author is not already one of ours, we add a
C<book_author_map> row and redirect back to the book page.

=cut
