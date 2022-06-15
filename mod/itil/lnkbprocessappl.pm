package itil::lnkbprocessappl;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnkbprocessappl.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'bprocess',
                htmlwidth     =>'250px',
                label         =>'Business process',
                vjointo       =>'itil::bprocess',
                vjoinon       =>['bprocessid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'businessprocess.name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'100px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'appl.name'),
                                                   
      new kernel::Field::Select(
                name          =>'applcistatus',
                group         =>'applinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'applapplid',
                label         =>'ApplicationID',
                group         =>'applinfo',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::Boolean(
                name          =>'autobpnotify',
                group         =>'eventnotification',
                label         =>
                'automatic notification of businessprocess impact',
                dataobjattr   =>'lnkbprocessappl.autobpnotify'),

      new kernel::Field::Textarea(
                name          =>'applfailinfo',
                group         =>'eventnotification',
                label         =>
                'impact to businessproces on application impairment',
                dataobjattr   =>'lnkbprocessappl.appfailinfo'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkbprocessappl.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkbprocessappl.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkbprocessappl.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkbprocessappl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkbprocessappl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkbprocessappl.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkbprocessappl.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkbprocessappl.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkbprocessappl.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkbprocessappl.realeditor'),

      new kernel::Field::Mandator(
                group         =>'bprocessinfo',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'ApplMandatorID',
                group         =>'bprocessinfo',
                dataobjattr   =>'businessprocess.mandator'),

      new kernel::Field::Select(
                name          =>'bprocesscistatus',
                group         =>'bprocessinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['bprocesscistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Text(
                name          =>'bprocessbprocessid',
                label         =>'ApplicationID',
                group         =>'bprocessinfo',
                dataobjattr   =>'businessprocess.id'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                group         =>'bprocessinfo',
                translation   =>'crm::businessprocess',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'bprocesscistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'businessprocess.cistatus'),

      new kernel::Field::Link(
                name          =>'customerid',
                label         =>'CustomerID',
                dataobjattr   =>'businessprocess.customer'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),
                                                   
      new kernel::Field::Link(
                name          =>'bprocessid',
                label         =>'ApplID',
                dataobjattr   =>'lnkbprocessappl.bprocess'),
                                                   
      new kernel::Field::Link(
                name          =>'applid',
                label         =>'SystemId',
                dataobjattr   =>'lnkbprocessappl.appl'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'MandatorID',
                dataobjattr   =>'businessprocess.mandator'),
   );
   $self->setDefaultView(qw(bprocess appl applapplid fraction cdate));
   $self->setWorktable("lnkbprocessappl");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkbprocessappl left outer join businessprocess ".
            "on lnkbprocessappl.bprocess=businessprocess.id ".
            "left outer join appl ".
            "on lnkbprocessappl.appl=appl.id";
   return($from);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.bprocess.read 
                              w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                ]);
   }
   return($self->SetFilter(@flt));
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ((!defined($oldrec) && !defined($newrec->{bprocessid})) ||
       (defined($newrec->{bprocessid}) && $newrec->{bprocessid}==0)){
      $self->LastMsg(ERROR,"invalid business process specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{applid})) ||
       (defined($newrec->{applid}) && $newrec->{applid}==0)){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
   my $bprocessid=effVal($oldrec,$newrec,"bprocessid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnBProcessValid($bprocessid,"applications")){
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
   my $bprocessid=effVal($oldrec,$newrec,"bprocessid");
   my @rw=qw(default eventnotification);

   return(@rw) if (!defined($oldrec) && !defined($newrec));
   return(@rw) if ($self->IsMemberOf("admin"));
   return(@rw) if ($self->isWriteOnBProcessValid($bprocessid,
                                                       "applications"));
   return(@rw) if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));

   return();
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
   return(qw(header default eventnotification misc bprocessinfo applinfo ));
}







1;
