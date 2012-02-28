package itil::lnkapplinvoicestorcum;
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
use strict;
use vars qw(@ISA);
use kernel;
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                translation   =>'itil::lnkapplinvoicestor',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'system',
                translation   =>'itil::lnkapplinvoicestor',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'storageclass',
                translation   =>'itil::lnkapplinvoicestor',
                htmlwidth     =>'180px',
                htmleditwidth =>'280px',
                label         =>'Storage class',
                vjointo       =>'itil::storageclass',
                vjoinon       =>['storageclassid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Link(
                name          =>'storageclassid',
                translation   =>'itil::lnkapplinvoicestor',
                selectfix     =>1,
                label         =>'Storage class id',
                dataobjattr   =>'lnkapplinvoicestorage.storageclass'),
                                                   
      new kernel::Field::Select(
                name          =>'storagetype',
                translation   =>'itil::lnkapplinvoicestor',
                htmlwidth     =>'100px',
                htmleditwidth =>'200px',
                label         =>'Storage type',
                vjointo       =>'itil::storagetype',
                vjoinon       =>['storagetypeid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Link(
                name          =>'storagetypeid',
                translation   =>'itil::lnkapplinvoicestor',
                label         =>'Storage type id',
                selectfix     =>1,
                dataobjattr   =>'lnkapplinvoicestorage.storagetype'),

      new kernel::Field::Select(
                name          =>'storageusage',
                translation   =>'itil::lnkapplinvoicestor',
                htmlwidth     =>'100px',
                htmleditwidth =>'100px',
                label         =>'Usage',
                value         =>['filesystem',
                                 'raw device'],
                dataobjattr   =>'lnkapplinvoicestorage.storageusage'),
                                                   
      new kernel::Field::Number(
                name          =>'capacity',
                translation   =>'itil::lnkapplinvoicestor',
                unit          =>'MB',
                precision     =>0,
                label         =>'Capacity',
                dataobjattr   =>'sum(lnkapplinvoicestorage.capacity)'),

      new kernel::Field::Date(
                name          =>'durationstart',
                translation   =>'itil::lnkapplinvoicestor',
                label         =>'Duration Start',
                group         =>'hidden',
                searchable    =>1,
                dataobjattr   =>'lnkapplinvoicestorage.durationstart'),

      new kernel::Field::Date(
                name          =>'durationend',
                translation   =>'itil::lnkapplinvoicestor',
                group         =>'hidden',
                searchable    =>1,
                label         =>'Duration End',
                dataobjattr   =>'lnkapplinvoicestorage.durationend'),

      new kernel::Field::Mandator(
                group         =>'applinfo',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                translation   =>'itil::lnkapplinvoicestor',
                label         =>'ApplMandatorID',
                group         =>'applinfo',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                translation   =>'itil::lnkapplinvoicestor',
                readonly      =>1,
                htmlwidth     =>'80px',
                group         =>'applinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Text(
                name          =>'applapplid',
                translation   =>'itil::lnkapplinvoicestor',
                label         =>'ApplicationID',
                readonly      =>1,
                group         =>'applinfo',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::TextDrop(
                name          =>'applconumber',
                translation   =>'itil::lnkapplinvoicestor',
                htmlwidth     =>'100px',
                group         =>'applinfo',
                htmdetail     =>0,
                readonly      =>1,
                label         =>'Application costcenter',
                dataobjattr   =>'appl.conumber'),


      new kernel::Field::Select(
                name          =>'systemcistatus',
                translation   =>'itil::lnkapplinvoicestor',
                readonly      =>1,
                group         =>'systeminfo',
                label         =>'System CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'systemcistatusid',
                label         =>'SystemCiStatusID',
                dataobjattr   =>'system.cistatus'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                translation   =>'itil::lnkapplinvoicestor',
                label         =>'SystemID',
                readonly      =>1,
                group         =>'systeminfo',
                dataobjattr   =>'system.systemid'),

      new kernel::Field::TextDrop(
                name          =>'systemconumber',
                translation   =>'itil::lnkapplinvoicestor',
                htmlwidth     =>'100px',
                htmdetail     =>0,
                readonly      =>1,
                group         =>'systeminfo',
                label         =>'System costcenter',
                dataobjattr   =>'system.conumber'),

      new kernel::Field::Link(
                name          =>'systemid',
                selectfix     =>1,
                label         =>'SystemID',
                dataobjattr   =>'lnkapplinvoicestorage.system'),

      new kernel::Field::Link(
                name          =>'applid',
                selectfix     =>1,
                label         =>'SystemJobID',
                dataobjattr   =>'lnkapplinvoicestorage.appl'),

      new kernel::Field::Link(
                name          =>'applname',
                label         =>'Application name',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::Link(
                name          =>'semid',
                dataobjattr   =>'appl.sem'),

      new kernel::Field::Link(
                name          =>'sem2id',
                dataobjattr   =>'appl.sem2'),

      new kernel::Field::Link(
                name          =>'tsmid',
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::Link(
                name          =>'opmid',
                dataobjattr   =>'appl.opm'),

      new kernel::Field::Link(
                name          =>'opm2id',
                dataobjattr   =>'appl.opm2'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                dataobjattr   =>'appl.responseteam'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'appl.businessteam'),

   );

   $self->setDefaultView(qw(linenumber appl system storageclass 
                            storagetype capacity));
   $self->setWorktable("lnkapplinvoicestorage");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplinvoicestorage left outer join system ".
            "on lnkapplinvoicestorage.system=system.id ".
            "left outer join storageclass ".
            "on lnkapplinvoicestorage.storageclass=storageclass.id ".
            "left outer join storagetype ".
            "on lnkapplinvoicestorage.storagetype=storagetype.id ".
            "left outer join appl ".
            "on lnkapplinvoicestorage.appl=appl.id";
   return($from);
}

sub getSqlGroup
{
   my $self=shift;
   my $group="lnkapplinvoicestorage.appl,".
             "lnkapplinvoicestorage.system,".
             "lnkapplinvoicestorage.storageclass,".
             "lnkapplinvoicestorage.storagetype";
   return($group);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RCFManager RCFManager2
                                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>\$userid},
                 {semid=>\$userid},       {sem2id=>\$userid},
                 {tsmid=>\$userid},       {tsm2id=>\$userid},
                 {opmid=>\$userid},       {opm2id=>\$userid},
                 {businessteamid=>\@grpids},
                 {responseteamid=>\@grpids}
                ]);
   }
   return($self->SetFilter(@flt));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplinvoicestor.jpg?".$cgi->query_string());
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   return(0);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (defined($rec));
   return("default");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return;
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_durationstart"))){
     Query->Param("search_durationstart"=>"<now");
   }
   if (!defined(Query->Param("search_durationend"))){
     Query->Param("search_durationend"=>">now OR [EMPTY]");
   }
}










1;
