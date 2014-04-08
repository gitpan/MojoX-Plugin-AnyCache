package MojoX::Plugin::AnyCache;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

has 'app';
has 'backend';
has 'config';

sub register {
  my ($self, $app, $config) = @_;

  $self->app($app);
  $self->config($config);
  $app->helper(cache => sub { $self });

  if(exists $config->{backend}) {
    eval {
      eval "require $config->{backend};";
      warn "Require failed: $@" if $self->config->{debug} && $@;
      my $backend = $config->{backend}->new;
      $backend->config($config);
      $self->backend($backend);
      my $method = "init";
      $backend->$method() if $backend->can($method);
    };
    die("Failed to load backend $config->{backend}: $@") if $@;
  }
}

sub check_mode {
  my ($self, $cb) = @_;
  die("No backend available") if !$self->backend;
  die("Backend " . ref($self->backend) ." doesn't support asynchronous requests") if $cb && !$self->backend->support_async;
  die("Backend " . ref($self->backend) ." doesn't support synchronous requests") if !$cb && !$self->backend->support_sync;
}

sub get {
  my ($self, $key, $cb) = @_;
  $self->check_mode($cb);
  if(my $serialiser = $self->backend->get_serialiser) {
    return $self->backend->get($key, sub { $cb->($serialiser->deserialise(@_)) }) if $cb;
    return $serialiser->deserialise($self->backend->get($key));
  } else {
    return $self->backend->get($key, sub { $cb->(@_) }) if $cb;
    return $self->backend->get($key);
  }
}

sub set {
  my ($self, $key, $value, $cb) = @_;
  $self->check_mode($cb);
  if(my $serialiser = $self->backend->get_serialiser) {
    return $self->backend->set($key, $serialiser->serialise($value), sub { $cb->(@_) }) if $cb;
    return $self->backend->set($key => $serialiser->serialise($value));
  } else {
    return $self->backend->set($key, $value, sub { $cb->(@_) }) if $cb;
    return $self->backend->set($key => $value);
  }
}

1;

=encoding utf8

=head1 NAME

MojoX::Plugin::AnyCache - Cache plugin with blocking and non-blocking support

=head1 SYNOPSIS

  $app->plugin('MojoX::Plugin::AnyCache' => {
    backend => 'MojoX::Plugin::AnyCache::Backend::Redis',
    server => '127.0.0.1:6379',
  });

  # For synchronous backends (blocking)
  $app->cache->set('key', 'value');
  my $value = $app->cache->get('key');

  # For asynchronous backends (non-blocking)
  $app->cache->set('key', 'value' => sub {
    # ...
  });
  $app->cache->get('key' => sub {
    my $value = shift;
    # ...
  });

=head1 DESCRIPTION

MojoX::Plugin::AnyCache provides an interface to both blocking and non-blocking
caching backends, for example Redis or Memcached.

It also has a built-in replicator backend (L<MojoX::Plugin::AnyCache::Backend::Replicator>)
which automatically replicates values across multiple backend cache nodes.

