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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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
                dataobjattr   =>'lnksimonpkgrec.id'),
                                                 
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
                wrdataobjattr =>'lnksimonpkgrec.system'),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Applicationnames',
                xhtmldetail    =>0,
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
                name          =>'needrefresh',
                label         =>'kg Restriction',
                readonly      =>1,
                dataobjattr   =>"if (".
                                "lnksimonpkgrec.modifydate<".
                                "simonpkg.modifydate,".
                                "1,0)"),

      new kernel::Field::Select(
                name          =>'reqtarget',
                label         =>'target state',
                transprefix   =>'TARGET.',
                value         =>[qw(MAND NEDL RECO)],
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
                value         =>[qw(REQUESTED ACCEPTED REJECTED EXPIRED)],
                selectfix     =>1,
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"if (lnksimonpkgrec.exceptreqtxt<>'',".
                                "if (exceptstate='ACCEPT','ACCEPTED',".
                                "if (exceptstate='REJECT','REJECTED','REQUESTED')),".
                                "NULL)"),

#      new kernel::Field::Text(
#                name          =>'comments',
#                searchable    =>0,
#                label         =>'Comments',
#                dataobjattr   =>'lnksimonpkgrec.comments'),

      new kernel::Field::Textarea(
                name          =>'exceptreqtxt',
                group         =>'exceptionreq',
                label         =>'exception request justification',
                dataobjattr   =>'lnksimonpkgrec.exceptreqtxt'),

      new kernel::Field::Date(
                name          =>'exceptreqdate',
                group         =>'exceptionreq',
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
                dataobjattr   =>'lnksimonpkgrec.exceptstate'),

      new kernel::Field::Textarea(
                name          =>'exceptrejecttxt',
                group         =>'exceptionappr',
                label         =>'exception approver explanation',
                dataobjattr   =>'lnksimonpkgrec.exceptrejecttxt'),

      new kernel::Field::Date(
                name          =>'exceptapprdate',
                group         =>'exceptionappr',
                htmldetail    =>'NotEmpty',
                label         =>'exception approve/reject date',
                dataobjattr   =>'lnksimonpkgrec.exceptapprdate'),
                                                   
      new kernel::Field::Contact(
                name          =>'exceptapprover',
                group         =>'exceptionappr',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                label         =>'exception approver',
                vjoinon       =>['exceptrequestorid'=>'userid']),

      new kernel::Field::Link(
                name          =>'exceptapproverid',
                label         =>'exception approver ID',
                group         =>'exceptionappr',
                dataobjattr   =>'lnksimonpkgrec.exceptapprover'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
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
   $self->setDefaultView(qw(system monpkg reqtarget curinststate exception cdate));
   $self->setWorktable("lnksimonpkgrec");
   return($self);
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
      $where="((system.cistatus in (3,4) and simonpkg.cistatus=4) ".
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
            "    lnksimonpkgrec.system=system.id) ";

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
      if (!$self->isWriteOnMonPkgValid($monpkgid,"software")){
         $self->LastMsg(ERROR,"no access");
         return(undef);
      }
      my $userid=$self->getCurrentUserId();
      if (effChanged($oldrec,$newrec,"exceptrejecttxt") ||
          effChanged($oldrec,$newrec,"exceptstate")){
         $newrec->{exceptapproverid}=$userid;
         $newrec->{exceptapprdate}=NowStamp("en");
      }
      if (effChanged($oldrec,$newrec,"exceptreqtxt")){
         if (effVal($oldrec,$newrec,"exceptreqtxt") eq ""){
            $newrec->{exceptrequestorid}=undef;
            $newrec->{exceptreqdate}=undef;
         }
         else{
            $newrec->{exceptrequestorid}=$userid;
            $newrec->{exceptreqdate}=NowStamp("en");
         }
         $newrec->{exceptstate}=undef;
         $newrec->{exceptrejecttxt}=undef;
         $newrec->{exceptapproverid}=undef;
         $newrec->{exceptapprdate}=undef;
      }
   }



   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=qw(default header source);

   if ($self->IsMemberOf("admin")){ # Schreibzugriff auf logisches system
      push(@l,"exceptionreq");
   }

   if ($rec->{exception} ne ""){
      push(@l,"exceptionappr");
   }

   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @editgroup=("exceptionreq","exceptionappr");

   return(@editgroup) if (!defined($oldrec) && !defined($newrec));
   my $monpkgid=$oldrec->{monpkgid};
   return(@editgroup) if ($self->IsMemberOf("admin"));
   return(@editgroup) if ($self->isWriteOnMonPkgValid($monpkgid,"software"));

   return(undef);
}


sub isWriteOnMonPkgValid
{
   my $self=shift;
   my $monpkgid=shift;
   my $group=shift;

   my $monpkg=$self->getPersistentModuleObject("SIMon::monpkg");
   $monpkg->SetFilter({id=>\$monpkgid});
   my ($arec,$msg)=$monpkg->getOnlyFirst(qw(ALL));
   my @g=$monpkg->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}





1;
