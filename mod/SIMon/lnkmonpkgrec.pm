package SIMon::lnkmonpkgrec;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use kernel::Field::TextURL;
use kernel::CIStatusTools;
use itil::system;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;

   $param{MainSearchFieldLines}=4;
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
                dataobjattr   =>'lnksimonpkgrec.id'),

      new kernel::Field::RecordUrl(),
                                                 
      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'fullname',
                searchable    =>0,
                dataobjattr   =>"concat(simonpkg.name,' @ ',system.name)"),

      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'150px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name',
                readonly      =>1,
                dataobjattr   =>'system.name'),
                                                   
      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'System ID',
                dataobjattr   =>'system.id',
                selectfix     =>1,
                wrdataobjattr =>'lnksimonpkgrec.system'),

      new kernel::Field::Select(
                name          =>'systemcistatus',
                label         =>'System CI-Status',
                readonly      =>1,
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'systemcistatusid',
                label         =>'System CI-Status ID',
                dataobjattr   =>'system.cistatus',
                selectfix     =>1),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Applicationnames',
                readonly      =>1,
                translation   =>'itil::system',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>['appl']),

      new kernel::Field::TextDrop(
                name          =>'monpkg',
                htmlwidth     =>'250px',
                label         =>'Installationpackage',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'SIMon::monpkg',
                vjoinon       =>['monpkgid'=>'id'],
                vjoindisp     =>'name',
                readonly      =>1,
                dataobjattr   =>'simonpkg.name'),
                                                   
      new kernel::Field::Link(
                name          =>'monpkgid',
                label         =>'MonPkg ID',
                dataobjattr   =>'simonpkg.id',
                wrdataobjattr =>'lnksimonpkgrec.simonpkg'),

      new kernel::Field::Link(
                name          =>'monpkgrestrictarget',
                label         =>'MonPkg Restriction target',
                readonly      =>1,
                dataobjattr   =>'simonpkg.restrictarget'),

      new kernel::Field::Link(
                name          =>'monpkgrestriction',
                label         =>'MonPkg Restriction',
                readonly      =>1,
                dataobjattr   =>'simonpkg.restriction'),

      new kernel::Field::Link(
                name          =>'managergrpid',
                selectfix     =>1,
                dataobjattr   =>'simonpkg.managergrpid'),

      new kernel::Field::Link(
                name          =>'needrefresh',
                label         =>'need recalc flag',
                readonly      =>1,
                dataobjattr   =>"if (lnksimonpkgrec.id is not null AND ".
                                "(lnksimonpkgrec.modifydate<".
                                "simonpkg.modifydate OR ".
                                "(lnksimonpkgrec.modifydate<".
                                "system.modifydate ".
                                "AND system.cistatus='4')),".
                                "if (system.cistatus>5 AND ". # prevent refresh
                                "lnksimonpkgrec.reqtarget='NEDL'". # of deleted
                                ",0,1)".                           # systems
                                ",0)"),               

      new kernel::Field::Link(
                name          =>'neednotifyreset',
                label         =>'need reset of notify flag',
                readonly      =>1,
                dataobjattr   =>
                   "if (lnksimonpkgrec.notifydate is not null AND (".
                   "system.instdate>lnksimonpkgrec.notifydate OR ".
                   "system.cistatus>5),1,0)"),

      new kernel::Field::Select(
                name          =>'reqtarget',
                label         =>'target state',
                transprefix   =>'TARGET.',
                value         =>[qw(MAND NEDL RECO MONI)],
                allownative   =>1,
                allowempty    =>1,
                readonly      =>1,
                useNullEmpty  =>1,
                dataobjattr   =>'lnksimonpkgrec.reqtarget'),

      new kernel::Field::Interface(
                name          =>'rawreqtarget',
                label         =>'raw request target',
                dataobjattr   =>'lnksimonpkgrec.reqtarget'),

      new kernel::Field::Select(
                name          =>'curinststate',
                label         =>'current installation state',
                transprefix   =>'INSTSTATE.',
                depend        =>['reqtarget'],
                readonly      =>1,
                background    =>\&getCurInstStateColor,
                value         =>[qw(INSTALLED NOTFOUND)],
                dataobjattr   =>getCurInstStateSql()),

      new kernel::Field::Select(
                name          =>'exception',
                label         =>'exception from target state',
                transprefix   =>'EXCEPTION.',
                value         =>[qw(REQUESTED ACCEPTED REJECTED EXPIRED
                                    AUTOACCEPT)],
                selectfix     =>1,
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"if (lnksimonpkgrec.exceptreqtxt<>'',".
                                "if (simonpkg.managergrpid is null,".
                                "'AUTOACCEPT',".
                                "if (exceptstate='ACCEPT','ACCEPTED',".
                                "if (exceptstate='REJECT','REJECTED',".
                                "'REQUESTED'))),".
                                "NULL)"),

      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                uploadable    =>0,
                htmlwidth     =>"500px",
                label         =>'Comments',
                dataobjattr   =>'lnksimonpkgrec.comments'),

      new kernel::Field::Textarea(
                name          =>'exceptreqtxt',
                group         =>'exceptionreq',
                label         =>'exception request justification',
                dataobjattr   =>'lnksimonpkgrec.exceptreqtxt'),

      new kernel::Field::Date(
                name          =>'exceptreqdate',
                group         =>'exceptionreq',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'exception request date',
                dataobjattr   =>'lnksimonpkgrec.exceptreqdate'),

      new kernel::Field::Contact(
                name          =>'exceptrequestor',
                group         =>'exceptionreq',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                label         =>'exception requestor',
                vjoinon       =>['exceptrequestorid'=>'userid']),

      new kernel::Field::Link(
                name          =>'exceptrequestorid',
                selectfix     =>1,
                group         =>'exceptionreq',
                label         =>'exception requestor ID',
                dataobjattr   =>'lnksimonpkgrec.exceptrequestor'),

      new kernel::Field::Select(
                name          =>'exceptstate',
                label         =>'exception approve state',
                transprefix   =>'APPR.',
                value         =>[qw(ACCEPT REJECT)],
                group         =>'exceptionappr',
                allownative   =>1,
                useNullEmpty  =>1,
                wrdataobjattr =>'lnksimonpkgrec.exceptstate',
                dataobjattr   =>"if (lnksimonpkgrec.exceptstate is null,".
                                "'REQUESTED',lnksimonpkgrec.exceptstate)"),

      new kernel::Field::Number(
                name          =>'rejectcnt',
                group         =>'exceptionappr',
                htmldetail    =>0,
                label         =>'counter for exception rejects',
                dataobjattr   =>'lnksimonpkgrec.rejectcnt'),

      new kernel::Field::Textarea(
                name          =>'exceptrejecttxt',
                group         =>'exceptionappr',
                label         =>'exception approver explanation',
                dataobjattr   =>'lnksimonpkgrec.exceptrejecttxt'),

      new kernel::Field::Select(
                name          =>'exceptcluster',
                label         =>'exception cluster',
                group         =>'exceptionappr',
                multisize     =>'4',
                transprefix   =>'EXCL.',
                value         =>['STORAGE',
                                 'CRYPTO',
                                 'NETWORK',
                                 'ADS',
                                 'VDS',
                                 'TSG',
                                 'GS',
                                 'OUTOFOP',
                                 'RETIERED',
                                 'MISC'],  # see also opmode at system
                uploadable    =>0,
                htmleditwidth =>'200px',
                container     =>'rawexceptcluster'),


      new kernel::Field::Container(
                name          =>'rawexceptcluster',
                label         =>'raw except cluster',
                htmldetail    =>0,
                dataobjattr   =>'lnksimonpkgrec.exceptcluster'),

      new kernel::Field::Date(
                name          =>'exceptapprdate',
                group         =>'exceptionappr',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                uploadable    =>0,
                label         =>'exception approve/reject date',
                dataobjattr   =>'lnksimonpkgrec.exceptapprdate'),
                                                   
      new kernel::Field::Contact(
                name          =>'exceptapprover',
                group         =>'exceptionappr',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                label         =>'exception approver',
                vjoinon       =>['exceptapproverid'=>'userid']),

      new kernel::Field::TextDrop(
                name          =>'managergrp',
                htmlwidth     =>'300px',
                group         =>'exceptionappr',
                label         =>'posible exception approver group',
                vjointo       =>'base::grp',
                readonly      =>1,
                vjoinon       =>['managergrpid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'notifycomments',
                label         =>'notify comments',
                dataobjattr   =>'simonpkg.comments'),

      new kernel::Field::Link(
                name          =>'exceptapproverid',
                label         =>'exception approver ID',
                group         =>'exceptionappr',
                dataobjattr   =>'lnksimonpkgrec.exceptapprover'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'system.mandator'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'system.databoss'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'system.cistatus'),

      new kernel::Field::Link(
                name          =>'admid',
                dataobjattr   =>'system.adm'),

      new kernel::Field::Link(
                name          =>'adm2id',
                dataobjattr   =>'system.adm2'),

      new kernel::Field::Link(
                name          =>'adminteamid',
                selectfix     =>1,
                dataobjattr   =>'system.admteam'),

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
                name          =>'secsystemsectarget',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.target'),

      new kernel::Field::Link(
                name          =>'secsystemsectargetid',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secsystemsecroles',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'secsystemmandatorid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.mandator'),

      new kernel::Field::Link(
                name          =>'secsystembusinessteamid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.businessteam'),

      new kernel::Field::Link(
                name          =>'secsystemtsmid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.tsm'),

      new kernel::Field::Link(
                name          =>'secsystemtsm2id',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.tsm2'),

      new kernel::Field::Link(
                name          =>'secsystemopmid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.opm'),

      new kernel::Field::Link(
                name          =>'secsystemopm2id',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.opm2'),

      new kernel::Field::Text(
                name          =>'systemsrcsys',
                htmldetail    =>'0',
                readonly      =>1,
                label         =>'System Source-System',
                dataobjattr   =>'system.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'systemsrcid',
                htmldetail    =>'0',
                readonly      =>1,
                label         =>'System Source-Id',
                dataobjattr   =>'system.srcid'),
                                                   
      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                htmldetail    =>'0',
                label         =>'Creator',
                dataobjattr   =>'lnksimonpkgrec.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnksimonpkgrec.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnksimonpkgrec.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'lnksimonpkgrec.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Last-Load',
                dataobjattr   =>'lnksimonpkgrec.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'installation monitoring start',
                dataobjattr   =>'lnksimonpkgrec.createdate'),

      new kernel::Field::Date(
                name          =>'systemcdate',
                group         =>'source',
                label         =>'system creation-date',
                dataobjattr   =>'system.createdate'),

      new kernel::Field::Date(
                name          =>'systemidate',
                group         =>'source',
                label         =>'system installation-date',
                dataobjattr   =>'system.instdate'),

      new kernel::Field::Date(
                name          =>'notifydate',
                group         =>'exceptionreq',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'installation request notification',
                group         =>'source',
                dataobjattr   =>'lnksimonpkgrec.notifydate'),

                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnksimonpkgrec.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnksimonpkgrec.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnksimonpkgrec.realeditor'),
   );
   $self->setDefaultView(qw(system monpkg reqtarget 
                            curinststate exception cdate));
   $self->setWorktable("lnksimonpkgrec");
   return($self);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;
   return(itil::system::SecureSetFilter($self,@flt));
}

sub getCurInstStateColor
{
   my ($self,$FormatAs,$current)=@_;

   my $st=$self->RawValue($current);
   my $fld=$self->getParent->getField("reqtarget");

   my $reqtarget=$fld->RawValue($current);
   my $color="green";
   if ($reqtarget eq "MAND" && $st ne "INSTALLED"){
      $color="red";
   }
   $color=undef if ($color eq "green" && $reqtarget ne "MAND");

   return($color);
}

sub getCurInstStateSql
{
   my $d=<<EOF;
select if (count(*)>0,'INSTALLED','NOTFOUND') 
from lnksoftwaresystem lnksoftsys 
   join lnksimonpkgsoftware lnksimonpkgsoft 
      on lnksimonpkgsoft.software=lnksoftsys.software 
where system.id=lnksoftsys.system 
   and lnksimonpkgsoft.simonpkg=simonpkg.id
EOF
   $d=~s/\n/ /g;
   $d=~s/  / /g;
   return("(".$d.")");
}


sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   my $where="";
   if ($mode eq "select"){
      $where="((system.id is not null and simonpkg.cistatus=4) ".
             "or lnksimonpkgrec.id is not null)";
   }
   return($where);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();


   my $from="system cross join simonpkg left outer join lnksimonpkgrec ".
            "on (lnksimonpkgrec.simonpkg=simonpkg.id and ".
            "    lnksimonpkgrec.system=system.id) ".
          "left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::system' ".
          "and system.id=lnkcontact.refid  ".
          "left outer join lnkapplsystem as secsystemlnkapplsystem ".
          "on system.id=secsystemlnkapplsystem.system ".
          "left outer join appl as secsystemappl ".
          "on secsystemlnkapplsystem.id=secsystemappl.id ".
             "and secsystemappl.cistatus<6 ".
          "left outer join lnkcontact secsystemlnkcontact ".
          "on secsystemlnkcontact.parentobj='itil::system' ".
          "and system.id=secsystemlnkcontact.refid ".
          "left outer join costcenter secsystemcostcenter ".
          "on secsystemappl.conumber=secsystemcostcenter.name ";

#   my $from="$worktable join simonpkg ".
#            "on lnksimonpkgrec.simonpkg=simonpkg.id ";

   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/SIMon/load/lnkmonpkgrec.jpg?".$cgi->query_string());
}

