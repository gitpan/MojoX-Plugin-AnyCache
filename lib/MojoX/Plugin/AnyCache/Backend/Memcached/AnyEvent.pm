package MojoX::Plugin::AnyCache::Backend::Memcached::AnyEvent;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';

use Cache::Memcached::AnyEvent;

has 'memcached';

has 'support_async' => sub { 1 };

sub get_memcached {
	my ($self) = @_;
	if(!$self->memcached) {
		my %opts = ();
		$opts{servers} = $self->config->{servers} if exists $self->config->{servers};
		$self->memcached(Cache::Memcached::AnyEvent->new(%opts));
	}
	return $self->memcached;
}

sub get { 
	my ($cb, $self) = (pop, shift);
	$self->get_memcached->get(@_, sub {
		my ($memcached, $value) = @_;
		$cb->($value);
	});
}

sub set {
	my ($cb, $self) = (pop, shift);
	$self->get_memcached->set(@_, sub {
		my ($memcached) = @_;
		$cb->();
	});
}

1;