package tsacinv::ext::globalOpValidate;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub checkAgainstAM
{
   my $self=shift;
   my $dataobj=shift;
   my $systemid=shift;

   if ($systemid ne ""){
      my $asys=getModuleObject($dataobj->Config,"tsacinv::system");
      if (defined($asys) && $asys->Ping()){
         $asys->SetFilter({systemid=>\$systemid});
         my ($amrec)=$asys->getOnlyFirst(qw(systemid services
                                            orderedservices));
         #print STDERR "amrec".Dumper($amrec);
         my $relServices=0;
         foreach my $svcRec (@{$amrec->{orderedservices}}){
            if ($svcRec->{bmonthly}){
               $relServices++;
            }
         }

         if ($relServices>0){
            $dataobj->LastMsg(ERROR,
              "The chosen operation is invalid in case ".
              "there are active services in AssetManager on the ".
              "current system");
            msg(ERROR,"invalid operation tried on SystemID $systemid");
            return(0);
         }
      }
      else{
         $dataobj->LastMsg(ERROR,
                "can not validate operation against AssetManager");
         msg(ERROR,"can not contact AssetManager for op check on ".
                   " SystemID $systemid");
         return(0);
      }
   }
   return(1);
}

sub Validate
{
   my $self=shift;
   my $dataobj=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if ($dataobj->SelfAsParentObject() eq "itil::system"){
      if (effVal($oldrec,$newrec,"srcsys") ne "AssetManager" &&
          effChanged($oldrec,$newrec,"cistatusid")){
         if (($oldrec->{cistatusid}<5 &&    # deaktivieren
              $newrec->{cistatusid}>4) ||   
             ($oldrec->{cistatusid}<5 &&    # reserviieren
              $newrec->{cistatusid}<3)){
            my $o=getModuleObject($dataobj->Config,"TS::system");
            my $id=effVal($oldrec,$newrec,"id");
            $o->SetFilter({id=>\$id});
            my ($sysrec)=$o->getOnlyFirst(qw(systemid));
            if (defined($sysrec)){
               my $systemid=$sysrec->{systemid};
               return(0) if (!$self->checkAgainstAM($dataobj,$systemid));
            }
         }
      }
   }

   return(1)
}

sub ValidateDelete
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   if ($dataobj->SelfAsParentObject() eq "itil::system"){
      if ($rec->{srcsys} ne "AssetManager" && 
          ($rec->{cistatusid}==3 ||
           $rec->{cistatusid}==4)){
         my $o=getModuleObject($dataobj->Config,"TS::system");
         my $id=$rec->{id};
         $o->SetFilter({id=>\$id});
         my ($sysrec)=$o->getOnlyFirst(qw(systemid));
         if (defined($sysrec)){
            my $systemid=$sysrec->{systemid};
            return(0) if (!$self->checkAgainstAM($dataobj,$systemid));
         }
      }
   }
   return(1);
}





1;
