package itil::lnkapplsystem;
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
                dataobjattr   =>'lnkapplsystem.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'appl.name'),
                                                   
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

      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                htmlwidth     =>'60px',
                dataobjattr   =>'lnkapplsystem.fraction'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkapplsystem.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplsystem.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkapplsystem.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplsystem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplsystem.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkapplsystem.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplsystem.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplsystem.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkapplsystem.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkapplsystem.realeditor'),

      new kernel::Field::Mandator(
                group         =>'applinfo',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'ApplMandatorID',
                group         =>'applinfo',
                dataobjattr   =>'appl.mandator'),

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

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                group         =>'applinfo',
                translation   =>'itil::appl',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Text(
                name          =>'applcustomerprio',
                label         =>'Customers Application Prioritiy',
                translation   =>'itil::appl',
                group         =>'applinfo',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetID',
                dataobjattr   =>'system.asset'),

      new kernel::Field::Link(
                name          =>'customerid',
                label         =>'CustomerID',
                dataobjattr   =>'appl.customer'),

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
                name          =>'applid',
                label         =>'ApplID',
                dataobjattr   =>'lnkapplsystem.appl'),
                                                   
      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemId',
                dataobjattr   =>'lnkapplsystem.system'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'MandatorID',
                dataobjattr   =>'appl.mandator'),
   );
   $self->setDefaultView(qw(appl system systemsystemid fraction cdate));
   $self->setWorktable("lnkapplsystem");
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplsystem.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplsystem left outer join appl ".
            "on lnkapplsystem.appl=appl.id ".
            "left outer join system ".
            "on lnkapplsystem.system=system.id";
   return($from);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
#      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
#                                  ["REmployee","RMember"],"both");
#      my @grpids=keys(%grps);
#      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
#                 {databossid=>$userid},
#                 {semid=>$userid},       {sem2id=>$userid},
#                 {tsmid=>$userid},       {tsm2id=>$userid},
#                 {businessteamid=>\@grpids},
#                 {responseteamid=>\@grpids},
#                 {sectargetid=>\$userid,sectarget=>\'base::user',
#                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"},
#                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
#                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"}
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

   if ((!defined($oldrec) && !defined($newrec->{applid})) ||
       (defined($newrec->{applid}) && $newrec->{applid}==0)){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{systemid})) ||
       (defined($newrec->{systemid}) && $newrec->{systemid}==0)){
      $self->LastMsg(ERROR,"invalid contract specified");
      return(undef);
   }
   my $applid=effVal($oldrec,$newrec,"applid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnApplValid($applid,"systems")){
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
   my $applid=effVal($oldrec,$newrec,"applid");

   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if ($self->isWriteOnApplValid($applid,"systems"));
   return("default") if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default misc applinfo systeminfo ));
}







1;
