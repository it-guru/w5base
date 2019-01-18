package tsotc::sysreq;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>"id"),

      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoineditbase =>{cistatusid=>">1 AND <6"},
                vjoinon       =>['applid'=>'id'],
                readonly      =>\&attrReadOnly,
                vjoindisp      =>'name'),

      new kernel::Field::Interface(
                name          =>'applid',
                label         =>'ApplicationID',
                dataobjattr   =>'appl'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'internal system alias',
                readonly      =>\&attrReadOnly,
                dataobjattr   =>"aliassysname"),

      new kernel::Field::Select(
                name          =>'reqstatus',
                selectfix     =>1,
                label         =>'request status',
                getPostibleValues=>\&calcPostibleReqStatus,
                transprefix   =>'reqstatus.',
                htmleditwidth =>'350px',
                dataobjattr   =>'reqstatus'),

      new kernel::Field::Interface(
                name          =>'reqstatusid',
                label         =>'raw request status',
                dataobjattr   =>'reqstatus'),

      new kernel::Field::Select(
                name          =>'opmode',
                label         =>'operation mode',
                readonly      =>\&attrReadOnly,
                transprefix   =>'opmode.',
                value         =>['',
                                 'prod',
                                 'test',
                                 'devel'],
                htmleditwidth =>'200px',
                dataobjattr   =>'opmode'),

      new kernel::Field::Interface(
                name          =>'rawopmode',
                label         =>'raw operation mode',
                dataobjattr   =>'opmode'),

      new kernel::Field::Select(
                name          =>'systemclass',
                label         =>'system classification',
                transprefix   =>'sysclass.',
                readonly      =>\&attrReadOnly,
                value         =>['',
                                 'applserver',
                                 'webserver',
                                 'databasesrv'],
                htmleditwidth =>'200px',
                dataobjattr   =>'systemclass'),

      new kernel::Field::Interface(
                name          =>'rawsystemclass',
                label         =>'raw system classification',
                dataobjattr   =>'systemclass'),

      new kernel::Field::Select(
                name          =>'osrelease',
                htmleditwidth =>'80%',
                label         =>'OS-Release',
                vjointo       =>'itil::osrelease',
                readonly      =>\&attrReadOnly,
                vjoineditbase =>{'cistatusid'=>[3,4],
                                 'id'=>[qw(
                                       13762946430019
                                       15193848570001
                                       15434971640001
                                       15434971730003
                                       15434971380001
                                       15434971330001
                                       13
                                       15434971000001
                                       15434970690001
                                       15434970770001
                                  )]},
                allowEmpty    =>1,
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'osreleaseid',
                label         =>'raw OS-Release',
                dataobjattr   =>'osrelease'),

      new kernel::Field::Number(
                name          =>'cpucount',
                editrange     =>[1,60],
                label         =>'CPU-Count',
                readonly      =>\&attrReadOnly,
                htmleditwidth =>'100px',
                dataobjattr   =>'cpucount'),

      new kernel::Field::Number(
                name          =>'memory',
                label         =>'Memory',
                readonly      =>\&attrReadOnly,
                unit          =>'MB',
                htmleditwidth =>'100px',
                editrange     =>[1,940*1024],
                dataobjattr   =>'memory'),

      new kernel::Field::SubList(
                name          =>'storage',
                label         =>'Storage',
                group         =>'storage',
                vjointo       =>\'tsotc::sysreqfs',
                vjoinon       =>['id'=>'sysreqid'],
                vjoindisp     =>['fsentry','fssize']),

      new kernel::Field::Text(
                name          =>'osclass',
                label         =>'OS-Class',
                vjointo       =>'itil::osrelease',
                readonly      =>1,
                group         =>'source',
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'osclass'),

      new kernel::Field::Text(
                name          =>'srcsys',
                selectfix     =>1,
                htmldetail    =>'NotEmpty',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'editor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(id,35,'0')"),

   );
   $self->setDefaultView(qw(name reqstatus appl cpucount memory));
   $self->setWorktable("tsotc_sysreq");
   return($self);
}


