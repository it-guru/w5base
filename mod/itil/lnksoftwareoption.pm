package itil::lnksoftwareoption;
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
use itil::lnksoftware;
use kernel;
@ISA=qw(itil::lnksoftware);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!defined($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Interface(
                name          =>'parentid',
                label         =>'parent product id',
                dataobjattr   =>'lnksoftwaresystem.parent'),
   );


   

   $self->getField("itclustsvc")->{uivisible}=0;
   $self->getField("itclustsvc")->{searchable}=0;
   $self->getField("itclustsvcid")->{searchable}=0;
   $self->getField("itclustsvcid")->{uivisible}=0;

   $self->getField("fullname")->{label}="Option label";
   $self->getField("system")->{searchable}=0;
   $self->getField("software")->{vjoineditbase}=[{pclass=>\'OPTION',
                                                  cistatusid=>[3,4]}];
   $self->getField("system")->{uivisible}=0;
   $self->getField("systemid")->{searchable}=0;
   $self->getField("systemid")->{uivisible}=0;
   $self->getField("softwareinstpclass")->{uivisible}=0;
   $self->getField("options")->{uivisible}=0;
   $self->getField("insoptionlist")->{uivisible}=0;
   $self->setDefaultView(qw(software version quantity system cdate));
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $parentid=effVal($oldrec,$newrec,"parentid");

   if ($parentid eq ""){
      $self->LastMsg(ERROR,"no parentid specifed");
      return(undef);
   }
   if (!defined($oldrec)){
      my $s=getModuleObject($self->Config,"itil::lnksoftware");
      $s->SetFilter({id=>\$parentid});
      my ($prec,$msg)=$s->getOnlyFirst(qw(softwareinstpclass softwareid));
      if (!defined($prec)){
         $self->LastMsg(ERROR,"invalid parent installation specifed");
         return(undef);
      }
      if ($prec->{softwareinstpclass} ne "MAIN"){
         $self->LastMsg(ERROR,"parent installation is not a MAIN installation");
         return(undef);
      }
      $newrec->{systemid}=$prec->{systemid};
      $newrec->{itclustsvcid}=$prec->{itclustsvcid};
      my $softwareid=effVal($oldrec,$newrec,"softwareid");
      if ($softwareid eq ""){
         $self->LastMsg(ERROR,"invalid softwareid");
         return(undef);
      }
      my $sp=getModuleObject($self->Config,"itil::software");
      $sp->SetFilter({id=>\$softwareid});
      my ($sprec,$msg)=$sp->getOnlyFirst(qw(parentid));
      if (!defined($sprec)){
         $self->LastMsg(ERROR,"can not find software product record");
         return(undef);
      }
      if ($sprec->{parentid} ne $prec->{softwareid}){
         $self->LastMsg(ERROR,"option not allowed for selected product");
         return(undef);
      }
   }

   my $bk=$self->SUPER::Validate($oldrec,$newrec,$origrec);
   return($bk) if (!$bk);
   return(1);
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="software.productclass='OPTION'";
   return($where);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my $from="lnksoftwaresystem left outer join software ".
            "on lnksoftwaresystem.software=software.id ".
            "left outer join lnkitclustsvc ".
            "on lnksoftwaresystem.lnkitclustsvc=lnkitclustsvc.id ".
            "left outer join itclust ".
            "on lnkitclustsvc.itclust=itclust.id ".
            "left outer join system ".
            "on lnksoftwaresystem.system=system.id ".
            "left outer join liccontract ".
            "on lnksoftwaresystem.liccontract=liccontract.id ".
            "join lnksoftwaresystem as plnksoftware ".
            "on lnksoftwaresystem.parent=plnksoftware.id ".
            "left outer join licproduct ".
            "on liccontract.licproduct=licproduct.id ";


   return($from);
}

sub SecureValidate    # needed to allow updates in SubList Edit mode
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (defined($oldrec)){ 
      delete($newrec->{software});
      delete($newrec->{softwareid});
      delete($newrec->{parentid});
   }

   return($self->SUPER::SecureValidate($oldrec,$newrec));
}











1;
