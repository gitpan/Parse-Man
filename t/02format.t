#!/usr/bin/perl -w

use strict;

use Test::More tests => 11;

my @paras;

package TestParser;
use base qw( Parse::Man );

sub para_P
{
   my $self = shift;
   my ( $opts ) = @_;

   push @paras, "";
}

sub chunk_R { $paras[-1] .= $_[1] }
sub chunk_B { $paras[-1] .= "<B>$_[1]</B>" }
sub chunk_I { $paras[-1] .= "<I>$_[1]</I>" }

package main;

my $parser = TestParser->new;

undef @paras;
$parser->from_string( <<'EOMAN' ),
Plain text
EOMAN
is_deeply( \@paras,
   [ "Plain text" ],
   'Unformatted' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.R Roman text
EOMAN
is_deeply( \@paras,
   [ "Roman text" ],
   '.R' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.B Bold text
EOMAN
is_deeply( \@paras,
   [ "<B>Bold text</B>" ],
   '.B' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.I Italic text
EOMAN
is_deeply( \@paras,
   [ "<I>Italic text</I>" ],
   '.I' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.RB roman1 bold roman2
EOMAN
is_deeply( \@paras,
   [ "roman1<B>bold</B>roman2" ],
   '.BR' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.RB "roman1 " bold " roman2"
EOMAN
is_deeply( \@paras,
   [ "roman1 <B>bold</B> roman2" ],
   '.BR quoted' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
.RB "roman1 " bold " roman2
EOMAN
is_deeply( \@paras,
   [ "roman1 <B>bold</B> roman2" ],
   '.BR trailing quote' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\fRRoman text
EOMAN
is_deeply( \@paras,
   [ "Roman text" ],
   '\fR' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\fBBold text
EOMAN
is_deeply( \@paras,
   [ "<B>Bold text</B>" ],
   '\fB' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\fIItalic text
EOMAN
is_deeply( \@paras,
   [ "<I>Italic text</I>" ],
   '\fI' );

undef @paras;
$parser->from_string( <<'EOMAN' ),
\fIitalic\fP roman
EOMAN
is_deeply( \@paras,
   [ "<I>italic</I> roman" ],
   '\f preserves space' );
