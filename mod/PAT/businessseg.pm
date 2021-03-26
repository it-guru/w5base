package PAT::businessseg;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use PAT::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   #$self->{useMenuFullnameAsACL}="1";

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'PAT_businessseg.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Shortname',
                dataobjattr   =>'PAT_businessseg.name'),

      new kernel::Field::Text(
                name          =>'title',
                label         =>'Business-Segment',
                dataobjattr   =>'PAT_businessseg.title'),

      new kernel::Field::Text(
                name          =>'bsegopt',
                label         =>'Business-Segment OPT',
                dataobjattr   =>'PAT_businessseg.bsegopt'),

      new kernel::Field::Text(
                name          =>'sopt',
                label         =>'S-OPT',
                dataobjattr   =>'PAT_businessseg.sopt'),

      new kernel::Field::Text(
                name          =>'orgname',
                label         =>'Organisation',
                dataobjattr   =>'PAT_businessseg.orgname'),

      new kernel::Field::Text(
                name          =>'orgshort',
                label         =>'Organisation Shortname',
                dataobjattr   =>'PAT_businessseg.orgshort'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'PAT_businessseg.comments'),

      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                uivisible     =>0,
                uploadable    =>0,
                label         =>'Business-Segment',
                dataobjattr   =>"concat(PAT_businessseg.name,': ',".
                                "PAT_businessseg.title)"),


      new kernel::Field::SubList(
                name          =>'subprocesses',
                label         =>'Sub-Processes',
                group         =>'subprocesses',
                subeditmsk    =>'subedit.subprocesses',
                vjointo       =>\'PAT::subprocess',
                vjoinon       =>['id'=>'businesssegid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                selectfix     =>1,
                label         =>'Source-System',
                dataobjattr   =>'PAT_businessseg.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'PAT_businessseg.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'PAT_businessseg.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'PAT_businessseg.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'PAT_businessseg.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'PAT_businessseg.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'PAT_businessseg.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'PAT_businessseg.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'PAT_businessseg.realeditor'),
   

   );
   $self->{history}={
      delete=>[
         'local'
      ],
      update=>[
         'local'
      ]
   };

   $self->setDefaultView(qw(name title bsegopt sopt orgname orgshort mdate));
   $self->setWorktable("PAT_businessseg");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/bussinessservice.jpg?".
          $cgi->query_string());
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default 
             subprocesses 
             source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(default subprocesses);

   return(@wrgrp) if ($self->PAT::lib::Listedit::isWriteValid($rec));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
#   if ($self->PAT::lib::Listedit::isViewValid($rec)){
#      return(@vl);
#   }
#   my @l=$self->SUPER::isViewValid($rec);
#   return(@vl) if (in_array(\@l,[qw(default ALL)]));
   return(qw(ALL));
}

sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





1;
