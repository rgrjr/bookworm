# The Bookworm "Authorship" class.
#
# This describes how a single "author" (who could also be an editor or a
# ghostwriter) relates to a particular book.
#
# [created.  -- rgr, 17-Sep-17.]
#

use strict;
use warnings;

package Bookworm::Authorship;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Authorship->build_field_accessors
	([ qw(authorship_id author_id book_id attribution_order role) ]);
    Bookworm::Authorship->build_fetch_accessor
	(qw(author author_id Bookworm::Author));
    Bookworm::Authorship->build_fetch_accessor
	(qw(book book_id Bookworm::Book));
    Bookworm::Authorship->define_class_slots('new_index');
}

sub table_name { 'book_author_map'; }
sub primary_key { 'authorship_id'; }

sub home_page_name { 'update-authorship.cgi'; }
sub item_id { shift()->author_id(@_);}
sub sort_index { shift()->attribution_order(@_); }

sub author_name {
    my ($self) = @_;

    my $author = $self->author;
    return $author ? $author->author_name : 'Anonymous';
}

sub book_title {
    my ($self) = @_;

    my $book = $self->book;
    return $book ? $book->title : 'Unknown';
}

sub pretty_name {
    my ($self) = @_;

    return join('', $self->author_name, ' as ', $self->role,
		' of ', $self->book_title);
}

my @field_descriptors
    = ({ accessor => 'authorship_id', verbosity => 2 },
       { accessor => 'book_id', pretty_name => 'Book',
	 type => 'foreign_key', class => 'Bookworm::Book' },
       { accessor => 'author_id', pretty_name => 'Author',
	 type => 'foreign_key', class => 'Bookworm::Author',
	 edit_p => 'find-author.cgi' },
       { accessor => 'attribution_order', pretty_name => 'Order',
	 type => 'integer' },
       { accessor => 'role', pretty_name => 'Role',
	 type => 'enumeration',
	 values => [ qw(author with editor translator) ]} );

sub local_display_fields { return \@field_descriptors };

1;

__END__

=head1 Bookworm::Authorship

Represents the relationship of a C<Bookworm::Book> to a
C<Bookworm::Author>, since the mapping between them is many-to-many.
Usually, this is simple authorship, in which case the C<role> slot
value is "author", but can also be as a ghostwriter (if the C<role> is
"with"), as an editor (if the C<role> is "editor"), or as a translator
(if the C<role> is "translator").  We also keep track of the
C<attribution_order> so that we can present authors in the correct
order when describing the book.

=head2 Accessors and methods

=head3 attribution_order

Returns or sets an integer that describes the order in which authors
of a given book should be presented.  The values should be distinct,
but no complaint is made if there are duplicates, and translators are
always presented last regardless.

=head3 author

Returns or sets our C<Bookworm::Author>, represented by our
C<author_id>.

=head3 author_id

Returns or sets the ID of our C<Bookworm::Author>.

=head3 author_name

Returns the C<author_name> of our C<author>, but is careful in that if
for some reason we don't have an C<author>, just returns the string
"Anonymous" instead.

=head3 authorship_id

Returns or sets the primary key of the underlying C<book_author_map>
row.

=head3 book

Returns or sets the C<Bookworm::Book> identified by our C<book_id>.

=head3 book_id

Returns or sets the ID of the C<Bookworm::Book> that owns us.

=head3 book_title

Returns the C<title> of our C<book>, but is careful in that if for
some reason we don't have a C<book>, just returns the string "Unknown"
instead.

=head3 home_page_name

Returns the string "update-authorship.cgi", so that the
C<home_page_url> method of C<Bookworm::Base> can construct a URL for
the book.  See the L<ModGen::DB::Thing/html_link> method.

=head3 item_id

Synonym for the C<author_id> slot, which allows the
C<book-authorship.cgi> page to manipulate the authorship of a book.
See L<Bookworm::Book/web_update_authorship> and
L<ModGen::DB::Thing/The container API>.

=head3 role

Returns or sets the role of the author with respect to the book.  This
is an enumeration in the database, and can be one of "author" (the
default), "with" (for a ghostwriter or other subsidiary author),
"editor", or "translator".  We expect that there may be multiple
authors in any given role, and not necessary any "author" role (as for
an edited collection of short stories).

=head3 sort_index

Synonym for the L</attribution_order> slot, used by the container API
for renumbering and display.  
See L<ModGen::DB::Thing/The container API>.

=cut
