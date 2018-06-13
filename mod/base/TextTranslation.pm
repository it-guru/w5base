package base::TextTranslation;
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
use vars qw(@ISA);
use kernel;
use kernel::App::Web;
use Safe;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main));
}

sub Main
{
   my ($self)=@_;

   my ($cursrc,$curdst,$cursrclang,$curdstlang);
   my $ua;
   my $html;

   my $tte=$self->Config->Param("TextTranslationEngine");
   if ($tte eq ""){
      msg(ERROR,"request to base::TextTranslation with no TextTranslationEngine rejected");
      our $cgi = CGI->new();
      print $cgi->header(
         -type=>'text/plain',
         -status=> '503 Service Unavailable'
      );
      return();
   }

   eval('
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTML::Parser;

$ua=new LWP::UserAgent(env_proxy=>0);
#$ua->cookie_jar(HTTP::Cookies->new(file => "/tmp/.w5base.cookies.txt"));
$ua->timeout(60);
$ua->agent("Mozilla/5.0 (X11; U; Linux i686; de-AT; rv:1.8.1.4) Gecko/20070509 SeaMonkey/1.1.2");
$html=new HTML::Parser();
');
   if ($@ ne ""){
      msg(ERROR,$@);
   }
   if (defined($ua)){
      my $proxy=$self->Config->Param("http_proxy");
      if ($proxy ne ""){
         msg(INFO,"set proxy to $proxy");
         $ua->proxy(['http','https', 'ftp'],$proxy);
      }
   }

   $cursrc=Query->Param("src");
   $curdst=Query->Param("dst");

   $cursrclang=Query->Param("srclang");
   $curdstlang=Query->Param("dstlang");

   $cursrclang=$self->Lang() if ($cursrclang eq "");
   $curdstlang="de" if ($curdstlang eq "" && $cursrclang eq "en");
   $curdstlang="en" if ($curdstlang eq "" && $cursrclang ne "en");

   if ($tte eq "google"){
      if ($curdstlang ne "" && $cursrclang ne "" && $cursrc ne "" && defined($ua)){
        # my $googleurl01="http://www.google.de/language_tools";
         my $googleurl02="http://translate.google.com/translate_a/t?".
                         "sl=$cursrclang&tl=$curdstlang";  
         my $googleurl02="https://translate.google.com/translate_a/single";
         #msg(INFO,"request0: $googleurl02");
        # my $response=$ua->request(GET($googleurl01));
        # if ($response->code ne "200"){
        #    msg(ERROR,"fail to init '$googleurl01' response code=".
        #              $response->code);
        #    $ua=undef;
        # }
        # open(F,">/tmp/googletrans01.html");
        # print F ($response->content());
        # close(F);
         my $sendcursrc=Unicode::String::latin1($cursrc)->utf8();
         if (Query->Param("mode") eq "xml"){
            $sendcursrc=$cursrc;
         }

         my %qparam=(
           'hl'=>'en',                                        #
           'oe'=>'UTF-8',                                     #
           'ie'=>'UTF-8',                                     #
           'source'=>'btn',                                   #
           'ssel'=>'3',                                       #
           'tsel'=>'3',                                       #
           'q'=>$sendcursrc,                                  #
           'sl'=>"$cursrclang",                               #
           'dt'=>[qw(bd ex ld md qca rw rm ss t at)],         #
           'tk'=>"701488.824154",                             #
           'kc'=>"0",                                         #
           'client'=>"t",                                     #
           'tl'=>"$curdstlang"                                #
         );

         my $c=new kernel::cgi(%qparam);
         $googleurl02.="?".kernel::cgi::Hash2QueryString(%qparam);

         msg(INFO,"request1: $googleurl02");


         #my $response=$ua->request(GET($googleurl02,
         #                 'Referer'=>'https://translate.google.com/translate_a/single',
         #                 'Content_Type'=>'application/x-www-form-urlencoded',
         #                 'Accept-Charset'=>'ISO-8859-15,utf-8;q=0.7,*;q=0.7',
         #                 'Accept-Language'=>'de,en-jm;q=0.7,en;q=0.3',
         #                 'user-agent'=>'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36',
         #                 'Content'=>[%qparam]));
         my $req=HTTP::Request->new(GET=>$googleurl02);
         $req->header('user-agent'=>'Mozilla/5.0 (X11; Linux x86_64)');
         $req->header('Accept'=>'*/*');
         $req->header('Host'=>'translate.google.com');

         my $response=$ua->request($req);
         if ($response->code ne "200"){
            msg(ERROR,"fail to get '$googleurl02' response code=".$response->code);
            $ua=undef;
         }
         $curdst="???";
         my $res=$response->content;
       
         if ($res ne ""){
            $res=UTF8toLatin1($res);
            #msg(INFO,"GoogleRawResponse=%s\n",$res);
            my $eenv=new Safe();
            my $res=$eenv->reval($res.";");
            if (ref($res) eq "ARRAY" &&
                ref($res->[0]) eq "ARRAY"){
               $curdst="";
               foreach my $resp (@{$res->[0]}){
                  $curdst.=$resp->[0];
               }
               msg(INFO,"GoogleQuery   =%s\n",$cursrc);
               msg(INFO,"GoogleResponse=%s\n",$curdst);
            }
         }
         #open(F,">/tmp/googletrans02.html");
         #print F ($response->content());
         #close(F);
         #eval('$html->parse($response->content);');

      }
   }
   if (Query->Param("mode") eq "plain"){
      print $self->HttpHeader("text/plain");
      print $curdst;
      return();
   }
   if (Query->Param("mode") eq "xml"){
      print $self->HttpHeader("text/xml");
      my $res=hash2xml({document=>{result=>latin1($curdst)->utf8(),
                        exitcode=>0}},{header=>1});
      print $res;
      return();
   }



   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>'default.css',
                           title=>$self->T($self->Self()));
   my @langtable=LangTable();
   my $srclang="<select name=srclang>";
   my $dstlang="<select name=dstlang>";
   foreach my $l (@langtable){
      $srclang.="<option value=\"$l\"";
      $srclang.=" selected" if ($l eq $cursrclang); 
      $srclang.=">$l</option>"; 
   }
   $srclang.="</select>";
   foreach my $l (@langtable){
      $dstlang.="<option value=\"$l\"";
      $dstlang.=" selected" if ($l eq $curdstlang); 
      $dstlang.=">$l</option>"; 
   }
   $dstlang.="</select>";
   $cursrc=~s/</&lt;/g; 
   $curdst=~s/</&lt;/g; 
   $cursrc=~s/>/&gt;/g; 
   $curdst=~s/>/&gt;/g; 
   $curdst=UTF8toLatin1($curdst);
   my $fromlabel=$self->T("from");
   my $tolabel=$self->T("to");
   my $translabel=$self->T("translate");
   my $reference=$self->T("ATTENTION: The translation will done bei Google-Translation Services! Do not use this module for internal Informations!");
   my $dstdis="";
   if (!defined($ua)){
      $curdst="LWP::UserAgent not available or Google Translation API Error";
      $dstdis="disabled";
   }
   print(<<EOF);
<style>
textarea{
   width:100%;
   height:100%;
}
</style>
<form method=POST>
<table width="100%" height="100%">
<tr height="1%"><td width=1%>$fromlabel:</td><td>$srclang</td></tr>
<tr><td colspan=2><textarea name=src>$cursrc</textarea></td></tr>
<tr height="1%"><td colspan=2 align=center><b><font color=red>$reference</td></tr>
<tr height="1%"><td colspan=2 align=center><input style="width:60%" type=submit value=" $translabel "></td></tr>
<tr height="1%"><td width=1%>$tolabel:</td><td>$dstlang</td></tr>
<tr><td colspan=2><textarea name=dst $dstdis>$curdst</textarea></td></tr>
</table>
</form>


EOF
   print $self->HtmlBottom(body=>1,form=>1);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Text2Acronym),$self->SUPER::getValidWebFunctions());
}


