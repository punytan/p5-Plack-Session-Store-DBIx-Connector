use inc::Module::Install;
name 'Plack-Session-Store-DBIx-Connector';
all_from 'lib/Plack/Session/Store/DBIx/Connector.pm';

# requires '';

requires 'Storable'        => 2.25;
requires 'MIME::Base64'    => 3.13;
requires 'DBIx::Connector' => 0.45;

requires 'DBI'         => 1.616;
requires 'DBD::SQLite' => 1.33;

requires 'File::Spec' => 3.33;
requires 'File::Temp' => 0.22;

requires 'Test::More'      => 0.98;
requires 'Test::Requires'  => 0.06;
requires 'Test::Exception' => 0.31;

requires 'Plack' => 0.998;
requires 'Plack::Session::Store::DBI' => 0.10;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;
WriteAll;
