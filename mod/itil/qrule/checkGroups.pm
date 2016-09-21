package itil::qrule::checkGroups;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This qulaity rule checks the CI-Status of the groups, references in
businessteam, serviceteam and customer.

=cut

#######################################################################
#######################################################################
#
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
   return(["itil::appl","itil::system",
           "itil::swinstance","itil::custcontract"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3 &&
                       $rec->{cistatusid}!=5);
   my $wfrequest={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   foreach my $fobj ($dataobj->getFieldObjsByView([qw(ALL)],
                                           oldrec=>$rec)){
      if ($fobj->Type() eq "Group"){
         my $name=$fobj->Name();
         next if ($fobj->{vjointo} ne "base::grp");
         my $localfield=$fobj->{vjoinon}->[0];
         my $lfobj=$dataobj->getField($localfield);
         my $ldata=$lfobj->RawValue($rec);
         if ($ldata eq "-2"){
            push(@qmsg,"not acceptable group reference anonymous in: ".$name);
         }
         if ($ldata ne ""){
            my $joinobj=$fobj->vjoinobj();
            $joinobj->SetFilter({$fobj->{vjoinon}->[1]=>\$ldata});
            my ($grec,$msg)=$joinobj->getOnlyFirst(qw(cistatusid fullname));
            if (!defined($grec)){
               push(@qmsg,"target group seems to be deleted: ".$name);
            }
            else{
               if ($grec->{cistatusid}==6){
                  push(@qmsg,"target group is marked as deleted: ".
                             $name." ($grec->{fullname})");
               }
            }
         }
      }
   }
   if ($#qmsg==-1){
      return(0,undef);
   }
   return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
}



1;
