package Hash::Compact;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);

our $VERSION = '0.01';

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

            if (!ref $value && $value eq ($option->{default} || '')) {
                delete $self->{$key};
            }
            else {
                $self->{$key} = $value;
            }
        }
    }
    else {
        my $key     = shift;
        my $option = $self->options->{$key} || {};
        $value  = $self->{$option->{alias_for} || $key} || $option->{default};
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
        grep { $_ ne '__OPTIONS__' } keys %$self }
}

1;
__END__

=encoding utf8

=head1 NAME

Hash::Compact -

=head1 SYNOPSIS

  use Hash::Compact;

=head1 DESCRIPTION

Hash::Compact is

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
