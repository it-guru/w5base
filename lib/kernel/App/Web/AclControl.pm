package kernel::App::Web::AclControl;
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
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
  
   $self->{acltable}="acl" if (!defined($self->{acltable})); 
   my $acltable=$self->{acltable};
   my $modes=['read','write'];
   my $modestranslation=$self->Self;
   if (defined($self->{param})){
      if (defined($self->{param}->{modes})){
         $modes=$self->{param}->{modes};
      }
      if (defined($self->{param}->{translation})){
         $modestranslation=$self->{param}->{translation};
      }
   }
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'aclid',
                label         =>'AclID',
                dataobjattr   =>$acltable.'.aclid'),

      new kernel::Field::Text(
                name          =>'refid',
                frontreadonly =>1,
                selectfix     =>1,
                label         =>'ReferenceID',
                dataobjattr   =>$acltable.'.refid'),

      new kernel::Field::Text(
                name          =>'aclparentobj',
                frontreadonly =>1,
                selectfix     =>1,
                label         =>'AclParentObj',
                dataobjattr   =>$acltable.'.aclparentobj'),

      new kernel::Field::MultiDst (
                name          =>'acltargetname',
                htmlwidth     =>'450',
                htmleditwidth =>'400',
                label         =>'Target-Name',
                dst           =>['base::grp' =>'fullname',
                                 'base::user'=>'fullname'],
                vjoineditbase =>[{'cistatusid'=>[3,4]},
                                 {'cistatusid'=>[4]}
                                ],
                dsttypfield   =>'acltarget',
                dstidfield    =>'acltargetid'),

      new kernel::Field::Select(
                name          =>'aclmode',
                label         =>'Acl-Mode',
                htmleditwidth =>'100',
                value         =>$modes,
                translation   =>$modestranslation,
                default       =>'read',
                dataobjattr   =>$acltable.'.aclmode'),

      new kernel::Field::Text(
                name          =>'posix',
                htmlwidth     =>'130',
                label         =>'Posix',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['acltargetid'=>'userid'],
                vjoindisp     =>'posix'),


      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>$acltable.'.expiration'),

      new kernel::Field::Select(
                name          =>'alertstate',
                value         =>['','yellow','orange',
                                 'red'],
                uivisible     =>sub{
                    my $self=shift;
                    my $mode=shift;
                    my $app=$self->getParent;
                    my %param=@_;
                    return(1) if (!defined($param{current}));
                    return(1) if (
                       $param{current}->{alertstate} ne "");
                    return(0);
                },
                readonly      =>1,
                label         =>'Alert-State',
                dataobjattr   =>$acltable.'.alertstate'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>$acltable.'.comments'),


      new kernel::Field::Link(
                name          =>'acltarget',
                label         =>'Target-Typ',
                dataobjattr   =>$acltable.'.acltarget'),

      new kernel::Field::Link(
                name          =>'acltargetid',
                dataobjattr   =>$acltable.'.acltargetid'),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                dataobjattr   =>$acltable.'.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                dataobjattr   =>$acltable.'.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                label         =>'Editor',
                dataobjattr   =>$acltable.'.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                label         =>'RealEditor',
                dataobjattr   =>$acltable.'.realeditor'),
   );
   $self->setDefaultView(qw(aclid refid acltargetname));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable($self->{acltable});
   return(1);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   if ((!defined($oldrec) && !defined($newrec->{refid})) ||
       (defined($newrec->{refid}) && $newrec->{refid}==0)){
      $self->LastMsg(ERROR,"no '%s' specified",
                           $self->getField("refid")->Label());
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{acltargetid})) ||
       (defined($newrec->{acltargetid}) && $newrec->{acltargetid}==0)){
      $self->LastMsg(ERROR,"no '%s' specified",
                           $self->getField("acltargetname")->Label());
      return(undef);
   }
   if (defined($self->getParent)){
      $newrec->{aclparentobj}=$self->getParent->SelfAsParentObject();
   }
   my $parentobj=effVal($oldrec,$newrec,"aclparentobj");
   if ($parentobj eq ""){
      $newrec->{aclparentobj}=$self->getParent;
   }
   my $parentobj=effVal($oldrec,$newrec,"aclparentobj");
   my $refid=effVal($oldrec,$newrec,"refid");

   if ($refid ne ""){
      my $pobj;
      if ($parentobj ne ""){
         $pobj=getModuleObject($self->Config,$parentobj);
      }
      if (defined($pobj)){
         if ($self->isDataInputFromUserFrontend()){
            if (!$self->checkParentWriteAccess($pobj,$refid)){
               $self->LastMsg(ERROR,"insufficient access to parent object");
               return(undef);
            }
         }
      }
      else{
         $self->LastMsg(ERROR,"no parentobj specified");
         return(undef);
      }
   }
   else{
      $self->LastMsg(ERROR,"no refid specified");
      return(undef);
   }
   return(1);
}

sub checkParentWriteAccess
{
   my $self=shift;
   my $pobj=shift;
   my $refid=shift;
   my $mode=shift;

   if ($refid eq ""){
      $self->LastMsg(ERROR,"invalid '%s' specified",
                        $self->getField("refid")->Label());
   }
   $pobj->SetFilter({$pobj->IdField->Name()=>\$refid});
   my @l=$pobj->getHashList(qw(ALL));
   if ($#l==-1){
      # Elternobjekt scheint nicht mehr zu existieren
      if ($refid ne "" && !($refid=~m/[\*\?]/) &&
          $pobj->Ping() && $mode eq "delete"){
         #msg(INFO,"Cleanup on none existing parent record '$pobj' '$refid'");
         return(1);
      }
      $self->LastMsg(ERROR,"invalid refid specified '%s' in %s",
                     $refid,$pobj->Self);
      return(0); # parent object id does not exists
   }
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid '%s' specified '%s'",
                        $self->getField("refid")->Label(),$refid);
      return(undef);
   }
   my $prec=$l[0];
   my @grps=$pobj->isWriteValid($prec);
   if (!grep(/^acls$/,@grps) &&
       !grep(/^acl$/,@grps) &&
       !grep(/^ALL$/,@grps)){
      #msg(INFO,"access only for '%s'\n",join(",",@grps));
      return(0);
   }

   return(1);
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;
   my $parentobj=$rec->{aclparentobj};
   my $refid=$rec->{refid};
   if ($refid ne ""){
      my $pobj;
      if ($parentobj ne ""){
         $pobj=getModuleObject($self->Config,$parentobj);
      }
      if (defined($pobj)){
         if (!$self->checkParentWriteAccess($pobj,$refid,"delete")){
            $self->LastMsg(ERROR,"insufficient access to parent object");
            return(undef);
         }
         return(1);
      }
      else{
         $self->LastMsg(ERROR,"no parentobj specified");
         return(undef);
      }
   }
   else{
      $self->LastMsg(ERROR,"no refid specified");
      return(undef);
   }
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{acltarget} eq "base::user"){
      return("default","header","userinfo");
   }
   if ($rec->{acltarget} eq "base::grp"){
      return("default","header");
   }
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if (!defined($rec));
   return("ALL") if (defined($self->getParent));
   return("ALL") if ($self->IsMemberOf("admin"));

   my $refid=$rec->{refid};
   my $parentobj=$rec->{aclparentobj};

   if ($refid ne ""){
      my $pobj;
      if ($parentobj ne ""){
         $pobj=getModuleObject($self->Config,$parentobj);
      }
      if (defined($pobj)){
         if ($self->checkParentWriteAccess($pobj,$refid)){
            return("ALL");
         }
      }
   }
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



   


1;
