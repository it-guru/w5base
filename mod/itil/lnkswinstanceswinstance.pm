package itil::lnkswinstanceswinstance;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
                label         =>'Relation ID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'lnkswinstanceswinstance.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'fromswinstance',
                htmlwidth     =>'250px',
                label         =>'Instance',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['fromswi'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'toswinstance',
                htmlwidth     =>'250px',
                label         =>'target Instance',
                vjointo       =>'itil::swinstance',
                vjoineditbase =>{'cistatusid'=>"<=5"},
                vjoinon       =>['toswi'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Select(
                name          =>'conmode',
                label         =>'Relation Type',
                value         =>['RELDEPEND','RELDIST'],
                translation   =>'itil::lnkswinstanceswinstance',
                dataobjattr   =>'lnkswinstanceswinstance.conmode'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkswinstanceswinstance.comments'),

      new kernel::Field::Link(
                name          =>'fromswi',
                label         =>'from Instance ID',
                dataobjattr   =>'lnkswinstanceswinstance.fromswi'),
                                   
      new kernel::Field::Link(
                name          =>'toswi',
                label         =>'target Instance ID',
                dataobjattr   =>'lnkswinstanceswinstance.toswi'),
                                   
      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkswinstanceswinstance.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkswinstanceswinstance.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkswinstanceswinstance.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkswinstanceswinstance.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkswinstanceswinstance.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkswinstanceswinstance.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkswinstanceswinstance.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkswinstanceswinstance.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkswinstanceswinstance.realeditor')
   );
   $self->setDefaultView(qw(fromswinstance toswinstance cdate));
   $self->setWorktable("lnkswinstanceswinstance");
   return($self);
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

   my $fromswi=effVal($oldrec,$newrec,"fromswi");
   if ($fromswi==0){
      $self->LastMsg(ERROR,"invalid from instance");
      return(0);
   }
   my $toswi=effVal($oldrec,$newrec,"toswi");
   if ($toswi==0){
      $self->LastMsg(ERROR,"invalid to instance");
      return(0);
   }
   if ($toswi eq $fromswi){
      $self->LastMsg(ERROR,"invalid self referencing instance");
      return(0);
   }
   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteToInstanceValid(
                   $fromswi)){
         $self->LastMsg(ERROR,"no write access");
         return(0);
      }
   }


   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default  source));
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

   my $fromswi=defined($rec) ? $rec->{fromswi} : undef;

   my $wrok=$self->isWriteToInstanceValid($fromswi);
   return("default") if ($wrok);
   return(undef);
}


sub isWriteToInstanceValid
{
   my $self=shift;
   my $swiid=shift;

   my $userid=$self->getCurrentUserId();
   my $wrok=0;
   $wrok=1 if (!defined($swiid));
  # $wrok=1 if ($self->IsMemberOf("admin"));
   if ($self->itil::lib::Listedit::isWriteOnSwinstanceValid($swiid,
                                                            "relations")){
      $wrok=1;
   }
   return($wrok);
}











1;
