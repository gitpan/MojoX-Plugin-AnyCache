#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

unless($ENV{'CACHE_TEST_REDIS'}) {
	plan skip_all => 'Redis tests skipped - set CACHE_TEST_REDIS to run tests'
}

package FakeApp {
	use Mojo::Base -base;
	sub helper {}
}

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

my %opts = ();
$opts{server} = $ENV{'CACHE_TEST_REDIS_HOST'} if $ENV{'CACHE_TEST_REDIS_HOST'};
$cache->register(FakeApp->new, { backend => 'MojoX::Plugin::AnyCache::Backend::Redis', %opts });
isa_ok $cache->backend, 'MojoX::Plugin::AnyCache::Backend::Redis';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';

# FIXME should clear redis, not choose a random key
# this could still fail!
my $key = rand(10000000);

$cache->get($key, sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->set($key => 'bar', sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get($key, sub { is shift, 'bar', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

done_testing(8);
