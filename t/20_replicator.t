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

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

my %opts = (
	nodes => [
		{ backend => 'FakeBackend' },
		{ backend => 'FakeBackend' },
		{ backend => 'FakeBackend' },
		{ backend => 'FakeBackend' },
	]
);
$cache->register(FakeApp->new, { backend => 'MojoX::Plugin::AnyCache::Backend::Replicator', %opts });
isa_ok $cache->backend, 'MojoX::Plugin::AnyCache::Backend::Replicator';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';
is @{$cache->backend->{nodes}}, 4, 'Backend created 4 nodes';

is $cache->get('foo'), undef, 'unset key returns undef in sync mode';
$cache->set('foo' => 'bar');
is $cache->get('foo'), 'bar', 'set key returns correct value in sync mode';

for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('foo'), 'bar', "node $_ stored correct value";
}

$cache->get('qux', sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->set('qux' => 'bar', sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('qux', sub { is shift, 'bar', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('qux'), 'bar', "node $_ stored correct value";
}

done_testing(19);
