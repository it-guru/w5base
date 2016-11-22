package base::lnkcampussubloc;
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
                                  
      new kernel::Field::TextDrop(
                name          =>'location',
                label         =>'Location',
                vjointo       =>'base::location',
                vjoineditbase =>{cistatusid=>'4'},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'primary LocationID',
                htmlwidth     =>'200px',
                dataobjattr   =>'campus.locationid'),

      new kernel::Field::Link(
                name          =>'isprim',
                label         =>'is primary Location',
                dataobjattr   =>'campus.isprim'),

      new kernel::Field::TextDrop(
                name          =>'pcampus',
                label         =>'Campus',
                vjointo       =>'base::campus',
                vjoineditbase =>{cistatusid=>'<6'},
                vjoinon       =>['pcampusid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'pcampusid',
                label         =>'parent CampusID',
                htmlwidth     =>'200px',
                dataobjattr   =>'campus.plocationid'),


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
   $self->setDefaultView(qw(pcampus location));
   $self->setWorktable("campus");
   return($self);
}


sub Validate
{
   my ($self,$oldrec,$newrec)=@_;

   my $locationid=effVal($oldrec,$newrec,"locationid");

   if ($locationid eq ""){
      $self->LastMsg(ERROR,"no secondary Location specified"); 
      return(undef);
   }
   my $pcampusid=effVal($oldrec,$newrec,"pcampusid");
   if ($pcampusid eq "" ||
       !$self->isWriteOnCampusValid($pcampusid,"seclocations")){
      $self->LastMsg(ERROR,"no write access to specified campus"); 
      return(undef);
   }

   my $campus=$self->getPersistentModuleObject("base::campus");
   $campus->SetFilter({id=>\$pcampusid});
   my ($crec,$msg)=$campus->getOnlyFirst(qw(ALL));

   my $location=$self->getPersistentModuleObject("base::location");
   $location->SetFilter({id=>\$locationid});
   my ($srec,$msg)=$location->getOnlyFirst(qw(ALL));
   $location->ResetFilter();
   $location->SetFilter({id=>\$crec->{locationid}});
   my ($prec,$msg)=$location->getOnlyFirst(qw(ALL));

   if (!defined($prec) || !defined($srec) ||
       $prec->{country} ne $srec->{country} ||
       $prec->{location} ne $srec->{location} ){
      $self->LastMsg(ERROR,
                     "secondary location does not match primary location"); 
      return(undef);
   }


  

   $newrec->{isprim}=undef;

   return(1);
}


sub isWriteOnCampusValid
{
   my $self=shift;
   my $pcampusid=shift;
   my $group=shift;

   my $campus=$self->getPersistentModuleObject("base::campus");
   $campus->SetFilter({id=>\$pcampusid});
   my ($crec,$msg)=$campus->getOnlyFirst(qw(ALL));
   my @g=$campus->isWriteValid($crec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}



sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="(campus.isprim is null)";
   return($where);
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
   return("default") if (!defined($rec));
   if ($self->IsMemberOf("admin")){
      return("default");
   }
   if ($self->isWriteOnCampusValid($rec->{pcampusid},"seclocations")){
      return("default");
   }
   
   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/location.jpg?".$cgi->query_string());
}

1;
