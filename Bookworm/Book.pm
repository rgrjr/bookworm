# The Bookworm "Book" class.
#
# [created.  -- rgr, 29-Jan-11.]
#

use strict;
use warnings;

package Bookworm::Book;

use base qw(Bookworm::Base);

BEGIN {
    Bookworm::Book->build_field_accessors
	([ qw(book_id title publisher_id publication_year
              category date_read notes location_id) ]);
    Bookworm::Book->build_fetch_accessor
	(qw(location location_id Bookworm::Location));
    Bookworm::Book->build_set_fetch_accessor
	('authorships',
	 query => q{select authorship_id from book_author_map
		    where book_id = ?},
	 object_class => 'Bookworm::Authorship',
	 cache_key => '_book_authorships');
}

sub table_name { 'book'; }
sub primary_key { 'book_id'; }

# Autoloaded subs.
    sub web_add_author;

sub pretty_name { shift()->title(); }
sub home_page_name { 'book.cgi'; }

sub parent_id_field { 'location_id'; }

sub search_page_name { 'find-book.cgi'; }

sub contained_item_class { return 'Bookworm::Authorship'; }
sub container_items { return shift()->authorships(@_); }

sub book_title {
    # Synonym to avoid ambiguity in web_update.
    shift->title(@_);
}

sub authors {
    my ($self, @new_value) = @_;

    if (@new_value) {
	$self->{_authors} = $new_value[0];
    }
    elsif ($self->{_authors}) {
	return $self->{_authors};
    }
    else {
	my $authors = [ map { $_->author; } @{$self->authorships} ];
	$self->{_authors} = $authors;
	return $authors;
    }
}

sub validate {
    my ($self, $interface) = @_;

    $interface->_error("Books must have a title.\n")
	unless $self->title;
    $interface->_error("Books must have a publisher.\n")
	unless $self->publisher_id;
}

sub format_authors_field {
    # This is only used for display, so it is always read-only.
    my ($self, $q, $descriptor, $cgi_param, $read_only_p, $value) = @_;

    if ($value && ref($value) && @$value) {
	return join(', ', map {
	    my $author = $_;
	    my $id = $author->author_id;
	    join('',
		 $author->html_link($q),
		 $self->book_id ? ()
		 # If the book hasn't been added, then we have to remember the
		 # author(s) in the form.
		 : qq{<input name="author_id" type="hidden" value="$id" />});
		    } @$value);
    }
    else {
	return 'none';
    }
}

sub format_authorship_field {
    # This is only used for display, so it is always read-only.
    my ($self, $q, $descriptor, $cgi_param, $read_only_p, $value) = @_;

    # If we're not in the database, we have just author_id CGI values.
    if (! $self->book_id) {
	require Bookworm::Author;
	# [yes, this is something of a kludge.  -- rgr, 9-Oct-17.]
	my $authors = [ map { Bookworm::Author->fetch($_);
			} $q->param('author_id') ];
	return 'none'
	    unless @$authors;
	my $d = $self->find_accessor_descriptor('author_id');
	return $self->format_authors_field($q, $d, 'author_id', 1, $authors);
    }
    return 'none'
	unless $value && ref($value) && @$value;

    # Classify.
    my %authors_from_role;
    for my $auth (@{$self->authorships}) {
	push(@{$authors_from_role{$auth->role}}, $auth);
    }

    my $listify = sub {
	my ($auths) = @_;

	if (! $auths) {
	    '';
	}
	elsif (@$auths == 2) {
	    join(' and ', map { $_->author->html_link($q); } @$auths);
	}
	else {
	    join(', ', map { $_->author->html_link($q); } @$auths);
	}
    };

    # Start with authors (and ghostwriters).
    my $result = $listify->($authors_from_role{author});
    $result .= ' with ' . $listify->($authors_from_role{with})
	if $authors_from_role{with};

    # Add editors.
    if ($authors_from_role{editor}) {
	my $eds = $listify->($authors_from_role{editor});
	my $n_eds = @{$authors_from_role{editor}};
	if ($result) {
	    $result .= ', edited by ' . $eds;
	}
	else {
	    $result = "$eds, ed" . $self->pluralize($n_eds);
	}
    }

    # And finally translators.
    my $trans = $listify->($authors_from_role{translator});
    if (! $trans) {
	# Usual case without a translator.
    }
    elsif ($result) {
	$result .= ", translated by $trans";
    }
    else {
	# Transient situation?
	$result = "Translated by $trans";
    }
    return $result;
}

