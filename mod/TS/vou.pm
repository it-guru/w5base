package TS::vou;
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
                dataobjattr   =>'vou.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'shortname',
                label         =>'Shortname',
                size          =>'8',
                dataobjattr   =>'vou.shortname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'vou.name'),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'Code',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'vou.code'),

      new kernel::Field::Select(
                name          =>'responsibleorg',
                htmleditwidth =>'40%',
                label         =>'responsible organisation',
                vjoineditbase =>{grpid=>"200"},
                vjointo       =>'base::grp',
                vjoinon       =>['rorgid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'rorgid',
                label         =>'responsible organisation ID',
                dataobjattr   =>'vou.rorg'),

      new kernel::Field::Select(
                name          =>'outype',
                label         =>'Unit Type',
                value         =>['HUB','SERVICE'],
                htmleditwidth =>'130px',
                dataobjattr   =>'vou.grouptype'),

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
                dataobjattr   =>'vou.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                selectfix     =>1,
                group         =>'comments',
                dataobjattr   =>'vou.databoss'),

      new kernel::Field::Contact(
                name          =>'leader',
                AllowEmpty    =>1,
                label         =>'Business Owner - Business',
                vjoinon       =>'leaderid'),

      new kernel::Field::Link(
                name          =>'leaderid',
                dataobjattr   =>'vou.leader'),

      new kernel::Field::Contact(
                name          =>'leaderit',
                AllowEmpty    =>1,
                label         =>'Business Owner - IT',
                vjoinon       =>'leaderid'),

      new kernel::Field::Link(
                name          =>'leaderitid',
                dataobjattr   =>'vou.leaderit'),

      new kernel::Field::Text(
                name          =>'canvasid',
                label         =>'CanvasID',
                group         =>'canvas',
                dataobjattr   =>'vou.canvasid'),

      new kernel::Field::Text(
                name          =>'canvasfield',
                label         =>'Canvas/Business field',
                group         =>'canvas',
                dataobjattr   =>'vou.canvasfield'),

      new kernel::Field::Contact(
                name          =>'canvasownerbu',
                group         =>'canvas',
                AllowEmpty    =>1,
                label         =>'Canvas Owner - Business',
                vjoinon       =>'canvasownerbuid'),

      new kernel::Field::Link(
                name          =>'canvasownerbuid',
                group         =>'canvas',
                dataobjattr   =>'vou.canvasownerbuid'),

      new kernel::Field::Contact(
                name          =>'canvasownerit',
                AllowEmpty    =>1,
                group         =>'canvas',
                label         =>'Canvas Owner - IT',
                vjoinon       =>'canvasowneritid'),

      new kernel::Field::Link(
                name          =>'canvasowneritid',
                dataobjattr   =>'vou.canvasowneritid'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'vou.description'),

      new kernel::Field::Text(
                name          =>'seg',
                label         =>'Segemente/Tribe',
                dataobjattr   =>'vou.segment'),

      new kernel::Field::Contact(
                name          =>'rte',
                AllowEmpty    =>1,
                label         =>'RTE ?',
                vjoinon       =>'rteid'),

      new kernel::Field::Link(
                name          =>'rteid',
                dataobjattr   =>'vou.rte'),

      new kernel::Field::Contact(
                name          =>'spc',
                AllowEmpty    =>1,
                label         =>'SPC ?',
                vjoinon       =>'spcid'),

      new kernel::Field::Link(
                name          =>'spcid',
                dataobjattr   =>'vou.spc'),


      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments',
                label         =>'Comments',
                dataobjattr   =>'vou.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'vou.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'vou.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'vou.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'vou.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'vou.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'vou.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'vou.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'vou.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'vou.realeditor'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'vou.lastqcheck'),
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
   $self->setDefaultView(qw(shortname name cistatus code cdate mdate));
   $self->setWorktable("vou");
   $self->{CI_Handling}={
      uniquename=>"shortname",
      uniquesize=>8,
      activator=>["admin","w5base.TS.vou"]
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
   my $wrgroups=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default canvas contacts comments source));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;

   if (!defined($oldrec) || defined($newrec->{shortname})){
      my $newshortname=$newrec->{shortname};
      $newshortname=~s/\[\d+\]$//;
      if ($newshortname=~m/^\s*$/ || 
          !($newshortname=~m/^[a-z0-9]+$/i) ||
          length($newshortname)>8){
         $self->LastMsg(ERROR,"invalid shortname specified");
         return(0);
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


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
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
   



   @l=("default","comments","canvas","contacts") if (in_array(\@l,"ALL"));

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
