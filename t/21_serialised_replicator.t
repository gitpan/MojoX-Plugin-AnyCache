#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;

package FakeApp {
	use Mojo::Base -base;
	sub helper {}
}

package FakeBackend {
	use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';
	my $storage = {};
	has 'config';
	has 'support_sync' => sub { 1 };
	has 'support_async' => sub { 1 };
	sub get {
		my ($self, $key, $cb) = @_;
		return $cb->($storage->{$key}) if $cb;
		return $storage->{$key};
	}
	sub set {
		my ($self, $key, $value, $cb) = @_;
		$storage->{$key} = $value;
		$cb->() if $cb;
	}
}

package FakeSerialiser {
	use Mojo::Base 'MojoX::Plugin::AnyCache::Serialiser';
	sub deserialise {
	    my ($self, $data, $flags) = @_;
	    $data =~ tr/0-9/A-J/ if $data;
	    return $data;
	}
	sub serialise {
	    my ($self, $data) = @_;
	    $data =~ tr/A-J/0-9/ if $data;
	    return $data;
	}
}

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

my %opts = (
	nodes => [
		{ backend => 'FakeBackend', serialiser => 'FakeSerialiser' },
		{ backend => 'FakeBackend', serialiser => 'FakeSerialiser' },
		{ backend => 'FakeBackend', serialiser => 'FakeSerialiser' },
		{ backend => 'FakeBackend', serialiser => 'FakeSerialiser' },
	]
);
$cache->register(FakeApp->new, { backend => 'MojoX::Plugin::AnyCache::Backend::Replicator', %opts });
isa_ok $cache->backend, 'MojoX::Plugin::AnyCache::Backend::Replicator';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';
is @{$cache->backend->{nodes}}, 4, 'Backend created 4 nodes';

is $cache->get('foo'), undef, 'unset key returns undef in sync mode';
$cache->set('foo' => 'BAR');
is $cache->get('foo'), 'BAR', 'set key returns correct value in sync mode';

for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('foo'), '10R', "node $_ stored correct value";
}

$cache->get('qux', sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->set('qux' => 'BAR', sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('qux', sub { is shift, 'BAR', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('qux'), '10R', "node $_ stored correct value";
}

done_testing(19);
