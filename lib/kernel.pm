package cache;

use strict;
use Data::Dumper;


sub new
{
   my $type=shift;
   my $configname=shift;
   my $self={@_};
   $self=bless($self,$type);
   return($self);
}
if (!defined($W5V2::Cache)){
   $W5V2::Cache=new cache();
}

sub AddHandler
{
   my ($self,$name,%p)=@_;

   if (exists($self->{'C'}->{$name})){
      printf STDERR ("WARN:  redifining existing cache handler '%s'\n",$name);
   }
   $self->{'C'}->{$name}={CacheFailCode=>$p{CacheFailCode},
                          Database=>$p{Database}};
}

sub Value($$)
{
   my ($self,$name,$key)=@_;

   printf STDERR ("read cache value $name -> {$key}\n");
}

sub Validate
{
   my ($self,@names)=@_;


}

sub Invalidate
{
   my ($self,@names)=@_;


}

package kernel;
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
use vars qw(@EXPORT @ISA);
use Data::Dumper;
use XML::Parser;
use W5Kernel;
use kernel::date;
use Scalar::Util qw(weaken);
use Exporter;
use Encode;
use Unicode::String qw(utf8 latin1 utf16);
use POSIX;
use charnames ':full';

@ISA = qw(Exporter);
@EXPORT = qw(&Query &LangTable &extractLanguageBlock 
             &globalContext &NowStamp &CalcDateDuration
             &trim &rtrim &ltrim &limitlen &rmNonLatin1 &rmAnyNonLatin1
             &in_array &array_insert
             &first_index
             &base36
             &hash2xml &xml2hash &effVal &effChanged &effChangedVal 
             &isDetailed
             &Debug &UTF8toLatin1 &Html2Latin1
             &Datafield2Hash &Hash2Datafield &CompressHash &FlattenHash
             &unHtml &quoteHtml &quoteSOAP &quoteWap &quoteQueryString &XmlQuote
             &Dumper &CSV2Hash &ObjectRecordCodeResolver
             &FancyLinks &ExpandW5BaseDataLinks &mkInlineAttachment 
             &FormatJsDialCall &HashExtr
             &mkMailInlineAttachment &haveSpecialChar
             &getModuleObject &getConfigObject &generateToken
             &orgRoles &extractLangEntry
             &msg &sysmsg &ERROR &WARN &DEBUG &INFO &OK &utf8 &latin1 &utf16
             &utf8_to_latin1
             &TextShorter &LengthOfLongestWord
             &joinCsvLine
             &splitCsvLine
             &getClientAddrIdString
             &is_POSIXmktime_Clean
             &Stacktrace);

sub utf8{return(&Unicode::String::utf8);}
sub utf16{return(&Unicode::String::utf16);}
sub latin1{return(&Unicode::String::latin1);}

#
# optimized utf8->latin1 converter to prevent lose of
# charachters based on map ...
# http://www.utf8-chartable.de/unicode-utf8-table.pl?start=256
#
# ISO-8859 Codings from 
# https://de.wikipedia.org/wiki/ISO_8859-15
sub utf8_to_latin1
{
   my $utf8string=shift;
   my $l=utf8($utf8string);
   my @names=$l->name;
   my $mapped;

   # If there is no specialmap for a character,
   # Latin letters a-zA-Z will be mapped like in this example:
   #  original: 'LATIN SMALL LETTER A WITH GRAVE'
   #  new:      'LATIN SMALL LETTER A'
   #
   # key => character from original string
   # val => array ref with new substituted character(s)
   my %specialmap=(
      'LATIN CAPITAL LETTER A WITH DIAERESIS'=>
         ['LATIN CAPITAL LETTER A WITH DIAERESIS'],
      'LATIN CAPITAL LETTER O WITH DIAERESIS'=>
         ['LATIN CAPITAL LETTER O WITH DIAERESIS'],
      'LATIN CAPITAL LETTER U WITH DIAERESIS'=>
         ['LATIN CAPITAL LETTER U WITH DIAERESIS'],
      'LATIN SMALL LETTER A WITH DIAERESIS'=>
         ['LATIN SMALL LETTER A WITH DIAERESIS'],
      'LATIN SMALL LETTER O WITH DIAERESIS'=>
         ['LATIN SMALL LETTER O WITH DIAERESIS'],
      'LATIN SMALL LETTER U WITH DIAERESIS'=>
         ['LATIN SMALL LETTER U WITH DIAERESIS'],
   );

   foreach my $n (@names) {
      if (exists($specialmap{$n})) {
         if (ref($specialmap{$n}) eq 'ARRAY') {
            foreach my $newname (@{$specialmap{$n}}) {
               if ($newname){
                  $mapped.=chr(charnames::vianame($newname));
               }
            }
         }
         else {
            if ($specialmap{$n}){
               $mapped.=chr(charnames::vianame($specialmap{$n}));
            }
         }
      }
      else {
         $n=~s/^(LATIN (CAPITAL|SMALL) LETTER [A-Z]) WITH.*$/$1/;
         if ($n){
            $mapped.=chr(charnames::vianame($n));
         }
      }
   }

   return($mapped);
}

sub LangTable
{
   return("en","de");
}

sub Dumper
{
   $Data::Dumper::Sortkeys = 1;
   #$Data::Dumper::Deepcopy = 1;
   
   return(Data::Dumper::Dumper(@_));
}

sub is_POSIXmktime_Clean
{
   if (POSIX::mktime(0,0,0,1, 0, 2050-1900)>0){
      return(1);
   }
   return(0);
}

