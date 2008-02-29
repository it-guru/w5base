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
                htmlwidth     =>'120px',
                label         =>'CO-Shortdescription',
                dataobjattr   =>'costcenter.fullname'),

      new kernel::Field::TextDrop(
                name          =>'delmgrteam',
                group         =>'delmgmt',
                htmlwidth     =>'300px',
                label         =>'Delivery-Management Team',
                vjointo       =>'base::grp',
                vjoinon       =>['delmgrteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                group         =>'delmgmt',
                label         =>'Delivery Manager',
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrid',
                group         =>'delmgmt',
                dataobjattr   =>'costcenter.delmgr'),

      new kernel::Field::TextDrop(
                name          =>'delmgr2',
                group         =>'delmgmt',
                label         =>'Deputy Delivery Manager',
                vjointo       =>'base::user',
                vjoinon       =>['delmgr2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgr2id',
                group         =>'delmgmt',
                dataobjattr   =>'costcenter.delmgr2'),


      new kernel::Field::Link(
                name          =>'delmgrteamid',
                group         =>'delmgmt',
                dataobjattr   =>'costcenter.delmgrteam'),

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
   

   );
   $self->setDefaultView(qw(name cistatus fullname mdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   $self->setWorktable("costcenter");
   return($self->SUPER::Initialize());
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

#   return(0) if (!$self->ProtectObject($oldrec,$newrec,$self->{adminsgroups}));
   return(1);
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $conummer=effVal($oldrec,$newrec,"name");
   if ($conummer=~m/^\s*$/ || !($conummer=~m/^[0-9]+$/)){
      $self->LastMsg(ERROR,"invalid CO-Numer '\%s' specified",$conummer);
      return(0);
   }
   $conummer=~s/^0+//g;
   $newrec->{name}=$conummer;

   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{delmgrid}) ||
             $newrec->{delmgrid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{delmgrid}=$userid;
         }
      }
      if (defined($newrec->{delmgrid}) &&
          $newrec->{delmgrid}!=$userid &&
          $newrec->{delmgrid}!=$oldrec->{delmgrid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as delmgr");
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


   return("default") if (!defined($rec) && $self->IsMemberOf("admin"));

   my @databossedit=("default","delmgmt","contacts");
   return(@databossedit) if (defined($rec) && $self->IsMemberOf("admin"));

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
   return(undef);
}


1;
