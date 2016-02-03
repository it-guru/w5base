package base::lnklocationgrp;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnklocationgrp.id'),


      new kernel::Field::TextDrop(
                name          =>'location',
                label         =>'Location',
                vjointo       =>'base::location',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'locationid',
                dataobjattr   =>'lnklocationgrp.location'),

      new kernel::Field::Group(
                name          =>'grp',
                label         =>'Organisation',
                vjoinon       =>'grpid'),

      new kernel::Field::Link(
                name          =>'grpid',
                readonly      =>1,
                group         =>'rel',
                dataobjattr   =>'lnklocationgrp.grp'),

      new kernel::Field::Select(
                name          =>'relmode',
                label         =>'relation mode',
                value         =>['RMbusinesrel1','RMbusinesrel2',
                                 'RMbusinesrel3'],
                dataobjattr   =>'lnklocationgrp.relmode'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmldetail    =>0,
                label         =>'Fullname',
                depend        =>['location','relmode','grp'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $rec=shift;

                   my $l=$self->getParent->getField("location")->
                         FormatedDetail($rec,"AscV01");
                   my $r=$self->getParent->getField("relmode")->
                         FormatedDetail($rec,"AscV01");
                   my $g=$self->getParent->getField("grp")->
                         FormatedDetail($rec,"AscV01");
                   return("$l-$g-$r");
                }),

      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnklocationgrp.comments'),

      new kernel::Field::Databoss(
                group         =>'locinfos'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'location.databoss'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnklocationgrp.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnklocationgrp.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnklocationgrp.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnklocationgrp.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnklocationgrp.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnklocationgrp.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnklocationgrp.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnklocationgrp.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnklocationgrp.realeditor')
   );
   $self->setDefaultView(qw(location grp relmode cdate));
   $self->setWorktable("lnklocationgrp");
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnklocationgrp.jpg?".$cgi->query_string());
#}
         

sub getDetailBlockPriority
{  
   my $self=shift;
   return(qw(header default locinfos source));
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $grpid=effVal($oldrec,$newrec,"grpid");
   if ($grpid eq ""){
      $self->LastMsg(ERROR,"no group selected with marked as oranisation");
      return(undef);
   }
   my $locationid=effVal($oldrec,$newrec,"locationid");
   if ($locationid eq ""){
      $self->LastMsg(ERROR,"invalid location");
      return(undef);
   }
   if (!$self->isLocationWriteable($locationid)){
         $self->LastMsg(ERROR,"no write access to requested location");
         return(undef);
   }
   return(1);
}

sub isLocationWriteable
{
   my $self=shift;
   my $locationid=shift;

   my $loc=getModuleObject($self->Config,"base::location");

   $loc->SetFilter({id=>\$locationid});
   my ($locrec,$msg)=$loc->getOnlyFirst(qw(ALL));
   if (!defined($locrec)){
      $self->LastMsg(ERROR,"locatioid does not exists");
      return(undef);
   }
   if ($self->isDataInputFromUserFrontend()){
      my @acl=$loc->isWriteValid($locrec);
      if (!in_array(\@acl,"grprelations")){
         return(undef);
      }
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join location ".
          "on $worktable.location=location.id ");
}





sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));
   if (defined($oldrec)){
      if (!$self->isLocationWriteable($oldrec->{locationid})){
         return(undef);
      }
   }

   return("default");
}





1;
