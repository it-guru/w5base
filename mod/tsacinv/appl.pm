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
                group         =>'appgen',
                size          =>'13',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'generic_appl."applid"'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full CI-Name',
                group         =>'appgen',
                explore       =>100,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'generic_appl."fullname"'),

      new kernel::Field::Link(
                name          =>'id',
                label         =>'ApplicationID',
                group         =>'appgen',
                dataobjattr   =>'generic_appl."id"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Applicationname',
                group         =>'appgen',
                uppersearch   =>1,
                dataobjattr   =>'generic_appl."name"'),
                                    
      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'CFM Assignment Group',
                group         =>'appgen',
                explore       =>200,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                explore       =>300,
                group         =>'appgen',
                dataobjattr   =>'generic_appl."status"'),
                                    
      new kernel::Field::Boolean(
                name          =>'deleted',
                readonly      =>1,
                group         =>'appgen',
                label         =>'marked as delete',
                dataobjattr   =>'generic_appl."deleted"'),

      new kernel::Field::Text(
                name          =>'usage',
                label         =>'Usage',
                explore       =>400,
                group         =>'default',
                dataobjattr   =>'"usage"'),
                                    
      new kernel::Field::Text(
                name          =>'criticality',
                label         =>'Criticality',
                group         =>'default',
                dataobjattr   =>'"criticality"'),
                                    
      new kernel::Field::Text(
                name          =>'customerprio',
                label         =>'Priority',
                group         =>'default',
                dataobjattr   =>'"customerprio"'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                group         =>'default',
                vjointo       =>'tsacinv::customer',
                vjoinon       =>['lcustomerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lcustomerid',
                dataobjattr   =>'"lcustomerid"'),

      new kernel::Field::TextDrop(
                name          =>'secunit',
                label         =>'SecurityUnit',
                group         =>'default',
                vjointo       =>'tsacinv::customer',
                vjoinon       =>['lsecunitid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lsecunitid',
                dataobjattr   =>'"lsecunitid"'),
                                    
      new kernel::Field::TextDrop(
                name          =>'iassignmentgroup',
                label         =>'INM Assignment Group',
                group         =>'default',
                explore       =>250,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lincidentagid',
                label         =>'AM-Incident-AssignmentID',
                dataobjattr   =>'"lincidentagid"'),

      new kernel::Field::TextDrop(
                name          =>'cimplementorgroup',
                label         =>'CHM Implementor Group',
                group         =>'default',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lchhangeimplid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lchhangeimplid',
                label         =>'AM-Change-ImplementorID',
                dataobjattr   =>'"lchhangeimplid"'),

                                    
      new kernel::Field::TextDrop(
                name          =>'sem',
                label         =>'Customer Business Manager',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                htmldetail    =>0,
                group         =>'default',
                label         =>'Customer Business Manager E-Mail',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'semldapid',
                htmldetail    =>0,
                group         =>'default',
                label         =>'Customer Business Manager LDAPID',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'semid',
                dataobjattr   =>'"semid"'),
                                    
      new kernel::Field::TextDrop(
                name          =>'tsm',
                label         =>'Technical Contact',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsmid'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'tsmemail',
                htmldetail    =>0,
                label         =>'Technical Contact E-Mail',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsmid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsmldapid',
                htmldetail    =>0,
                group         =>'default',
                label         =>'Technical Contact LDAPID',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsmid'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'tsmid',
                dataobjattr   =>'"tsmid"'),
                                    
      new kernel::Field::TextDrop(
                name          =>'tsm2',
                label         =>'Deputy Technical Contact',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsm2id'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'tsm2email',
                htmldetail    =>0,
                label         =>'Deputy Technical Contact E-Mail',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsm2id'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsm2ldapid',
                htmldetail    =>0,
                label         =>'Deputy Technical Contact LDAPID',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsm2id'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                dataobjattr   =>'"tsm2id"'),


      new kernel::Field::TextDrop(
                name          =>'opm',
                label         =>'OPM Contact',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opmid'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'opmemail',
                htmldetail    =>0,
                label         =>'OPM Contact E-Mail',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opmid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'opmldapid',
                htmldetail    =>0,
                label         =>'OPM Contact LDAPID',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opmid'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'opmid',
                dataobjattr   =>'"opmid"'),
                                    
      new kernel::Field::TextDrop(
                name          =>'opm2',
                label         =>'Deputy OPM Contact',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opm2id'=>'lempldeptid'],
                searchable    =>0,
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'opm2email',
                htmldetail    =>0,
                label         =>'Deputy OPM Contact E-Mail',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opm2id'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'opm2ldapid',
                htmldetail    =>0,
                label         =>'Deputy OPM Contact LDAPID',
                group         =>'default',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['opm2id'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::Link(
                name          =>'opm2id',
                dataobjattr   =>'"opm2id"'),
                                    
      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'generic_appl."lassignmentid"'),
                                    
      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                group         =>'default',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostid'=>'id'],
                dataobjattr   =>'"conumber"'),
                                    
      new kernel::Field::TextDrop(
                name          =>'accountno',
                label         =>'Account-Number',
                group         =>'default',
                size          =>'15',
                vjointo       =>'tsacinv::accountno',
                vjoinon       =>['id'=>'lapplicationid'],
                vjoindisp     =>'name'),
                                    
      new kernel::Field::Text(
                name          =>'ref',
                label         =>'Application Reference',
                group         =>'default',
                dataobjattr   =>'"ref"'),

      new kernel::Field::Link(
                name          =>'lcostid',
                label         =>'AC-CostcenterID',
                dataobjattr   =>'"lcostid"'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                group         =>'default',
                size          =>'16',
                dataobjattr   =>'"version"'),

      new kernel::Field::Text(
                name          =>'prodcomp',
                label         =>'Product/Component',
                group         =>'default',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'"prodcomp"'),

      new kernel::Field::Text(
                name          =>'issoxappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application is mangaged by rules of SOX or ICS',
                dataobjattr   =>'"issoxappl"'),
                                    
      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Application Description',
                group         =>'default',
                dataobjattr   =>'"description"'),

      new kernel::Field::Textarea(
                name          =>'maintwindow',
                label         =>'Application Maintenence Window',
                group         =>'default',
                dataobjattr   =>'"maintwindow"'),

      new kernel::Field::Text(
                name          =>'altbc',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'Alternate BC',
                dataobjattr   =>'"altbc"'),

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
                vjoinbase     =>{systemstatus=>"\"!out of operation\"",
                                 deleted=>'0'},
                vjoinon       =>['id'=>'lparentid'],
                vjoindisp     =>['child','systemweblink','systemid','comments'],
                vjoininhash   =>['child','systemweblink','systemid','comments',
                                 'srcsys','srcid']),

      new kernel::Field::Text(
                name          =>'usedsharedstoragesys',
                group         =>'usedsharedcomp',
                label         =>'direct connected Shared-Storage Servers',
                vjointo       =>'tsacinv::lnksharedstorage',
                weblinkto     =>'NONE',
                htmldetail    =>0,
                preferArray   =>1,
                vjoinon       =>['applid'=>'applid'],
                vjoindisp     =>'storagename'),

      new kernel::Field::Text(
                name          =>'usedsharednetcomp',
                group         =>'usedsharedcomp',
                label         =>'direct connected Shared-Network Components',
                vjointo       =>'tsacinv::lnksharednet',
                htmldetail    =>0,
                preferArray   =>1,
                weblinkto     =>'NONE',
                vjoinon       =>['applid'=>'applid'],
                vjoindisp     =>'netname'),

      new kernel::Field::SubList(
                name          =>'usedsharednetcompids',
                group         =>'usedsharedcomp',
                label         =>'direct connected Shared-Network SystemIDs',
                vjointo       =>'tsacinv::lnksharednet',
                htmldetail    =>0,
                weblinkto     =>'NONE',
                vjoinon       =>['applid'=>'applid'],
                vjoindisp     =>['netsystemid','netname']),

      new kernel::Field::Boolean(
                name          =>'isgeneric',
                readonly      =>1,
                htmldetail    =>0,
                selectfix     =>1,
                group         =>'appgen',
                label         =>'is generic only',
                dataobjattr   =>'decode(appl."id",NULL,1,0)'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'"replkeypri"'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>'"replkeysec"'),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'"cdate"'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'"mdate"'),

      new kernel::Field::Date(
                name          =>'mdaterev',
                group         =>'source',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'Modification-Date reverse',
                dataobjattr   =>'"mdaterev"'),

      new kernel::Field::Text(
                name          =>'srcsys',
                ignorecase    =>1,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"srcsys"'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"srcid"'),

      new kernel::Field::Date(
                name          =>'srcload',
                timezone      =>'CET',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'"srcload"'),

   );
   $self->{use_distinct}=0;
   $self->setWorktable("appl");
   $self->setDefaultView(qw(name applid usage conumber assignmentgroup));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>'!"out of operation"');
   }
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tsacinv/load/appl.jpg?".$cgi->query_string());
}
         

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{isgeneric}){
      return(qw(header appgen));
   }
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


