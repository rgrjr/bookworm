# The Bookworm "Author" class.
#
# [created.  -- rgr, 29-Jan-11.]
#

use strict;
use warnings;

package Bookworm::Author;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Author->build_field_accessors
	([ qw(author_id first_name mid_name last_name notes) ]);
    # These are created during search.
    Bookworm::Author->define_class_slots(qw(author_sort_name n_books));
}

sub table_name { 'author'; }
sub primary_key { 'author_id'; }

sub pretty_name { shift()->author_name(); }
sub home_page_name { 'author.cgi'; }
sub search_page_name { 'find-author.cgi'; }

sub books {
    my $self = shift;

    if (@_) {
	$self->{_books} = shift;
    }
    elsif ($self->{_books}) {
	return $self->{_books};
    }
    else {
	require Bookworm::Book;
	my $books = [ ];
	my $query = qq(select bam.book_id
		       from book_author_map as bam
                            join book on bam.book_id = book.book_id
		       where author_id = ?
                       order by title);
	my $dbh = $self->connect_to_database;
	my $ids = $dbh->selectcol_arrayref($query, undef, $self->author_id)
	    or die $dbh->errstr;
	for my $id (@$ids) {
	    push(@$books, Bookworm::Book->fetch($id));
	}
	$self->{_books} = $books;
	return $books;
    }
}

sub validate {
    my ($self, $interface) = @_;

    $interface->_error("Authors must have at least a last name.\n")
	unless $self->last_name;
}

sub author_name {
    my $self = shift;

    my $result = '';
    for my $field (qw(first_name mid_name last_name)) {
	my $name = $self->$field();
	next
	    unless $name;
	$result .= ' '
	    if $result;
	$result .= $name;
    }
    return $result;
}

my @field_descriptors
    = ({ accessor => 'author_id', pretty_name => 'Author', verbosity => 2 },
       { accessor => 'first_name', pretty_name => 'First name',
	 type => 'string' },
       { accessor => 'mid_name', pretty_name => 'Middle name',
	 type => 'string' },
       { accessor => 'last_name', pretty_name => 'Last name',
	 type => 'string', default_sort => 'asc' },
       { accessor => 'notes', pretty_name => 'Notes',
	 type => 'text' }
    );

sub local_display_fields { return \@field_descriptors };

sub default_search_fields {
    return [ { accessor => 'last_name', pretty_name => 'Author name',
	       type => 'string',
	       search_field => [ qw(first_name mid_name last_name) ] },
	     'notes',
	     { accessor => 'limit',
	       search_type => 'limit',
	       pretty_name => 'Max authors to show',
	       default => 100 } ];
}

sub default_display_columns {
    return [ { accessor => 'author_sort_name', pretty_name => 'Author name',
	       type => 'return_address_link',
	       return_address => 'author.cgi',
	       order_by => '_author_sort_name' },
	     { accessor => 'n_books', pretty_name => '# books',
	       order_by => '_n_books' },
	     qw(notes) ];
}

my $web_search_base_query
    = q{select author.*, 
	       concat(last_name, ', ', first_name, ' ', mid_name)
		   as _author_sort_name,
	       count(bam.author_id) as _n_books
	from author
	     left join book_author_map as bam
		  on bam.author_id = author.author_id};

sub web_search {
    # Add "left join" & "group by" so we can count books.  This must be a left
    # join so we include authors without books (yet).
    my ($class, $q, @options) = @_;

    return $class->SUPER::web_search
	($q,
	 base_query => $web_search_base_query,
	 extra_clauses => 'group by author.author_id',
	 @options);
}

my $book_columns
    = [ { accessor => 'title', pretty_name => 'Book',
	  type => 'self_link',
	  return_address => 'book.cgi' },
	qw(publication_year category notes date_read location_id) ];

sub ajax_sort_content {
    # Handle AJAX requests to sort our books.
    my ($self, $q) = @_;

    my $prefix = $q->param('prefix') || '';
    my $messages = { debug => '' };
    if ($prefix eq 'book') {
	my $books = $self->books;
	my $book_presenter = @$books ? $books->[0] : $self;
	$messages->{book_content}
	    = $book_presenter->present_sorted_content
		($q, $self->html_link(undef) . ' books',
		 $book_columns, $books, prefix => 'book');
    }
    else {
	$messages->{debug} = "Unknown prefix '$prefix'.";
    }
    $q->send_encoded_xml($messages);
}

sub web_update {
    # Add an onSubmit trigger that supports AJAX book sorting.
    my ($self, $q, @options) = @_;

    $q->include_javascript('update-content.js');
    my $a1 = $q->oligo_query('ajax-author-sort.cgi', prefix => 'book');
    my $on_submit
	= qq{return maybe_update_sort(event, 'book', 'update', '$a1', '&');};
    $self->SUPER::web_update
	($q, @options, onsubmit => $on_submit);
}

sub post_web_update {
    my ($self, $q) = @_;

    my @links;
    my $book_link = $q->oligo_query('book.cgi', author_id => $self->author_id);
    push(@links, $q->a({ href => $book_link }, '[Add book]'));
    my $books = $self->books;
    my $presenter = @$books ? $books->[0] : $self;
    join("\n",
	 $q->ul(map { $q->li($_); } @links),
	 $q->div({ id => 'book_content' },
		 $presenter->present_sorted_content
		     ($q, 'Books by this author',
		      $book_columns, $books,
		      prefix => 'book', default_sort => 'title')));
}

1;

__END__

=head1 Bookworm::Author

Represents an author in the Bookworm database.  This also includes
editors, ghostwriters, and translators.  Authors are primarily
interesting in terms of the books they have written.

=head2 Accessors and methods

=head3 ajax_sort_content

Support AJAX sorting of our books.  This is the implementation of the
C<ajax-author-sort.cgi> page using C<present_sorted_content>.

=head3 author_id

Returns or sets the primary key for the author in the database.

=head3 author_name

Returns the C<first_name>, C<mid_name>, and C<last_name>, suitably
composed into a single string.

=head3 author_sort_name

Returns or sets a sortable version of the author's name This slot is
constructed as "C<last_name>, C<first_name>, C<mid_name>" by the
search page, and is not valid otherwise.

=head3 books

Returns or sets an arrayref of C<Bookworm::Book> objects for which we
have some kind of authorship as recorded in the C<book_author_map>
table (though we might in fact just be an editor).  Note that setting
the C<books> slot does not update C<book_author_map>.

=head3 default_display_columns

Returns an arrayref of attribute descriptors and attribute names for
author search result display.

=head3 default_search_fields

Returns an arrayref of attribute descriptors and attribute names that
define author search dialog fields.

=head3 first_name

Returns or sets the first name of the author, which is free text.  The
first name is not required.

=head3 home_page_name

Returns the string "author.cgi", so that the C<home_page_url>
method of C<Bookworm::Base> can construct a URL for the book.  See the
L<ModGen::DB::Thing/html_link> method.

=head3 last_name

Returns or sets the last name and optional suffix of the author, which
is free text.  The last name is required by the C<validate> method.

=head3 mid_name

Returns or sets the middle name or initial of the author, which is
free text.  The middle name is not required.

=head3 n_books

Returns or sets the number of books we have by this author.  This slot
is created by the search page, and is not valid otherwise.

=head3 notes

Returns or sets a free text string of notes about the author, which is
free text.

=head3 validate

Given a C<ModGen::Web::Interface>, insists on having a C<last_name>,
reporting an error via the interface if it is missing.

=cut
