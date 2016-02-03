package itil::lnksystemnfsnas;
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
use Data::Dumper;
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
                dataobjattr   =>'lnksystemnfsnas.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'systemnfsnasserver',
                label         =>'Server',
                readonly      =>1,
                vjointo       =>'itil::systemnfsnas',
                vjoinon       =>['systemnfsnasid'=>'id'],
                vjoindisp     =>'system'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'systemnfsnas',
                htmlwidth     =>'250px',
                label         =>'Export Path',
                readonly      =>1,
                vjointo       =>'itil::systemnfsnas',
                vjoinon       =>['systemnfsnasid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'Client System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'syssystemid',
                htmlwidth     =>'100px',
                group         =>'systemdata',
                label         =>'SystemID',
                readonly      =>1,
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'systemid'),

      new kernel::Field::Select(
                name          =>'systemcistatus',
                readonly      =>1,
                group         =>'systemdata',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Email(
                name          =>'sememail',
                label         =>'SeM EMail',
                group         =>'systemdata',
                depend        =>['systemid'],
                onRawValue    =>\&getApplData),

      new kernel::Field::Email(
                name          =>'tsmemail',
                label         =>'TSM EMail',
                group         =>'systemdata',
                depend        =>['systemid'],
                onRawValue    =>\&getApplData),

      new kernel::Field::Text(
                name          =>'appl',
                group         =>'systemdata',
                label         =>'Application',
                depend        =>['systemid'],
                onRawValue    =>\&getApplData),

      new kernel::Field::Text(
                name          =>'exportoptions',
                label         =>'Client Export Options',
                dataobjattr   =>'lnksystemnfsnas.exportoptions'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'lnksystemnfsnas.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnksystemnfsnas.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnksystemnfsnas.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnksystemnfsnas.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnksystemnfsnas.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnksystemnfsnas.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnksystemnfsnas.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnksystemnfsnas.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnksystemnfsnas.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnksystemnfsnas.realeditor'),

      new kernel::Field::Link(
                name          =>'systemcistatusid',
                label         =>'SystemCIStatusID',
                dataobjattr   =>'system.cistatus'),

      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'lnksystemnfsnas.system'),

      new kernel::Field::Link(
                name          =>'systemnfsnasid',
                label         =>'SystemNFSNASID',
                dataobjattr   =>'lnksystemnfsnas.systemnfsnas'),

      new kernel::Field::Link(
                name          =>'secadm',
                selectable    =>0,
                dataobjattr   =>'nfsserver.adm'),

      new kernel::Field::Link(
                name          =>'secadm2',
                selectable    =>0,
                dataobjattr   =>'nfsserver.adm2'),

      new kernel::Field::Link(
                name          =>'secadmteam',
                selectable    =>0,
                dataobjattr   =>'nfsserver.admteam'),

      new kernel::Field::Link(
                name          =>'secroles',
                selectable    =>0,
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'sectarget',
                selectable    =>0,
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                selectable    =>0,
                dataobjattr   =>'lnkcontact.targetid'),

   );
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(linenumber systemnfsnasserver system 
                            syssystemid systemnfsnas cdate));
   $self->setWorktable("lnksystemnfsnas");
   return($self);
}


sub getApplData
{
   my $self=shift;
   my $current=shift;
   my $name=$self->Name();
   my $systemid=$current->{systemid};

   my %applid;
   my %name;
   my %tsm;
   my %sem;
   my $lnkapplsystem=$self->getParent->getPersistentModuleObject(
                      "itil::lnkapplsystem");
   $lnkapplsystem->SetFilter({systemid=>\$systemid});
   my @l=$lnkapplsystem->getHashList(qw(applid));
   map({$applid{$_->{applid}}=1} @l);
   my $appl=$self->getParent->getPersistentModuleObject(
                      "itil::appl");
   if (keys(%applid)){
      $appl->SetFilter({id=>[keys(%applid)]});
      my @l=$appl->getHashList(qw(name sememail sem2email tsmemail tsm2email));
      foreach my $rec (@l){
         $name{$rec->{name}}=1 if ($rec->{name} ne "");
         $tsm{$rec->{tsmemail}}=1 if ($rec->{tsmemail} ne "");
         $sem{$rec->{sememail}}=1 if ($rec->{sememail} ne "");
      }
   }
   return([sort(keys(%name))]) if ($name eq "appl");
   return([sort(keys(%tsm))])  if ($name eq "tsmemail");
   return([sort(keys(%sem))])  if ($name eq "sememail");
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.itil.system.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                [qw(REmployee RApprentice RFreelancer RBoss)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {secadm=>\$userid},
                 {secadm2=>\$userid},
                 {secadmteam=>\@grpids},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}


sub getSqlFrom
{
   my $self=shift;
   my $from="lnksystemnfsnas left outer join system ".
            "on lnksystemnfsnas.system=system.id ".
            "left outer join systemnfsnas ".
            "on lnksystemnfsnas.systemnfsnas=systemnfsnas.id".
            " left outer join system as nfsserver ".
            "on systemnfsnas.system=nfsserver.id".
            " left outer join lnkcontact ".
            "on lnkcontact.parentobj='itil::system' ".
            "and systemnfsnas.system=lnkcontact.refid";

   return($from);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (effVal($oldrec,$newrec,"systemid")==0){
      $self->LastMsg(ERROR,"invalid system specified");
      return(undef);
   }
   return(1);
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
   my $oldrec=shift;
   my $newrec=shift;

   my $systemnfsnasid=effVal($oldrec,$newrec,"systemnfsnasid");
   my $systemnfsnas=$self->getPersistentModuleObject("itil::systemnfsnas");
   $systemnfsnas->SetFilter({id=>\$systemnfsnas});
   my ($rec,$msg)=$systemnfsnas->getOnlyFirst(qw(ALL));
   if (defined($rec)){
      if (grep(/^default$/,$systemnfsnas->isWriteValid($rec))){
         return("default","misc");
      }
   }
   return("default","misc") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default systemdata misc source));
}







1;
