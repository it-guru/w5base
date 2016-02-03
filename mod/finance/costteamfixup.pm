package finance::costteamfixup;
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
use kernel::Field;
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);



   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'costteamfixup.id'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'team',
                htmlwidth     =>'300px',
                label         =>'Team',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['grpid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'120px',
                label         =>'CO-Number',
                dataobjattr   =>'costteamfixup.name'),

      new kernel::Field::Text(
                name          =>'costatus',
                htmlwidth     =>'120px',
                label         =>'CO-Status',
                weblinkto     =>undef,
                weblinkon     =>undef,
                vjoinon       =>['name'=>'name'],
                vjointo       =>'finance::costcenter',
                vjoindisp     =>'cistatus'),

      new kernel::Field::Select(
                name          =>'fixupmode',
                label         =>'Fixup mode',
                value         =>['fix','min','max','delta'],
                htmleditwidth =>'100px',
                dataobjattr   =>'costteamfixup.fixupmode'),

      new kernel::Field::Number(
                name          =>'fixupminutes',
                htmleditwidth =>'100',
                unit          =>'Min.',
                label         =>'Fixup time/per month',
                dataobjattr   =>'costteamfixup.fixupminutes'),

      new kernel::Field::Date(
                name          =>'durationstart',
                label         =>'Fixup duration start',
                dataobjattr   =>'costteamfixup.durationstart'),

      new kernel::Field::Date(
                name          =>'durationend',
                label         =>'Fixup duration end',
                dataobjattr   =>'costteamfixup.durationend'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'costteamfixup.comments'),

#      new kernel::Field::Text(
#                name          =>'accarea',
#                htmlwidth     =>'120px',
#                label         =>'Accounting Area',
#                dataobjattr   =>'costteamfixup.accarea'),

      new kernel::Field::Link(
                name          =>'grpid',
                dataobjattr   =>'costteamfixup.grpid'),


      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'costteamfixup.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'costteamfixup.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'costteamfixup.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'costteamfixup.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'costteamfixup.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'costteamfixup.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'costteamfixup.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'costteamfixup.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'costteamfixup.realeditor'),
   

   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(team name costatus fixupmode fixupminutes mdate));
   $self->setWorktable("costteamfixup");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default delmgmt contacts control misc source));
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf("admin")){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
              [qw(REmployee RApprentice RFreelancer RBoss)],
                                  "direct");
      my @grpids=keys(%grps);
      push(@flt,[ {grpid=>\@grpids} ]);
   }
   return($self->SetFilter(@flt));
}





sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/finance/load/costteamfixup.jpg?".$cgi->query_string());
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

#   return(1) if ($self->IsMemberOf("admin"));

   my $grpid=$rec->{grpid};
   if ($grpid=~m/^\d+$/){
      if ($self->IsMemberOf($grpid,["RBoss","RBoss2"],"direct")){
         return(1);
      }
   }
   if ($self->IsMemberOf("admin")){
      return(1);
   }
   $self->LastMsg(ERROR,"delete only allowed for the team boss");
   
   return(0);
}

sub InitNew
{
   my $self=shift;

   my $initteam=$self->getInitiatorGroupsOf($self->getCurrentUserId());
   Query->Param("Formated_durationstart"=>$self->T("now"));
   Query->Param("Formated_team"=>$initteam);
   my @l=$self->getInitiatorGroupsOf($self->getCurrentUserId());
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=effVal($oldrec,$newrec,"name");
   if ($name=~m/^\s*$/ || !($name=~m/^\d+$/)){
      $self->LastMsg(ERROR,"invalid or missing co number");
      return(0);
   }

   my $grpid=effVal($oldrec,$newrec,"grpid");
   if ($grpid=~m/^\s*$/ || !($grpid=~m/^\d+$/)){
      $self->LastMsg(ERROR,"invalid or missing team");
      return(0);
   }
   else{
      if (!$self->IsMemberOf("admin")){
         if (!($self->IsMemberOf($grpid,["RMember",
                                       "REmployee","RBackoffice"],"direct"))){
            $self->LastMsg(ERROR,"you are not member of target group");
            return(0);
         }
      }
   }
   if (defined($oldrec)){
      my $grpid=$oldrec->{grpid};
      if (!$self->IsMemberOf("admin")){
         if (!($self->IsMemberOf($grpid,["RMember",
                                       "REmployee","RBackoffice"],"direct"))){
            $self->LastMsg(ERROR,"you are not member of old group");
            return(0);
         }
      }
   }
   return(1);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   return(qw(default header)) if (!defined($rec));
   return(qw(ALL));
   return(undef);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   if (defined($rec)){
      my $grpid=$rec->{grpid};
      if ($self->IsMemberOf("admin")){
         return(qw(ALL));
      }
      else{
         if ($grpid=~m/^\d+$/){
            if ($self->IsMemberOf($grpid,["RBoss","RBoss2",
                                          "REmployee","RBackoffice"],"direct")){
               return(qw(ALL));
            }
         }
      }
   }
   else{
      return(qw(ALL));
   }
   return(undef);
}


1;
