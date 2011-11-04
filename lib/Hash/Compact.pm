package Hash::Compact;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);

our $VERSION = '0.03';

sub new {
    my $class   = shift;
    my $options = @_ > 1 && (ref $_[-1] || '') eq 'HASH' ? pop : {};
    my $self    = bless { __OPTIONS__ => $options }, $class;
    my $args    = shift || {};

    croak '$args must be a hash-ref'
        if (ref $args || '') ne 'HASH';

    while (my ($key, $value) = each %$args) {
        $self->param($key, $value);
    }

    $self;
}

sub options { $_[0]->{__OPTIONS__} }

sub param {
    my $self = shift;
    my $value;

    if (@_ > 1) {
        croak 'incorrect key/value pair'
            if @_ % 2;

        my %args = @_;
        while (my ($key, $value) = each %args) {
            my $option = $self->options->{$key} || {};
            $key = $option->{alias_for} || $key;

            if (defined $value && !ref $value && $value eq ($option->{default} || '')) {
                delete $self->{$key};
            }
            else {
                $self->{$key} = $value;
            }
        }
    }
    else {
        my $key    = shift;
        my $option = $self->options->{$key} || {};

        $value = $self->{$option->{alias_for} || $key} || $option->{default};
    }

    $value;
}

sub to_hash {
    my $self = shift;

    +{
        map  {
            my $value = $self->{$_};
            if (blessed $value && $value->can('to_hash')) {
                $_ => $value->to_hash;
            }
            else {
                $_ => $value;
            }
        }
        grep { $_ ne '__OPTIONS__' } keys %$self
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Hash::Compact - A hash-based object implementation with key alias and
default value support

=head1 SYNOPSIS

  package My::Memcached;

  use strict;
  use warnings;
  use parent qw(Cache::Memcached::Fast);

  use JSON;
  use Hash::Compact;

  my $OPTIONS = {
      foo => {
          alias_for => 'f',
      },
      bar => {
          alias_for => 'b',
          default   => 'bar',
      },
  };

  sub get {
      my ($self, $key) = @_;
      my $value = $self->SUPER::get($key);
      Hash::Compact->new(decode_json $value, $OPTIONS);
  }

  sub set {
      my ($self, $key, $value, $expire) = @_;
      my $hash = Hash::Compact->new($value, $OPTIONS);
      $self->SUPER::set($key, encode_json $hash->to_hash, $expire);
  }

  package main;

  use strict;
  use warnings;
  use Test::More;

  my $key   = 'key';
  my $value = { foo => 'foo' };
  my $memd  = My::Memcached->new({servers => [qw(localhost:11211)]});
     $memd->set($key, $value);

  my $cached_value = $memd->get($key);
  is_deeply $cached_value->param('foo'), 'foo';
  is_deeply $cached_value->param('bar'), 'bar';
  is_deeply $cached_value->to_hash, +{ f => 'foo' };

  $cached_value->param(bar => 'baz');
  $memd->set($key, $cached_value->to_hash);

  $cached_value = $memd->get($key);
  is_deeply $cached_value->param('foo'), 'foo';
  is_deeply $cached_value->param('bar'), 'baz';
  is_deeply $cached_value->to_hash, +{ f => 'foo', b => 'baz' };

  done_testing;

=head1 DESCRIPTION

When we store some structured value into a column of a relational
database or some key/value storage, redundancy of long key names can
be a problem for storage space.

This module is yet another hash-based object implementation which aims
to be aware of both space efficiency and easiness to use for us.

=head1 METHODS

=head2 new (I<\%hash> I<[, \%options]>)

  my $hash = Hash::Compact->new({
          foo => 'foo',
      }, {
          foo => {
              alias_for => 'f',
          },
          bar => {
              alias_for => 'b',
              default   => 'bar',
          },
      },
  );

Creates and returns a new Hash::Compact object. If C<\%options> not
passed, Hash::Compact object C<$hash> will be just a plain hash-based
object.

C<\%options> is a hash-ref which key/value pairs are associated with
ones of C<\%hash>. It may contain the fields below:

=over 4

=item * alias_for

Alias to an actual key. If it's passed, C<\%hash> will be compacted
into another hash which has aliased key. The original key of C<\%hash>
will be just an alias to an actual key.

=item * default

If this exists and the value associated with the key of C<\%hash> is
undefined, Hash::Compact object C<$hash> returns just the value. It's
for space efficiency; C<$hash> doesn't need to have key/value pair
when the value isn't defined or it's same as default value.

=back

=head2 param (I<$key> I<[, $value]>)

  $hash->param('foo');          #=> 'foo'
  $hash->param('bar');          #=> 'bar' (returns the default value)

  $hash->param(bar => 'baz');
  $hash->param('bar');          #=> 'baz'

Setter/getter method.

=head2 to_hash ()

  my $compact_hash_ref = $hash->to_hash;
  #=> { f => 'foo', b => 'baz' } (returns a compacted hash)

Returns a compacted hash according to C<\%options> passed into the
constructor above;

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
