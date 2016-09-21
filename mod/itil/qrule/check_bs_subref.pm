package itil::qrule::check_bs_subref;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every BusinessService CI-Status "installed/active","inactiv/stored" 
or "available", needs to have ONLY sub businessservices in the 
same CI-State.
For State (=alloed):
available/in project = available/in project;installed/activ
installed/activ      = installed/activ
inactiv/stored       = available/in project;installed/activ;inactiv/stored

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
   return(["itil::businessservice"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my @msg;

   return(0,undef) if ($rec->{cistatusid}!=3 && 
                       $rec->{cistatusid}!=4 &&
                       $rec->{cistatusid}!=5);

   my @okstate;
   if ($rec->{cistatusid}==3){
      @okstate=qw(3 4);
   }
   elsif ($rec->{cistatusid}==4){
      @okstate=qw(4);
   }
   elsif ($rec->{cistatusid}==5){
      @okstate=qw(3 4 5);
   }
   my $bs=getModuleObject($self->getParent->Config,"itil::businessservice");
   my $appl=getModuleObject($self->getParent->Config,"itil::appl");

   foreach my $s (@{$rec->{servicecomp}}){
      if ($s->{objtype} eq $bs->SelfAsParentObject()){
         $bs->ResetFilter();
         $bs->SetFilter({id=>\$s->{obj1id}});
         my ($orec,$msg)=$bs->getOnlyFirst(qw(id fullname cistatusid));
         if (!defined($orec)){
            push(@msg,"sub element can not be resolved");
         }
         else{
            if (!in_array(\@okstate,$orec->{cistatusid})){
               push(@msg,"invalid state in sub elemente: ".$orec->{fullname});
            }
         }
      }
      if ($s->{objtype} eq $appl->SelfAsParentObject()){
         $appl->ResetFilter();
         $appl->SetFilter({id=>\$s->{obj1id}});
         my ($orec,$msg)=$appl->getOnlyFirst(qw(id name cistatusid));
         if (!defined($orec)){
            push(@msg,"sub element can not be resolved");
         }
         else{
            if (!in_array(\@okstate,$orec->{cistatusid})){
               push(@msg,"invalid state in sub elemente: ".$orec->{name});
            }
         }
      }
   }



   if ($#msg!=-1){
      return(3,{qmsg=>\@msg, dataissue=>\@msg});
   }
   return(0,undef);

}



1;
