package itil::appldoc;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

# Migration neues Dokumentenhandling:
=head1
update appladv set isactive=null where isactive=0;
update applnor set isactive=null where isactive=0;
delete from applnor using applnor, applnor as tmp
where not applnor.id=tmp.id
   and applnor.id<tmp.id
   and tmp.isactive=1
   and applnor.isactive=1
   and applnor.appl=tmp.appl;
alter table applnor add unique(appl,isactive), add refreshinfo1 datetime;
delete from appladv using appladv, appladv as tmp
where not appladv.id=tmp.id
   and appladv.id<tmp.id
   and tmp.isactive=1
   and appladv.isactive=1
   and appladv.appl=tmp.appl;
alter table appladv add unique(appl,isactive), add refreshinfo1 datetime;
=cut


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   my ($worktable,$workdb)=$self->getWorktable();
   $self->{doclabel}="DOC-" if (!defined($self->{doclabel}));
   my $doclabel=$self->{doclabel};
   my $haveitsemexp="costcenter.itsem is not null ".
                    "or costcenter.itsemteam is not null ".
                    "or costcenter.itseminbox is not null ".
                    "or costcenter.itsem2 is not null";

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>"$worktable.id"),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Link(
                name          =>'srcparentid',
                selectfix     =>1,
                label         =>'Source Parent W5BaseID',
                dataobjattr   =>'appl.id'),
                                                  
      new kernel::Field::Link(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'Parent W5BaseID',
                dataobjattr   =>"$worktable.appl"),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                readonly      =>1,
                uploadable    =>1,
                label         =>'Applicationname',
                weblinkto     =>'itil::appl',
                weblinkon     =>['srcparentid'=>'id'],
                dataobjattr   =>'appl.name'),

      new kernel::Field::Select(
                name          =>'dstate',           # NULL = empty join
                label         =>'Document state',   # 10   = empty record
                value         =>[10,20,30],         # 20   = edit record
                default       =>'10',               # 30   = archived record
                readonly      =>1,
                translation   =>'itil::appldoc',
                transprefix   =>'dstate.',
                dataobjattr   =>"$worktable.dstate"),
                                                  
      new kernel::Field::Link(
                name          =>'dstateid',
                selectfix     =>1,
                label         =>'Derive State ID',
                dataobjattr   =>"$worktable.dstate"),
                                                  
      new kernel::Field::Boolean(
                name          =>'isactive',
                selectfix     =>1,
                htmldetail    =>0,
                readonly      =>1,
                selectsearch  =>sub{
                   my $self=shift;
                   return(['1',
                           $self->getParent->T('yes - show only active')],
                          ['', 
                           $self->getParent->T('no - show all')]);
                },
                label         =>'is active',
                dataobjattr   =>"$worktable.isactive"),
                                                  
      new kernel::Field::Interface(
                name          =>'rawisactive',
                selectfix     =>1,
                readonly      =>1,
                label         =>'raw is active',
                dataobjattr   =>"$worktable.isactive"),
                                                  
      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                readonly      =>1,
                label         =>'Application CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Mandator(
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Link(
                name          =>'applmgrid',
                group         =>'sem',
                dataobjattr   =>'appl.applmgr'),

      new kernel::Field::Link(
                name          =>'semid',
                group         =>'sem',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem,appl.sem)"),

      new kernel::Field::Link(
                name          =>'sem2id',
                group         =>'sem',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem2,appl.sem2)"),

      new kernel::Field::Link(
                name          =>'tsmid',
                group         =>'tsm',
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                group         =>'tsm',
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::Link(
                name          =>'opmid',
                group         =>'opm',
                dataobjattr   =>'appl.opm'),

      new kernel::Field::Link(
                name          =>'opm2id',
                group         =>'opm',
                dataobjattr   =>'appl.opm2'),

      new kernel::Field::Text(
                name          =>'conumber',
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                label         =>'CO-Number',
                dataobjattr   =>'appl.conumber'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                readonly      =>1,
                label         =>'Service Delivery Manager',
                translation   =>'finance::costcenter',
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrteamid',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsemteam,costcenter.delmgrteam)"),

      new kernel::Field::Link(
                name          =>'delmgrid',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem,costcenter.delmgr)"),

      new kernel::Field::Link(
                name          =>'delmgr2id',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem2,costcenter.delmgr2)"),

      new kernel::Field::Group(
                name          =>'responseteam',
                readonly      =>1,
                uploadable    =>0,
                translation   =>'itil::appl',
                label         =>'CBM Team',
                vjoinon       =>'responseteamid'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsemteam,appl.responseteam)"),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                readonly      =>1,
                uploadable    =>0,
                translation   =>'itil::appl',
                htmldetail    =>0,
                vjointo       =>'base::grp',
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'customerid',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::Date(
                name          =>'refreshinfo1',
                uivisible     =>0,
                dataobjattr   =>"$worktable.refreshinfo1"),

      new kernel::Field::Date(
                name          =>'refreshinfo2',
                uivisible     =>0,
                dataobjattr   =>"$worktable.refreshinfo2"),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                dataobjattr   =>"$worktable.additional"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>"$worktable.srcsys"),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>"$worktable.srcid"),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>"$worktable.srcload"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                searchable    =>'0',
                label         =>'last Editor',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                searchable    =>'0',
                label         =>'Editor Account',
                dataobjattr   =>"$worktable.editor"),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                searchable    =>'0',
                label         =>'real Editor Account',
                dataobjattr   =>"$worktable.realeditor"),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'docdate',
                dataobjattr   =>"$worktable.docdate"),

      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Documentname',
                dataobjattr   =>
               "if ($worktable.dstate is null or $worktable.dstate<=10,".
               "concat(appl.name,'$doclabel','-',substr(now(),1,7),'-(AUTO)'),".
               "concat(appl.name,'$doclabel','-',".
                       "substr($worktable.docdate,1,7)))"),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>"$worktable.lastqcheck"),
      new kernel::Field::QualityResponseArea()

   );
   my $fo=$self->getField("isactive");
   delete($fo->{default});
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(fullname cistatus mandator dstate 
                            isactive editor mdate));
   return($self);
}



