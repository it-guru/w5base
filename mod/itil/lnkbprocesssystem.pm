package itil::lnkbprocesssystem;
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
   $param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnkbprocesssystem.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'bprocess',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::bprocess',
                vjoinon       =>['bprocessid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'businessprocess.name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'system.name'),
                                                   
      new kernel::Field::Select(
                name          =>'systemcistatus',
                group         =>'systeminfo',
                label         =>'System CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                label         =>'SystemID',
                group         =>'systeminfo',
                dataobjattr   =>'system.systemid'),

      new kernel::Field::Text(
                name          =>'shortdesc',
                label         =>'Short Description',
                translation   =>'itil::system',
                group         =>'systeminfo',
                dataobjattr   =>'system.shortdesc'),

      new kernel::Field::Select(
                name          =>'osrelease',
                group         =>'systeminfo',
                translation   =>'itil::system',
                selectwidth   =>'40%',
                readonly      =>1,
                label         =>'OS-Release',
                vjointo       =>'itil::osrelease',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Select(
                name          =>'isprod',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                selectwidth   =>'30%',
                label         =>'Productionsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_prod'),

      new kernel::Field::Select(
                name          =>'istest',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                selectwidth   =>'30%',
                label         =>'Testsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_test'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkbprocesssystem.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkbprocesssystem.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkbprocesssystem.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkbprocesssystem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkbprocesssystem.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkbprocesssystem.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkbprocesssystem.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkbprocesssystem.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkbprocesssystem.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkbprocesssystem.realeditor'),

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
                translation   =>'itil::bprocess',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'bprocesscistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'businessprocess.cistatus'),

      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetID',
                dataobjattr   =>'system.asset'),

      new kernel::Field::Link(
                name          =>'customerid',
                label         =>'CustomerID',
                dataobjattr   =>'businessprocess.customer'),

      new kernel::Field::Select(
                name          =>'isdevel',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                selectwidth   =>'30%',
                label         =>'Developmentsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_devel'),

      new kernel::Field::Select(
                name          =>'iseducation',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                selectwidth   =>'30%',
                label         =>'Educationsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_education'),

      new kernel::Field::Select(
                name          =>'isapprovtest',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                selectwidth   =>'30%',
                label         =>'Approval Testsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_approvtest'),

      new kernel::Field::Select(
                name          =>'isreference',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                selectwidth   =>'30%',
                label         =>'Referencesystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_reference'),

                                                   
      new kernel::Field::Link(
                name          =>'systemcistatusid',
                label         =>'SystemCiStatusID',
                dataobjattr   =>'system.cistatus'),
                                                   
      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetId',
                dataobjattr   =>'system.asset'),
                                                   
      new kernel::Field::Link(
                name          =>'bprocessid',
                label         =>'ApplID',
                dataobjattr   =>'lnkbprocesssystem.bprocess'),
                                                   
      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemId',
                dataobjattr   =>'lnkbprocesssystem.system'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'MandatorID',
                dataobjattr   =>'businessprocess.mandator'),
   );
   $self->setDefaultView(qw(bprocess system systemsystemid fraction cdate));
   $self->setWorktable("lnkbprocesssystem");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkbprocesssystem left outer join businessprocess ".
            "on lnkbprocesssystem.bprocess=businessprocess.id ".
            "left outer join system ".
            "on lnkbprocesssystem.system=system.id";
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
   if ((!defined($oldrec) && !defined($newrec->{systemid})) ||
       (defined($newrec->{systemid}) && $newrec->{systemid}==0)){
      $self->LastMsg(ERROR,"invalid system specified");
      return(undef);
   }
   my $bprocessid=effVal($oldrec,$newrec,"bprocessid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnBProcessValid($bprocessid,"systems")){
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

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bprocessid=effVal($oldrec,$newrec,"bprocessid");

   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if ($self->isWriteOnBProcessValid($bprocessid,"systems"));
   return("default") if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default misc bprocessinfo systeminfo ));
}







1;
