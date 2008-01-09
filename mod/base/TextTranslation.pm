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
         $ua->proxy(['http', 'ftp'],$proxy);
      }
   }

   $cursrc=Query->Param("src");
   $curdst=Query->Param("dst");

   $cursrclang=Query->Param("srclang");
   $curdstlang=Query->Param("dstlang");

   $cursrclang=$self->Lang() if ($cursrclang eq "");
   $curdstlang="de" if ($curdstlang eq "" && $cursrclang eq "en");
   $curdstlang="en" if ($curdstlang eq "" && $cursrclang ne "en");


   if ($curdstlang ne "" && $cursrclang ne "" && $cursrc ne "" && defined($ua)){
     # my $googleurl01="http://www.google.de/language_tools";
      my $googleurl02="http://translate.google.com/translate_t?".
                      "langpair=$cursrclang|$curdstlang";  
     # my $response=$ua->request(GET($googleurl01));
     # if ($response->code ne "200"){
     #    msg(ERROR,"fail to init '$googleurl01' response code=".
     #              $response->code);
     #    $ua=undef;
     # }
     # open(F,">/tmp/googletrans01.html");
     # print F ($response->content());
     # close(F);


      my $response=$ua->request(POST($googleurl02,
                       'Referer'=>'http://translate.google.com/translate_t',
                       'Content_Type'=>'application/x-www-form-urlencoded',
                       'Accept-Charset'=>'ISO-8859-15,utf-8;q=0.7,*;q=0.7',
                       'Accept-Language'=>'de,en-jm;q=0.7,en;q=0.3',
                       'Accept'=>'text/xml,application/xml,application/xhtml'.
                                 '+xml,text/html;q=0.9,text/plain;q=0.8',
                       'Content'=>['hl'=>'en',
     #                            'ie'=>'UTF8',
                                 'text'=>$cursrc,
                                 'langpair'=>"$cursrclang|$curdstlang"]));
      #my $response=$ua->request(GET($googleurl02));
      if ($response->code ne "200"){
         msg(ERROR,"fail to get '$googleurl02' response code=".$response->code);
         $ua=undef;
      }
      $curdst="";
      $html->handler( start=>sub {
                         my ($self,$tag,$attr,$dtext)=@_;
                         if (lc($tag) eq "div" &&
                             $attr->{id} eq "result_box"){
                            $self->{_dst}=1;
                         }
                         if (lc($tag) eq "br" &&
                            $self->{_dst}){
                            $curdst.="\n";
                         }
                      },'self, tagname, attr, text');
      $html->handler( end=>sub {
                         my ($self,$tag)=@_;
                         if (lc($tag) eq "div"){
                            $self->{_dst}=0;
                         }
                      },'self, tagname');
      $html->handler( text=>sub {
                         my ($self,$dtext)=@_;
                         if ($self->{_dst}){
                            $dtext=~s/^\s//;
                            $curdst.=$dtext;
                         }
                      },'self, text');

      open(F,">/tmp/googletrans02.html");
      print F ($response->content());
      close(F);
      eval('$html->parse($response->content);');

   }
   if (Query->Param("mode") eq "plain"){
      print $self->HttpHeader("text/plain");
      print $curdst;
      return();
   }
   if (Query->Param("mode") eq "xml"){
      print $self->HttpHeader("text/xml");
      my $res=hash2xml({document=>{result=>$curdst,exitcode=>0}},{header=>1});
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
   my $dstdis="";
   if (!defined($ua)){
      $curdst="LWP::UserAgent not available";
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
<table width=100% height=100%>
<tr height=1%><td width=1%>$fromlabel:</td><td>$srclang</td></tr>
<tr><td colspan=2><textarea name=src>$cursrc</textarea></td></tr>
<tr height=1%><td colspan=2 align=center><input style="width:60%" type=submit value=" $translabel "></td></tr>
<tr height=1%><td width=1%>$tolabel:</td><td>$dstlang</td></tr>
<tr><td colspan=2><textarea name=dst $dstdis>$curdst</textarea></td></tr>
</table>
</form>


EOF
   print $self->HtmlBottom(body=>1,form=>1);
}


1;