sub joinCsvLine
{
   return(join(";",map({
      my $v=$_;
      $v=~s/;//g;
      $v=~s/\n//g;
      $v=~s/\r//g;
      $v;
   } @_)));
}

sub splitCsvLine
{
   return(split(/;/,$_[0]));
}




sub ObjectRecordCodeResolver
{
   my $back;
   if (defined($_[0])){
      my $deep=$_[1];
      $deep=+1;
      if ($deep>50){
         $back=msg(ERROR,$_[0]." deep limit reached in ".
                         "ObjectRecordCodeResolver");
      }
      elsif (ref($_[0]) eq "ARRAY"){
         $back=[];
         foreach my $rec (@{$_[0]}){
            push(@{$back},ObjectRecordCodeResolver($rec,$deep)); 
         }
      }
      elsif (ref($_[0]) eq "HASH"){
         $back={};
         foreach my $k (keys(%{$_[0]})){
            $back->{$k}=ObjectRecordCodeResolver($_[0]->{$k},$deep);
         }
      }
      elsif (ref($_[0]) eq "SCALAR"){
         $back={};
         my $var=${$_[0]};
         $back=\$var;
      }
      elsif (ref($_[0])){
         $back=msg(ERROR,$_[0]." not resolvable in ObjectRecordCodeResolver");
      }
      else{
         $back="".$_[0];
      }
   }
   return($back);
}

sub getClientAddrIdString
{
   my $realclientendpoint=shift;
   $realclientendpoint=0 if (!defined($realclientendpoint));

   my $addr=undef;
   if (exists($ENV{HTTP_X_FORWARDED_FOR}) &&
       $ENV{HTTP_X_FORWARDED_FOR} ne ""){
      if ($realclientendpoint){
         $addr=$ENV{HTTP_X_FORWARDED_FOR};
         $addr=~s/[,;].*$//;  # use only first IP - if HTTP_X_FORWARDED_FOR is
                              # a path (multiple RevProxys in path)
      }
      else{
         if ($ENV{HTTP_X_FORWARDED_FOR} ne $ENV{REMOTE_ADDR}){
            $addr=$ENV{HTTP_X_FORWARDED_FOR}." (".$ENV{REMOTE_ADDR}.")";
         }
         else{
            $addr=$ENV{HTTP_X_FORWARDED_FOR};
         }
      }
   }
   else{
      if (exists($ENV{REMOTE_ADDR}) &&
          $ENV{REMOTE_ADDR} ne ""){
         $addr=$ENV{REMOTE_ADDR};
      }
   }
   if (defined($addr)){  # sec hack - HTTP_X_FORWARDED_FOR is not 100% safe!
      $addr=~s/[^0-9a-fA-F:. (),;]/_/g;
   }
   return($addr);
}

sub CSV2Hash
{
   my $t=shift;
   my @orgkey=@_;

   my @t=split("\n",$t);
   my @fld=split(/;/,shift(@t));

   if ($#orgkey==-1){
      @t=map({
            my @l=split(/;/,$_);
            my %r;
            for(my $c=0;$c<=$#l;$c++){
            $r{$fld[$c]}=$l[$c];     
            }
            \%r;
            } @t);
      return(\@t);
   }
   my %t;
   while(my $l=shift(@t)){
      my @k=@orgkey;
      my @l=split(/;/,$l);
      my %r;
      for(my $c=0;$c<=$#l;$c++){
         $r{$fld[$c]}=$l[$c];     
      }
      foreach my $k (@k){
         $t{$k}->{$r{$k}}=\%r; 
      }
   }
   return(\%t);
}


sub extractLangEntry       # extracts a specific lang entry from a multiline
{                          # textarea field like :
   my $labeldata=shift;    #
      my $lang=shift;         # hello
      my $maxlen=shift;       # [de:]
      my $multiline=shift;    # Hallo

      $multiline=0 if (!defined($multiline)); # >1 means max lines 0 = join all
      $maxlen=0    if (!defined($maxlen));    # 0 means no limits

      my $curlang="";
   my %ltxt;
   foreach my $line (split('\r{0,1}\n',$labeldata)){
      if (my ($newlang)=$line=~m/^\s*\[([a-z]{1,3}):\]\s*$/){
         $curlang=$newlang;
      }
      else{
         push(@{$ltxt{$curlang}},$line);
      }
   }
   if (exists($ltxt{$lang})){
      $ltxt{""}=$ltxt{$lang};
   }
   my $d;
   if (ref($ltxt{""}) eq "ARRAY"){
      if ($multiline>0){
         $d=trim(join("\n",@{$ltxt{""}}));
      }
      else{
         $d=trim(join(" ",@{$ltxt{""}}));
      }
   }
   else{
      $d="";
   }

   return(trim($d));
}



sub haveSpecialChar
{
   my $str=shift;
   my %param=@_;

   if ($str=~m/[\~ß\s÷‹ƒ‰ˆ¸ﬂ\\,;\*\?\r\n\t]/){
      msg(ERROR,"haveSpecialChar at '$-[0]'-'$+[0]' in '$str'\n");
      return(1);
   }
   return(0);
}

