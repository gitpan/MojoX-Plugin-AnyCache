package MojoX::Plugin::AnyCache::Serialiser::MessagePack;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Serialiser';

use Data::MessagePack;
use constant F_MESSAGEPACK => 256;

sub deserialise {
    my ($self, $data, $flags) = @_;

    return unless defined $data;

    $flags ||= 0;

    if ($flags & F_MESSAGEPACK) {
        my $mp = Data::MessagePack->new();
        # TODO implement serialiser configuration
        $mp->prefer_integer(0);
        $data = $mp->unpack( $data );
    }

    return $data;
}

sub serialise {
    my ($self, $data) = @_;

    return unless defined $data;

    my $flags = 0;

    if (ref $data) {
        my $mp = Data::MessagePack->new();
        $mp->prefer_integer(0);
        $data = $mp->pack( $data );
        $flags |= F_MESSAGEPACK;
    }

    return ($data, $flags);
}

1;
