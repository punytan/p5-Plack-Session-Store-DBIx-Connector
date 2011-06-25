package Plack::Session::Store::DBIx::Connector;
use strict;
use warnings;
our $VERSION = '0.02';

use Storable ();
use MIME::Base64 ();
use DBIx::Connector ();

sub new {
    my ($class, $args, %params) = @_;

    my $serializer = ref $params{serializer} eq 'CODE'
        ? $params{serializer}
        : sub { MIME::Base64::encode_base64( Storable::nfreeze(shift) ) };

    my $deserializer = ref $params{deserializer} eq 'CODE'
        ? $params{deserializer}
        : sub { Storable::thaw( MIME::Base64::decode_base64(shift) ) };

    my $connector = ref $args eq 'ARRAY'
        ? DBIx::Connector->new(@$args)
        : $args;

    my $table = $params{table} || 'sessions';

    return bless {
        serializer   => $serializer,
        deserializer => $deserializer,
        connector    => $connector,
        sql => {
            fetch  => { select => "SELECT session_data FROM $table WHERE id = ?" },
            remove => { delete => "DELETE FROM $table WHERE id = ?" },
            store  => {
                select => "SELECT 1 FROM $table WHERE id = ?",
                update => "UPDATE $table SET session_data = ? WHERE id = ?",
                insert => "INSERT INTO $table (session_data, id) VALUES(?, ?)",
            },
        },
    }, $class;
}

sub prepare_cached { shift->{connector}->dbh->prepare_cached(@_) }

sub fetch {
    my ($self, $session_id) = @_;

    my $sth = $self->prepare_cached($self->{sql}{fetch}{select});
    $sth->execute($session_id);

    my ($data) = $sth->fetchrow_array;
    $sth->finish;

    $self->{deserializer}->($data)
        if $data;
}

sub store {
    my ($self, $session_id, $session) = @_;

    my $sth = $self->prepare_cached($self->{sql}{store}{select});
    $sth->execute($session_id);

    my ($exists) = $sth->fetchrow_array;
    $sth->finish;

    my $type = $exists ? 'update' : 'insert';
    my $sql  = $self->{sql}{store}{$type};

    my $data = $self->{serializer}->($session);

    my $sth2 = $self->prepare_cached($sql);
    $sth2->execute($data, $session_id);
}

sub remove {
    my ($self, $session_id) = @_;

    my $sth = $self->prepare_cached($self->{sql}{remove}{delete});
    $sth->execute($session_id);
    $sth->finish;
}

1;
__END__

=head1 NAME

Plack::Session::Store::DBIx::Connector - DBIx::Connector based session store

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Session::Store::DBIx::Connector;

  builder {
    enable 'Session',
      store => Plack::Session::Store::DBIx::Connector->new(
        [$dsn, $user, $password, \%attr]
      );
    $app;
  }

  # or

  use DBIx::Connector;

  my $conn = DBIx::Connector->new($dsn, $user, $password, \%attr);

  builder {
    enable 'Session',
      store => Plack::Session::Store::DBIx::Connector->new($conn);
    $app;
  }

  # with custom serializer / deserializer

  builder {
    enable 'Session',
      store => Plack::Session::Store::DBIx::Connector->new(
        [$dsn, $user, $password, \%attr],
        serializer => sub {
            # stringify the data structure to store it into database
        },
        deserializer => sub {
            # convert fetched string into perl's data structure
        },
      );
    $app;
  }

=head1 DESCRIPTION

Plack::Session::Store::DBIx::Connector is an alternative DBI based session store middleware.

This module is inspired by L<Plack::Session::Store::DBI>. The main part of these implementation are co-opted.
So, if you are friends with L<Plack::Session::Store::DBI>, it can be replaced easily by this module.

=head1 SESSION TABLE SCHEMA

  CREATE TABLE sessions (
    id           CHAR(72) PRIMARY KEY,
    session_data TEXT
  );

  See also L<Plack::Session::Store::DBI>.

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

L<Plack::Session::Store::DBI>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
