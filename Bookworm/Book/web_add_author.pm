# Add an author to a book.
#
# [created.  -- rgr, 29-Jan-11.]
#
# $Id$

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

    # Add the thing.
    my $dbh = $q->connect_to_database();
    $dbh->do('insert into book_author_map (author_id, book_id) values (?, ?)',
	     undef, $author_id, $self->book_id)
	or die $dbh->errstr;
    my $caller = $q->param('return_address') || $self->home_page_name;
    my $return_address = $q->oligo_query($caller, message => 'Author added');
    print $q->redirect($caller);
}

1;
