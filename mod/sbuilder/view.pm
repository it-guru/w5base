package sbuilder::view;
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
use kernel::TemplateParsing;
use CGI;
@ISA=qw(kernel::App::Web kernel::TemplateParsing);

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
   my ($func,$p)=$self->extractFunctionPath();

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(form=>1,multipart=>1,body=>1,
                           title=>$self->T($self->Self()));
   print $self->getParsedTemplate("tmpl/".$p,{
                                   static=>{
                                       LOGHEAD=>"",
                                           LOG=>"",
                                      LOGSTYLE=>""}
                                  });
   print $self->HtmlBottom(body=>1,form=>1);
}

sub findtemplvar
{
   my $self=shift;
   my $opt=shift;
   my $var=shift;
   my @param=@_;

   if ($var eq "LISTDATAOBJ"){
      my $oname=shift(@param);
      my $o=$self->getPersistentModuleObject($oname,$oname);
      if (defined($o)){
         my $d="";
         $o->ResetFilter();
         $o->SetCurrentView($param[0]);
         my ($rec,$msg)=$o->getFirst();
         my %v;
         if (defined($rec)){
            do{
               $v{$rec->{$param[0]}}=1;
               ($rec,$msg)=$o->getNext();
            } until(!defined($rec));
         }
         foreach my $v (sort(keys(%v))){
            $d.="<tr><td>$v</td></tr>";
         }
         return($d);
      }
      return("&lt;invalid object '".$oname."&gt;");
   }

   return($self->SUPER::findtemplvar($opt,$var,@param));
}





1;