sub Text2Acronym
{
   my $self=shift;
   my $acywords;
   my $cursrc=Query->Param("src");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>'default.css',
                           title=>$self->T($self->Self()));
#   my ($cursrc,$curdst,$cursrclang,$curdstlang);
#   my $ua;
#   my $html;
#   eval('
#use LWP::UserAgent;
#use HTTP::Request::Common;
#use HTTP::Cookies;
#use HTML::Parser;
#
#$ua=new LWP::UserAgent(env_proxy=>1);
#$ua->cookie_jar(HTTP::Cookies->new(file => "/tmp/.w5base.cookies.txt"));
#$ua->timeout(60);
#$ua->agent("Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.1) Gecko/2008070206 Firefox/3.0.1");
#$html=new HTML::Parser();
#');
#   if ($@ ne ""){
#      msg(ERROR,$@);
#   }
#   if (defined($ua)){
#      my $proxy=$self->Config->Param("http_proxy");
#      if ($proxy ne ""){
#         msg(INFO,"set proxy to $proxy");
#         $ua->proxy(['http', 'ftp'],$proxy);
#      }
#   }
#
#
#
#
#   if ($cursrc ne "" && defined($ua)){
#      my $ace="http://ac.epfl.ch";
#      my $response=$ua->request(GET($ace));
#print ("ace=$ace <br>");
#print ("ua=$ua <br>");
#print ("cursrc=$cursrc <br>");
#printf ("code=%s <br>",$response->code);
#      if ($response->code ne "200"){
#         msg(ERROR,"fail to init '$ace' response code=".
#                   $response->code);
#         $ua=undef;
#      }
#      my $acetarget="http://ac.epfl.ch/cgi-bin/ac.cgi";
#      my $response=$ua->request(POST($acetarget,
#                       'Referer'=>'http://ac.epfl.ch/cgi-bin/ac.cgi',
#                       'Content_Type'=>'application/x-www-form-urlencoded',
#                       'Accept-Charset'=>'ISO-8859-15,utf-8;q=0.7,*;q=0.7',
#                       'Accept'=>'text/xml,application/xml,application/xhtml'.
#                                 '+xml,text/html;q=0.9,text/plain;q=0.8',
#                       'Accept-Language'=>'de-de,de;q=0.8,en-us;q=0.5,en;q=0.3',
#                       'Content'=>['F_UserId'=>'1',
#                                   'F_FeedBack'=>'0',
#                                   'F_Keywords'=>"$cursrc",
#                                   'F_Submit'=>'Get New Acronyms',
#                                   'F_SimpleSearch'=>'1',
#                                   'F_Extra'=>'0',
#                                   'F_Done'=>'0',
#                                   'F_Advance'=>'0',
#                                   'F_DisplayPage'=>'1',
#                                   'F_FeedBack'=>'0']));
#printf ("rccode=%s <br>",$response->status_line());
#   }
   if ($cursrc ne ""){
      $acywords=<<EOF;
<tr>
    <td></td>
    <td align=center width=190><b>Acronym</b></td>
    <td align=center width=190><b>Keyword</b></td>
    <td></td>
</tr>
EOF
      $cursrc=~s/<.*?script>//g;
      my $letters=scanWord($cursrc);
      my (%acros);
      for (my $l=4;$l<7;$l++){
          moveStart($letters,$l,\%acros);
      }
      my $dbs=initDBs(['en','de']);
      seekWord(\%acros,$dbs);
      closeDBs($dbs);
      foreach my $key (keys(%acros)){
         if ($acros{$key} == 5 and 
             substr($key,0,1) eq lc(substr($cursrc,0,1))){
             $acros{$key} =3;
         }elsif($acros{$key} != 5){
             delete($acros{$key});
         } 
      }
      my @keys=sort({ $acros{$a} <=> $acros{$b} } keys(%acros));
      foreach my $key (@keys){
         my ($nword,$found,@ks);
         for (my $ss=0;$ss<length($key);$ss++){
             push(@ks,substr($key,$ss,1));
         }
         for (my $s=0;$s<length($cursrc);$s++){
            $found=0;
            my $keychr=lc(substr($cursrc,$s,1));
            if ($keychr eq $ks[0]){
               splice(@ks,0,1);
               $found=1;
            } 
            if ($found==1){
               $nword=$nword."<b>$keychr</b>";
            }else{
               $nword=$nword.$keychr;
            }
         }
         $acywords.="<tr><td></td><td align=center width=190>$key
                 </td><td width=190 align=center>$nword</td><td></td></tr>";
      }
      $acywords.="<tr><td colspan=4>&nbsp;</td></tr><tr><td></td><td ".
                 "align=center colspan=2><b>possibilities=".
                 keys(%acros)."</b><td></td></tr></table>";
   }else{
      $acywords.="<script language=JavaScript>".
                 "loading('please insert your Keywords ...')</script>";
   }
   $acywords=~s/<.*?script>//g;
   my $aout=$self->getParsedTemplate("tmpl/base.Text2Acronym",
                                             {static=>{acywords=>$acywords}});
   print $aout;
   print $self->HtmlBottom(body=>1,form=>1);
}

