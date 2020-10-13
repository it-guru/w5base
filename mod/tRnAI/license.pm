package tRnAI::license;
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
use tRnAI::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}="1";

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'tRnAI_license.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'License Label',
                dataobjattr   =>'tRnAI_license.name'),

      new kernel::Field::Text(
                name          =>'ponum',
                label         =>'Purchase Order Number',
                dataobjattr   =>'tRnAI_license.ponum'),

      new kernel::Field::Text(
                name          =>'plmnum',
                label         =>'PLM Ticket Number',
                dataobjattr   =>'tRnAI_license.plmnum'),

      new kernel::Field::Date(
                name          =>'expdate',
                label         =>'Expiration Date',
                dayonly       =>1,
                dataobjattr   =>'tRnAI_license.expdate'),

      new kernel::Field::Date(
                name          =>'expnotify1',
                label         =>'Expiration Notify',
                htmldetail    =>0,
                selectfix     =>1,
                dataobjattr   =>'tRnAI_license.expnotify1'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tRnAI_license.comments'),

      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'License Description',
                dataobjattr   =>'tRnAI_license.fullname'),


      new kernel::Field::SubList(
                name          =>'instances',
                label         =>'Instances',
                group         =>'instances',
                subeditmsk    =>'subedit.instances',
                vjointo       =>\'tRnAI::lnkinstlic',
                vjoinon       =>['id'=>'licenseid'],
                vjoindisp     =>['instance','system']),


      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tRnAI_license.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tRnAI_license.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tRnAI_license.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tRnAI_license.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tRnAI_license.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tRnAI_license.realeditor'),
   

   );
   $self->setDefaultView(qw(fullname expdate cdate mdate));
   $self->setWorktable("tRnAI_license");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/liccontract.jpg?".$cgi->query_string());
}



sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default instances source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $fullname=effVal($oldrec,$newrec,"fullname");
   my $name=effVal($oldrec,$newrec,"name");
   my $ponum=effVal($oldrec,$newrec,"ponum");
   my $plmnum=effVal($oldrec,$newrec,"plmnum");
   if ($plmnum=~m/[^0-9]/){
      $self->LastMsg(ERROR,"invalid PLM Ticket Number");
      return(0);
   }
   if ($ponum=~m/[^0-9]/){
      $self->LastMsg(ERROR,"invalid Purchase Order Number");
      return(0);
   }
   $name=~s/\s/_/g;
   $name=~s/-//g;
   my $fname="";
   $fname.=$name if ($name ne "");
   if ($ponum ne ""){
      $fname.="-" if ($fname ne "");
      $fname.=$ponum;
   }
   if ($plmnum ne ""){
      $fname.="-" if ($fname ne "");
      $fname.=$plmnum;
   }
   if (trim($fname) eq ""){
      $self->LastMsg(ERROR,
               "missing necessary informations to create Lizense-Description");
      return(0);
   }
   if (trim($fname) ne trim($fullname)){
      $newrec->{fullname}=trim($fname);
   }

   if (effChanged($oldrec,$newrec,"expdate")){
      if (defined($oldrec) && $oldrec->{expnotify1} ne ""){
         $newrec->{expnotify1}=undef;
      }
   }



   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(default instances);

   return(@wrgrp) if ($self->tRnAI::lib::Listedit::isWriteValid($rec));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL") if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"]));
   my @vl=("header","default","instances","source");
   if ($self->tRnAI::lib::Listedit::isViewValid($rec)){
      return(@vl);
   }
   my @l=$self->SUPER::isViewValid($rec);
   return(@vl) if (in_array(\@l,[qw(default ALL)]));
   return(undef);
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
