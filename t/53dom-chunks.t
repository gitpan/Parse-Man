#!/usr/bin/perl -w

use strict;

use Test::More tests => 24;

use Parse::Man::DOM;

my $parser = Parse::Man::DOM->new;

sub chunks_from_first_para
{
   my $document = $parser->from_string( $_[0] );
   my ( $para ) = $document->paras;
   return $para->body->chunks;
}

my @chunks;

@chunks = chunks_from_first_para <<'EOMAN';
.PP
Plain text
EOMAN
is( $chunks[0]->format, "R",          'Plain text format' );
is( $chunks[0]->text,   "Plain text", 'Plain text text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
\fRRoman text
EOMAN
is( $chunks[0]->format, "R",          '\fR format' );
is( $chunks[0]->text,   "Roman text", '\fR text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
\fBBold text
EOMAN
is( $chunks[0]->format, "B",         '\fB format' );
is( $chunks[0]->text,   "Bold text", '\fB text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
\fIItalic text
EOMAN
is( $chunks[0]->format, "I",           '\fI format' );
is( $chunks[0]->text,   "Italic text", '\fI text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
\fIitalic\fP roman
EOMAN
is( $chunks[0]->format, "I",      '\fI format' );
is( $chunks[0]->text,   "italic", '\fI text' );
is( $chunks[1]->format, "R",      '\fP format restored' );
is( $chunks[1]->text,   " roman", '\fP text preserves whitespace' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
.R Roman text
EOMAN
is( $chunks[0]->format, "R",          '.R format' );
is( $chunks[0]->text,   "Roman text", '.R text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
.B Bold text
EOMAN
is( $chunks[0]->format, "B",         '.B format' );
is( $chunks[0]->text,   "Bold text", '.B text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
.I Italic text
EOMAN
is( $chunks[0]->format, "I",           '.I format' );
is( $chunks[0]->text,   "Italic text", '.I text' );

@chunks = chunks_from_first_para <<'EOMAN';
.PP
.RB roman1 bold roman2
EOMAN
is( $chunks[0]->format, "R",      '.RB format 1' );
is( $chunks[0]->text,   "roman1", '.RB text 1' );
is( $chunks[1]->format, "B",      '.RB format 2' );
is( $chunks[1]->text,   "bold",   '.RB text 2' );
is( $chunks[2]->format, "R",      '.RB format 3' );
is( $chunks[2]->text,   "roman2", '.RB text 3' );
