package itil::lnkapplinvoicestor;
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

      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                group         =>'source',
                searchable    =>0,
                dataobjattr   =>'lnkapplinvoicestorage.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'storageclass',
                htmlwidth     =>'180px',
                htmleditwidth =>'280px',
                label         =>'Storage class',
                vjointo       =>'itil::storageclass',
                vjoinon       =>['storageclassid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Link(
                name          =>'storageclassid',
                label         =>'Storage class id',
                dataobjattr   =>'lnkapplinvoicestorage.storageclass'),
                                                   
      new kernel::Field::Select(
                name          =>'storagetype',
                htmlwidth     =>'100px',
                htmleditwidth =>'200px',
                label         =>'Storage type',
                vjointo       =>'itil::storagetype',
                vjoinon       =>['storagetypeid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Link(
                name          =>'storagetypeid',
                label         =>'Storage type id',
                dataobjattr   =>'lnkapplinvoicestorage.storagetype'),

      new kernel::Field::Select(
                name          =>'storageusage',
                htmlwidth     =>'100px',
                htmleditwidth =>'100px',
                label         =>'Usage',
                value         =>['filesystem',
                                 'raw device'],
                dataobjattr   =>'lnkapplinvoicestorage.storageusage'),
                                                   
      new kernel::Field::Number(
                name          =>'capacity',
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $d=shift;
                   my $current=shift;
                   return("MB") if ($mode ne "HtmlDetail");
                   $d=sprintf("MB &nbsp;&nbsp;(%.1lf GB - tech: %.1lf GB)",
                              $d/1000.0,$d/1024.0);
                   $d=~s/\./,/g;
                   return($d);
                },
                precision     =>0,
                label         =>'Capacity',
                dataobjattr   =>'lnkapplinvoicestorage.capacity'),

      new kernel::Field::Date(
                name          =>'durationstart',
                group         =>'duration',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   if (defined($current) && $current->{durationstart} ne ""){
                      my $d=CalcDateDuration($current->{durationstart},
                                             NowStamp("en"));
                      if ($d->{totalminutes}>20160){ # modify only allowed 
                                                     # for 14 days
                         return(1);
                      }
                   }
                   return(0);
                },
                label         =>'Duration Start',
                dataobjattr   =>'lnkapplinvoicestorage.durationstart'),

      new kernel::Field::Date(
                name          =>'durationend',
                group         =>'duration',
                label         =>'Duration End',
                dataobjattr   =>'lnkapplinvoicestorage.durationend'),

      new kernel::Field::Text(
                name          =>'ordernumber',
                label         =>'Ordernumber',
                dataobjattr   =>'lnkapplinvoicestorage.ordernumber'),

      new kernel::Field::Boolean(
                name          =>'use_as_fs',
                group         =>'logicalusage',
                htmlhalfwidth =>1,
                label         =>'normal filesystem',
                dataobjattr   =>'lnkapplinvoicestorage.use_as_fs'),

      new kernel::Field::Boolean(
                name          =>'use_as_db',
                group         =>'logicalusage',
                htmlhalfwidth =>1,
                label         =>'database',
                dataobjattr   =>'lnkapplinvoicestorage.use_as_db'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'lnkapplinvoicestorage.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplinvoicestorage.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkapplinvoicestorage.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplinvoicestorage.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplinvoicestorage.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkapplinvoicestorage.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplinvoicestorage.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplinvoicestorage.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkapplinvoicestorage.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkapplinvoicestorage.realeditor'),

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
                readonly      =>1,
                htmlwidth     =>'80px',
                group         =>'applinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'applcistatusid',
                group         =>'applinfo',
                label         =>'Interface: Application CI-State ID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Text(
                name          =>'applapplid',
                label         =>'ApplicationID',
                readonly      =>1,
                group         =>'applinfo',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::TextDrop(
                name          =>'applconumber',
                htmlwidth     =>'100px',
                group         =>'applinfo',
                htmdetail     =>0,
                readonly      =>1,
                label         =>'Application costcenter',
                dataobjattr   =>'appl.conumber'),


      new kernel::Field::Select(
                name          =>'systemcistatus',
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
                label         =>'SystemID',
                readonly      =>1,
                group         =>'systeminfo',
                dataobjattr   =>'system.systemid'),

      new kernel::Field::TextDrop(
                name          =>'systemconumber',
                htmlwidth     =>'100px',
                htmdetail     =>0,
                readonly      =>1,
                group         =>'systeminfo',
                label         =>'System costcenter',
                dataobjattr   =>'system.conumber'),

      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'lnkapplinvoicestorage.system'),

      new kernel::Field::Link(
                name          =>'applid',
                selectfix     =>1,
                label         =>'SystemJobID',
                dataobjattr   =>'lnkapplinvoicestorage.appl'),

      new kernel::Field::Interface(
                name          =>'applname',
                label         =>'Interface: Application name',
                group         =>'applinfo',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Link(
                name          =>'fullname',
                readonly      =>1,
                label         =>'Storage name',
                dataobjattr   =>'concat(appl.name," @ ",system.name,'.
                                '" @ ",storagetype.name,'.
                                '" @ ",storageclass.name)'),

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
   $self->{history}=[qw(insert modify delete)];

   $self->setDefaultView(qw(linenumber system appl storageclass 
                            storagetype durationstart capacity));
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

   if (effVal($oldrec,$newrec,"systemid")==0){
      $self->LastMsg(ERROR,"invalid system specified");
      return(undef);
   }
   if (effVal($oldrec,$newrec,"durationstart") eq ""){
      $newrec->{durationstart}=NowStamp("en");
   }
#  wegen Altfaellen notwendig 21.01.2011 (HV)
#   if (effVal($oldrec,$newrec,"capacity")==0){
#      $self->LastMsg(ERROR,"capacitiy to less");
#      return(undef);
#   }
   my $ordernumber=effVal($oldrec,$newrec,"ordernumber");
   if ($ordernumber ne "" && !($ordernumber=~m/^[A-Z\d]+$/)){
      $self->LastMsg(ERROR,"invalid ordernumber");
      return(undef);
   }

   my $applid=effVal($oldrec,$newrec,"applid");
   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnInvoiceDataValid($applid)){
         $self->LastMsg(ERROR,"no write access to requested application");
         return(undef);
      }
   }
   my $systemid=effVal($oldrec,$newrec,"systemid");
   if ($applid eq "" || $systemid eq ""){
      $self->LastMsg(ERROR,"application and system necessary");
      return(undef);
   }
   else{
      if (effChanged($oldrec,$newrec,"systemid") ||
          effChanged($oldrec,$newrec,"applid")){
         my $o=getModuleObject($self->Config,"itil::lnkapplsystem");
         $o->SetFilter({applid=>\$applid,systemid=>\$systemid});
         my ($lnkrec,$msg)=$o->getOnlyFirst(qw(id));
         if (!defined($lnkrec)){
            $self->LastMsg(ERROR,"system not related to selected application"); 
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
   return("header","default","duration","logicalusage") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","duration","logicalusage") if (!defined($rec) ||
                                        $self->IsMemberOf("admin"));
   my @grp=qw(ALL);
   if (defined($rec) && $rec->{cdate} ne ""){
      my $d=CalcDateDuration($rec->{cdate},NowStamp("en"));
      if ($d->{totalminutes}>10080){ # modify only allowed for 7 days
         @grp=qw(duration);
      }
   }
   my $applid=$rec->{applid};
   if ($applid ne ""){
      if ($self->isWriteOnInvoiceDataValid($applid)){
         return(@grp);
      }
   }
   return;
}

sub isWriteOnInvoiceDataValid
{
   my $self=shift;
   my $applid=shift;
   if ($self->isWriteOnApplValid($applid,"systems")){
      return(1);
   }
   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->SetFilter({id=>\$applid});
   my ($arec,$msg)=$appl->getOnlyFirst(qw(businessteamid));
   if (defined($arec) && $arec->{businessteamid} ne ""){
      if ($self->IsMemberOf($arec->{businessteamid},"RITSoDManager","down")){
         return(1);
      }
   }
   return(0);

}



sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default duration logicalusage applinfo systeminfo source));
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
