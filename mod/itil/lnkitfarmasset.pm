package itil::lnkitfarmasset;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

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
                dataobjattr   =>'lnkitfarmasset.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'itfarm',
                htmlwidth     =>'250px',
                label         =>'Serverfarm',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::itfarm',
                vjoinon       =>['itfarmid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'itfarmid',
                label         =>'Serverfarm ID',
                dataobjattr   =>'lnkitfarmasset.itfarm'),

      new kernel::Field::Link(
                name          =>'itfarmcistatuid',
                label         =>'Serverfarm CIstatusID',
                dataobjattr   =>'itfarm.cistatus'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Fullname',
                dataobjattr   =>"concat(itfarm.fullname,'-',asset.name)"),

      new kernel::Field::TextDrop(
                name          =>'asset',
                htmlwidth     =>'250px',
                label         =>'Asset',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'asset.name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'assetfullname',
                htmlwidth     =>'250px',
                label         =>'Asset Fullname',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'Asset ID',
                dataobjattr   =>'lnkitfarmasset.asset'),

      new kernel::Field::Select(
                name          =>'assetcistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                readonly      =>1,
                vjointo       =>'base::cistatus',
                vjoinon       =>['assetcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'assetcistatusid',
                label         =>'Asset CI-Status ID',
                dataobjattr   =>'asset.cistatus'),

      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkitfarmasset.comments'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                readonly      =>1,
                htmllimit     =>'20',
                forwardSearch =>1,
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['assetid'=>'assetid'],
                vjoindisp     =>['name','systemid','cistatus']),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkitfarmasset.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkitfarmasset.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkitfarmasset.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'lnkitfarmasset.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Last-Load',
                dataobjattr   =>'lnkitfarmasset.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkitfarmasset.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkitfarmasset.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkitfarmasset.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkitfarmasset.realeditor'),
   );
   $self->setDefaultView(qw(itfarm asset cdate));
   $self->setWorktable("lnkitfarmasset");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();


   my $from="$worktable left outer join asset ".
            "on lnkitfarmasset.asset=asset.id ".
            "left outer join itfarm ".
            "on lnkitfarmasset.itfarm=itfarm.id";

   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkitfarmasset.jpg?".$cgi->query_string());
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::lnkitfarmasset");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getDetailBlockPriority
{  
   my $self=shift;
   return(qw(header default systems source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $itfarmid=effVal($oldrec,$newrec,"itfarmid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnITFarmValid($itfarmid,"assets")){
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
   my $itfarmid=$oldrec->{itfarmid};
   return(@editgroup) if ($self->IsMemberOf("admin"));
   return(@editgroup) if ($self->isWriteOnITFarmValid($itfarmid,"assets"));

   return(undef);
}





1;