sub SetFilterForQualityCheck    # prepaire dataobject for automatic
{                               # quality check (nightly)
   my $self=shift;
   my $stateparam=shift;
   my @view=@_;                 # predefinition for request view
   my @flt;
   if (my $cistatusid=$self->getField("isactive")){
      $flt[0]->{isactive}="1 [EMPTY]";
      if (my $mdate=$self->getField("mdate")){
         $flt[1]->{mdate}=">now-14d";
      }
   }
   $self->SetFilter(\@flt);
   $self->SetCurrentView(@view);
   return(1);
}





sub handleRawValueAutogenField
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();
   if (defined($current) &&
       $current->{srcparentid} ne ""){
      if ($current->{dstateid}<=10){  # autogen field value
         my $r=$app->autoFillGetResultCache($self->{name},
                                             $current->{srcparentid});
         return($r) if (defined($r));
         return($app->autoFillAutogenField($self,$current));
      }
      my $r=$self->resolvContainerEntryFromCurrent($current);
      return($r);
   }
   return("NONE"); 
}

sub FinishView    # called on finsh view of one record (f.e. to reset caches)
{
   my $self=shift;
   my $rec=shift;

   my $c=$self->Cache();

   delete($c->{autoFillCache});
}


sub autoFillAddResultCache
{
   my $self=shift;

   my $c=$self->Cache();
   $c->{autoFillCache}={} if (!exists($c->{autoFillCache}));

   while(my $p=shift){
      my $name=shift(@$p);
      my $val=shift(@$p);
      my $id=shift(@$p);
      $id="" if (!defined($id));

      if (!exists($c->{autoFillCache}->{"C$id"})){
         $c->{autoFillCache}->{"C$id"}={};
      }
      my $C=$c->{autoFillCache}->{"C$id"};
      $C->{$name}={} if (!exists($C->{$name}));
     
      if (ref($val) eq "ARRAY"){
         map({$C->{$name}->{$_}++} grep(!/^\s*$/,@$val));
      }
      else{
         $C->{$name}->{$val}++ if ($val ne "");
      }
   }
}

