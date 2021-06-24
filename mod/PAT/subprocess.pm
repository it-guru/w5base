package PAT::subprocess;
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
                dataobjattr   =>'PAT_subprocess.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Shortname',
                dataobjattr   =>'PAT_subprocess.name'),

      new kernel::Field::Text(
                name          =>'title',
                label         =>'Sub-Process',
                dataobjattr   =>'PAT_subprocess.title'),

      new kernel::Field::TextDrop(
                name          =>'businessseg',
                label         =>'Business-Segment',
                vjointo       =>'PAT::businessseg',
                vjoinon       =>['businesssegid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'businesssegid',
                label         =>'Business-SegmentID',
                dataobjattr   =>'PAT_subprocess.businessseg'),


      new kernel::Field::Text(
                name          =>'business',
                label         =>'Business',
                dataobjattr   =>'PAT_subprocess.business'),

      new kernel::Field::Text(
                name          =>'businesssubprocess',
                label         =>'Business-SubProcess',
                dataobjattr   =>'PAT_subprocess.subprocess'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'PAT_subprocess.description'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'PAT_subprocess.comments'),

      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                uivisible     =>0,
                uploadable    =>0,
                label         =>'Sub-Process',
                dataobjattr   =>"concat(PAT_subprocess.name,': ',".
                                "PAT_subprocess.title)"),


      new kernel::Field::SubList(
                name          =>'ictnames',
                label         =>'ICT-AliasNames',
                group         =>'ictnames',
                subeditmsk    =>'subedit.ictnames',
                vjointo       =>\'PAT::lnksubprocessictname',
                vjoinon       =>['id'=>'subprocessid'],
                vjoindisp     =>['relevance','ictname','cdate'],
                vjoininhash   =>['relevance','ictname','cdate',
                                 'ictfullname','ictnameid','ictoid']),

      new kernel::Field::Text(
                name          =>'allictnames',
                label         =>'relevant ICT-AliasNames',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'ictnames',
                vjointo       =>\'PAT::lnksubprocessictname',
                vjoinon       =>['id'=>'subprocessid'],
                vjoindisp     =>'ictname'),

      new kernel::Field::TimeSpans(
                name          =>'onlinetime',
                label         =>'Online-Time',
                days          =>['mon-fri','sat','sun/HOL'],
                tspandaymap   =>[1,1,1,0,0,0,0],
                group         =>'times',
                dataobjattr   =>'PAT_subprocess.onlinetime'),

      new kernel::Field::TimeSpans(
                name          =>'usetime',
                label         =>'Use-Time',
                days          =>['mon-fri','sat','sun/HOL'],
                tspandaymap   =>[1,1,1,0,0,0,0],
                group         =>'times',
                dataobjattr   =>'PAT_subprocess.usetime'),

      new kernel::Field::TimeSpans(
                name          =>'coretime',
                label         =>'Core-Time',
                days          =>['mon-fri','sat','sun/HOL'],
                tspandaymap   =>[1,1,1,0,0,0,0],
                group         =>'times',
                dataobjattr   =>'PAT_subprocess.coretime'),

      new kernel::Field::TimeSpans(
                name          =>'ibicoretime',
                label         =>'IBI Core-Time',
                days          =>['mon-fri','sat','sun/HOL'],
                tspandaymap   =>[1,1,1,0,0,0,0],
                group         =>'ibitimes',
                dataobjattr   =>'PAT_subprocess.ibi_coretime'),

      new kernel::Field::Number(
                name          =>'ibithcoretimemonfri',
                label         =>'IBI Threashold Core-Time mon-fri',
                precision     =>0,
                unit          =>'min',
                group         =>'ibitimes',
                dataobjattr   =>'PAT_subprocess.ibi_th_coretime_monfri'),

      new kernel::Field::Number(
                name          =>'ibithcoretimesat',
                label         =>'IBI Threashold Core-Time sat',
                precision     =>0,
                unit          =>'min',
                group         =>'ibitimes',
                dataobjattr   =>'PAT_subprocess.ibi_th_coretime_sat'),

      new kernel::Field::Number(
                name          =>'ibithcoretimesun',
                label         =>'IBI Threashold Core-Time sun/HOL',
                precision     =>0,
                unit          =>'min',
                group         =>'ibitimes',
                dataobjattr   =>'PAT_subprocess.ibi_th_coretime_sun'),

      new kernel::Field::TimeSpans(
                name          =>'ibinonprodtime',
                label         =>'IBI NonProd-Time',
                days          =>['mon-fri','sat','sun/HOL'],
                tspandaymap   =>[1,1,1,0,0,0,0],
                group         =>'ibitimes',
                dataobjattr   =>'PAT_subprocess.ibi_nonprodtime'),

      new kernel::Field::Number(
                name          =>'ibithnonprodtimemonfri',
                label         =>'IBI Threashold NonProd-Time mon-fri',
                precision     =>0,
                unit          =>'min',
                group         =>'ibitimes',
                dataobjattr   =>'PAT_subprocess.ibi_th_nonprodtime_monfri'),

      new kernel::Field::Number(
                name          =>'ibithnonprodtimesat',
                label         =>'IBI Threashold NonProd-Time sat',
                precision     =>0,
                unit          =>'min',
                group         =>'ibitimes',
                dataobjattr   =>'PAT_subprocess.ibi_th_nonprodtime_sat'),

      new kernel::Field::Number(
                name          =>'ibithnonprodtimesun',
                label         =>'IBI Threashold NonProd-Time sun/HOL',
                precision     =>0,
                unit          =>'min',
                group         =>'ibitimes',
                dataobjattr   =>'PAT_subprocess.ibi_th_nonprodtime_sun'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                selectfix     =>1,
                label         =>'Source-System',
                dataobjattr   =>'PAT_subprocess.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'PAT_subprocess.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'PAT_subprocess.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'PAT_subprocess.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'PAT_subprocess.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'PAT_subprocess.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'PAT_subprocess.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'PAT_subprocess.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'PAT_subprocess.realeditor'),
   

   );
   $self->{history}={
      delete=>[
         'local'
      ],
      update=>[
         'local'
      ]
   };

   $self->setDefaultView(qw(name title businessseg mdate));
   $self->setWorktable("PAT_subprocess");
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
             ictnames 
             times
             ibitimes
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

   my @wrgrp=qw(default ictnames times ibitimes);

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