sub FormatJsDialCall
{
   my ($dialermode,$dialeripref,$dialerurl,$phone)=@_;
   my $qdialeripref=quotemeta($dialeripref);
   if ($dialermode=~m/Cisco/i){
      $phone=~s/[\s\/\-]//g;
      $phone=~s/$qdialeripref/0/;
      $phone=~s/[\s\/\-]//g;
      $dialerurl=~s/\%phonenumber\%/$phone/g;

      my $open="openwin('$dialerurl',".
         "'_blank',".
         "'height=360,width=580,toolbar=no,status=no,".
         "resizable=yes,scrollbars=no')";
      my $cmd="$open;";
      return($cmd);
   }
   elsif ($dialermode=~m/0dial-tag/i){
      $phone=~s/[\s\/\-]//g;
      $phone=~s/$qdialeripref/0/;
      $phone=~s/[\s\/\-]//g;
      $phone=~s/^\+/00/;
      $dialerurl="tel:0$phone";

      my $open="window.location.href='$dialerurl';";
      my $cmd="$open;";
      return($cmd);
   }
   elsif ($dialermode=~m/dial-tag/i){
      $phone=~s/[\s\/\-]//g;
      $phone=~s/$qdialeripref/0/;
      $phone=~s/[\s\/\-]//g;
      $dialerurl="tel:$phone";

      my $open="window.location.href='$dialerurl';";
      my $cmd="$open;";
      return($cmd);
   }
   return(undef);
}


sub unHtml
{
   my $d=shift;
   $d=~s/<br>/\n/g;

   return($d);
}

sub quoteSOAP
{
   my $d=shift;

   $d=~s/&/&amp;/g;
   $d=~s/</&lt;/g;
   $d=~s/>/&gt;/g;
   $d=~s/\\/&#92;/g;
   return($d);
}


sub Html2Latin1
{
   my $d=shift;

   $d=~s/<br>/\r\n/g;
   $d=~s/<[a-zA-Z]+[^>]*>//g;
   $d=~s/<\/[a-zA-Z]+[^>]*>//g;
   $d=~s/&amp;/&/g;
   $d=~s/&lt;/</g;
   $d=~s/&gt;/>/g;
   $d=~s/&Auml;/\xC4/g;
   $d=~s/&Ouml;/\xD6/g;
   $d=~s/&Uuml;/\xDC/g;
   $d=~s/&auml;/\xE4/g;
   $d=~s/&ouml;/\xF6/g;
   $d=~s/&uuml;/\xFC/g;
   $d=~s/&szlig;/\xDF/g;
   $d=~s/&quot;/"/g;
   $d=~s/&#x0027;/'/g;
   $d=~s/&nbsp;/ /g;

   return($d);
}

sub quoteHtml
{
   my $d=shift;

   $d=~s/&/&amp;/g;
   $d=~s/</&lt;/g;
   $d=~s/>/&gt;/g;
   $d=~s/\xC4/&Auml;/g;
   $d=~s/\xD6/&Ouml;/g;
   $d=~s/\xDC/&Uuml;/g;
   $d=~s/\xE4/&auml;/g;
   $d=~s/\xF6/&ouml;/g;
   $d=~s/\xFC/&uuml;/g;
   $d=~s/\xDF/&szlig;/g;
   $d=~s/"/&quot;/g;
   $d=~s/'/&#x0027;/g;
   $d=~s/&amp;nbsp;/&nbsp;/g;

   return($d);
}

sub quoteWap
{
   my $d=shift;

   $d=~s/&/&amp;/g;
   $d=~s/</&lt;/g;
   $d=~s/>/&gt;/g;
   $d=~s/\xC4/&Auml;/g;
   $d=~s/\xD6/&Ouml;/g;
   $d=~s/\xDC/&Uuml;/g;
   $d=~s/\xE4/&auml;/g;
   $d=~s/\xF6/&ouml;/g;
   $d=~s/\xFC/&uuml;/g;
   $d=~s/\xDF/&szlig;/g;
   $d=~s/"/&quot;/g;
   $d=~s/'/&prime;/g;
   $d=~s/&amp;nbsp;/&nbsp;/g;

   return($d);
}

sub quoteQueryString {
   my $toencode = shift;
   return undef unless defined($toencode);
# force bytes while preserving backward compatibility -- dankogai
   $toencode = pack("C*", unpack("C*", $toencode));
   $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
   return $toencode;
}

sub orgRoles
{
   return(qw(REmployee RApprentice RFreelancer RBoss RBoss2));
}


sub XmlQuote
{
   my $org=shift;
   $org=rmAnyNonLatin1(unHtml($org));
   $org=~s/&/&amp;/g;
   $org=~s/</&lt;/g;
   $org=~s/>/&gt;/g;
   utf8::encode($org);
   return($org);
}