#sub SelfAsParentObject    # this method is needed because existing derevations
#{
#   return("itil::lnkitfarmasset");
#}
#

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getDetailBlockPriority
{  
   my $self=shift;
   return(qw(header default exceptionreq exceptionappr source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $monpkgid=effVal($oldrec,$newrec,"monpkgid");

   if ($self->isDataInputFromUserFrontend()){
      my $systemid=effVal($oldrec,$newrec,"systemid");
      my $managergrpid=effVal($oldrec,$newrec,"managergrpid");
      my $sobj=$self->getPersistentModuleObject("itil::system");
      if (!$sobj->isWriteOnFieldGroupValid($systemid,"default") &&
          !$self->IsMemberOf($managergrpid)){
         $self->LastMsg(ERROR,"no access");
         return(undef);
      }
      my $userid=$self->getCurrentUserId();
      if (effChanged($oldrec,$newrec,"exceptreqtxt")){
         if (effVal($oldrec,$newrec,"exceptapproverid") ne ""){
            $newrec->{comments}=
                   effVal($oldrec,$newrec,"comments").
                   (effVal($oldrec,$newrec,"comments") ne "" ? "\n":'').
                   NowStamp("en").";".$ENV{REMOTE_USER}.";".
                   "approve/reject reset\n";
         }
         $newrec->{exceptapproverid}=undef;
         $newrec->{exceptapprdate}=undef;
      }
      if (effChanged($oldrec,$newrec,"exceptstate")){
         my $newstate=effVal($oldrec,$newrec,"exceptstate");
         if ($newstate eq "REJECT"){
            $newrec->{rejectcnt}=\'rejectcnt+1';
         }
         if ($newstate eq "ACCEPT"){
            $newrec->{rejectcnt}='0';
         }
         if (exists($newrec->{rejectcnt})){
            msg(INFO,"send Mail to requestor state=$newstate");
            my $userid=$self->getCurrentUserId();
            my @emailto;
            my %notifyparam;
            my %notifycontrol;

            if ($newstate eq "REJECT"){
               $notifycontrol{mode}="WARN";
            }
            push(@emailto,effVal($oldrec,$newrec,"exceptrequestorid"));

            $notifyparam{emailfrom}=$userid;
            $notifyparam{emailto}=\@emailto;
            $notifyparam{emailbcc}=['11634953080001',$userid];
            $self->NotifyLangContacts($oldrec,$newrec,
               \%notifyparam,\%notifycontrol,
               sub{
                  my $self=shift;
                  my $notifyparam=shift;
                  my $notifycontrol=shift;
                  my $subject=$self->T("exception request");
                  my $text;
                  $subject.=" ".$newstate;
                  $subject.=" ".$self->T("for")." ";
                  $subject.=effVal($oldrec,$newrec,"system");
                  $text.=
                    $self->T("Your exception request for non-installation of");
                  $text.="\n";
                  $text.=effVal($oldrec,$newrec,"monpkg");
                  $text.=" ";
                  $text.=$self->T("on");
                  $text.=" ";
                  $text.=effVal($oldrec,$newrec,"system");
                  $text.="\n";
                  $text.="... ".$self->T("is $newstate")."\n";
                  $text.="\n---\n";
                  $text.=$self->T("Justification").":\n";
                  $text.=effVal($oldrec,$newrec,"exceptrejecttxt");
                  $text.="\n---\n";
                  return($subject,$text); 
               }
            ); 
         }
      }
      if (effChanged($oldrec,$newrec,"exceptrejecttxt") ||
          effChanged($oldrec,$newrec,"exceptstate")){
         $newrec->{exceptapproverid}=$userid;
         $newrec->{exceptapprdate}=NowStamp("en");
         $newrec->{comments}=
                effVal($oldrec,$newrec,"comments").
                (effVal($oldrec,$newrec,"comments") ne "" ? "\n":'').
                NowStamp("en").";".$ENV{REMOTE_USER}.";".
                "approve/reject\n";
      }
      if (effChanged($oldrec,$newrec,"exceptreqtxt")){
         if (effVal($oldrec,$newrec,"rejectcnt")>3){
            $self->LastMsg(ERROR,"no further exception requests allowed - ".
                                 "too many rejects");
            return(undef);
         }
         if (effVal($oldrec,$newrec,"exceptreqtxt") eq ""){
            if (effVal($oldrec,$newrec,"exceptrequestorid") ne ""){
               $newrec->{comments}=
                      effVal($oldrec,$newrec,"comments").
                      (effVal($oldrec,$newrec,"comments") ne "" ? "\n":'').
                      NowStamp("en").";".$ENV{REMOTE_USER}.";".
                      "exception reset\n";
            }
            $newrec->{exceptrequestorid}=undef;
            $newrec->{exceptreqdate}=undef;
         }
         else{
            $newrec->{exceptrequestorid}=$userid;
            $newrec->{exceptreqdate}=NowStamp("en");
            $newrec->{comments}=
                   effVal($oldrec,$newrec,"comments").
                   (effVal($oldrec,$newrec,"comments") ne "" ? "\n":'').
                   NowStamp("en").";".$ENV{REMOTE_USER}.";".
                   "exception request\n";
         }
         $newrec->{exceptstate}=undef;
         $newrec->{exceptrejecttxt}=undef;
         $newrec->{exceptapproverid}=undef;
         $newrec->{exceptapprdate}=undef;
      }
   }
   if (effChanged($oldrec,$newrec,"rawreqtarget")){  # Change Targetstate
      $newrec->{notifydate}=undef;
   }
   my $exceptreqtxt=effVal($oldrec,$newrec,"exceptreqtxt");
   if ($exceptreqtxt ne ""){
      if (length($exceptreqtxt)<20){
         $self->LastMsg(ERROR,"exception request justification ".
                              "not detailed enouth");
         return(undef);
      }
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=qw(default header source);

   if ($rec->{systemid} ne ""){# Schreibzugriff auf logisches system
      my $sobj=$self->getPersistentModuleObject("itil::system");
      if ($sobj->isWriteOnFieldGroupValid($rec->{systemid},"default")){
          push(@l,"exceptionreq");
      }
      if ($rec->{exception} ne "" && $rec->{managergrpid} ne ""){
         push(@l,"exceptionreq");
         push(@l,"exceptionappr");
      }
   }


   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my @wrgrp=();

   if (defined($oldrec)){
      my $systemid=effVal($oldrec,$newrec,"systemid");
      my $reqtarget=effVal($oldrec,$newrec,"reqtarget");
      my $managergrpid=effVal($oldrec,$newrec,"managergrpid");
      if ($systemid ne "" && $reqtarget eq "MAND"){
         my $sobj=$self->getPersistentModuleObject("itil::system");
         if ($sobj->isWriteOnFieldGroupValid($systemid,"default")){
            push(@wrgrp,"exceptionreq");
         }
         if ($managergrpid ne ""){
            if ($self->IsMemberOf($managergrpid)){
               push(@wrgrp,"exceptionappr");
            }
         }
      }
   }

   return(@wrgrp);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);

   if (my $exceptreqtxt=effChangedVal($oldrec,$newrec,"exceptreqtxt")){
      if ($exceptreqtxt ne ""){
         my $managergrpid=effVal($oldrec,$newrec,"managergrpid");
         if ($managergrpid ne ""){
            my $sendmail=1;
            my $userid=$self->getCurrentUserId();
            my @l=$self->getMembersOf($managergrpid,
               "RMember",
               "direct"
            );
            my @emailto;
            foreach my $uid (@l){
               if ($userid eq $uid){
                  $sendmail=0;         # current user is in managergrp
               }
               else{
                  push(@emailto,$uid);
               }
            }
            if ($sendmail && $#emailto!=-1){
               my %notifyparam;
               my %notifycontrol;

               $notifyparam{emailfrom}=$userid;
               $notifyparam{emailfromfake}=1;  # prevent OutOffOffice Mails 
               $notifyparam{emailto}=\@emailto;
               $notifyparam{emailbcc}=['11634953080001'];
               $self->NotifyLangContacts($oldrec,$newrec,
                  \%notifyparam,\%notifycontrol,
                  sub{
                     my $self=shift;
                     my $notifyparam=shift;
                     my $notifycontrol=shift;
                     my $subject=$self->T("exception approve request");
                     my $text;
                     $subject.=": ".effVal($oldrec,$newrec,"system");
                     $text.=
                       $self->T("Requirement to exception non-installation of");
                     $text.="\n";
                     $text.=effVal($oldrec,$newrec,"monpkg");
                     $text.=" ";
                     $text.=$self->T("on");
                     $text.=" ";
                     $text.=effVal($oldrec,$newrec,"system");
                     $text.=".";
                     $text.="\n";
                     $text.="\n---\n";
                     $text.=$self->T("Justification").":\n";
                     $text.=effVal($oldrec,$newrec,"exceptreqtxt");
                     $text.="\n---\n";
                     return($subject,$text); 
                  }
               ); 
            }
         }
      }
   }
   return($bak);
}

sub isDeleteValid
{
   my $self=shift;
   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_systemcistatus"))){
     Query->Param("search_systemcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}










1;
