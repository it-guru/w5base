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
                label         =>'W5BaseID',
                dataobjattr   =>'costcenter.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'120px',
                label         =>'CO-Number',
                dataobjattr   =>'costcenter.name'),

      new kernel::Field::Text(
                name          =>'accarea',
                htmlwidth     =>'120px',
                label         =>'Accounting Area',
                dataobjattr   =>'costcenter.accarea'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'costcenter.cistatus'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'220px',
                label         =>'CO-Shortdescription',
                dataobjattr   =>'costcenter.fullname'),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                label         =>'Databoss',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['databossid'=>'userid'],
                vjoindisp     =>'fullname'),

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

      new kernel::Field::TextDrop(
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

      new kernel::Field::TextDrop(
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

      new kernel::Field::Boolean(
                name          =>'isdirectwfuse',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'costcenter is direct useable by workflows',
                dataobjattr   =>'costcenter.is_directwfuse'),

      new kernel::Field::TextDrop(
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

      new kernel::Field::TextDrop(
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
                label         =>'Owner',
                dataobjattr   =>'costcenter.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'costcenter.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'costcenter.realeditor'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'costcenter.lastqcheck'),
      new kernel::Field::QualityResponseArea()
   );
   $self->{history}=[qw(modify delete)];
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","admin.finance.costcenter"],
                         uniquesize=>20};
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
   my @all=qw(header default itsem delmgmt contacts control misc source);

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



sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub ValidateCONumber
{
   my $self=shift;
   my $fieldname=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $conummer=uc(effVal($oldrec,$newrec,$fieldname));
   if ($conummer=~m/^\s*$/ || 
       (!($conummer=~m/^[0-9]+$/) &&
        !($conummer=~m/^[A-Z,0-9][0-9]{8}[A-Z,0-9]$/) &&
        !($conummer=~m/^[A-Z]-[0-9]{6,12}-[A-Z,0-9]{3,6}$/) )){
      return(0);
   }
   $conummer=~s/^0+//g;
   if (defined($newrec)){
      $newrec->{$fieldname}=$conummer;
   }
   return(1);
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
   if (!$self->finance::costcenter::ValidateCONumber("name",
       $oldrec,$newrec)){
      $self->LastMsg(ERROR,
          $self->T("invalid number format '\%s' specified",
                   "finance::costcenter"),$newrec->{name});
      return(0);
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
