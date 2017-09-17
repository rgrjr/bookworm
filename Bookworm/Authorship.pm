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
