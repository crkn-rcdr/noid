#!/usr/bin/env perl

use strictures 2;
use Dancer2;
use Noid;
use File::Copy qw/move/;
use Scalar::Util qw/looks_like_number/;
use Util::Any -list => ['none'];

my $NOID_DIR = $ENV{'NOID_DIR'} || '/noid/dbs';
my $NAAN     = $ENV{'NAAN'}     || '69429';
my $NAA      = $ENV{'NAA'}      || 'CRKN';
my $SUBNAA   = $ENV{'SUBNAA'}   || 'Platform';
my $CONTACT  = $ENV{'CONTACT'}  || 'smelter';
my $TEMPLATE = $ENV{'TEMPLATE'} || 'reedeedeedk';

my %prefixes = (
  manifest    => 'm',
  manifests   => 'm',
  canvas      => 'c',
  canvases    => 'c',
  collection  => 's',
  collections => 's'
);

chdir($NOID_DIR);

set log         => 'warning';
set serializer  => 'JSON';
set show_errors => 0;

get '/' => sub {
  return {
    collection => ( glob('s*') )[-1] || 'none',
    manifest   => ( glob('m*') )[-1] || 'none',
    canvas     => ( glob('c*') )[-1] || 'none'
  };
};

sub create_db {
  my ( $contact, $template ) = @_;
  my $report = Noid::dbcreate( $NOID_DIR, $contact,
    $template, 'long', $NAAN, $NAA, $SUBNAA );

  return { error => Noid::errmsg( undef, 1 ) } unless $report;

  my ($prefix) = ( $template =~ /(.+)\./ );
  my $new_dir = $prefix;
  mkdir($new_dir);
  move( 'NOID', "$new_dir/NOID" );

  return { name => $new_dir };
}

sub mint {
  my ( $prefix, $n, $contact ) = @_;
  my @dbs = sort {
    int( ( $b =~ /$prefix(\d+)/ )[0] ) <=> int( ( $a =~ /$prefix(\d+)/ )[0] )
  } glob("$prefix*");
  my $dbname = $dbs[0] || $prefix . '0';
  unless ( -d $dbname ) {
    my $r = create_db( $contact, "$dbname.$TEMPLATE" );
    return $r if $r->{error};
    $dbname = $r->{name};
  }

  my $noid = Noid::dbopen( $dbname . '/NOID/noid.bdb', 0 );
  return { error => Noid::errmsg( undef, 1 ) } unless $noid;

  my @ids;
  my $id = undef;
  while ( $n > 0 ) {
    while ( !defined( $id = Noid::mint( $noid, $contact ) ) ) {
      my $error = Noid::errmsg( $noid, 1 );
      if ( $error =~ /exhausted/ ) {
        Noid::dbclose($noid);
        my $newdbname =
          $prefix . ( int( ( $dbname =~ /$prefix(\d+)/ )[0] ) + 1 );
        my $newdb = create_db( $contact, "$newdbname.$TEMPLATE" );
        return $newdb if $newdb->{error};
        $noid = Noid::dbopen( $newdb->{name} . '/NOID/noid.bdb', 0 );
        return { error => Noid::errmsg( undef, 1 ) } unless $noid;
      } else {
        return { error => $error };
      }
    }

    push @ids, $id;
    $id = undef;
    $n--;
  }

  return { ids => \@ids };
}

post '/mint/:number/:type' => sub {
  my $type = route_parameters->get('type');
  if ( none { $type eq $_ } keys %prefixes ) {
    status 400;
    return {
      error => "Can only mint 'collections', 'manifests', or 'canvases'."
    };
  }
  my $n       = route_parameters->get('number');
  my $number  = looks_like_number($n) ? abs( int($n) ) : 0;
  my $contact = request_header('X-Noid-Contact') || $CONTACT;

  my $result = mint( $prefixes{$type}, $number, $contact );

  if ( $result->{error} ) {
    status 500;
    return { error => $result->{error} };
  } else {
    return { ids => $result->{ids} };
  }
};

__PACKAGE__->to_app;