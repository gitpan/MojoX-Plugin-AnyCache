#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Mojo::IOLoop;

package FakeApp {
	use Mojo::Base -base;
	sub helper {}
}

package FakeBackend {
	use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';
	my $storage = {};
	has 'config';
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

$cache->register(FakeApp->new, { backend => 'FakeBackend' });
isa_ok $cache->backend, 'FakeBackend';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';

dies_ok { $cache->get('foo') } 'dies in sync mode without backend support';
like $@, qr/^Backend FakeBackend doesn't support synchronous requests/, 'correct error message in sync mode';
dies_ok { $cache->get('foo', sub {}) } 'dies in async mode without backend support';
like $@, qr/^Backend FakeBackend doesn't support asynchronous requests/, 'correct error message in async mode';

$cache->backend->support_sync(1);
is $cache->get('foo'), undef, 'unset key returns undef in sync mode';
$cache->set('foo' => 'bar');
is $cache->get('foo'), 'bar', 'set key returns correct value in sync mode';

$cache->backend->support_async(1);
$cache->get('qux', sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->set('qux' => 'bar', sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('qux', sub { is shift, 'bar', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

done_testing(14);
