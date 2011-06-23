#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);

use Test::More;
use Test::Requires 'DBD::SQLite';

use Plack::Request;
use Plack::Session;
use Plack::Session::State::Cookie;
use Plack::Session::Store::DBIx::Connector;

use DBI;
use DBIx::Connector;

use t::lib::TestSession;

my $tmp  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($tmp, "01_basic.db");

my @args = ( "dbi:SQLite:$file", undef, undef, { RaiseError => 1, AutoCommit => 1 } );

# create database file
DBI->connect(@args)->do(
    'CREATE TABLE sessions (id CHAR(72) PRIMARY KEY, session_data TEXT)'
);

my $connect_args = \@args;
t::lib::TestSession::run_all_tests(
    store  => Plack::Session::Store::DBIx::Connector->new($connect_args),
    state  => Plack::Session::State->new,
    env_cb => sub {
        open my $in, '<', \do { my $d };
        my $env = {
            'psgi.version'    => [ 1, 0 ],
            'psgi.input'      => $in,
            'psgi.errors'     => *STDERR,
            'psgi.url_scheme' => 'http',
            SERVER_PORT       => 80,
            REQUEST_METHOD    => 'GET',
            QUERY_STRING      => join "&" => map { $_ . "=" . $_[0]->{ $_ } } keys %{$_[0] || +{}},
        };
    },
);

my $conn = DBIx::Connector->new(@args);
t::lib::TestSession::run_all_tests(
    store  => Plack::Session::Store::DBIx::Connector->new($conn),
    state  => Plack::Session::State->new,
    env_cb => sub {
        open my $in, '<', \do { my $d };
        my $env = {
            'psgi.version'    => [ 1, 0 ],
            'psgi.input'      => $in,
            'psgi.errors'     => *STDERR,
            'psgi.url_scheme' => 'http',
            SERVER_PORT       => 80,
            REQUEST_METHOD    => 'GET',
            QUERY_STRING      => join "&" => map { $_ . "=" . $_[0]->{ $_ } } keys %{$_[0] || +{}},
        };
    },
);

done_testing;

