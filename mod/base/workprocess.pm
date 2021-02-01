package base::workprocess;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
   #$param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);



   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'workprocess.id'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'workprocess.mandator'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Prozess label',
                dataobjattr   =>'workprocess.name'),

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
                dataobjattr   =>'workprocess.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'workprocess.databoss'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'base::workprocess'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Textarea(
                name          =>'target',
                label         =>'target of the workprocess',
                dataobjattr   =>'workprocess.comments'),

      new kernel::Field::SubList(
                name          =>'items',
                label         =>'Workprocess items',
                group         =>'items',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.workprocess',
                vjointo       =>'base::workprocessitem',
                vjoinon       =>['id'=>'workprocessid'],
                vjoindisp     =>['itemno','visualname'],
                vjoininhash   =>['orderkey','id','name','comments'],
                ),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'workprocess.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'workprocess.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'workprocess.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'workprocess.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'workprocess.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'workprocess.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'workprocess.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'workprocess.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'workprocess.realeditor'),
   

   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.base.workprocess"],
                         uniquesize=>80};
   $self->setDefaultView(qw(mandator name cistatus mdate));
   $self->setWorktable("workprocess");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default items contacts misc source));
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/workprocess.jpg?".$cgi->query_string());
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

   my @databossedit=("default","items","contacts");
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
