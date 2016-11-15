package base::campus;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(        
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'campus.id'),
                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmldetail    =>0,
                dataobjattr   =>'campus.fullname'),

      new kernel::Field::Text(      
                name          =>'label',
                label         =>'Label',
                dataobjattr   =>'campus.label'),

      new kernel::Field::Text(
                name          =>'campusid',
                htmlwidth     =>'100px',
                htmleditwidth =>'150px',
                readonly     =>sub{
                   my $self=shift;
                   if ($self->getParent->IsMemberOf("admin")){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Campus ID',
                dataobjattr   =>'campus.campusid'),

      new kernel::Field::TextDrop(
                name          =>'location',
                label         =>'primary Location',
                vjointo       =>'base::location',
                vjoineditbase =>{cistatusid=>'4'},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'primary LocationID',
                htmlwidth     =>'200px',
                dataobjattr   =>'campus.locationid'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'campus.databoss'),

#      new kernel::Field::SubList(
#                name          =>'locations',
#                label         =>'locations',
#                group         =>'locations',
#                subeditmsk    =>'subedit.locations',
#                forwardSearch =>1,
#                vjointo       =>'base::lnkcampussubloc',
#                vjoinon       =>['id'=>'plocationid'],
#                vjoindisp     =>['location']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::Link(
                name          =>'isprim',
                label         =>'is primary Location',
                dataobjattr   =>'campus.isprim'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'campus.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'campus.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'campus.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'campus.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'campus.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'campus.realeditor'),


   );
   $self->setDefaultView(qw(fullname));
   $self->setWorktable("campus");
   return($self);
}


sub Validate
{
   my ($self,$oldrec,$newrec)=@_;

   my $locationid=effVal($oldrec,$newrec,"locationid");

   if ($locationid eq ""){
      $self->LastMsg(ERROR,"no primary Location specified"); 
      return(undef);
   }
   my $loc=getModuleObject($self->Config,"base::location");
   $loc->SetFilter({id=>\$locationid});
   my ($locrec)=$loc->getOnlyFirst(qw(country location));
   if (!defined($locrec)){
      $self->LastMsg(ERROR,"can not identify location record"); 
      return(undef);
   }
   my $label=effVal($oldrec,$newrec,"label");
   my $fullname=effVal($oldrec,$newrec,"fullname");
   my $newfullname="CAMPUS:".$locrec->{country}."-".$locrec->{location};
   if ($label ne ""){
      $newfullname.=":".$label;
   } 
   $newfullname=~s/\s/_/g;
   if ($newfullname ne $fullname){
      $newrec->{fullname}=$newfullname;
   }

   $newrec->{isprim}='1';

   ########################################################################
   # standard security handling
   #
   my $userid=$self->getCurrentUserId();
   if (!defined($oldrec)){
      if (!defined($newrec->{databossid}) ||
          $newrec->{databossid}==0){
         my $userid=$self->getCurrentUserId();
         $newrec->{databossid}=$userid;
      }
   }
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }

   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default contacts 
              locations source));
}




sub isViewValid
{
   my ($self,$rec)=@_;
   if (!defined($rec)){
      return("header","default");
   }
   return("ALL");
}

sub isWriteValid
{
   my ($self,$rec)=@_;
   if ($self->IsMemberOf("admin")){
      return("default");
   }
   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/campus.jpg?".$cgi->query_string());
}

1;
