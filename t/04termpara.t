#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub join_para { $paras[-1] .= ": " }

sub para_TP
{
   my $self = shift;
   my ( $opts ) = @_;

   push @paras, "";
}

sub chunk_R { $paras[-1] .= $_[1] }

package main;

my $parser = TestParser->new;

undef @paras;
$parser->from_string( <<'EOMAN' ),
.TP
Term
Definition here
EOMAN
is_deeply( \@paras,
   [ "Term: Definition here" ],
   '.TP' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.TP
Term
Definition here
.TP
Another
defined term
EOMAN
is_deeply( \@paras,
   [ "Term: Definition here",
     "Another: defined term" ],
   '.TD * 2' );