my @field_descriptors
    = ({ accessor => 'book_id', verbosity => 2 },
       { accessor => 'title', pretty_name => 'Title',
	 type => 'string', size => 50 },
       { accessor => 'authors', pretty_name => 'Authors',
	 type => 'authors', order_by => '_sortable_authors',
	 verbosity => 2 },
       { accessor => 'authorships', pretty_name => 'Authors',
	 type => 'authorship', order_by => '_sortable_authors' },
       { accessor => 'publisher_id', pretty_name => 'Publisher',
	 type => 'foreign_key', class => 'Bookworm::Publisher',
	 edit_p => 'find-publisher.cgi' },
       { accessor => 'publication_year', pretty_name => 'Year',
	 type => 'string' },
       { accessor => 'category', pretty_name => 'Category',
	 type => 'enumeration',
	 values => [ qw(fiction sf history biography satire text
		        guidebook nonfiction) ] },
       { accessor => 'date_read', pretty_name => 'Date read',
	 type => 'string' }, 
       { accessor => 'notes', pretty_name => 'Notes',
	 type => 'text', search_field => 'book.notes' },
       { accessor => 'location_id', pretty_name => 'Location',
	 edit_p => 'find-location.cgi',
	 type => 'foreign_key', class => 'Bookworm::Location' }
    );

sub local_display_fields { return \@field_descriptors };

sub default_search_fields {
    my ($class) = @_;

    return [ { accessor => 'book_title',
	       pretty_name => 'Title/ID',
	       search_type => 'string',
	       search_id => 'book.book_id',
	       search_field => 'title' },
	     { accessor => 'last_name', pretty_name => 'Authors',
	       type => 'text',
	       search_field => [ qw(first_name mid_name last_name) ] },
	     qw(publication_year date_read category notes),
	     { accessor => 'limit',
	       search_type => 'limit',
	       pretty_name => 'Max books to show',
	       default => 100 } ];
}

sub default_display_columns {
    return [ { accessor => 'title', pretty_name => 'Book',
	       type => 'return_address_link',
	       return_address => 'book.cgi',
	       default_sort => 'asc' },
	     qw(authorships category publication_year publisher_id
		notes date_read location_id) ];
}

my $web_search_base_query
    = q{select book.*,
	       group_concat(last_name separator ', ') as _sortable_authors
	from book
	     left join book_author_map as bam
		  on bam.book_id = book.book_id
	     left join author
		  on author.author_id = bam.author_id};

sub web_search {
    # Tweak the result columns so we can sort by authors.
    my ($class, $q, @options) = @_;
    my %options = @options;

    return $class->SUPER::web_search($q,
				     base_query => $web_search_base_query,
				     extra_clauses => 'group by book.book_id',
				     create_new_page => $class->home_page_name,
				     @options);
}

sub web_update {
    my ($self, $q) = @_;

    my @authors = $q->param('author_id');
    if (@authors) {
	# [total hack.  -- rgr, 25-May-13.]
	require Bookworm::Author;
	$self->authors([ map { Bookworm::Author->fetch($_); } @authors ]);
    }
    $self->SUPER::web_update($q);
}

