package TS::orgdom;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
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
                dataobjattr   =>'orgdom.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'orgdomid',
                label         =>'Organisation Domain',
                htmleditwidth =>'80px',
                size          =>'3',
                dataobjattr   =>'orgdom.orgdomid'),

      #new kernel::Field::Text(
      #          name          =>'lseg',
      #          label         =>'lead Segment',
      #          htmleditwidth =>'80px',
      #          size          =>'3',
      #          dataobjattr   =>'orgdom.lseg'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                selectfix     =>1,
                dataobjattr   =>'orgdom.name'),

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
                dataobjattr   =>'orgdom.cistatus'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmldetail    =>0,
                dataobjattr   =>"concat(".
                                "orgdom.orgdomid,".
                                "if (orgdom.name<>'',': ',''),".
                                "orgdom.name".
                                ")"),

      new kernel::Field::SubList(
                name          =>'ictorelations',
                label         =>'ICTO Relations',
                htmlwidth     =>'300px',
                group         =>'ictorelations',
                searchable    =>0,
                vjointo       =>'TS::lnkorgdomappl',
                vjoinon       =>['id'=>'orgdomid'],
                vjoindisp     =>['ictono','fraction','vou']),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'ictorelations',
                searchable    =>1,
                readonly      =>1,
                vjointo       =>'TS::lnkorgdomappl',
                vjoinon       =>['id'=>'orgdomid'],
                vjoininhash   =>['appl','applid','vouid'],
                vjoindisp     =>['appl']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'orgdom.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'orgdom.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'orgdom.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'orgdom.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'orgdom.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'orgdom.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'orgdom.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'orgdom.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'orgdom.realeditor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"orgdom.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(orgdom.id,35,'0')"),


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
   $self->setDefaultView(qw(orgdomid name lseg cistatus cdate mdate));
   $self->setWorktable("orgdom");
   $self->{CI_Handling}={
      activator=>["admin","w5base.TS.orgdom"]
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
   return(qw(header default orgdomattr orgdom 
             ictorelations contacts comments source));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;

   if (length(trim(effVal($oldrec,$newrec,"name")))<3){
      $self->LastMsg(ERROR,
              "Name field not sufficient filled");
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
   return("TS::orgdom");
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

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

   return(undef) if (!$self->IsMemberOf("admin"));

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

   if (in_array(\@l,"ALL")){
      @l=("default","ictorelations");
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
