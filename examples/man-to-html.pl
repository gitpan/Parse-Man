#!/usr/bin/perl

use strict;
use warnings;

use Template;
use String::Tagged::HTML;
use File::Slurp qw( slurp );
use Getopt::Long;

my $FILE_EXTENSION = "html";
my $LINK_EXTENSION;
my $OUTPUT_DIR;
my $PAGE_TEMPLATE;

GetOptions(
   'file-extension|e=s' => \$FILE_EXTENSION,
   'link-extension=s'   => \$LINK_EXTENSION,
   'output-dir|O=s'     => \$OUTPUT_DIR,
   'template|t=s'       => \$PAGE_TEMPLATE,
) or exit(1);

defined $LINK_EXTENSION or $LINK_EXTENSION = $FILE_EXTENSION;
defined $PAGE_TEMPLATE  or $PAGE_TEMPLATE = \*DATA;

package ManToHTMLParser;
use base qw( Parse::Man::DOM );
sub chunklist_class { return "ManToHTMLParser::Chunklist"; }

package ManToHTMLParser::Chunklist;
use base qw( Parse::Man::DOM::Chunklist );

my %format_to_tag = (
   B  => "b",
   I  => "i",
   SM => "small",
);

sub as_html
{
   my $self = shift;

   my $ret = String::Tagged::HTML->new;

   foreach my $chunk ( $self->chunks ) {
      if( $chunk->is_linebreak ) {
         $ret->append( "\n" );
      }
      elsif( $chunk->is_space ) {
         $ret->append( " " );
      }
      elsif( $chunk->is_break ) {
         $ret->append_tagged( "<br/>", raw => 1 );
      }
      elsif( $chunk->format eq "R" ) {
         $ret->append( $chunk->text );
      }
      else {
         my $tag = $format_to_tag{ $chunk->format };
         $ret->append_tagged( $chunk->text, $tag => 1 );
      }
   }

   my $str = $ret->str;

   # Turn foo(1) text into a link
   while( $str =~ m{([[:alpha:]_][[:alnum:]_]*)\((\d[a-z]*)\)}g ) {
      my $name    = $1;
      my $section = $2;

      my $ofs = $-[0];
      my $len = $+[0] - $-[0];

      my $href = ::make_link( lc $name, $section );

      $ret->apply_tag( $ofs, $len, a => { href => $href } ) if defined $href;
   }

   return $ret->as_html;
}

package main;

my @doms;
my %doms_by_namesection;

sub make_link
{
   my ( $name, $section ) = @_;

   if( exists $doms_by_namesection{"$name.$section"} ) {
      return "$name.$section.$LINK_EXTENSION";
   }
   else {
      print STDERR "Omitting link to $name($section) because no file is being generated\n";
      return undef;
   }
}

my $parser = ManToHTMLParser->new;
my $template = Template->new( { DEBUG => 1 } );

my $pagefile = slurp $PAGE_TEMPLATE;

foreach my $manfile ( @ARGV ) {
   my $dom = $parser->from_file( $manfile );

   push @doms, $dom;
   $doms_by_namesection{ lc $dom->meta("name")->value . "." . $dom->meta("section")->value } = $dom;
}

foreach my $dom ( @doms ) {
   my $output;

   unless( $template->process( \$pagefile, { document => $dom }, \$output ) ) {
      print STDERR "Failed: ", $template->error, "\n";
      next;
   }

   my $outfile = join ".", lc $dom->meta("name")->value, $dom->meta("section")->value, $FILE_EXTENSION;

   $outfile = "$OUTPUT_DIR/$outfile" if defined $OUTPUT_DIR;

   my $outh;
   unless( open $outh, ">", $outfile ) {
      print STDERR "Cannot write $outfile - $!\n";
      next;
   }

   print $outh $output;
}

__DATA__
[% BLOCK heading -%]
    <h[% level %]>[% text | html %]</h[% level %]>
[% END -%]
[% BLOCK plain;
   SET tag = para.filling ? "p" : "pre"; -%]
    <[% tag %]>[% para.body.as_html %]</[% tag %]>
[% END -%]
[% BLOCK term -%]
    <dl>
      <dt>[% para.term.as_html %]</dt>
      <dd>[% para.definition.as_html %]</dd>
    </dl>
[% END -%]
[% BLOCK indent -%]
    <dl>
      <dd>[% para.body.as_html %]</dd>
    </dl>
[% END -%]
<html>
  <head>
    <title>[% document.meta("name").value %]</title>
  </head>
  <body>
    <h1>[% document.meta("name").value %] ([% document.meta("section").value %])</h1>
[% FOREACH para IN document.paras;
     SWITCH para.type;
       CASE "heading";
         INCLUDE heading level=para.level+1 text=para.text;
       CASE "plain";
         INCLUDE plain para=para;
       CASE "term";
         INCLUDE term para=para;
       CASE "indent"; 
         INCLUDE indent para=para;
     END;
   END -%]
  </body>
</html>
