package MojoX::Plugin::AnyCache::Backend::Redis;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';

use Mojo::Redis;

has 'redis';

has 'support_async' => sub { 1 };

sub get_redis {
	my ($self) = @_;
	if(!$self->redis) {
		my %opts = ();
		$opts{server} = $self->config->{server} if exists $self->config->{server};
		$self->redis(Mojo::Redis->new(%opts));
	}
	return $self->redis;
}

sub get { 
	my ($cb, $self) = (pop, shift);
	$self->get_redis->get(@_, sub {
		my ($redis, $value) = @_;
		$cb->($value);
	});
}

sub set {
	my ($cb, $self) = (pop, shift);
	$self->get_redis->set(@_, sub {
		my ($redis) = @_;
		$cb->();
	});
}

1;