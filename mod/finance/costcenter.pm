package finance::costcenter;
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
use finance::lib::Listedit;
@ISA=qw(finance::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);


   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'costcenter.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'200px',
                htmleditwidth =>'200px',
                label         =>'Costcenter',
                dataobjattr   =>'costcenter.name'),

      new kernel::Field::Text(
                name          =>'accarea',
                htmlwidth     =>'130px',
                htmleditwidth =>'130px',
                label         =>'Accounting Area',
                dataobjattr   =>'costcenter.accarea'),

      new kernel::Field::Select(
                name          =>'costcentertype',
                label         =>'Costcenter type',
                transprefix   =>'CC.',
                htmleditwidth =>'150px',
                value         =>[qw(costcenter costnode pspelement)],
                dataobjattr   =>'costcenter.costcentertype'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                selectfix     =>1,
                dataobjattr   =>'costcenter.cistatus'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'220px',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                label         =>'Costcenter label',
                dataobjattr   =>"if (costcenter.fullname<>'',".
                                "concat(costcenter.name,' : ',".
                                "costcenter.fullname),costcenter.name)"),

      new kernel::Field::Text(
                name          =>'shortdesc',
                htmlwidth     =>'220px',
                label         =>'Shortdescription',
                dataobjattr   =>'costcenter.fullname'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'costcenter.databoss'),

      new kernel::Field::Group(
                name          =>'delmgrteam',
                group         =>'delmgmt',
                AllowEmpty    =>1,
                label         =>'Service Delivery-Management Team',
                vjoinon       =>'delmgrteamid'),

      new kernel::Field::Link(
                name          =>'delmgrteamid',
                group         =>'delmgmt',
                dataobjattr   =>'costcenter.delmgrteam'),

      new kernel::Field::Contact(
                name          =>'delmgr',
                group         =>'delmgmt',
                label         =>'Service Delivery Manager',
                AllowEmpty    =>1,
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrid',
                group         =>'delmgmt',
                dataobjattr   =>'costcenter.delmgr'),

      new kernel::Field::Group(
                name          =>'itsemteam',
                group         =>'itsem',
                AllowEmpty    =>1,
                label         =>'IT Servicemanagement Team',
                vjoinon       =>'itsemteamid'),

      new kernel::Field::Link(
                name          =>'itsemteamid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsemteam'),

      new kernel::Field::Contact(
                name          =>'itsem',
                group         =>'itsem',
                label         =>'IT Servicemanager',
                AllowEmpty    =>1,
                vjointo       =>'base::user',
                vjoinon       =>['itsemid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'itsemid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsem'),


      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'finance::costcenter'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'costcenter.comments'),

      new kernel::Field::Text(
                name          =>'conodenumber',
                htmlwidth     =>'150px',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Costcenter-Number',
                dataobjattr   =>"if(instr(costcenter.name,'-'),".
                     "substr(costcenter.name,instr(costcenter.name,'-')+1,10),".
                     "costcenter.name)"),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'costcenter.allowifupdate'),

      new kernel::Field::Boolean(
                name          =>'isdirectwfuse',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'costcenter is direct useable by workflows',
                dataobjattr   =>'costcenter.is_directwfuse'),

      new kernel::Field::Contact(
                name          =>'delmgr2',
                group         =>'delmgmt',
                AllowEmpty    =>1,
                label         =>'Deputy Service Delivery Manager',
                vjointo       =>'base::user',
                vjoinon       =>['delmgr2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgr2id',
                group         =>'delmgmt',
                dataobjattr   =>'costcenter.delmgr2'),

      new kernel::Field::Contact(
                name          =>'itsem2',
                group         =>'itsem',
                AllowEmpty    =>1,
                label         =>'Deputy IT Servicemanager',
                vjointo       =>'base::user',
                vjoinon       =>['itsem2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'itsem2id',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsem2'),

      new kernel::Field::Contact(
                name          =>'itseminbox',
                group         =>'itsem',
                label         =>'IT Servicemanagement Inbox',
                AllowEmpty    =>1,
                vjointo       =>'base::user',
                vjoineditbase =>{
                                   cistatusid=>[3,4,5],
                                   usertyp=>\'function'
                                },
                vjoinon       =>['itseminboxid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'itseminboxid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itseminbox'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'costcenter.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'costcenter.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'costcenter.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"costcenter.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(costcenter.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'costcenter.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'costcenter.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'costcenter.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'costcenter.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'costcenter.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'costcenter.realeditor'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'costcenter.lastqcheck'),
      new kernel::Field::QualityResponseArea()
   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.finance.costcenter"],
                         uniquesize=>40};
   $self->setDefaultView(qw(name fullname cistatus mdate));
   $self->setWorktable("costcenter");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default itsem delmgmt contacts control misc source));
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;   # if $rec is undefined, general access to app is checked
   my %param=@_;

   return("header","default") if (!defined($rec));


   my ($itsem,$delmgr)=managerState($rec);
   my @all=qw(header default itsem delmgmt contacts control misc source
              history qc);

   if ($itsem>0){
      @all=grep(!/^delmgmt$/,@all);
   } 
   if ($delmgr>0){
      @all=grep(!/^itsem$/,@all);
   }

   return(@all);
}





sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/costcenter.jpg?".$cgi->query_string());
}



