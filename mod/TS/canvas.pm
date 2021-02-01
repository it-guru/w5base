package TS::canvas;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::CIStatusTools;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);



   $self->{useMenuFullnameAsACL}=$self->Self();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                searchable    =>0,
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'canvas.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'canvasid',
                label         =>'CanvasID',
                htmleditwidth =>'80px',
                size          =>'3',
                dataobjattr   =>'canvas.canvasid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                selectfix     =>1,
                dataobjattr   =>'canvas.name'),

      new kernel::Field::Select(
                name          =>'responsibleorg',
                htmleditwidth =>'40%',
                selectfix     =>1,
                label         =>'responsible organisation',
                vjoineditbase =>{grpid=>"200 822"},
                vjointo       =>'base::grp',
                vjoinon       =>['rorgid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'rorgid',
                label         =>'responsible organisation ID',
                selectfix     =>1,
                dataobjattr   =>'canvas.rorg'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'50%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                selectfix     =>1,
                dataobjattr   =>'canvas.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                selectfix     =>1,
                group         =>'comments',
                dataobjattr   =>'canvas.databoss'),

      new kernel::Field::Contact(
                name          =>'leader',
                label         =>'Owner - Business',
                AllowEmpty    =>1,
                vjoinon       =>'leaderid'),

      new kernel::Field::Link(
                name          =>'leaderid',
                dataobjattr   =>'canvas.leader'),

      new kernel::Field::Contact(
                name          =>'leaderit',
                label         =>'Owner - IT',
                AllowEmpty    =>1,
                vjoinon       =>'leaderitid'),

      new kernel::Field::Link(
                name          =>'leaderitid',
                dataobjattr   =>'canvas.leaderit'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmldetail    =>0,
                dataobjattr   =>"concat(".
                                "canvas.canvasid,".
                                "if (canvas.name<>'',': ',''),".
                                "canvas.name".
                                ")"),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'ictorelations',
                label         =>'ICTO Relations',
                htmlwidth     =>'300px',
                group         =>'ictorelations',
                searchable    =>0,
                vjointo       =>'TS::lnkcanvas',
                vjoinon       =>['id'=>'canvasid'],
                vjoindisp     =>['icto','fraction','vou']),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'canvas.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'canvas.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'canvas.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'canvas.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'canvas.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'canvas.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'canvas.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'canvas.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'canvas.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'canvas.realeditor'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'canvas.lastqcheck'),
      new kernel::Field::QualityResponseArea()

   );
   $self->{history}={
      insert=>[
         'local'
      ],
      update=>[
         'local'
      ],
      delete=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(fullname cistatus leader cdate mdate));
   $self->setWorktable("canvas");
   $self->{CI_Handling}={
      activator=>["admin","w5base.TS.canvas"]
   };
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
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

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default canvasattr canvas 
             ictorelations contacts comments source));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;

   if (length(trim(effVal($oldrec,$newrec,"name")))<5){
      $self->LastMsg(ERROR,
              "Name field not sufficient filled");
      return(0);
   }

   my $ocistatusid=undef;
   $ocistatusid=$oldrec->{cistatusid} if (defined($oldrec));
   my $ncistatusid=effVal($oldrec,$newrec,"cistatusid");

   if ($ocistatusid>=4 && $ncistatusid<4){
      if (!$self->IsMemberOf($self->{CI_Handling}->{activator})){
         $self->LastMsg(ERROR,"cistatus back to planning is not allowed");
         return(0);
      }
   }
   if ($ncistatusid>=4 && $ncistatusid<6){
      if (effVal($oldrec,$newrec,"leaderid") eq ""){
         $self->LastMsg(ERROR,
                 "a owner is needed for selected CI-State");
         return(0);
      }
   }

   if (exists($newrec->{canvasid})){
      my $canvasid=$newrec->{canvasid};
      if ($canvasid ne ""){
         if ($canvasid=~m/^[0-9]+$/){
            if ($canvasid<100){
               $canvasid=sprintf("C%02d",$canvasid);
            }
            else{
               $canvasid=sprintf("C%03d",$canvasid);
            }
         }
         $canvasid=uc($canvasid);
         if (!($canvasid=~m/^C[0-9]{2,3}$/)){
            $self->LastMsg(ERROR,"invalid format of CanvasID");
            return(0);
         }
         if ($newrec->{canvasid} ne $canvasid){
            $newrec->{canvasid}=$canvasid;
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
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   if (!$self->HandleRunDownRequests($oldrec,$newrec,$comprec,
                                     %{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   if ($rec->{cistatusid}>=4){
      if ($rec->{cistatusid}>=6){
         my $d=CalcDateDuration($rec->{mdate},NowStamp("en"));
         if ($d->{days}>6){
            return($self->isWriteValid($rec));
         }
      }
      return(0);
   }
   return($self->isWriteValid($rec));
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("TS::canvas");
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

#   my $rorgid=effVal($oldrec,$newrec,"rorgid");  # noch nicht ausgewertet!
#
#
#   my $id=effVal($oldrec,$newrec,"id");
#   my $cistatus=effVal($oldrec,$newrec,"cistatusid");
#   my $shortname=effVal($oldrec,$newrec,"shortname");
#   my $name=effVal($oldrec,$newrec,"name");
#
#   my $reprgrp=effVal($oldrec,$newrec,"reprgrp"); # schon mal aktiv gewesen?

#   if ($cistatus>3 || $reprgrp ne ""){
#      $self->syncToGroups($id,$cistatus,$shortname,$name,$oldrec,$newrec);
#   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub isWriteValid
{
   my $self=shift;
   my @l;


   if (!defined($_[0])){
      @l=$self->SUPER::isWriteValid(@_);
   }

   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   if ($userid eq $rec->{databossid}){
      push(@l,"ALL");
   }
   if ($self->IsMemberOf($self->{CI_Handling}->{activator})){
      push(@l,"ALL");
   }

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
         push(@l,"ALL") if (grep(/^write$/,@roles));
      }
   }



   if (in_array(\@l,"ALL")){
      @l=("default","ictorelations","contacts");
   }

   return(@l);
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