sub post_web_update {
    my ($self, $q) = @_;

    my @links;
    my $similar_book_link
	= $q->oligo_query('book.cgi',
			  (map { ($_ => $self->$_());
			   } qw(publisher_id publication_year
				category notes location_id)),
			  (map { (author_id => $_->author_id);
			   } @{$self->authors}));
    push(@links,
	 $q->a({ href => $similar_book_link }, '[Add similar book]'));
    push(@links,
	 $q->a({ href => $q->oligo_query('book-authorship.cgi',
					 book_id => $self->book_id) },
	       '[Update authors]'));
    return $q->ul(map { $q->li($_); } @links);
}

sub web_update_authorship {
    my ($self, $q) = @_;
    require ModGen::CGI::make_selection_op_buttons;

    # Handle selection operations.
    use ModGen::Web::Interface;
    my $doit = $q->param('doit') || '';
    my $interface = ModGen::Web::Interface->new(store_message_p => 1,
						query => $q);
    if ($self->handle_container_selection($q)) {
	# Already done.
    }
    elsif ($doit eq 'Delete') {
	$self->move_or_delete_items($q, $interface)
	    and return;
	delete($self->{_book_authorships});	# decache.
    }
    elsif ($doit =~ /To (top|bottom)|Renumber/) {
	$self->renumber_selected_items($q);
    }

    # Present the page.
    $q->_header();
    print($q->h2('Authorship of ', $self->html_link($q)), "\n");
    my $authorships = $self->authorships;
    my $auth1 = $authorships->[0] || $self;
    print($q->start_form(onsubmit
			 => 'return submit_or_operate_on_selected(event)'),
	  $q->hidden('book_id'),
	  "\n");
    print($auth1->present_object_content
	  ($q, "Authors",
	   [ { accessor => 'authorship_id', pretty_name => 'Select?',
	       type => 'checkbox', checked_p => 0, label => ' ' },
	     { accessor => 'author_name', pretty_name => 'Author',
	       type => 'self_link' },
	     qw(attribution_order role) ],
	   $authorships), "\n");
    print($q->p($q->a({ href => $q->oligo_query('add-book-author.cgi',
						book_id => $self->book_id) },
		      '[Add author]')),
	  "\n");
    print($q->make_selection_op_buttons
	      (commit => 1, 'Delete', 'To top', 'To bottom',
	       selected => 0, 'Renumber'), "\n",
	  $q->end_form(), "\n");
    $q->_footer();
}

### Database plumbing.

sub _update_author_data {
    # If we have an "authors" arrrayref, update book_author_map to match.
    my ($self, $dbh) = @_;

    my $authors = $self->{_authors};
    return
	# Must not have changed.
	unless $authors;
    my $book_id = $self->book_id || die;
    $dbh->do(q{delete from book_author_map
	       where book_id = ?},
	     undef, $book_id)
	or die $dbh->errstr;
    for my $author (@$authors) {
	$dbh->do(q{insert into book_author_map (book_id, author_id)
		   values (?, ?)},
		 undef, $book_id, $author->author_id)
	    or die $dbh->errstr;
    }
}

sub insert {
    my ($self, $dbh) = @_;

    $self->SUPER::insert($dbh);
    $self->_update_author_data($dbh);
    return $self;
}

1;

__END__

=head1 Bookworm::Book

=head2 Accessors and methods

=head3 authors

Returns or sets an arrayref of authors.  The first time this is called
with no arguments, the authors are retrieved from our C<authorships>,
and the result is cached.  If called with an arrayref, the cached
value is updated, but no attempt is made to change the C<authorships>
value or the database.  This is intended for keeping track of authors
before the book has been added to the database; see the L</insert>
method.  Use with caution; if the authorship set is changed, the cache
is not invalidated.

=head3 authorships

Set fetch accessor that retrieves an arrayref of
C<Bookworm::Authorship> instances from the database that belong to
this book.

=head3 book_id

Returns or sets the primary key for this book.

=head3 book_title

Synonym for the L</title> slot, to avoid ambiguity in C<web_update>.

=head3 category

Returns or sets the book category, e.g. fiction, biography.  This is
implemented as an enumeration in the schema and the user interface.

=head3 contained_item_class