sub scanWord
{
   my $name=shift;
   my $word=1;
   my $ipos=0;
   my $char;
   my @letters;
   # scan given word 
   for (my $s=0;$s<length($name);$s++){
      my $tmpchr=substr($name,$s,1);
      if ($tmpchr=~m/ /){
         $word++;
      }else{
         my $rest=substr($name,$s+1,length($name)-$s);
         $char={'char'=>$tmpchr,
                'word'=>$word,
                'rest'=>$rest,
                'pos'=>$ipos};
         push(@letters,$char);
         $ipos++; 
      }
   }
   return(\@letters);
}

sub moveStart
{
   my $letters=shift;
   my $length=shift;
   my $acros=shift;
   # move start position one step forward
   for (my $a=0;$a<$#{$letters}+2-$length;$a++){
      if ($a == $#{$letters}+1-$length){
         my $lastword;
         for (my $y=0;$y<$length;$y++){ 
            $lastword=$lastword.$letters->[$a+$y]->{'char'};
         }
         $acros->{lc($lastword)}=1;
         next;
      }
      my ($rstr,$rpos)=chglastchar($letters,$length,$acros,"",$a);
      for (my $l=2;$l<$length;$l++){
         ($rstr)=chgchar($letters,$length,$acros,$rstr,$rpos,$l);
      }   
   }
}