sub xml2hash {
   my $d=shift;
   my $h={};

   my $p=new XML::Parser();

   my $hbuf;
   my $hbuflevel;

   my $CurrentTag;
   my $CurrentRoot;
   my $currentTarget; 
   

   $p->setHandlers(Start=>sub{
                      my ($p,$tag,%attr)=@_;
                      my @c=$p->context();
                      my $chk=$h;
                      foreach my $c (@c){
                         if (!exists($chk->{$c})){
                            $chk->{$c}={};
                         }
                         if (ref($chk) eq "HASH"){
                            $chk=$chk->{$c};
                         }
                         if (ref($chk) eq "ARRAY"){
                            $chk=$chk->[$#{$chk}];
                         }
                      }
                      if (ref($chk->{$tag}) eq "HASH"){
                         my %old=%{$chk->{$tag}};
                         my @sublist=(\%old);
                         $chk->{$tag}=\@sublist;
                         $currentTarget=\$chk->{$tag};
                      }
                      if (ref($chk->{$tag}) eq "ARRAY"){
                         my $newchk={};
                         push(@{$chk->{$tag}},$newchk);
                         $chk=$newchk;
                         $currentTarget=undef;
                      }
                      elsif (!exists($chk->{$tag})){
                         $chk->{$tag}={};
                         $currentTarget=\$chk->{$tag};
                      }
                   },
                   End=>sub{
                      my ($p,$tag,%attr)=@_;
                      my @c=$p->context();
                      $currentTarget=undef;
                    #  $buffer=undef;
                   },
                   Char=>sub {
                      my ($p,$s)=@_;
                      my @c=$p->context();
                      my $trimeds=trim($s);
                      if (defined($currentTarget) && $trimeds ne ""){
                         if (!ref($$currentTarget)){
                            $$currentTarget.=$s;
                         }
                         else{
                            $$currentTarget=$s;
                         }
                      }
                   });

   eval("\$p->parse(\$d);");
   if ($@ ne ""){
      msg(WARN,"XML parse: $@");
      return(undef);
   }
   return($h);
}

sub hash2xml {
  my ($request,$param,$parentKey,$depth) = @_;
  my $xml="";
  $param={} if (!defined($param) || ref($param) ne "HASH");
  $depth=0 if (!defined($depth));

  sub indent
  {
     my $n=shift;
     my $i="";
     for(my $c=0;$c<$n;$c++){
        $i.=" ";
     }
     return($i);
  }
  return($xml) if (!ref($request));
  if (ref($request) eq "HASH"){
     foreach my $k (keys(%{$request})){
        my $usek=$k;                         # in XML no pure numeric key are
        $usek=~s/\s/_/g;
        $usek="ID$k" if ($k=~m/^\d+$/);      # allowed! 
        if (ref($request->{$k}) eq "HASH"){
           $xml.=indent($depth).
                 "<$usek>\n".hash2xml($request->{$k},$param,$k,$depth+1).
                 indent($depth)."</$usek>\n";
        }
        elsif (ref($request->{$k}) eq "ARRAY"){
           foreach my $subrec (@{$request->{$k}}){
              if (ref($subrec)){
                 $xml.=indent($depth).
                       "<$usek>\n".hash2xml($subrec,$param,$k,$depth+1).
                       indent($depth)."</$usek>\n";
              }
              else{
                 $xml.=indent($depth)."<$usek>".XmlQuote($subrec)."</$usek>\n";
              }
           }
        }
        else{
           my $d=$request->{$k};
           if (!($d=~m#^<subrecord>#m) &&
               !($d=~m#^<xmlroot>#m)){  # prevent double quoting
              $d=XmlQuote($d);
           }
           else{
              $d="\n".join(">\n",map({indent($depth).$_} split(">\n",$d))).
                      ">\n";
           }
           $xml.=indent($depth)."<$usek>".$d."</$usek>\n";
        }
     }
  }
  if (ref($request) eq "ARRAY"){
     foreach my $d (@{$request}){
        if (ref($d)){
           $xml.=hash2xml($d,$param,$parentKey,$depth+1);;
        }
        else{
           if (!($d=~m#^<subrecord>#m)){  # prevent double quoting
              $d=XmlQuote($d);
           }
           else{
              $d="\n".join(">\n",map({indent($depth).$_} split(">\n",$d))).
                      ">\n";
           }
           $xml.=indent($depth)."<$parentKey>".$d."</$parentKey>\n";
        }
     }
  }
  if ($depth==0 && $param->{header}==1){
     my $encoding="UTF-8";
     $xml="<?xml version=\"1.0\" encoding=\"$encoding\" ?>\n\n".$xml;
  }
  return $xml;
}


sub Datafield2Hash
{
   my $data=shift;
   my %hash;
   my @lines=split(/\n/,$data);

   foreach my $l (@lines){
      if ($l=~/^\s*(.*)\s*=\s*'(.*)'.*$/){
         my $key=$1;
         my $val=$2;
         $val=~s/<br>/\n/g;
         $val=~s/\\&lt;br&gt;/<br>/g;
         if (defined($hash{$key})){
            push(@{$hash{$key}},$val);
         }
         else{
            $hash{$key}=[$val];
         }
      }
   }
   return(%hash);
}

sub Hash2Datafield
{
   my %hash=@_;
   my $data="\n\n";
   foreach my $k (sort(keys(%hash))){
      my $d=$hash{$k};
      my @dlist=($d);
      if (ref($d) eq "ARRAY"){
         @dlist=@{$d};
      }
      foreach my $d (@dlist){
         $d=~s/\'/"/g;
         $d=~s/<br>/\\&lt;br&gt;/g;
         $d=~s/\n/<br>/g;
         utf8::decode($d);
         $data="$data$k='".$d."'=$k\r\n";
      }
   }
   $data.="\n";
   return($data);
}

sub HashExtr
{
   my $h=shift;
   my $path=shift;
   my $regexp=shift;
   my $lastarraylevel=shift;
   my @l;


   if (ref($path) ne "ARRAY"){
      $path=~s/^\/+//g;
      $path=[split(/\//,$path)];
   }
   my @lpath=(@{$path});

   if (ref($h) eq "ARRAY"){
      for(my $c=0;$c<=$#{$h};$c++){
         push(@l,HashExtr($h->[$c],\@lpath,$regexp,$h->[$c]));
      }
   }
   if (ref($h) eq "HASH"){
      if ($#lpath==0){
         if ($h->{$lpath[0]}=~m/$regexp/){
            if (ref($lastarraylevel)){
               push(@l,$lastarraylevel);
            }
            else{
               push(@l,{$lpath[0]=>$h->{$lpath[0]}});
            }
         }
      }
      else{
         my $k=shift(@lpath);
         if (exists($h->{$k})){
            push(@l,HashExtr($h->{$k},\@lpath,$regexp));
         }
      }
   }

   return(@l);
}

# remove any non-Latin1 char, witch not belongs to the "kern" german charset
sub rmNonLatin1
{
   my $txt=shift;
   $txt=~s/([\x00-\x08])//g; 
   $txt=~s/([\x10])/\n/g; 
   $txt=~s/([^\x00-\xff])/sprintf('&#%d;', ord($1))/ge; 
   $txt=~s/[¿¡¬√≈]/A/g; 
   $txt=~s/[»… À]/E/g; 
   $txt=~s/[ÃÕŒœ]/I/g; 
   $txt=~s/[—]/N/g; 
   $txt=~s/[”‘’]/O/g; 
   $txt=~s/[Ÿ⁄€]/U/g; 
   $txt=~s/[›]/Y/g; 
   $txt=~s/[‡·‚„Â]/a/g; 
   $txt=~s/[ËÈÍÎ]/e/g; 
   $txt=~s/[ÏÌÓÔ]/i/g; 
   $txt=~s/[Ò]/n/g; 
   $txt=~s/[ÚÛÙı]/o/g; 
   $txt=~s/[˘˙˚]/u/g; 
   $txt=~s/[˝ˇ]/y/g; 
   $txt=~s/[^\ta-z0-9,:;\!"#\\\?\+\-\/<>\._\&\[\]\(\)\n\{\}= ÷ƒ‹ˆ‰¸ﬂ\|\@\^\*'\$\ß\%~]//ig;
   return($txt);
}

# allow additional to the rmNonLatin1 all acent chars
sub rmAnyNonLatin1
{
   my $txt=shift;
   $txt=~s/([\x00-\x08])//g; 
   $txt=~s/([\x10])/\n/g; 
   $txt=~s/([^\x00-\xff])/sprintf('&#%d;', ord($1))/ge; 
   $txt=~s/[^\ta-z0-9,:;\!"#\\\?\+\-\/<>\._\&\[\]\(\)\n\{\}= ÷ƒ‹ˆ‰¸ﬂ ¿¡¬√≈»… ÀÃÕŒœ—“”‘’Ÿ⁄€›‡·‚„ÂËÈÍÎÏÌÓÔÒÚÛÙı˘˙˚˝ˇ\|\@\^\*'\$\ß\%~]//ig;
   return($txt);
}

sub CompressHash
{
   my $h;
   if (ref($_[0]) eq "HASH"){
      $h=shift;
   }
   else{
      $h={@_};
   }
   foreach my $k (keys(%$h)){
      if (ref($h->{$k}) eq "ARRAY" &&
          $#{$h->{$k}}<=0){
         $h->{$k}=$h->{$k}->[0];
      }
   }
   return($h);
}


sub FlattenHash
{
   my $h=shift;
   my $namespace=shift;

   my %H;
   if (!defined($namespace)){
      $namespace="";
   }
   foreach my $k (keys(%$h)){
       my $name=$namespace;
       $name.="." if ($name ne "");
       $name.=$k;
       if (ref($h->{$k}) eq "HASH"){
          my $sub=FlattenHash($h->{$k},$name); 
          foreach my $subk (keys(%$sub)){
             $H{$subk}=$sub->{$subk};
          }
          
       }
       else{
          $H{$name}=$h->{$k};
       }
   }
   return(\%H);
}

#
# detects the effective value in a validate operation
#
sub effVal
{
   my $oldrec=shift;
   my $newrec=shift;
   my $var=shift;
   if ((defined($newrec) && !ref($newrec)) || 
       (defined($oldrec) && !ref($oldrec))){
      Stacktrace();
   }
   if (exists($newrec->{$var})){
      return($newrec->{$var});
   }
   if (defined($oldrec) && exists($oldrec->{$var}) && 
       !(exists($newrec->{$var}))){
      return($oldrec->{$var});
   }
   return(undef);
}

#
# detects the effective change of a given variable
#
sub effChanged
{
   my $oldrec=shift;
   my $newrec=shift;
   my $var=shift;
   my $mode=shift;   # dayonly
   if (defined($newrec) && exists($newrec->{$var})){
      my $newrecvar;
      my $oldrecvar;
      if (defined($oldrec)){
         $oldrecvar=$oldrec->{$var};
         if ($mode eq "dayonly"){
            $oldrecvar=~s/\s[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}//;
         }
      }
      if (defined($newrec)){
         $newrecvar=$newrec->{$var};
         if ($mode eq "dayonly"){
            $newrecvar=~s/\s[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}//;
         }
      }
      if ($newrecvar ne $oldrecvar){
         return(1);
      }
   }
   return(undef);
}

sub isDetailed
{
   my $oldrec=shift;
   my $newrec=shift;
   my $var=shift;
   my $minlen=shift;
   my $minwords=shift;

   my $val=effVal($oldrec,$newrec,$var);

   if (defined($minlen)){
      my $chkval=$val;
      $chkval=~s/(.)\1{3}//g;  # remove repeating chars
      return(0) if (length($chkval)<$minlen);
   }
   if (defined($minwords)){
      my @l=grep(!/^\s*$/,  # remove emty words
              map({$_=~s/([a-z])\1{2}//gi;$_;} # replace xxxxx durch nix
                 split(/[^a-z]+/i,$val)
              )
           ); 
      return(0) if ($#l+1<$minwords);
   }
   return(1);
}


#
# detects the effective change of a given variable
#
sub effChangedVal
{
   my $oldrec=shift;
   my $newrec=shift;
   my $var=shift;
   if (defined($newrec) && exists($newrec->{$var})){
      if (defined($oldrec)){
         if ($newrec->{$var} ne $oldrec->{$var}){
            return($newrec->{$var});
         }
      }
      else{
         return($newrec->{$var});
      }
   }
   return(undef);
}




sub Debug
{
   return($W5V2::Debug);
}


sub globalContext
{
   $W5V2::Context->{GLOBAL}={} if (!exists($W5V2::Context->{GLOBAL}));
   return($W5V2::Context->{GLOBAL});
}

sub Query
{
   return($W5V2::Query);
}


sub CalcDateDuration
{
   my $d1=shift;
   my $d2=shift;
   my $tz=shift;
   $tz="GMT" if (!defined($tz));

   if (ref($d1)){
      $d1=$d1->ymd." ".$d1->hms;
   }
   if (ref($d2)){
      $d2=$d2->ymd." ".$d2->hms;
   }
   if ($d1 eq "" && $d2 eq ""){
      return(undef);
   }
   if ((my ($wsY,$wsM,$wsD,$wsh,$wsm,$wss,$wsms)=$d1=~
         m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\.\d{1,6}){0,1}$/) 
       &&
       (my ($weY,$weM,$weD,$weh,$wem,$wes,$wems)=$d2=~
         m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\.\d{1,6}){0,1}$/)){
      # $wsms and $wems will be ignored (ms part of timestamp)
      my ($dd,$dh,$dm,$ds);
      $wsms=~s/^\.//;
      $wems=~s/^\.//;
      $wsms=undef if ($wsms eq "");
      $wems=undef if ($wems eq "");
      $wsms=999999 if (defined($wsms) && $wsms>999999);
      $wems=999999 if (defined($wems) && $wems>999999);
      eval('($dd,$dh,$dm,$ds)=Delta_DHMS($tz,
                                         $wsY,$wsM,$wsD,$wsh,$wsm,$wss,
                                         $weY,$weM,$weD,$weh,$wem,$wes);');
      if ($@ ne ""){
         return(undef);
      }
      $dd=0 if (!defined($dd)); 
      $dh=0 if (!defined($dh)); 
      $dm=0 if (!defined($dm)); 
      $ds=0 if (!defined($ds)); 
      my $duration={days=>$dd,hours=>$dh,minutes=>$dm, seconds=>$ds};
      $duration->{totalminutes}=($dd*24*60)+($dh*60)+$dm+(1/60*$ds);
      $duration->{totalseconds}=($dd*24*60*60)+($dh*60*60)+($dm*60)+$ds;
      $duration->{totaldays}=$duration->{totalminutes}/1440.0;
 
      #
      #  since 08/2019 the .999 handling of dates is changed to .999999
      #  handling becuase ms is not 1/1000 of a second but 1/1000000 
      #  (i hope this is now correc)
      #
      if ((defined($wsms) || defined($wems))){  # not final tested ms handling
         if ($duration->{totalseconds}>0){      # (05.08.2015)
            if (defined($wsms)){
               $duration->{totalseconds}-=(1/1000000)*$wsms;
            }
            if (defined($wems)){
               $duration->{totalseconds}+=(1/1000000)*$wems;
            }
         }
         else{
            if (defined($wsms)){
               $duration->{totalseconds}+=(1/1000000)*$wsms;
            }
            if (defined($wems)){
               $duration->{totalseconds}-=(1/1000000)*$wems;
            }
         }
      }
      my $d="";
      $d.="${dd}d" if ($dd!=0);
      $d.=" "      if ($dh!=0 && $d ne "");
      $d.="${dh}h" if ($dh!=0);
      $d.=" "      if ($dm!=0 && $d ne "");
      $d.="${dm}m" if ($dm!=0);
      $d.=" "      if ($ds!=0 && $d ne "");
      $d.="${ds}s" if ($ds!=0);
      $duration->{string}=$d;
      return($duration);
   }
   else{
      msg(WARN,"parsing error d1='$d1' d2='$d2'");
   }
   return(undef);
}

sub NowStamp
{
   if ($_[0] eq "ISO"){
      return(sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",Today_and_Now("GMT")));
   }
   if ($_[0] eq "en"){
      return(sprintf("%04d-%02d-%02d %02d:%02d:%02d",Today_and_Now("GMT")));
   }
   return(sprintf("%04d%02d%02d%02d%02d%02d",Today_and_Now("GMT")));
}

sub getConfigObject($$$)
{
   my $instdir=shift;
   my $configname=shift;
   my $package=shift;

   my ($basemod,$app)=$package=~m/^(\S+)::(.*)$/;

   $W5V2::Config={} if (!defined($W5V2::Config));
   my $configkey="$configname::$basemod";

   # handling of reread config is now handeled by W5FastConfig.pm
   # at setPreLoad method - so it works in W5Server context too.
   # if (exists($W5V2::Config->{$configkey})){
   #   if ($W5V2::Config->{$configkey}->{Time}<time()-3500){
   #      delete($W5V2::Config->{$configkey});
   #   }
   # }

   if (exists($W5V2::Config->{$configkey})){
      return($W5V2::Config->{$configkey}->{Config});
   }
   #msg(INFO,"(re)read config for base '$basemod' from package '$package'");
   my $config=new kernel::config();
   $configname=~s/^.*\///;  # remove all bevor the last / to handel 
                            # installations deeper then 1st layer
   if (!$config->readconfig($instdir,$configname,$basemod)){
      if ($ENV{SERVER_SOFTWARE} ne ""){
         print("Content-type:text/plain\n\n");
         print msg(ERROR,"can't read configfile '%s'",$configname); 
         exit(1);
      }
      else{
         msg(ERROR,"can't read configfile '%s'",$configname); 
         exit(1);
      }
   }
   $W5V2::Config->{$configkey}={Config=>$config,Time=>time()};
   return($config);
}

sub generateToken
{
   my $len=shift;
   my $token="";

   my @set=('a'..'z','A'..'Z','0'..'9');
   for(my $c=0;$c<$len;$c++){
      if ($c==3){
         $token.=time();
      }
      $token.=$set[rand($#set)];
   }
   return(substr($token,0,$len));
}

sub defaultModuleObject_newMethod
{
   my $type=shift;
   my %param=@_;
   my $self;

   { # SUPER is not working - so we need to calc parrent:new
      no strict qw/refs/;
      my @isa=eval("\@${type}::ISA");
      my $new="$isa[0]::new";
      $self=bless(&{$new}(%param),$type);
   }
   return($self);
}

sub getModuleObject
{
   my $config;
   my $package;
   my $param;
   if (ref($_[0])){
      $config=shift;
      $package=shift;
      $param=shift;
   }
   else{
      my $instdir=shift;
      my $configname=shift;
      $package=shift;
      $param=shift;
      $config=getConfigObject($instdir,$configname,$package);
   }
   my $modpath=$config->Param("MODPATH");
   if ($modpath ne ""){
      foreach my $path (split(/:/,$modpath)){
         $path.="/mod";
         my $qpath=quotemeta($path);
         unshift(@INC,$path) if (!grep(/^$qpath$/,@INC));
      }
   }
   my $modconf=$config->Param("MODULE");
   if (ref($modconf) eq "HASH"){
      $modconf=$modconf->{$package};
   }
   return(undef) if (lc($modconf) eq "disabled");
   my ($basemod,$app)=$package=~m/^(\S+)::(.*)$/;
   return(undef) if (!defined($config));
   #printf STDERR ("dump%s\n",Dumper($config));
   my %modparam=();
   $modparam{Config}=$config;
   $modparam{param}=$param if (defined($param));;
   my $virtualtab=$config->Param("VIRTUALMODULE");
   if (ref($virtualtab) eq "HASH"){
      if (defined($virtualtab->{$app})){
         $modparam{OrigModule}=$basemod;  
         ($basemod,$app)=$virtualtab->{$app}=~m/^(\S+)::(.*)$/;
      }
      if (defined($virtualtab->{$package})){
         $modparam{OrigModule}=$basemod;  
         ($basemod,$app)=$virtualtab->{$package}=~m/^(\S+)::(.*)$/;
      }
   }
   my ($o,$msg);
   $package="${basemod}::${app}"; # MOD neuaufbau - basemod vieleicht ver‰ndert
   $package=~s/[^a-z0-9:_]//gi;
   if ($config->Param("SAFE") eq "1"){
      my $compartment=new Safe();
      #
      # Das ist mit Sicherheit noch nicht fertig !!!
      #
      $compartment->reval("use $package;\$o=new $package(\%modparam);");
   }
   else{
      eval("use $package;");
      if ($@ eq ""){
         {  # dynamic define new method (Hack) in package, if it not exists
            no strict qw/refs/;
            my $func=$package."::new";
            if (!(*{$func}{CODE})){
               *{$func}=\&defaultModuleObject_newMethod;
            }
         }
         eval("(\$o,\$msg)=new $package(\%modparam);");
      }
   }
   if ($@ ne "" || !defined($o) || $o eq "InitERROR"){
      $msg=$@;
      if ($ENV{SERVER_SOFTWARE} ne "" || $W5V2::Debug eq "1"){
         #print("Content-type:text/plain\n\n");
         msg(ERROR,"can't create object '%s'",$package); 
         if ($msg ne ""){ 
            print STDERR ("---\n$msg---\n");
         }
         return(undef);
      }
      else{
         msg(ERROR,"can't create object '%s'",$package); 
         return(undef);
      }
   }
   if (lc($modconf) eq "readonly"){
      no strict;
      my $f="${package}::isWriteValid";
      *$f=sub {return undef};
      my $f="${package}::isDeleteValid";
      *$f=sub {return undef};
   }

   return($o);
}

sub TextShorter
{
   my $text=shift;
   my $limit=shift;
   my @mode=@_;
   if ($#mode==0 && ref($mode[0]) eq "ARRAY"){
      @mode=@{$mode[0]};
   }
   if (in_array(\@mode,["LINK","URL"])){
      my $ll=index($text,"//");
      $ll=index($text,"/",$ll+2);
      my $start=$ll+11;
      $start=$limit-1 if ($start<10 || $start>$limit);
      $text=substr($text,0,$start)."...".substr($text,length($text)-16,16);
   }
   if (in_array(\@mode,["INDICATED","INDI"])){
      if (length($text)>$limit){
         $text=substr($text,0,$limit-3)."...";
      }
   }
   if (in_array(\@mode,["DOTHIER"])){
      if (length($text)>$limit){
         my @text=split(/\./,$text);
         my @n=(".");
         my $pretext;
         my @pref;
         my @post;
         while(my $ts=shift(@text)){
            my $te=pop(@text);
            push(@pref,$ts);
            push(@post,$te) if (defined($te));
            $pretext=join(".",@pref,@n,@post);
            if (length($text)<=$limit &&
                length($pretext)>$limit){
               last;
            }
            $text=$pretext;
         }
      }
   }
   if (length($text)>$limit){
      $text=substr($text,0,$limit);
   }
   return($text);
}

sub LengthOfLongestWord
{
   my $str=shift;
   my @l=split(/\s/,$str);
   my $max=0;

   foreach my $s (@l){
     $max=length($s) if ($max<length($s));
   }
   return($max);
}




sub _isWriteValid {return undef};

sub _FancyLinks
{
   my $link=shift;
   my $prefix=shift;
   my $name=shift;
   my $res="<a href=\"$link\" tabindex=-1 target=_blank>$link</a>".$prefix;
   if ($name ne ""){
      $res="<a href=\"$link\" tabindex=-1 title=\"$link\" ".
           "target=_blank>$name</a>".$prefix;
   }
   else{
      if (length($link)>55){
         my $title=$link;
         my $slink=TextShorter($link,55,"URL");
         $title=~s/^.*?://g;
         $res="<a href=\"$link\" tabindex=-1 target=_blank title=\"$title\">".
              "$slink</a>".$prefix;
      }
   }
   return($res);
}

sub _FancyMailLinks
{
   my $link=shift;
   my $prefix=shift;
   my $name=shift;
   my $res="<a href=\"$link\" target=_blank>$link</a>".$prefix;
   if ($name ne ""){
      $res="<a href=\"$link\" title=\"$link\" target=_blank>$name</a>".$prefix;
   }
   return($res);
}

sub _FancySmbShares
{
   my $host=shift;
   my $share=shift;

   my $res="<a href=\"file:////$host/$share/\" target=_blank>".
           "\\\\$host\\$share</a>";
   return($res);
}

sub FancyLinks
{
   my $data=shift;
   my $newline=chomp($data);

   $data=~s#([\s"<>]{0,1})(http|https|telnet|news)
            (://\S+?)(\?\S+?){0,1}
            ([\s"<>]+|&quot;|&lt;|&gt;|$)#$1._FancyLinks("$2$3$4",$5)#gex;
   $data.="\n" if($newline);
   $data=~s#(mailto)(:\S+?)(\@)(\S+)#_FancyMailLinks("$1$2$3$4")#ge;
   $data=~s#\\\\([^\\]+)\\(\S+)#_FancySmbShares($1,$2)#ge;

   return($data);
}


sub _ExpandW5BaseDataLinks
{
   my $self=shift;
   my $formats=shift;
   my $FormatAs=shift;
   my $raw=shift;
   my $targetobj=shift;
   my $mode=shift;
   my $id=shift;
   my $view=shift;

   if (lc($mode) eq "show" && $id ne ""){
      my $obj=getModuleObject($self->Config,$targetobj);
      if (defined($obj)){
         my $idobj=$obj->IdField();
         if (defined($idobj)){
            $obj->SecureSetFilter({$idobj->Name=>\$id});
            my @view=split(/,/,$view);
            my ($trec,$msg)=$obj->getOnlyFirst(@view);
            if (defined($trec)){
               my @d;
               foreach my $k (@view){
                  push(@d,$trec->{$k}) if ($trec->{$k} ne "");
               }
               if ($#d==-1){
                  @d=("[EMPTY LINK]");
               }
               my $d=join(", ",@d);
               if (in_array($formats,$FormatAs)){
                  my $url=$targetobj;
                  $url=~s/::/\//g;
                  $url="../../$url/ById/$id";
                  $d="<a href='$url' target=_blank>".$d."</a>";
               }
               return($d);
            }
         }
      }
   }

   $raw=~s/w5base:/w5base?:/;
   return($raw);
}

sub ExpandW5BaseDataLinks
{
   my $self=shift;
   my $FormatAs=shift;
   my $data=shift;
   my @formats=qw(HtmlWfActionlog HtmlDetail HtmlMail);
   return($data) if (!in_array(\@formats,$FormatAs));

   $data=~s#(w5base://([^\/]+)/([^\/]+)/([^\/]+)/([,0-9,a-z,A-Z_]+))#_ExpandW5BaseDataLinks($self,\@formats,$FormatAs,$1,$2,$3,$4,$5)#ge;

   return($data);
}

sub _mkInlineAttachment
{
   my $id=shift;
   my $rootpath=shift;
   my $size;

   eval("use GD;");
   if ($@ ne ""){
      $size="height=90";
   }
   $rootpath="" if ($rootpath eq "");
   my $d="<img border=0 $size ".
         "src=\"${rootpath}../../base/filemgmt/load/thumbnail/inline/$id\">";
   $d="<a rel=\"lytebox[inline]\" href=\"${rootpath}../../base/filemgmt/load/inline/$id\" ".
      "target=_blank>$d</a>";
   return($d);
}
sub _mkMailInlineAttachment
{
   my $id=shift;
   my $baseurl=shift;
   my $size;

   eval("use GD;");
   if ($@ ne ""){
      $size="height=90";
   }
   my $d="&lt;Attachment&gt;";
   $d="<a rel=\"lytebox[inline]\" ".
      "href=\"$baseurl/public/base/filemgmt/load/inline/$id\" ".
      "target=_blank>$d</a>";
   return($d);
}
sub mkInlineAttachment
{
   my $data=shift;
   my $rootpath=shift;
   $data=~s#\[attachment\((\d+)\)\]#_mkInlineAttachment($1,$rootpath)#ge;
   return($data);
}
sub mkMailInlineAttachment
{
   my $baseurl=shift;
   my $data=shift;
   $data=~s#\[attachment\((\d+)\)\]#_mkMailInlineAttachment($1,$baseurl)#ge;
   return($data);
}

sub Stacktrace {
  my $traceonly=shift;
  my ( $path, $line, $subr );
  my $max_depth = 30;
  my $i = 0;

  print STDERR ("--- Begin stack trace ---\n");
  my $firstLine;
  while ( (my @call_details = (caller($i++))) && ($i<$max_depth) ) {
    my $line="$i $call_details[1]($call_details[2]) ".
             "in $call_details[3]\n";
    $firstLine=$line if (!defined($firstLine));
    print STDERR ($line);
  }
  print STDERR ("--- End stack trace ---\n");
  die("die with kernel::Stacktrace(0): ".$firstLine) if (!$traceonly);
}




1;
