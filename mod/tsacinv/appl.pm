package tsacinv::appl;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
use tsacinv::lib::tools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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
                name          =>'applid',
                label         =>'ApplicationID',
                size          =>'13',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'amtsicustappl.code'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Name',
                uivisible     =>0,
                dataobjattr   =>"concat(concat(concat(amtsicustappl.name,' ('".
                                "),amtsicustappl.code),')')"),

      new kernel::Field::Link(
                name          =>'id',
                label         =>'ApplicationID',
                dataobjattr   =>'amtsicustappl.ltsicustapplid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Applicationname',
                uppersearch   =>1,
                dataobjattr   =>'amtsicustappl.name'),
                                    
      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'lower(amtsicustappl.status)'),
                                    
      new kernel::Field::Text(
                name          =>'tenant',
                label         =>'Tenant',
                group         =>'source',
                dataobjattr   =>'amtenant.code'),
                                    
      new kernel::Field::Interface(
                name          =>'tenantid',
                label         =>'Tenant ID',
                group         =>'source',
                dataobjattr   =>'amtenant.ltenantid'),
                                    
      new kernel::Field::Text(
                name          =>'usage',
                label         =>'Usage',
                dataobjattr   =>'amtsicustappl.usage'),
                                    
      new kernel::Field::Text(
                name          =>'criticality',
                label         =>'Criticality',
                dataobjattr   =>'amtsicustappl.businessimpact'),
                                    
      new kernel::Field::Text(
                name          =>'customerprio',
                label         =>'Priority',
                dataobjattr   =>'amtsicustappl.priority'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                vjointo       =>'tsacinv::customer',
                vjoinon       =>['lcustomerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lcustomerid',
                dataobjattr   =>'amcostcenter.lcustomerlinkid'),

      new kernel::Field::TextDrop(
                name          =>'secunit',
                label         =>'SecurityUnit',
                vjointo       =>'tsacinv::customer',
                vjoinon       =>['lsecunitid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lsecunitid',
                dataobjattr   =>'amtsicustappl.lsecurityunitid'),
                                    
      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'CFM Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'iassignmentgroup',
                label         =>'INM Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lincidentagid',
                label         =>'AM-Incident-AssignmentID',
                dataobjattr   =>'amtsicustappl.lincidentagid'),


      new kernel::Field::TextDrop(
                name          =>'capprovergroup',
                label         =>'CHM Approver Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lchhangeapprid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lchhangeapprid',
                label         =>'AM-Change-ApproverID',
                dataobjattr   =>'amtsicustappl.lchangeapprid'),

      new kernel::Field::TextDrop(
                name          =>'cimplementorgroup',
                label         =>'CHM Implementor Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lchhangeimplid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lchhangeimplid',
                label         =>'AM-Change-ImplementorID',
                dataobjattr   =>'amtsicustappl.lchangeimplid'),

                                    
      new kernel::Field::TextDrop(
                name          =>'sem',
                label         =>'Customer Business Manager',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                htmldetail    =>0,
                label         =>'Customer Business Manager E-Mail',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'semldapid',
                htmldetail    =>0,
                label         =>'Customer Business Manager LDAPID',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'semid',
                dataobjattr   =>'amtsicustappl.lservicecontactid'),
                                    
      new kernel::Field::TextDrop(
                name          =>'tsm',
                label         =>'Technical Contact',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsmid'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'tsmemail',
                htmldetail    =>0,
                label         =>'Technical Contact E-Mail',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsmid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsmldapid',
                htmldetail    =>0,
                label         =>'Technical Contact LDAPID',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsmid'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'tsmid',
                dataobjattr   =>'amtsicustappl.ltechnicalcontactid'),
                                    
      new kernel::Field::TextDrop(
                name          =>'tsm2',
                label         =>'Deputy Technical Contact',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsm2id'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'tsm2email',
                htmldetail    =>0,
                label         =>'Deputy Technical Contact E-Mail',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsm2id'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsm2ldapid',
                htmldetail    =>0,
                label         =>'Deputy Technical Contact LDAPID',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsm2id'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                dataobjattr   =>'amtsicustappl.ldeputytechnicalcontactid'),




      new kernel::Field::TextDrop(
                name          =>'opm',
                label         =>'OPM Contact',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opmid'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'opmemail',
                htmldetail    =>0,
                label         =>'OPM Contact E-Mail',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opmid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'opmldapid',
                htmldetail    =>0,
                label         =>'OPM Contact LDAPID',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opmid'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'opmid',
                dataobjattr   =>'amtsicustappl.lleaddemid'),
                                    
      new kernel::Field::TextDrop(
                name          =>'opm2',
                label         =>'Deputy OPM Contact',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opm2id'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'opm2email',
                htmldetail    =>0,
                label         =>'Deputy OPM Contact E-Mail',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opm2id'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'opm2ldapid',
                htmldetail    =>0,
                label         =>'Deputy OPM Contact LDAPID',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opm2id'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'opm2id',
                dataobjattr   =>'amtsicustappl.ldeputydemid'),








                                    
      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'amtsicustappl.lassignmentid'),
                                    
      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostid'=>'id'],
                dataobjattr   =>'amcostcenter.trimmedtitle'),
                                    
      new kernel::Field::TextDrop(
                name          =>'accountno',
                label         =>'Account-Number',
                size          =>'15',
                vjointo       =>'tsacinv::accountno',
                vjoinon       =>['id'=>'lapplicationid'],
                vjoindisp     =>'name'),
                                    
      new kernel::Field::Text(
                name          =>'ref',
                label         =>'Application Reference',
                dataobjattr   =>'amtsicustappl.ref'),

      new kernel::Field::Link(
                name          =>'lcostid',
                label         =>'AC-CostcenterID',
                dataobjattr   =>'amtsicustappl.lcostcenterid'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                size          =>'16',
                dataobjattr   =>'amtsicustappl.version'),

      new kernel::Field::Text(
                name          =>'issoxappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application is mangaged by rules of SOX or ICS',
                dataobjattr   =>'amtsicustappl.soxrelevant'),
                                    
      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Application Description',
                dataobjattr   =>'businessdesc.memcomment'),

      new kernel::Field::Textarea(
                name          =>'maintwindow',
                label         =>'Application Maintenence Window',
                dataobjattr   =>'amtsimaint.memcomment'),

      new kernel::Field::Text(
                name          =>'altbc',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'Alternate BC',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::SubList(
                name          =>'interfaces',
                label         =>'Interfaces',
                group         =>'interfaces',
                vjointo       =>'tsacinv::lnkapplappl',
                vjoinon       =>['id'=>'lparentid'],
                vjoindisp     =>['child']),

      new kernel::Field::SubList(
                name          =>'systems',
                group         =>'systems',
                label         =>'Systems',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinbase     =>{systemstatus=>"\"!out of operation\""},
                vjoinon       =>['id'=>'lparentid'],
                vjoindisp     =>['child','systemweblink','systemid','comments'],
                vjoininhash   =>['child','systemweblink','systemid','comments',
                                 'srcsys','srcid']),

      new kernel::Field::Boolean(
                name          =>'tbsm_ordered',
                group         =>'systems',
                htmldetail    =>0,
                label         =>'is TBSM on one of systems ordered',
                dataobjattr   =>"decode(tbsm.ordered,'XMBSM',1,0)"),

      new kernel::Field::Text(
                name          =>'usedsharedstoragesys',
                group         =>'usedsharedcomp',
                label         =>'direct connected Shared-Storage Servers',
                vjointo       =>'tsacinv::lnksharedstorage',
                weblinkto     =>'NONE',
                htmldetail    =>0,
                vjoinon       =>['applid'=>'applid'],
                vjoindisp     =>'storagename'),

      new kernel::Field::Text(
                name          =>'usedsharednetcomp',
                group         =>'usedsharedcomp',
                label         =>'direct connected Shared-Network Components',
                vjointo       =>'tsacinv::lnksharednet',
                htmldetail    =>0,
                weblinkto     =>'NONE',
                vjoinon       =>['applid'=>'applid'],
                vjoindisp     =>'netname'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'amtsicustappl.dtlastmodif'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(amtsicustappl.code,35,'0')"),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'amtsicustappl.dtcreation'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'amtsicustappl.dtlastmodif'),

#      new kernel::Field::Date(
#                name          =>'lastqcheck',
#                group         =>'source',
#                label         =>'Quality Check last date',
#                dataobjattr   =>'amtsicustappl.dqualitycheck'),

      new kernel::Field::Date(
                name          =>'mdaterev',
                group         =>'source',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'Modification-Date reverse',
                dataobjattr   =>'amtsicustappl.dtlastmodif'),

      new kernel::Field::Text(
                name          =>'srcsys',
                ignorecase    =>1,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amtsicustappl.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amtsicustappl.externalid'),

      new kernel::Field::Date(
                name          =>'srcload',
                timezone      =>'CET',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'amtsicustappl.dtimport'),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(name applid usage conumber assignmentgroup));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_tenant"))){
     Query->Param("search_tenant"=>"CS");
   }
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tsacinv/load/appl.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from=
      "amtsicustappl, ".
      "(select amcostcenter.* from amcostcenter ".
      " where amcostcenter.bdelete=0) amcostcenter,amemplgroup assigrp,".
      "(select distinct ".
      "      amtsiservicetype.identifier ordered,amtsicustappl.ltsicustapplid ".
      " from amtsiservice,amtsiservicetype,amtsirelportfappl,amtsicustappl,".
      "      amportfolio ".
      " where amtsiservice.lservicetypeid=amtsiservicetype.ltsiservicetypeid ".
      "     and amtsiservicetype.identifier='XMBSM' ".
      "     and amtsiservice.bdelete=0 ".
      "     and amtsirelportfappl.bdelete=0 ".
      "     and amtsiservice.lportfolioid=amtsirelportfappl.lportfolioid ".
      "     and amtsirelportfappl.bactive=1 ".
      "     and amtsirelportfappl.lapplicationid=amtsicustappl.ltsicustapplid ".
      "     and amtsirelportfappl.lportfolioid=amportfolio.lportfolioitemid ".
      "     and amportfolio.bdelete=0 ".
      ") tbsm,".
      "amcomment amtsimaint,amcomment businessdesc,".
      "amtenant";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=
      "amtsicustappl.bdelete=0 ".
      "and amtsicustappl.lmaintwindowid=amtsimaint.lcommentid(+) ".
      "and amtsicustappl.ltenantid=amtenant.ltenantid ".
      "and amtsicustappl.lcostcenterid=amcostcenter.lcostid(+) ".
      "and amtsicustappl.lcustbusinessdescid=businessdesc.lcommentid(+) ".
      "and amtsicustappl.lassignmentid=assigrp.lgroupid(+) ".
      "and amtsicustappl.ltsicustapplid=tbsm.ltsicustapplid(+) ";
   return($where);
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
   my $rec=shift;
   return(undef);
}