sub attrReadOnly
{
   my $self=shift;
   my $current=shift;

   my $reqstatus;
   $reqstatus=$current->{reqstatus} if (defined($current));
   my $isController=$self->getParent->isController($current);


   if ($reqstatus>1 &&   # parameters that can never change after 1st deployment
       in_array([qw(appl opmode osrelease systemclass)],$self->Name())){
      return(1);
   }
   if ($reqstatus eq "2" && !$isController &&
       in_array([qw(name systemclass appl memory 
                    cpucount opmode)],$self->Name())){
      return(1);
   }
   return(0);
}


sub calcPostibleReqStatus
{
   my $self=shift;
   my $current=shift;
   my $newrec=shift;

   my $app=$self->getParent;

   my @l;

   if (!defined($current) || $current->{reqstatus} eq "1"){
      push(@l,"1",$app->T("(1) reserved"));
   }
   if (defined($current)){
      if ($current->{reqstatus} eq "1" ||
          $current->{reqstatus} eq "2"){
         push(@l,"2",$app->T("(2) deployment on order"));
      }
      if ($current->{reqstatus} eq "2"){
         if ($app->isController($current)){
            push(@l,"4",$app->T("(4) installed/active"));
            push(@l,"3",$app->T("(3) deployment in process"));
            push(@l,"99",$app->T("(99) deployment rejected"));
         }
         #if ($app->IsMemberOf("admin")){  # eingriffs m�glichkeit f�r Admins
         #   push(@l,"1",$app->T("(1) reserved"));
         #}
      }
      if ($current->{reqstatus} eq "3"){
         push(@l,"3",$app->T("(3) deployment in process"));
         if ($app->isController($current)){
            push(@l,"4",$app->T("(4) installed/active"));
            push(@l,"99",$app->T("(99) deployment rejected"));
         }
         #if ($app->IsMemberOf("admin")){  # eingriffs m�glichkeit f�r Admins
         #   push(@l,"1",$app->T("(1) reserved"));
         #}
      }
      if ($current->{reqstatus} eq "4"){
         push(@l,"4",$app->T("(4) installed/active"));
         if ($app->isRequestor($current)){
            push(@l,"5",$app->T("(5) prepair update"));
            push(@l,"10",$app->T("(10) rundown on order"));
         }
      }
      if ($current->{reqstatus} eq "5"){
         if ($app->isController($current)){
            push(@l,"6",$app->T("(6) disposed of waste"));
         }
      }
      if ($current->{reqstatus} eq "6"){
         push(@l,"8",$app->T("(8) update on order"));
      }
      if ($current->{reqstatus} eq "10"){
         push(@l,"10",$app->T("(10) rundown on order"));
         if ($app->isRequestor($current)){
            push(@l,"4",$app->T("(4) installed/active"));
         }
      }
      if ($current->{reqstatus} eq "11"){
         push(@l,"11",$app->T("(11) rundown in process"));
         if ($app->isController($current)){
            push(@l,"90",$app->T("(90) disposed of waste"));
         }
      }
      if ($current->{reqstatus} eq "90"){
         push(@l,"90",$app->T("(90) disposed of waste"));
      }
      if ($current->{reqstatus} eq "99"){
         push(@l,"99",$app->T("(99) deployment rejected"));
      }
   }

   return(@l);
}


sub isController
{
   my $self=shift;
   my $rec=shift;

   if ($self->IsMemberOf([qw(w5base.tsotc.controller)])){
      return(1);
   }
   return(0);

}


