package MojoX::Plugin::AnyCache::Serialiser::MessagePack;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Serialiser';

use Data::MessagePack;

sub deserialise {
    my ($self, $data) = @_;

    return unless defined $data;

    # TODO implement serialiser configuration
    my $mp = Data::MessagePack->new();
    $mp->prefer_integer(0);
    $data = $mp->unpack( $data );

    return $data;
}

sub serialise {
    my ($self, $data) = @_;

    return unless defined $data;

    my $mp = Data::MessagePack->new();
    $mp->prefer_integer(0);
    $data = $mp->pack( $data );

    return $data;
}

1;
