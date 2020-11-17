package TS::lnkcanvas;
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
                group         =>'source',
                dataobjattr   =>'lnkcanvas.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'canvas',
                htmlwidth     =>'100px',
                label         =>'Canvas Object',
                vjointo       =>'TS::canvas',
                vjoinon       =>['canvasid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'canvasid',
                label         =>'CanvasID',
                dataobjattr   =>'lnkcanvas.canvasid'),

      new kernel::Field::Text(
                name          =>'ictono',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'ICTO-ID',
                dataobjattr   =>'lnkcanvas.ictono'),

      new kernel::Field::TextDrop(
                name          =>'icto',
                label         =>'ICTO Objectname',
                async         =>'1',
                AllowEmpty    =>1,
                htmlwidth     =>'80px',
                vjointo       =>'tscape::archappl',
                vjoinon       =>['ictoid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'ictoid',
                htmldetail    =>0,
                uploadable    =>0,
                searchable    =>0,
                label         =>'ICTO internal ID',
                dataobjattr   =>'lnkcanvas.ictoid'),

      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                searchable    =>0,
                default       =>'100',
                htmlwidth     =>'60px',
                dataobjattr   =>'lnkcanvas.fraction'),

      new kernel::Field::TextDrop(
                name          =>'vou',
                htmlwidth     =>'100px',
                label         =>'virtual Org-Unit',
                htmlwidth     =>'160px',
                vjointo       =>'TS::vou',
                vjoinon       =>['vouid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'vouid',
                label         =>'VouID',
                dataobjattr   =>'lnkcanvas.vouid'),

      new kernel::Field::Link(
                name          =>'canvascanvasid',
                label         =>'CanvasID',
                dataobjattr   =>'canvas.canvasid'),

      new kernel::Field::Link(
                name          =>'canvasownerid',
                label         =>'Canvas Owner',
                dataobjattr   =>'canvas.leader'),

      new kernel::Field::Link(
                name          =>'canvasowneritid',
                label         =>'Canvas OwnerIT',
                dataobjattr   =>'canvas.leaderit'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkcanvas.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkcanvas.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'lnkcanvas.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'lnkcanvas.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Last-Load',
                dataobjattr   =>'lnkcanvas.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkcanvas.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkcanvas.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkcanvas.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkcanvas.realeditor'),

   );
   $self->setDefaultView(qw(canvas ictono vou cdate));
   $self->setWorktable("lnkcanvas");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="lnkcanvas left outer join canvas ".
            "on lnkcanvas.canvasid=canvas.id ";
   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   if (!defined($oldrec) || effChanged($oldrec,$newrec,"ictoid")){
      my $ictoid=effVal($oldrec,$newrec,"ictoid");
      my $o=getModuleObject($self->Config,"tscape::archappl");
      if (!defined($o)){
         $self->LastMsg(ERROR,"unable to connect cape");
         return(undef);
      }
      if ($ictoid ne ""){
         $o->SetFilter({id=>\$ictoid});
         my ($archrec,$msg)=$o->getOnlyFirst(qw(archapplid));
         if (!defined($archrec)){
            $self->LastMsg(ERROR,"unable to identify archictecture record");
            return(undef);
         }
         $newrec->{ictono}=$archrec->{archapplid};
      }
      else{
         $newrec->{ictono}=undef;
      }
   }

   my $ictono=effVal($oldrec,$newrec,"ictono");
   if ($ictono ne ""){
      my $o=$self->Clone();
      my $flt={ictono=>\$ictono};
      if (defined($oldrec)){
         $flt->{id}="!".$oldrec->{id};
      }
      $o->SetFilter($flt);
      my @l=$o->getHashList(qw(canvasid fraction id vouid));
      my $curictovouid;
      my $fraction=0;
      foreach my $r (@l){
        $curictovouid=$r->{vouid} if ($r->{vouid} ne "");
        $fraction+=$r->{fraction};
      }
      my $newfraction=effVal($oldrec,$newrec,"fraction");
      my $newvoid=effVal($oldrec,$newrec,"vouid");

      if ($newvoid ne "" && $curictovouid ne ""){
         if ($newvoid ne $curictovouid){
            $self->LastMsg(ERROR,
                    "results in not unique ICTO->virtual Org relation");
            return(0);
         }
      }
      if ((0.0+$fraction+$newfraction)>100.0){
         $self->LastMsg(ERROR,"results in more then 100% ICTO relation");
         return(0);
      }
   }


   return(1);
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) || effChanged($oldrec,$newrec,"canvasid")){
      my $canvasid=effVal($oldrec,$newrec,"canvasid");
      if (!$self->isWriteOnCanvasValid($canvasid,"ictorelations")){
         $self->LastMsg(ERROR,"no write access to specified canvas object");
         return(0);
      }
   }
   return(1);
}




sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));


   if (defined($rec) && $rec->{canvasid} ne ""){
      if ($self->isWriteOnCanvasValid($rec->{canvasid},"ictorelations")){
         return("default","relations");
      }
   }
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default source ));
}


sub isWriteOnCanvasValid
{
   my $self=shift;
   my $canvasid=shift;
   my $group=shift;

   my $canvas=$self->getPersistentModuleObject("TS::canvas");
   $canvas->SetFilter({id=>\$canvasid});
   my ($arec,$msg)=$canvas->getOnlyFirst(qw(ALL));
   return(0) if (!defined($arec));
   my @g=$canvas->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}








1;
