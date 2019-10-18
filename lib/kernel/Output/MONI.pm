package kernel::Output::MONI;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use kernel::Formater;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   return(0);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_asctab.gif");
}
sub Label
{
   return("Monitor-Formater");
}
sub Description
{
   return("Format is a nice table only");
}

sub MimeType
{
   return("text/plain");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".txt");
}


sub prepareParent
{
   my $self=shift;
   my $app=shift;

   $self->{HttpStatusCode}="900 backend error";
}


sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Status: ".$self->{HttpStatusCode}."\n";
   $d.="Content-type:".$self->MimeType().";charset=ISO-8895-1\n\n";

   return($d);
}


sub getEmpty
{
   my $self=shift;
   my %param=@_;
   $self->getParent->getParent->LastMsg(ERROR,"unexpected record count");
   $self->{HttpStatusCode}="901 unexpected record count";
   my $d=$self->getErrorDocument(%param);
   return($d);
}




sub getErrorDocument
{
   my $self=shift;
   my (%param)=@_;

   my @msg;
   if ($param{msg}){
      push(@msg,$param{msg});
   }
   push(@msg,$self->getParent->getParent->LastMsg());

   my $d="";
   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }

   $d.="FAIL\n";
   if ($#msg!=-1){
      @msg=map({$_.="\n" if (!($_=~m/\n$/s)); $_} @msg);
      $d.=join("",@msg);
      $d.="\n";
   }

   return($d);
}





sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my $app=$self->getParent->getParent();
   my @maxlist=();
   my $headlines=1;

   $self->{HttpStatusCode}="200 OK";
   if ($#{$self->{recordlist}}!=0){
      $self->getParent->getParent->LastMsg(ERROR,"unexpected record count");
      $self->{HttpStatusCode}="901 unexpected record count";
      return($self->getErrorDocument());
   }

   my %search=$app->getSearchHash();
   my %searchCol;

   foreach my $fldname (keys(%search)){
      for(my $c=0;$c<=$#{$self->{fieldobjects}};$c++){
         if ($self->{fieldobjects}->[$c]->Name() eq $fldname){
            $searchCol{$fldname}=$c;
         }
      }
   }
   if (keys(%search)!=keys(%searchCol)){
      $self->getParent->getParent->LastMsg(ERROR,
                                           "unexpected column count in result");
      $self->{HttpStatusCode}="902 unexpected column count in result";
      return($self->getErrorDocument());
   }

   my $rec=$self->{recordlist}->[0];

   my $allMatch=1;

   if (!keys(%searchCol)){
      $allMatch=0;
   }

   foreach my $fldName (keys(%searchCol)){
      my $colnum=$searchCol{$fldName};
      my $recfldval=$rec->[$colnum];
      if ($recfldval ne $search{$fldName}){
         $allMatch=0;
      }
   }
   if (!$allMatch){
      $self->getParent->getParent->LastMsg(ERROR,
                                           "unexpected field value in result");
      $self->{HttpStatusCode}="903 unexpected field value in result";
      return($self->getErrorDocument());
   }
   $d="OK\n";
   return($d);
}

1;