sub getSqlFrom
{
   my $self=shift;
   my $from='generic_appl left outer join appl on generic_appl."id"=appl."id"';
   return($from);
}

#sub initSqlWhere
#{
#   my $self=shift;
#   my $where="amtsiprovsto.lassetid=assetportfolio.lastid ".
#             "and amtsiprovsto.bdelete='0' ".
#             "and assetportfolio.lmodelid=ammodel.lmodelid ".
#             "and ammodel.lnatureid=amnature.lnatureid(+) ".
#             "and amnature.name IN ('DISKSUBSYSTEM',".
#             "'DISKSUBSYSTEM_COMP','NAS-FILER') ".
#             "and assetportfolio.ltenantid=amtenant.ltenantid ".
#             "and assetportfolio.llocaid=amlocation.llocaid(+) ";
#   return($where);
#}




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
      # check 2: Assignment Group active
      my $acgroup=getModuleObject($self->Config,"tsacinv::group");
      $acgroup->SetFilter({lgroupid=>\$applrec->{lassignmentid}});
      my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
      if (!defined($acgrouprec)){
         $self->LastMsg(ERROR,"Can't find Assignment Group of system");
         return(undef);
      }
      my $databossid=$self->getCurrentUserId();

      if ($self->IsMemberOf("admin")){
         # check 3: Supervisor registered
         if ($acgrouprec->{supervisorldapid} eq "" &&
             $acgrouprec->{supervisoremail} eq ""){
            $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
            return(undef);
         }
         my $importtype="posix";
         my $importname=$acgrouprec->{supervisorldapid};
         if ($importname eq ""){
            $importname=$acgrouprec->{supervisoremail};
            $importtype="email";
         }
         # check 4: load Supervisor ID in W5Base
         my $user=getModuleObject($self->Config,"base::user");
         $databossid=$user->GetW5BaseUserID($importname,$importtype);
         if (!defined($databossid)){
            $self->LastMsg(ERROR,"Can't import Supervisor as Databoss");
            return(undef);
         }
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
   return(qw(header appgen default interfaces systems usedsharedcomp
             control
             w5basedata source));
}



