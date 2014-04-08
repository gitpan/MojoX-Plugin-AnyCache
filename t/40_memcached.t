#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

unless($ENV{'CACHE_TEST_MEMCACHED'}) {
	plan skip_all => 'Memcached tests skipped - set CACHE_TEST_MEMCACHED to run tests'
}

package FakeApp {
	use Mojo::Base -base;
	sub helper {}
}

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

$cache->register(FakeApp->new, { backend => 'MojoX::Plugin::AnyCache::Backend::Memcached', servers => [ "127.0.0.1:11211" ] });
isa_ok $cache->backend, 'MojoX::Plugin::AnyCache::Backend::Memcached';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';

# FIXME should clear memcached, not choose a random key
# this could still fail!
my $key = rand(10000000);

is $cache->get($key), undef, 'unset key returns undef in sync mode';
$cache->set($key => 'bar');
is $cache->get($key), 'bar', 'set key returns correct value in sync mode';

done_testing(7);
