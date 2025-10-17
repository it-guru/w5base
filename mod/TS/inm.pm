package TS::inm;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
   return(qw(ById));
}

sub ById
{
   my $self=shift;

   return(
      $self->simpleRESTCallHandler(
         "ExpandPath",
         {
            incidentid=>{
               typ=>'STRING',
               mandatory=>1,
               path=>0
            }
         },undef,\&doById,@_)
   );
}






sub doById
{
   my $self=shift;
   my $param=shift;

   my $val="undefined";
   if (exists($param->{incidentid})){
      $val=$param->{incidentid};
   }
   $val=~s/^\///;
   $val=~s/[^a-z0-9]//gi;

   msg(INFO,"try to find inm location for $val");

   my $sm=$self->getPersistentModuleObject("sm9","tssm::inm");
  # my $sn=$self->getPersistentModuleObject("snow","tssnow::inm");

   my @flt;
   if ($val=~m/^IM/){
      push(@flt,{incidentnumber=>\$val});
   }
   if ($val=~m/^INC/){
      push(@flt,{srcsys=>\'TS_SN_INM',srcid=>\$val});
   }
   if ($#flt!=-1){
      $sm->SetFilter(\@flt);
      my ($chkrec,$msg)=$sm->getOnlyFirst(qw(urlofcurrentrec));
      if (defined($chkrec) && $chkrec->{urlofcurrentrec} ne ""){
         $self->HtmlGoto($chkrec->{urlofcurrentrec});
         return(-1);
      }
   }
   if ($val=~m/^INC/){
     # $sn->SetFilter({incidentnumber=>\$val});
     # my ($chkrec,$msg)=$sn->getOnlyFirst(qw(urlofcurrentrec));
     # if (defined($chkrec) && $chkrec->{urlofcurrentrec} ne ""){
     #    $self->HtmlGoto($chkrec->{urlofcurrentrec});
         return(-1);
     # }
   }
   printf("Status: 404 Forbidden - ".
          "account needs to be activated with web browser\n");
   printf("Content-type: text/html\n\n".
          "<h1>404 not found!</h1>");

   return(-1);
}

