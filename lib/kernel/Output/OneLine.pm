package kernel::Output::OneLine;
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
use base::load;
use kernel::FormaterMultiOperation;
@ISA    = qw(kernel::FormaterMultiOperation);



sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;
   my %param=@_;
 
   return(1) if ($param{mode} eq "Init"); 
   my $app=$self->getParent()->getParent;
#   my @l=$app->getCurrentView();
#   if ($#l==0){
#      return(1);
#   }
   return(1);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_asctab.gif");
}
sub Label
{
   return("Output to one line");
}
sub Description
{
   return("Writes in one ASCII line.");
}

sub MimeType
{
   return("text/html");
}

sub getEmpty
{
   my $self=shift;
   my %param=@_;
   my $d="";
   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }
   return($d);
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".txt");
}

sub getHttpHeader
{  
   my $self=shift;
   my $d="";
   $d.="Content-type:".$self->MimeType().";charset=iso-8859-1\n\n";
   return($d);
}

sub quoteData
{
   my $d=shift;

   $d=~s/;/\\;/g;
   $d=~s/\r\n/\\n/g;
   $d=~s/\n/\\n/g;
   return($d); 
}

sub MultiOperationTableHeader
{
   my $self=shift;

   my $d=undef;

   return($d);
}

sub ProcessLine
{
   my $self=shift;

   return($self->kernel::Formater::ProcessLine(@_));
}



sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
 

   my @l=$app->getCurrentView();
   my @useField=Query->Param("useField");
   my $d=$self->SUPER::ProcessHead($fh,$rec,$msg);

   if ($#l!=0){
      $d.="<table class=freeform width=95% border=0>";
      $d.="<tr>";
      $d.="<td nowrap>";
      $d.="&nbsp;&nbsp;&nbsp;".
          "&nbsp;&nbsp;&nbsp;".
          "<select name=useField multiple size=5 style='width:95%'>";
      foreach my $fldname (@l){
         my $fld=$app->getField($fldname);
         if (defined($fld)){
            my $fldlabel=$fld->Label($rec);
            if ($fldlabel ne ""){
               $d.="<option value=\"$fldname\"";
               $d.=" selected" if (in_array(\@useField,$fldname));
               $d.=">";
               $d.=$fldlabel;
               $d.="</option>";
            }
         }
      }
      $d.="</select>";
      $d.="</td>";
      $d.="<td width=1% valign=bottom>";
      $d.="<input type=submit value=\"".
          $self->getParent->getParent->T("show",'kernel::Output::OneLine').
          "\">";
      $d.="</td>";
      $d.="</tr>";
      $d.="</table><br><br><hr>";
   }
   return($d);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d;

   my %l=();
   my @view=$app->getCurrentView();
   my @useField=Query->Param("useField");
   if ($#view==0){
      @useField=@view;
   }
   for(my $recno=0;$recno<=$#{$self->{recordlist}};$recno++){
      for(my $fieldno=0;$fieldno<=$#{$self->{recordlist}->[$recno]};$fieldno++){
         if (in_array(\@useField,$view[$fieldno])){
            $l{$self->{recordlist}->[$recno]->[$fieldno]}++;
         }
      }
   }
   my @l=grep(!/^\s*$/,sort(keys(%l)));
   
   if (grep(/^\S+\@\S+\.\S+$/,@l)){   # output seems to be an email list
      $d.=join("; ",@l);
   }
   elsif (!grep(/\s/,@l)){
      $d.=join(" ",@l);
   }
   elsif (!grep(/,/,@l)){
      $d.=join(", ",@l);
   }
   elsif (!grep(/;/,@l)){
      $d.=join("; ",@l);
   }
   elsif (!grep(/\t/,@l)){
      $d.=join("\t",@l);
   }
   $d.="\r\n<br><br>";
   $d.=$app->HtmlBottom(form=>1,body=>1);
   return($d);
}

1;
