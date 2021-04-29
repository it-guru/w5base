package PAT::lnksubprocessictname;
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
                dataobjattr   =>'PAT_lnksubprocessictname.id'),

      new kernel::Field::RecordUrl(),


      new kernel::Field::TextDrop(
                name          =>'subprocess',
                label         =>'Sub-Process',
                htmlwidth     =>'300',
                vjointo       =>'PAT::subprocess',
                vjoinon       =>['subprocessid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'subprocessid',
                label         =>'SubProcessID',
                dataobjattr   =>'PAT_lnksubprocessictname.subprocess'),

      new kernel::Field::Select(
                name          =>'relevance',
                label         =>'Relevance',
                default       =>'standard',
                htmlwidth     =>'110',
                selectfix     =>1,
                transprefix   =>'REL.',
                value         =>['1', '2', '3', '4' ],
                dataobjattr   =>'PAT_lnksubprocessictname.relevance'),

      new kernel::Field::Text(
                name          =>'rawrelevance',
                label         =>'Raw-Relevance',
                dataobjattr   =>'PAT_lnksubprocessictname.relevance'),

      new kernel::Field::TextDrop(
                name          =>'ictname',
                label         =>'ICT-AliasName',
                htmlwidth     =>'200',
                vjointo       =>'PAT::ictname',
                vjoinon       =>['ictnameid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'ictfullname',
                label         =>'ICT-AliasName Fullname',
                htmldetail    =>0,
                vjointo       =>'PAT::ictname',
                vjoinon       =>['ictnameid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'ictnameid',
                label         =>'ICT-NameID',
                dataobjattr   =>'PAT_lnksubprocessictname.ictname'),


      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'PAT_lnksubprocessictname.comments'),

#      new kernel::Field::Text(
#                name          =>'fullname',
#                readonly      =>1,
#                uivisible     =>0,
#                uploadable    =>0,
#                label         =>'Sub-Process',
#                dataobjattr   =>"concat(PAT_lnksubprocessictname.name,': ',".
#                                "PAT_lnksubprocessictname.title)"),


#      new kernel::Field::SubList(
#                name          =>'instances',
#                label         =>'Instances',
#                group         =>'instances',
#                subeditmsk    =>'subedit.instances',
#                vjointo       =>\'tRnAI::lnkinstlic',
#                vjoinon       =>['id'=>'licenseid'],
#                vjoindisp     =>['instance','system']),


      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                selectfix     =>1,
                label         =>'Source-System',
                dataobjattr   =>'PAT_lnksubprocessictname.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'PAT_lnksubprocessictname.srcid'),

      new kernel::Field::Interface(
                name          =>'ictoid',
                group         =>'source',
                label         =>'ICTO-ID',
                dataobjattr   =>'PAT_ictname.ictoid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'PAT_lnksubprocessictname.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'PAT_lnksubprocessictname.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'PAT_lnksubprocessictname.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'PAT_lnksubprocessictname.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'PAT_lnksubprocessictname.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'PAT_lnksubprocessictname.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'PAT_lnksubprocessictname.realeditor'),
   

   );
   $self->setDefaultView(qw(subprocess ictname relevance mdate));
   $self->setWorktable("PAT_lnksubprocessictname");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="PAT_lnksubprocessictname ".
            "left outer join PAT_ictname ".
            "on PAT_lnksubprocessictname.ictname=".
            "PAT_ictname.id ";
   return($from);
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
             instances 
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

   my @wrgrp=qw(default);

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