Returns the string 'Bookworm::Authorship', which enables books to act
as containers for their author(s).

=head3 container_items

This acts as an alias for the C<authorship> slot, which enables books
to act as containers for their author(s).

=head3 date_read

Returns or sets a string recording the date on which the book was last
read.  This is treated as a string, partly to allow approximate dates,
and partly because the MODEST user interface does not have much
support for dates, other than recording and displaying them.

=head3 default_display_columns

Returns an arrayref of attribute descriptors and attribute names for
book search result display.

=head3 default_search_fields

Returns an arrayref of attribute descriptors and attribute names that
define book search dialog fields.

=head3 format_authors_field

Given a C<ModGen::CGI> query object, an attribute descriptor, the name
of the CGI parameter, a read-only flag, and the value (an arrayref of
C<Bookworm::Author> objects), return a string with links to all
authors.  This is used for books that are not in the database yet, so
they don't have L</authorship>.  The read-only flag is ignored because
the value is always treated as read-only.  See
L<ModGen::Thing/format_accessor_value>.

=head3 format_authorship_field

Given a C<ModGen::CGI> query object, an attribute descriptor, the name
of the CGI parameter, a read-only flag, and the value (an arrayref of
C<Bookworm::Authorship> objects), return a string with links to all
authors, treating ghostwriters, editors, and translators specially;
this is the normal way to present the L</authorship> for a book.  The
read-only flag is ignored because the value is always treated as
read-only.  See L<ModGen::Thing/format_accessor_value>.

Here's an example of the C<format_authorship_field> result for
multiple "author" authors (title on the first line, authorship string
on the second):

	Shadow of the Lion, The
	Mercedes Lackey, Eric Flint, David Freer

For a "with" author:

	Within Reach: My Everest Story
	Mark Pfetzer with Jack Galvin

For an edited collection:

	Best SF: 1967
	Harry Harrison and Brian W. Aldiss, eds

For a translated work:

	Love in the Time of Cholera
	Gabriel Garcia Marquez, translated by Edith Grossman

In the second and third examples, the authorship C<attribution_order>
is ignored, because translators and "with" authors are always
presented after "primary" authors.

=head3 home_page_name

Returns the string "book.cgi", so that the C<home_page_url> method
of C<Bookworm::Base> can construct a URL for the book.  See the
L<ModGen::DB::Thing/html_link> method.

=head3 insert

Given a database handle, insert the book into the database (taken care
of by the C<ModGen::DB::Thing> main method), and then update the
C<book_author_map> table to match the value cached from the
L</authors> accessor.

=head3 location

Fetch accessor that returns or sets the C<Bookworm::Location> based on
the C<location_id>.

=head3 location_id

Returns or sets the ID of the book's location, a C<Bookworm::Location>
instance.  When created, a book is not required to have a location,
but there is no user interface for removing a location.

=head3 notes

Returns or sets free text notes about the book.

=head3 parent_id_field

This slot acts as an alias for the L</location_id> slot.

=head3 publication_year

Returns or sets a string identifying the year of publication.  (For
reissues of classics, I usually make this the year of first
publication, and put the actual year this edition was published in the
notes.)

=head3 publisher_id

Returns or sets the ID of the C<Bookworm::Publisher>.  Note that there
is no fetch accessor for the publisher, because we don't do much with
publishers.

=head3 title

Returns or sets the string that is the primary title of the book,
prepared for sorting, as in "Adventures of Huckleberry Finn, The".
Subtitles are usually reported in the C<notes> field.

=head3 validate

Given a C<ModGen::Web::Interface>, insists on having a C<title> and a
C<publisher_id>, reporting any errors via the interface.

=head3 web_add_author

Autoloaded.

=head3 web_update_authorship

Presents a Web page that allows the authorship
(i.e. C<book_author_map> content) to be manipulated by the user.  This
uses the MODEST container API to reorder and/or delete authors en
masse (not that we usually have masses of authors).  See
L<ModGen::DB::Thing/The container API>.

=cut
