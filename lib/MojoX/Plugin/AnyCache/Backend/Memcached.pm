package MojoX::Plugin::AnyCache::Backend::Memcached;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';

use Cache::Memcached;

has 'memcached';

has 'support_sync' => sub { 1 };

sub get_memcached {
	my ($self) = @_;
	if(!$self->memcached) {
		my %opts = ();
		$opts{servers} = $self->config->{servers} if exists $self->config->{servers};
		$self->memcached(Cache::Memcached->new(%opts));
	}
	return $self->memcached;
}

sub get { shift->get_memcached->get(@_) }
sub set { shift->get_memcached->set(@_)	}

1;