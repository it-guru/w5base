package base::env;
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
use vars qw(@ISA);
use kernel;
use kernel::App::Web;
use CGI;
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
   return(qw(Main ParsedConfig));
}

sub ParsedConfig
{
   my ($self)=@_;

   my $cfg=$self->Config();

   if (!$self->IsMemberOf("admin") &&
       !$self->IsMemberOf("support")){
      print($self->noAccess());
      return();
   }

   if ($ENV{HTTP_ACCEPT}=~m/\/json$/){
      print $self->HttpHeader("application/json");
   }
   if ($ENV{HTTP_ACCEPT}=~m/\/plain$/){
      print $self->HttpHeader("text/plain");
   }
   print $self->HttpHeader("text/html");
   
   print $self->HtmlHeader(title=>"Config",body=>1);
   print("<b># Config</b><br><br>");
   foreach my $var (sort($self->Config()->varlist())){
      my $p=$self->Config->Param($var);
      if (ref($p) eq "HASH"){
         foreach my $k (sort(keys(%$p))){
            my $val=$p->{$k};
            $val=~s/>/&gt;/g;
            $val=~s/</&lt;/g;
            printf ("%s[%s] = \"%s\"<br>",$var,$k,$val);
         }
      }
      else{
         my $val=$p;
         $val=~s/>/&gt;/g;
         $val=~s/</&lt;/g;
         printf ("%s = \"%s\"<br>",$var,$val);
      }
   }
   print $self->HtmlBottom(body=>1);
}

sub Main
{
   my ($self)=@_;

   if ($ENV{HTTP_ACCEPT}=~m/wap.wml/){
      print $self->HttpHeader("text/wap");
      print(<<EOF);
<?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN" "http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <card id="eins">
    <p>
  	Dies ist <a href="xx">die</a> erste Card.
    </p>
<form>
<input type="text" name=hans>
</form>
  </card>
</wml>
EOF
   }
   else{
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>'default.css',
                              title=>$self->T($self->Self()));
      print("<xmp>");
      print("Enviroment:\n");
      print("===========\n");
      foreach my $v (sort(keys(%ENV))){
         my $val=$ENV{$v};
         $val=~s/\n/\\n/g;
         printf("%-25s='%s'\n",$v,$val);
      }
      my $httpHeaders=Query->HttpHeader();
      if (keys(%$httpHeaders)){
         print("\n\n");
    
         print("Request-Header:\n");
         print("===============\n");
         foreach my $v (sort(keys(%$httpHeaders))){
            my $val=$httpHeaders->{$v};
            $val=~s/\n/\\n/g;
            printf("%-25s='%s'\n",$v,$val);
         }
      }

      
     
      print("</xmp>");
      print $self->HtmlBottom(body=>1,form=>1);
   }
}


1;