sub jsExploreObjectMethods
{
   my $self=shift;
   my $methods=shift;

   my $label=$self->T("add shared network systems");
   $methods->{'m500addApplicationNetworksystems'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call m500addApplicationNetworksystems on \",this);
          \$(\".spinner\").show();
          var app=this.app;
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          app.pushOpStack(new Promise(function(methodDone){
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'tsacinv::appl');
                w5obj.SetFilter({
                   applid:dataobjid
                });
                w5obj.findRecord(\"applid,usedsharednetcompids\",function(data){
                   for(recno=0;recno<data.length;recno++){
                      for(netsno=0;
                          netsno<data[recno].usedsharednetcompids.length;
                          netsno++){
                         var netsrec=data[recno].usedsharednetcompids[netsno];
                         app.addNode(\"tsacinv::system\",
                                     netsrec.netsystemid,netsrec.netsystemid);
                         app.addEdge(app.toObjKey(dataobj,dataobjid),
                                     app.toObjKey(\"tsacinv::system\",
                                     netsrec.netsystemid));
                      }
                   }
                   methodDone(\"end of addApplicationInterfaces\");
                });
             });
          }));
       }
   ";

   my $label=$self->T("add systems");
   $methods->{'m501addApplicationSystems'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call m501addApplicationSystems on \",this);
          \$(\".spinner\").show();
          var app=this.app;
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          app.pushOpStack(new Promise(function(methodDone){
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'tsacinv::appl');
                w5obj.SetFilter({
                   applid:dataobjid
                });
                w5obj.findRecord(\"applid,systems\",function(data){
                   for(recno=0;recno<data.length;recno++){
                      for(subno=0;subno<data[recno].systems.length;subno++){
                         var subrec=data[recno].systems[subno];
                         app.addNode('tsacinv::system',subrec.systemid,
                                     subrec.systemid);
                         app.addEdge(app.toObjKey(dataobj,dataobjid),
                                     app.toObjKey('tsacinv::system',
                                     subrec.systemid),
                                     {noAcross:true});
                      }
                   }
                   methodDone(\"end of m501addApplicationSystems\");
                });
             });
          }));
       }
   ";


}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}










1;
