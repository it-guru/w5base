package base::qrule::MandatorCheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

If there is a mandator record which is not deleted, but referes to
a group which is marked as "disposed of wasted", this will produce
a DataIssue for admins.
The admin needs to cleanup posible existing datas and set the 
mandator also to "disposed of wasted".

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["base::mandator"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my @failmsg;

   if ($self->isQruleApplicable($rec)){
      my $grpid=$rec->{grpid};
      if ($grpid eq "" || $grpid eq "0" || $grpid eq "-1"){
         push(@failmsg,"missing correct group relation");
      }
      else{
         my $grp=getModuleObject($dataobj->Config,"base::grp");
         $grp->SetFilter({grpid=>\$grpid});
         my @l=$grp->getHashList(qw(cistatusid grpid));
         if ($#l!=0){
            push(@failmsg,"no or not unique group entry");
         }
         else{
            if ($l[0]->{cistatusid}==6){
               push(@failmsg,"mandator points to a deleted group");
            }
         }
      }
   }


   if ($#failmsg!=-1){
      return(3,{qmsg=>[@failmsg],dataissue=>[@failmsg]});
   }

   return(0,undef);
}

sub isQruleApplicable
{
   my $self=shift;
   my $rec=shift;

   if ($rec->{cistatusid}<6){
      return(1);
   }
   return(0);
}



1;