sub autoFillGetResultCache
{
   my $self=shift;
   my $name=shift;
   my $id=shift;
   $id="" if (!defined($id));

   my $c=$self->Cache();
   $c->{autoFillCache}={} if (!exists($c->{autoFillCache}));

   foreach my $useid ($id,""){
      if (exists($c->{autoFillCache}->{"C$useid"})){
         if (exists($c->{autoFillCache}->{"C$useid"}->{$name})){
            return([sort(keys(%{$c->{autoFillCache}->{"C$useid"}->{$name}}))]);
         }
      }
   }
   return(undef);
}

sub autoFillAutogenField
{
   my $self=shift;
   my $fld=shift;
   my $current=shift;

   my $r=$self->autoFillGetResultCache($fld->{name},$current->{srcparentid});

   return($r);
}



sub preProcessReadedRecord
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec->{id}) && $rec->{srcparentid} ne ""){
      my $o=$self->Clone;
      $o->BackendSessionName("preProcessReadedRecord"); # prevent sesssion reuse
                                                  # on sql cached_connect
      my ($id)=$o->ValidatedInsertRecord({parentid=>$rec->{srcparentid},
                                          owner=>0,
                                          isactive=>1});
      $rec->{id}=$id;
      $rec->{isactive}="1";
   }
   if ($rec->{dstateid}<=10){
      $rec->{owner}=undef;
      $rec->{mdate}=undef;
   }
   return(undef);
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   my $userid=$self->getCurrentUserId();

   my $readgrp="w5base.".$self->SelfAsParentObject().".read";

   $readgrp=~s/::/\./g;

   if (!$self->IsMemberOf("admin") && 
       !$self->IsMemberOf($readgrp)){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                              [qw(RCFManager RCFManager2)],"both");
      my @grpids=keys(%grps);
      my %dgrps=$self->getGroupsOf($ENV{REMOTE_USER},
                              [orgRoles()],"direct");
      my @dgrpids=keys(%dgrps);
      push(@flt,[
                 {responseteamid=>[@grpids,@dgrpids]},
                 {delmgrteamid=>[@grpids,@dgrpids]},
       #          {sectargetid=>\$userid,sectarget=>\'base::user',
       #           secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
       #                     "*roles=?read?=roles*"},
       #          {sectargetid=>\@grpids,sectarget=>\'base::grp',
       #           secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
       #                     "*roles=?read?=roles*"},
                 {applmgrid=>$userid},
                 {tsmid=>$userid},
                 {tsm2id=>$userid},
                 {opmid=>$userid},
                 {opm2id=>$userid},
                 {semid=>$userid},
                 {sem2id=>$userid},
                 {delmgrid=>$userid},
                 {delmgr2id=>$userid}
                ]);
   }
   if (!$self->isDirectFilter(@flt)){
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_mandator"))){
     Query->Param("search_mandator"=>
                  "!Extern");
   }
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="appl left outer join $worktable ".
          "on appl.id=$worktable.appl ".
          "left outer join lnkcontact ".
          "on lnkcontact.parentobj in ('itil::appl') ".
          "and appl.id=lnkcontact.refid ".
          "left outer join costcenter on appl.conumber=costcenter.name";

   return($from);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1) if (defined($newrec) &&
                 exists($newrec->{lastqcheck}) && 
                 keys(%{$newrec})==1);
 
   if (defined($oldrec)){
      $newrec->{dstate}=20;
      $newrec->{isactive}=1;
      if ($oldrec->{dstate} eq "10"){  # ensure that ALL default values will
         my ($worktable,$workdb)=$self->getWorktable(); # be written!
         my @fieldlist=$self->getFieldObjsByView([qw(ALL)],
                                                 oldrec=>$oldrec,
                                                 opmode=>'validateFields');
         foreach my $fobj (@fieldlist){
            if ($fobj->{container} eq "additional" &&
                !exists($newrec->{$fobj->{name}})){
               $newrec->{$fobj->{name}}=effVal($oldrec,$newrec,$fobj->{name});
            }
         }
      }
   }
   if (effVal($oldrec,$newrec,"dstate")>10 &&
       effVal($oldrec,$newrec,"dstate")<30 ){ # nur im verankert modes setzen
      my $tz=$self->UserTimezone();
      my ($year, $month)=$self->Today_and_Now($tz);
      $newrec->{docdate}=sprintf("%04d-%02d",$year,$month);
   }

   if (effChanged($oldrec,$newrec,"dstate") && $newrec->{dstate}==20){
      my $o=$self->Clone();
      if ($oldrec->{parentid} eq "" || $oldrec->{id} eq ""){
         $self->LastMsg(ERROR,"havy problem ! - contact admin");
         return(undef);
      }
      $o->UpdateRecord({dstate=>30,
                        rawisactive=>undef},{parentid=>$oldrec->{parentid},
                                       dstateid=>"!30",
                                       id=>"!$oldrec->{id}"});
   }
   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{dstate}<30){
      my $userid=$self->getCurrentUserId();
      return(qw(default)) if ($self->IsMemberOf("admin"));
   }
   return();
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{dstate}>10){
      return(qw(header default source));
   }
   return("header","default","qc","source");
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{dstate}<30);
   return(1);
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   if (effChanged($oldrec,$newrec,"dstate")){
      if ($oldrec->{dstate} eq "10" && $newrec->{dstate} eq "20"){
         my $o=$self->Clone();  # neuen automatisch generiteren Record erzeugen
         $o->ValidatedInsertRecord({parentid=>$oldrec->{parentid},
                                    rawisactive=>undef});
      }
   }
   if ($newrec->{dstate} eq "20"){
      my $o=$self->Clone();
      $o->SetFilter({parentid=>\$oldrec->{parentid},dstate=>\'10'});
      my ($chkrec,$msg)=$o->getOnlyFirst(qw(id));
      if (!defined($chkrec)){ # ensure autogen Recrod exists
         $o->ValidatedInsertRecord({parentid=>$oldrec->{parentid},
                                    rawisactive=>undef});
      }
      $o->UpdateRecord({rawisactive=>undef},{parentid=>$oldrec->{parentid},
                                       id=>"!$oldrec->{id}"});
   }
   if ($newrec->{dstate} eq "30"){
      my $o=$self->Clone();
      $o->UpdateRecord({rawisactive=>1},{parentid=>$oldrec->{parentid},
                                       dstateid=>\'10'});
   }
   return($bak);
}



sub SetFilter
{
   my $self=shift;

   my $flt=$_[0];


   if ($flt->{isactive}==1){
      $self->SetNamedFilter("isACTIVE",[{isactive=>'1'},{parentid=>\undef}]);
   }

   delete($flt->{isactive});



   return($self->SUPER::SetFilter(@_));
}




sub prepUploadFilterRecord
{
   my $self=shift;
   my $newrec=shift;

   if ((!defined($newrec->{id}) || $newrec->{id} eq "")
       && $newrec->{name} ne ""){
      my $o=$self->Clone();
      $o->SetFilter({name=>\$newrec->{name},
                     isactive=>'1 [EMPTY]'});
      my ($crec,$msg)=$o->getOnlyFirst(qw(id));
      if (defined($crec)){
         $newrec->{id}=$crec->{id};
      }
      else{
         $self->LastMsg(ERROR,"invalid application");
      }
   }

   delete($newrec->{name});
   delete($newrec->{custcontractnames});
   $self->SUPER::prepUploadFilterRecord($newrec);
}







1;
