package SIMon::lnkmonpkgsoftware;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use kernel::Field::TextURL;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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
                dataobjattr   =>'lnksimonpkgsoftware.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'monpkg',
                htmlwidth     =>'250px',
                label         =>'Installationpackage',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'SIMon::monpkg',
                vjoinon       =>['monpkgid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Link(
                name          =>'monpkgid',
                label         =>'MonPkg ID',
                dataobjattr   =>'lnksimonpkgsoftware.simonpkg'),

      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'250px',
                label         =>'Software',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'software.name'),
                                                   
      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'Software ID',
                dataobjattr   =>'lnksimonpkgsoftware.software'),

      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnksimonpkgsoftware.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnksimonpkgsoftware.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnksimonpkgsoftware.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnksimonpkgsoftware.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'lnksimonpkgsoftware.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Last-Load',
                dataobjattr   =>'lnksimonpkgsoftware.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnksimonpkgsoftware.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnksimonpkgsoftware.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnksimonpkgsoftware.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnksimonpkgsoftware.realeditor'),
   );
   $self->setDefaultView(qw(monpkg software cdate));
   $self->setWorktable("lnksimonpkgsoftware");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();


   my $from="$worktable join simonpkg ".
            "on lnksimonpkgsoftware.simonpkg=simonpkg.id ".
            "join software ".
            "on lnksimonpkgsoftware.software=software.id";

   return($from);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnkitfarmasset.jpg?".$cgi->query_string());
#}

#sub SelfAsParentObject    # this method is needed because existing derevations
#{
#   return("itil::lnkitfarmasset");
#}
#

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getDetailBlockPriority
{  
   my $self=shift;
   return(qw(header default source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $monpkgid=effVal($oldrec,$newrec,"monpkgid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnMonPkgValid($monpkgid,"software")){
         $self->LastMsg(ERROR,"no access");
         return(undef);
      }
   }


   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @editgroup=("default");

   return(@editgroup) if (!defined($oldrec) && !defined($newrec));
   my $monpkgid=$oldrec->{monpkgid};
   return(@editgroup) if ($self->IsMemberOf("admin"));
   return(@editgroup) if ($self->isWriteOnMonPkgValid($monpkgid,"software"));

   return(undef);
}


sub isWriteOnMonPkgValid
{
   my $self=shift;
   my $monpkgid=shift;
   my $group=shift;

   my $monpkg=$self->getPersistentModuleObject("SIMon::monpkg");
   $monpkg->SetFilter({id=>\$monpkgid});
   my ($arec,$msg)=$monpkg->getOnlyFirst(qw(ALL));
   my @g=$monpkg->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}





1;