sub isRequestor
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();

   return(1) if (defined($rec) && $rec->{creator} eq $userid);

   my $appid=$rec->{applid};

   if ($appid ne ""){
      my @v=qw(tsmid tsm2id applmgrid opmid opm2id);
      my $p=$self->getPersistentModuleObject($self->Config,"itil::appl");

      $p->SetFilter({id=>\$appid});
      my ($apprec)=$p->getOnlyFirst(@v);
      if (defined($apprec)){
         foreach my $fld (@v){
            if ($apprec->{$fld} eq $userid){
               return(1);
            }
         }
      }
   }
   return(0);

}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;

   if (!defined($oldrec)){
      if (!$self->isRequestor({applid=>$newrec->{applid}})){
         $self->LastMsg(ERROR,"no permission to request systems for specified application");
         return(0);
      }
   }

   my $reqstatus;
   if (defined($oldrec)){
      $reqstatus=$oldrec->{reqstatus};
   }
   if (!defined($oldrec) && ! exists($newrec->{reqstatus})){
      $newrec->{reqstatus}=1;
   }
   my $iname=effVal($oldrec,$newrec,"name");
   if (length($iname)<3 || haveSpecialChar($iname)){
      $self->LastMsg(ERROR,"invalid internal system alias");
      return(0);
   }

   if (effChanged($oldrec,$newrec,"osreleaseid")){
      if (defined($oldrec) && $#{$oldrec->{storage}}!=-1){
         my $oldreleaseid=$oldrec->{osreleaseid};
         my $newreleaseid=$newrec->{osreleaseid};
         if ($oldreleaseid ne ""){
            my $o=getModuleObject($self->Config,"itil::osrelease");
            $o->SetFilter({id=>[$oldreleaseid,$newreleaseid]});
            $o->SetCurrentView(qw(id osclass));
            my $i=$o->getHashIndexed("id");
            if ($i->{id}->{$oldreleaseid}->{osclass} ne 
                $i->{id}->{$newreleaseid}->{osclass}){
               $self->LastMsg(ERROR,"os change not supported, ".
                                    "with existing storeage");
               return(0);
            }
         }
      }
   }

   if ($reqstatus eq "1" && $newrec->{reqstatus} eq "2"){
      # initiate deployment request
      if (effVal($oldrec,$newrec,"cpucount") eq ""){
         $self->LastMsg(ERROR,"missing definition for cpu count");
         return(0);
      }
      if (effVal($oldrec,$newrec,"memory") eq ""){
         $self->LastMsg(ERROR,"missing definition for memory");
         return(0);
      }
      if (effVal($oldrec,$newrec,"opmode") eq ""){
         $self->LastMsg(ERROR,"missing definition for operation mode");
         return(0);
      }
      if (effVal($oldrec,$newrec,"systemclass") eq ""){
         $self->LastMsg(ERROR,"missing definition for system classification");
         return(0);
      }
      my $foundroot=0;
      if (effVal($oldrec,$newrec,"osclass") eq "WIN"){
         foreach my $fsrec (@{$oldrec->{storage}}){
            if ($fsrec->{fsentry} eq "C:"){
               $foundroot++;
               last;
            }
         }
      }
      else{
         foreach my $fsrec (@{$oldrec->{storage}}){
            if ($fsrec->{fsentry} eq "/"){
               $foundroot++;
               last;
            }
         }
      }
      if (!$foundroot){
         $self->LastMsg(ERROR,"missing root filesystem");
         return(0);
      }
   }
   if ($reqstatus eq "2" && $newrec->{reqstatus} eq "4"){
      # deployment successfull

   }



   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","storage");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));

   if ($rec->{reqstatus} eq "90" || $rec->{reqstatus} eq "99"){
      return(undef);
   }
   if ($self->isRequestor($rec)){
      if ($rec->{reqstatus} eq "1"){
         return("default","storage");
      }
      return("default");
   }
   if ($self->isController($rec)){
      return("default");
   }
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (defined($rec) && 
                 $rec->{reqstatus} eq "1" ||
                 $rec->{reqstatus} eq "10");
                
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


1;