#sub schain
#{
#   my $self=shift;
#   my $page="schain";
#
#   my $idname=$self->IdField->Name();
#   $page.=$self->HtmlPersistentVariables($idname);
#
#   return($page);
#}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(schain ImportAppl),$self->SUPER::getValidWebFunctions());
}

#sub getHtmlDetailPages
#{
#   my $self=shift;
#   my ($p,$rec)=@_;
#   return($self->SUPER::getHtmlDetailPages($p,$rec),"schain"=>"Servicekette");
#}

#sub getDefaultHtmlDetailPage
#{
#   my $self=shift;
#
#
#
#
#
#
#   return("schain");
#}

#sub getHtmlDetailPageContent
#{
#   my $self=shift;
#   my ($p,$rec)=@_;
#   return($self->schain($p,$rec)) if ($p eq "schain");
#   return($self->SUPER::getHtmlDetailPageContent($p,$rec));
#}


sub ImportAppl
{
   my $self=shift;

   my $importname=Query->Param("importname");
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"application has been successfuly imported");
      }
      Query->Delete("DOIT");
   }

   # mandator select box createion
   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write","direct");
   my $m=getModuleObject($self->Config,"base::mandator");
   if ($self->IsMemberOf("admin")){
      $m->SetFilter({cistatusid=>\'4'});
   }
   else{
      $m->SetFilter({cistatusid=>\'4',grpid=>\@mandators});
   }
   my ($mandatorlist)=$m->getHtmlSelect("mandatorid","grpid",["name"]);
   ######################################################################


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1,
                           title=>"AssetManager Application Import");

   print $self->getParsedTemplate("tmpl/minitool.appl.import",{
                                     static=>{
                                        importname=>$importname,
                                        mandatorlist=>$mandatorlist
                                     },
                                  });
   print $self->HtmlBottom(body=>1,form=>1);
}


   

sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   if ($param->{importname} ne ""){
      $flt={applid=>[$param->{importname}]};
   }
   else{
      return(undef);
   }
   $self->ResetFilter();
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(applid name lassignmentid));
   if ($#l==-1){
      $self->LastMsg(ERROR,"ApplicationID not found in AssetManager");
      return(undef);
   }
   if ($#l>0){
      $self->LastMsg(ERROR,"ApplicationID not unique in AssetManager");
      return(undef);
   }

   my $applrec=$l[0];
   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->SetFilter($flt);
   my ($w5applrec,$msg)=$appl->getOnlyFirst(qw(ALL));
   my $identifyby;
   if (defined($w5applrec)){
      if ($w5applrec->{cistatusid}==4){
         $self->LastMsg(ERROR,"ApplicationID already exists in W5Base");
         return(undef);
      }
      $identifyby=$appl->ValidatedUpdateRecord($w5applrec,{cistatusid=>4},
                                              {id=>\$w5applrec->{id}});
   }
   else{
      # check 1: Assigmenen Group registered
      if ($applrec->{lassignmentid} eq ""){
         $self->LastMsg(ERROR,"ApplicationID has no Assignment Group");
         return(undef);
      }
      # check 2: Assingment Group active
      my $acgroup=getModuleObject($self->Config,"tsacinv::group");
      $acgroup->SetFilter({lgroupid=>\$applrec->{lassignmentid}});
      my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
      if (!defined($acgrouprec)){
         $self->LastMsg(ERROR,"Can't find Assignment Group of system");
         return(undef);
      }
      # check 3: Supervisor registered
      if ($acgrouprec->{supervisorldapid} eq "" &&
          $acgrouprec->{supervisoremail} eq ""){
         $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
         return(undef);
      }
      my $importname=$acgrouprec->{supervisorldapid};
      $importname=$acgrouprec->{supervisoremail} if ($importname eq "");
      # check 4: load Supervisor ID in W5Base
      my $user=getModuleObject($self->Config,"base::user");
      my $databossid=$user->GetW5BaseUserID($importname,"email");
      if (!defined($databossid)){
         $self->LastMsg(ERROR,"Can't import Supervisor as Databoss");
         return(undef);
      }
      # check 5: find id of mandator "extern"
      my $mandatorid=Query->Param("mandatorid");
      my $allowifupdate=0;
      my $mand=getModuleObject($self->Config,"base::mandator");
      $mand->SetFilter({name=>"extern"});
      my ($mandrec,$msg)=$mand->getOnlyFirst(qw(grpid));
      if (!defined($mandrec)){
         $self->LastMsg(ERROR,"Can't find mandator extern");
         return(undef);
      }
      if ($mandatorid eq $mandrec->{grpid} || $mandatorid eq ""){
         $mandatorid=$mandrec->{grpid};   # extern is the default and with
         $allowifupdate=1;                # allow ifupdate by def
      }
      # final: do the insert operation
      my $appname=$applrec->{name};
      $appname=~s/ /_/g;
      my $newrec={name=>$appname,
                  applid=>$applrec->{applid},
                  allowifupdate=>$allowifupdate,
                  mandatorid=>$mandatorid,
                  srcsys=>'AssetManager',
                  srcid=>$applrec->{applid},
                  cistatusid=>4};
      if ($self->IsMemberOf("admin")){
         $newrec->{databossid}=$databossid;
      }
      $identifyby=$appl->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      $appl->ResetFilter();
      $appl->SetFilter({'id'=>\$identifyby});
      my ($rec,$msg)=$appl->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         my $qc=getModuleObject($self->Config,"base::qrule");
         $qc->setParent($appl);
         $qc->nativQualityCheck($appl->getQualityCheckCompat($rec),$rec);
      }
   }
   return($identifyby);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default interfaces systems usedsharedcomp
             control
             w5basedata source));
}







1;
