package kernel::mime;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use Data::Dumper;
use MIME::Words qw(:all);
use vars(qw(@EXPORT @ISA));
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&mimeencode);

##############################################################################
# Encodes a string for use in mail headers                                   #
#                                                                            #
# Parameters: $text = string to encode.                                      #
# Returns:  $newtext = encoded string.                                       #
##############################################################################

sub mimeencode {
  my ($text) = @_;
  my @words = split(/ /, $text);
  my $line = '';
  my @lines;

  my $e=MIME::Words::encode_mimewords($text, 'Q', 'ISO-8859-1');
  $e=~s/= =/=\n =/g;
  return($e);
  

  foreach my $word (@words) {
    my $sameword = 0;
    $word =~ s/\n//g;
    my $encword;
    if ($word =~ /[\x7F-\xFF]/) {
      $encword = MIME::Words::encode_mimeword($word, 'Q', 'ISO-8859-1');
    } elsif (length($word) > 75) {
      $encword = MIME::Words::encode_mimeword($word, 'Q', 'us-ascii');
    } else {
      $encword = $word;
    }

    # no more than 75 chars per line allowed
    if (length($encword) > 75) {
      while ($encword) {
        if ($encword =~ /(^=\?[-\w]+\?\w\?)(.{55}.*?)((=.{2}|[^=]{3}).*\?=)$/) {
          addword($1 . $2 . '?=', \$line, \@lines, $sameword);
          $encword = $1 . $3;
        } else {
          addword($encword, \$line, \@lines, $sameword);
          $encword = '';
        }
        $sameword = 1;
      }
    } else {
      addword($encword, \$line, \@lines, $sameword);
    }
  }

  my $delim = (@lines) ? ' ' : '';
  push(@lines, $delim . $line) if ($line);
  return join('', @lines);

}

##############################################################################
# Adds a word to a MIME encoded string, inserts linefeed if necessary        #
#                                                                            #
# Parameters:                                                                #
#   $word = word to add                                                      #
#   $line = current line                                                     #
#   $lines = complete text (without current line)                            #
#   $sameword = boolean switch, indicates that this is another part of       #
#               the last word (for encoded words > 75 chars)                 #
##############################################################################

sub addword {
  my ($word, $line, $lines, $sameword) = @_;
printf STDERR ("fifi0 addword word='$word' line='$$line'\n");

  # If the passed fragment is a new word (and not another part of the
  # previous): Check if it is MIME encoded
  if (!$sameword && $word =~ /^(=\?[^\?]+?\?[QqBb]\?)(.+\?=[^\?]*)$/) {
    # Word is encoded, save without the MIME header
    # (e.g. "t=E4st?=" instead of "?iso-8859-1?q?t=E4st?=")
    my $charset = $1;
    my $newword = $2;

printf STDERR ("fifi1 addword charset='$charset' newword='$newword'\n");
    if ($$line =~ /^(=\?[^\?]+\?[QqBb]\?)(.+)\?=$/) {
      # Previous word was encoded, too:
      # Delete the trailing "?=" and insert an underline character (=space)
      # (space between two encoded words is ignored)
printf STDERR ("fifi 2 1='$1' 2='$2'\n");
      if ($1 eq $charset) {
printf STDERR ("fifi 3 1='$1' 2='$2'\n");
        if (length($1.$2)+length($newword)>75) {
          my $delim = (@$lines) ? ' ' : '';
          push(@$lines, "$delim$1$2_?=\n");
          $$line = $word;
        } else {
          $$line=$1.$2.'_'.$newword;
        }
      } else {
        if (length("$$line $word")>75) {
          my $delim = (@$lines) ? ' ' : '';
          push(@$lines, "$delim$1$2_?=\n");
          $$line=$word;
        } else {
          $$line="$1$2_?= $word";
        }
      }
      return 0;
    }
  }

  # New word is not encoded: simply append it, but check for line length
  # and add a newline if necessary
  if (length($$line) > 0) {
    if (length($$line) + length($word) >= 75) {
      my $delim = (@$lines) ? ' ' : '';
      push(@$lines, "$delim${$line}\n");
      $$line = $word;
    } else {
      if ($$line=~m/(=\?[^\?]+\?[QqBb]\?)(.+)\?=$/){
         $$line .= " =?ISO-8859-1?Q?=20?=$word";
      }
      else{
         $$line .= " $word";
      }
    }
  } else {
    # line is empty
    $$line = $word;
  } 
}

1;