sub chgchar
{
   # change characters after start position (first character in $str)
   my $letters=shift;
   my $length=shift;
   my $acros=shift;
   my $str=shift;
   my $pos=shift;
   my $level=shift;
   my $newstr=substr($str,0,length($str)-$level);
   my $posnew=$pos;
   while (length($newstr) < $length){
      if ($#{$letters} >= $posnew-$level+1){
         $newstr=$newstr.$letters->[$posnew-$level+1]->{'char'};
         $posnew++;
      }else{
         last;
      }
   }
   if ($pos < $#{$letters}){
      if ($level == 2){
         chgchar($letters,$length,$acros,
                 chglastchar($letters,$length,$acros,$newstr,$pos),
                 $level);
      }else{
         chgchar($letters,$length,$acros,
                 chgchar($letters,$length,$acros,$newstr,$pos,$level-1),
                 $level); 
      }
   }elsif($pos == $#{$letters}){
      if ($level == 2){
         chglastchar($letters,$length,$acros,$newstr,$pos);
      }else{
         chgchar($letters,$length,$acros,$newstr,$pos,$level-1);
      }
   }
   return($str,$pos+1);
}

sub chglastchar
{
   # change last character for all possibilities
   my $letters=shift;
   my $length=shift;
   my $acros=shift;
   my $str=shift;
   my $pos=shift;
   while (length($str) >= $length){
      $str=substr($str,0,length($str)-1);
   }
   for (my $c=$pos;$c<=$#{$letters};$c++){
      $str=$str.$letters->[$c]->{'char'};
      if($length == length($str)){
         $acros->{lc($str)}=1;
         if ($#{$letters} != $letters->[$c]->{'pos'}){
            chglastchar($letters,$length,$acros,substr($str,0,$length-1),$letters->[$c]->{'pos'}+1);
            return($str,$letters->[$c]->{'pos'}+1);
         }
      }
   }   
   return($str,$pos+1);
}

sub initDBs
{
   my $db=shift;
   my @rdb;
   my $fnd3="";
   my $fnd4="";
   foreach my $d (@$db){
      my %db;
      my $tell=0;
      open(my $fh,'<'." $W5V2::INSTDIR/lib/dict/$d") ||
          printf STDERR ("ERROR: can't open dictionary $d\n");
      $db{'tblname'}="$d";
      while (my $w=<$fh>){
         if ($fnd3 ne lc(substr($w,0,3))){
            $fnd3=lc(substr($w,0,3)); 
            $db{'keypos'}->{$fnd3}=$tell;
         }
         if ($fnd4 ne lc(substr($w,0,4))){
            $fnd4=lc(substr($w,0,4)); 
            $db{'keypos'}->{$fnd4}=$tell;
         }
         $tell=tell($fh);
      }
      seek($fh,0,0);
      $db{'dbfp'}=$fh;
      push(@rdb,\%db);
   }
   return(\@rdb); 
}

sub closeDBs
{
   my $db=shift;
   foreach my $fh (@$db){
      close($fh->{'dbfp'});
   }
}

sub seekWord
{
   my $acros=shift;
   my $dbs=shift;
   foreach my $key (keys(%$acros)){
      foreach my $db (@$dbs){
         my $f;
         $f=$db->{'dbfp'};
         my ($ch,$l);
         if (exists($db->{'keypos'}->{substr($key,0,4)})){
            $ch=substr($key,0,4);
            $l=4;
            seek($f,$db->{'keypos'}->{$ch},0);
         }elsif(exists($db->{'keypos'}->{substr($key,0,3)})){
            $ch=substr($key,0,3);
            $l=3;
            seek($f,$db->{'keypos'}->{$ch},0);
         }else{
            last;
         }
         while(my $dict=<$f>){
            chop($dict);
            if (lc($dict) eq $key){
               $acros->{$key}=5;
               last;
            } 
            if (lc(substr($dict,0,$l)) ne $ch){
               last;
            }
         }
      }
   }
   return($acros);
}

1;