sub ValidateCONumber
{
   my $self=shift;
   my $dataobj=shift;  # call for which dataobject
   my $fieldname=shift;
   my $oldrec=shift;
   my $newrec=shift;


   if (!exists($self->{costcenter})){
      $self->LoadSubObjs("ext/costcenter","costcenter");
   }
   my $n=0;
   foreach my $obj (values(%{$self->{costcenter}})){
      if ($obj->ValidateCONumber($dataobj,$fieldname,$oldrec,$newrec)){
         return(1);
      }
      $n++;
   }
   if ($n==0){ # if there are no modules, only real nubers are allowed
      msg(INFO,"no module found - using default format for costcenters");
      my $conumber=effVal($oldrec,$newrec,$fieldname);
      if ($conumber=~m/^\d+$/){
         return(1);
      }
   }
   else{
      # check if already an active costcenter record exists
      my $conumber=effVal($oldrec,$newrec,$fieldname);
      if ($conumber ne ""){
         my $o=getModuleObject($self->Config,"finance::costcenter");
         $o->SetFilter({name=>\$conumber,cistatusid=>\'4'});
         my ($corec)=$o->getOnlyFirst(qw(id));
         if (defined($corec)){
            return(1);
         }
      }

   }
   return(0);
}


sub managerState
{
   my $oldrec=shift;
   my $newrec=shift;

   my $itsem=0;
   my $delmgr=0;

   foreach my $v (qw(delmgrid delmgr2id delmgrteamid)){
      $delmgr++ if (effVal($oldrec,$newrec,$v) ne "");
   }
   foreach my $v (qw(itsemid itsem2id itsemteamid)){
      $itsem++ if (effVal($oldrec,$newrec,$v) ne "");
   }
   return($itsem,$delmgr);
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my ($itsem,$delmgr)=managerState($oldrec,$newrec);
   if ($itsem>0 && $delmgr){
      $self->LastMsg(ERROR,"IT Servicemanagement an delivery management ".
                           "can not exist concurrently");
      return(0);
   }

   if ((effVal($oldrec,$newrec,"delmgr2id") ne "" &&
        effVal($oldrec,$newrec,"delmgrid") eq "") ||
       (effVal($oldrec,$newrec,"itsem2id") ne "" &&
        effVal($oldrec,$newrec,"itsemid") eq "")){
      $self->LastMsg(ERROR,"specifing debuty only is not allowed");
      return(0);
   }

   foreach my $v (qw(delmgrid delmgr2id delmgrteamid)){
      $delmgr++ if (effVal($oldrec,$newrec,$v) ne "");
   }
   foreach my $v (qw(itsemid itsem2id itsemteamid)){
      $itsem++ if (effVal($oldrec,$newrec,$v) ne "");
   }




   my $name=effVal($oldrec,$newrec,"name");
   if (length(trim($name))<2){
      $self->LastMsg(ERROR,"invalid cost element specified");
      return(0);
   }

   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      if (!defined($oldrec) && !defined($newrec->{databossid})){
         my $userid=$self->getCurrentUserId();
         $newrec->{databossid}=$userid;
      }
      my $databossid=effVal($oldrec,$newrec,"databossid");
      if (!defined($databossid) || $databossid eq ""){
      $self->LastMsg(ERROR,"no write access - ".
                           "you have to define databoss at first");
         return(undef);
      }
   }
   if (effChanged($oldrec,$newrec,"name")){
      if (!$self->finance::costcenter::ValidateCONumber(
           $self->SelfAsParentObject,"name",$oldrec,$newrec)){
         if ($self->IsMemberOf("admin")){
            $self->LastMsg(WARN,
                $self->T("invalid number format '\%s' specified",
                         "finance::costcenter"),$newrec->{name});
         }
         else{
            $self->LastMsg(ERROR,
                $self->T("invalid number format '\%s' specified",
                         "finance::costcenter"),$newrec->{name});
            return(0);
         }
      }
   }


   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }

   
#   if (defined($newrec->{cistatusid}) && $newrec->{cistatusid}>4){
#      # validate if subdatastructures have a cistauts <=4 
#      # if true, the new cistatus isn't alowed
#   }
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();


   return("default") if (!defined($rec));
   if (defined($rec) && !defined($rec->{databossid}) &&
       !($self->IsMemberOf("admin"))){
      return("default");
   }

   my @databossedit=("default","delmgmt","itsem","contacts","control");
   return(@databossedit) if (defined($rec) && $self->IsMemberOf("admin"));
   return(@databossedit) if (defined($rec) && $rec->{databossid}==$userid);

   if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ["RMember"],"both");
      my @grpids=keys(%grps);
      foreach my $contact (@{$rec->{contacts}}){
         if ($contact->{target} eq "base::user" &&
             $contact->{targetid} ne $userid){
            next;
         }
         if ($contact->{target} eq "base::grp"){
            my $grpid=$contact->{targetid};
            next if (!grep(/^$grpid$/,@grpids));
         }
         my @roles=($contact->{roles});
         @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
         return(@databossedit) if (grep(/^write$/,@roles));
      }
   }
   return();
}


sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   return(undef) if (!$self->globalOpValidate("ValidateDelete",$rec));

   return($self->SUPER::ValidateDelete($rec));
}




sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("finance::costcenter");
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}






1;
