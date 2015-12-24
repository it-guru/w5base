package itil::ipnet;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
                dataobjattr   =>'ipnet.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'120px',
                label         =>'CO-Number',
                dataobjattr   =>'ipnet.name'),

      new kernel::Field::Text(
                name          =>'accarea',
                htmlwidth     =>'120px',
                label         =>'Accounting Area',
                dataobjattr   =>'ipnet.accarea'),

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
                dataobjattr   =>'ipnet.cistatus'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'220px',
                label         =>'CO-Shortdescription',
                dataobjattr   =>'ipnet.fullname'),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                label         =>'Databoss',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['databossid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'ipnet.databoss'),

#      new kernel::Field::TextDrop(
#                name          =>'ldelmgr',
#                group         =>'delmgmt',
#                label         =>'lead Delivery Manager',
#                AllowEmpty    =>1,
#                vjointo       =>'base::user',
#                vjoinon       =>['ldelmgrid'=>'userid'],
#                vjoindisp     =>'fullname'),
#
#      new kernel::Field::Link(
#                name          =>'ldelmgrid',
#                group         =>'delmgmt',
#                dataobjattr   =>'ipnet.ldelmgr'),
#
#      new kernel::Field::TextDrop(
#                name          =>'ldelmgr2',
#                group         =>'delmgmt',
#                label         =>'lead Deputy Delivery Manager',
#                AllowEmpty    =>1,
#                vjointo       =>'base::user',
#                vjoinon       =>['ldelmgr2id'=>'userid'],
#                vjoindisp     =>'fullname'),
#
#      new kernel::Field::Link(
#                name          =>'ldelmgr2id',
#                group         =>'delmgmt',
#                dataobjattr   =>'ipnet.ldelmgr2'),


      new kernel::Field::TextDrop(
                name          =>'delmgrteam',
                group         =>'delmgmt',
                htmlwidth     =>'300px',
                label         =>'Service Delivery-Management Team',
                vjointo       =>'base::grp',
                vjoinon       =>['delmgrteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

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
                dataobjattr   =>'ipnet.delmgr'),

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
                dataobjattr   =>'ipnet.delmgr2'),


      new kernel::Field::Link(
                name          =>'delmgrteamid',
                group         =>'delmgmt',
                dataobjattr   =>'ipnet.delmgrteam'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'finance::ipnet'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'ipnet.comments'),

      new kernel::Field::Boolean(
                name          =>'isdirectwfuse',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'ipnet is direct useable by workflows',
                dataobjattr   =>'ipnet.is_directwfuse'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'ipnet.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'ipnet.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'ipnet.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'ipnet.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'ipnet.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'ipnet.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'ipnet.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'ipnet.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'ipnet.realeditor'),
   

   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","admin.finance.ipnet"],
                         uniquesize=>20};
   $self->setDefaultView(qw(name fullname cistatus mdate));
   $self->setWorktable("ipnet");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default delmgmt contacts control misc source));
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/ip_network.jpg?".$cgi->query_string());
}



sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


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
   my $conummer=uc(effVal($oldrec,$newrec,"name"));
   if ($conummer=~m/^\s*$/ || 
       (!($conummer=~m/^[0-9]+$/) &&
        !($conummer=~m/^[A-Z]-[0-9]+-[A-Z,0-9]+$/) )){
      $self->LastMsg(ERROR,"invalid number format '\%s' specified",$conummer);
      return(0);
   }
   $conummer=~s/^0+//g;
   $newrec->{name}=$conummer;

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

   return() if (!($self->IsMemberOf("admin")));  # init phase!!! - no user wr


   return("default") if (!defined($rec));
   if (defined($rec) && !defined($rec->{databossid}) &&
       !($self->IsMemberOf("admin"))){
      return("default");
   }

   my @databossedit=("default","delmgmt","contacts","control");
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


1;
