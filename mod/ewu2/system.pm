package ewu2::system;
#  W5Base Framework
#  Copyright (C) 118  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                searchable    =>1,
                group         =>'source',
                label         =>"DevLabSystemID",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"COMPUTER_SYSTEM_ID\""),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>"full systemname",
                ignorecase    =>1,
                htmldetail    =>0,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"UNAME\" || ' (' || ".
                                "\"COMPUTER_SYSTEMS\".\"COMPUTER_SYSTEM_ID\" ".
                                "||')'"),

      new kernel::Field::Text(
                name          =>'typedfullname',
                label         =>"full systemname",
                nowrap        =>1,
                uivisible     =>0,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"UNAME\" || ' (' || ".
                                "\"COMPUTER_SYSTEMS\".\"COMPUTER_SYSTEM_ID\" ".
                                "||') ' || \"COMPUTER_SYSTEMS\".\"TYPE\""),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>"Systemname",
                ignorecase    =>1,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"UNAME\""),

      new kernel::Field::Text(
                name          =>'status',
                label         =>"Status",
                ignorecase    =>1,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"STATUS\""),

      new kernel::Field::Text(
                name          =>'type',
                label         =>"system type",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"TYPE\""),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>"'15506528210001'"),

      new kernel::Field::Boolean(
                name          =>'deleted',
                label         =>"marked as delete",
                htmldetail    =>0,
                dataobjattr   =>"decode(\"COMPUTER_SYSTEMS\".".
                                "\"DELETED_AT\",NULL,0,1)"),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                group         =>'ipaddresses',
                vjointo       =>'ewu2::ipaddress',
                vjoinon       =>['id'=>'devlabsystemid'],
                vjoindisp     =>[qw(name dnsname dnsdomain comments)]),

      new kernel::Field::SubList(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                vjointo       =>'ewu2::lnksystemcontact',
                vjoinon       =>['id'=>'devlabsystemid'],
                vjoindisp     =>[qw(contactfullname comments)]),

      new kernel::Field::SubList(
                name          =>'contractowners',
                label         =>'contract owners',
                group         =>'contacts',
                searchable    =>0,
                vjointo       =>'ewu2::lnksystemcontrowner',
                htmldetail    =>'NotEmpty',
                vjoinon       =>['id'=>'devlabsystemid'],
                vjoindisp     =>[qw(contractowner)]),

      new kernel::Field::SubList(
                name          =>'contracts',
                label         =>'Contracts',
                group         =>'contracts',
                vjointo       =>'ewu2::lnksystemcontract',
                searchable    =>0,
                vjoinon       =>['id'=>'devlabsystemid'],
                vjoindisp     =>[qw(contractname projectname)]),

      new kernel::Field::Text(
                name          =>'description',
                label         =>"Description",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"DESCRIPTION\""),

      new kernel::Field::TextDrop(
                name          =>'location',
                label         =>'Location',
                translation   =>'itil::asset',
                vjointo       =>'base::location',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>"LocationID",
                dataobjattr   =>"'11927275230009'"),

      new kernel::Field::Textarea(
                name          =>'notes',
                label         =>"Notes",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"NOTES\""),

      new kernel::Field::Link(
                name          =>'physicalelementid',
                label         =>"Physical Element Id",
                dataobjattr   =>"decode(\"COMPUTER_SYSTEMS\".\"TYPE\",".
                             "'VirtualMachine',VHOST.PHYSICAL_ELEMENT_ID,".
                             "\"COMPUTER_SYSTEMS\".\"PHYSICAL_ELEMENT_ID\")"),

      new kernel::Field::Link(
                name          =>'clustercsid',
                label         =>"Cluster Cs Id",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CLUSTER_CS_ID\""),

      new kernel::Field::TextDrop(
                name          =>'vhostname',
                label         =>"virtualisation Host",
                group         =>'virtualisation',
                htmldetail    =>'NotEmpty',
                vjointo       =>'ewu2::system',
                vjoinon       =>['hostingcsid'=>'id'],
                vjoindisp     =>'typedfullname'),

      new kernel::Field::TextDrop(
                name          =>'vhostsystemname',
                label         =>"virtualisation Systemname",
                group         =>'virtualisation',
                htmldetail    =>0,
                vjointo       =>'ewu2::system',
                vjoinon       =>['hostingcsid'=>'id'],
                vjoindisp     =>'systemname'),

      new kernel::Field::Link(
                name          =>'hostingcsid',
                label         =>"Hosting Cs Id",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"HOSTING_CS_ID\""),

      new kernel::Field::Text(
                name          =>'vmvirtualisationtype',
                label         =>"Virtualisation Type",
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".".
                                "\"VM_VIRTUALISATION_TYPE\""),

      new kernel::Field::SubList(
                name          =>'vsystems',
                label         =>'virtual systems',
                group         =>'virtualisation',
                htmldetail    =>'NotEmpty',
                vjointo       =>'ewu2::system',
                vjoinon       =>['id'=>'hostingcsid'],
                vjoindisp     =>[qw(typedfullname status osrelease)]),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>"OS-Release",
                group         =>'sysdata',
                ignorecase    =>1,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"OS\""),

      new kernel::Field::Text(
                name          =>'platform',
                label         =>"Platform",
                group         =>'sysdata',
                ignorecase    =>1,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"PLATFORM\""),

      new kernel::Field::Text(
                name          =>'cputype',
                group         =>'sysdata',
                label         =>"CPU-Type",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CPU_TYPE\""),

      new kernel::Field::Text(
                name          =>'cpuspeed',
                group         =>'sysdata',
                label         =>"CPU-Speed",
                dataobjattr   =>
                  "NULLIF(case when instr(".
                         "lower(\"COMPUTER_SYSTEMS\".CPU_SPEED),'ghz')>1 then ".
                     "(nvl(to_number( ".
                       "regexp_substr(\"COMPUTER_SYSTEMS\".CPU_SPEED, ".
                                     "'^\\s*([0-9]+)',1,1,NULL,1)),0)+ ".
                      "(nvl(to_number( ".
                        "rpad(regexp_substr(\"COMPUTER_SYSTEMS\".CPU_SPEED, ".
                                      "'^\\s*[0-9]+[,.]([0-9]{1,3})', ".
                                      "1,1,NULL,1),3,'0')),0)*0.001))*1000 ".
                      "else ".
                     "(nvl(to_number( ".
                       "regexp_substr(\"COMPUTER_SYSTEMS\".CPU_SPEED, ".
                                     "'^\\s*([0-9]+)',1,1,NULL,1)),0)+ ".
                      "(nvl(to_number( ".
                         "rpad(regexp_substr(\"COMPUTER_SYSTEMS\".CPU_SPEED, ".
                                       "'^\\s*[0-9]+[,.]([0-9]{1,3})', ".
                                       "1,1,NULL,1),3,'0')),0)*0.001)) ".
                  "end,0)"),

      new kernel::Field::Text(
                name          =>'cpucount',
                group         =>'sysdata',
                label         =>"CPU-Count",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CPU_COUNT\""),

      new kernel::Field::Text(
                name          =>'cpucorestotal',
                group         =>'sysdata',
                label         =>"CPU Cores Total",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CPU_CORES_TOTAL\""),

      new kernel::Field::Text(   
                name          =>'memory',  
                group         =>'sysdata',
                label         =>"Memory",
                unit          =>'MB',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"RAM_MB\""),

      new kernel::Field::Text(
                name          =>'hostid',
                label         =>"Host-ID",
                group         =>'sysdata',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"HOSTID\""),

      new kernel::Field::TextDrop(
                name          =>'asset',
                label         =>"Asset",
                group         =>'asset',
                htmldetail    =>'NotEmpty',
                vjointo       =>'ewu2::asset',
                vjoinon       =>['physicalelementid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'operatedby',
                label         =>"Operated By",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"OPERATED_BY\""),

      new kernel::Field::Text(
                name          =>'servicelevel',
                label         =>"Service Level",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"SERVICE_LEVEL\""),

      new kernel::Field::Text(
                name          =>'lockversion',
                uivisible     =>0,
                label         =>"Lock Version",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"LOCK_VERSION\""),

      new kernel::Field::Text(
                name          =>'survey',
                label         =>"Survey",
                uivisible     =>0,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"SURVEY\""),

      new kernel::Field::Text(
                name          =>'backupsystem',
                group         =>'backup',
                label         =>"Backup System",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"BACKUP_SYSTEM\""),

      new kernel::Field::Text(
                name          =>'backupserver',
                group         =>'backup',
                label         =>"Backup Server",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"BACKUP_SERVER\""),

      new kernel::Field::Text(
                name          =>'managementaccess',
                uivisible     =>0,
                label         =>"Management Access",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"MANAGEMENT_ACCESS\""),

      new kernel::Field::Text(
                name          =>'domain',
                label         =>"Domain",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"DOMAIN\""),

      new kernel::Field::Text(
                name          =>'puppet',
                label         =>"Puppet",
                uivisible     =>0,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"PUPPET\""),

      new kernel::Field::Text(
                name          =>'sger',
                uivisible     =>0,
                label         =>"Sger",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"SGER\""),

      new kernel::Field::Date(
                name          =>'dlicensedate',
                label         =>"License Date",
                uivisible     =>0,
                timezone      =>'CET',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"LICENSE_DATE\""),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                timezone      =>'CET',
                label         =>"Creation-Date",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CREATED_AT\""),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                timezone      =>'CET',
                label         =>"Modification-Date",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"UPDATED_AT\""),

      new kernel::Field::Date(
                name          =>'ddate',
                group         =>'source',
                timezone      =>'CET',
                uivisible     =>0,
                label         =>"Deletion-Date",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"DELETED_AT\""),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(systemname type status osrelease 
                            vhostname asset id));
   $self->setWorktable("\"COMPUTER_SYSTEMS\"");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join $worktable \"VHOST\" ".
            "on $worktable.\"HOSTING_CS_ID\"=\"VHOST\".\"COMPUTER_SYSTEM_ID\"";

   return($from);
}





sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"ewu2"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","sysdata","virtualisation",
          "asset","ipaddresses","contacts",
          "backup","contracts","source");
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }

}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(ImportSystem));
}  

sub ImportSystem
{
   my $self=shift;

   my $importname=trim(Query->Param("importname"));
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"system has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"EWU2 System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


   

sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   my $w5flt;
   if ($param->{importname} ne ""){
      if ($param->{importname}=~m/^\d+$/){
         $flt={id=>[$param->{importname}],deleted=>\'0'};
      }
      else{
         $flt={systemname=>[$param->{importname}],deleted=>\'0'};
      }
      $w5flt={srcid=>[$param->{importname}],srcsys=>\'EWU2'};
   }
   else{
      return(undef);
   }
   $self->ResetFilter();
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(ALL));
   if ($#l==-1){
      $self->LastMsg(ERROR,"DevLabSystemID not found in EWU2");
      return(undef);
   }
   if ($#l>0){
      $self->LastMsg(ERROR,"DevLabSystemID not unique in EWU2");
      return(undef);
   }
   my $sysrec=$l[0];


   if ($sysrec->{status} ne "up"){
      $self->LastMsg(ERROR,"DevLabSystemID is not up");
      return(undef);
   }





   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter($w5flt);
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   my $identifyby;
   if (defined($w5sysrec)){
      if ($w5sysrec->{cistatusid}==4){
         $self->LastMsg(ERROR,"DevLabSystemID already exists in W5Base");
         return(undef);
      }

      my %newrec=(cistatusid=>4);
      my $userid;

      if ($self->isDataInputFromUserFrontend() &&
          !$self->IsMemberOf("admin")) {
         $userid=$self->getCurrentUserId();
         $newrec{databossid}=$userid;
      }

      if ($sys->ValidatedUpdateRecord($w5sysrec,\%newrec,
                                      {id=>\$w5sysrec->{id}})) {
         $identifyby=$w5sysrec->{id};
      }
   }
   else{
      # check 1: Assigmenen Group registered
#      if ($sysrec->{lassignmentid} eq ""){
#         $self->LastMsg(ERROR,"SystemID has no Assignment Group");
#         return(undef);
#      }
#      # check 2: Assignment Group active
#      my $acgroup=getModuleObject($self->Config,"tsacinv::group");
#      $acgroup->SetFilter({lgroupid=>\$sysrec->{lassignmentid}});
#      my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisoremail));
#      if (!defined($acgrouprec)){
#         $self->LastMsg(ERROR,"Can't find Assignment Group of system");
#         return(undef);
#      }
#      # check 3: Supervisor registered
#      #if ($acgrouprec->{supervisoremail} eq ""){
#      #   $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
#      #   return(undef);
#      #}
      my $importname;
      # check 4: load Supervisor ID in W5Base
      my $user=getModuleObject($self->Config,"base::user");
      my $admid;
      if ($importname ne ""){
         $admid=$user->GetW5BaseUserID($importname,"email");
      }
      #if (!defined($admid)){
      #   $self->LastMsg(WARN,"Can't import Supervisor as Admin");
      #}
      # check 5: find id of mandator "extern"
      my $mandatorid;
      if (exists($param->{mandatorid})){
         $mandatorid=$param->{mandatorid};
      }
      else{
         my $mand=getModuleObject($self->Config,"base::mandator");
         $mand->SetFilter({name=>"extern"});
         my ($mandrec,$msg)=$mand->getOnlyFirst(qw(grpid));
         if (!defined($mandrec)){
            $self->LastMsg(ERROR,"Can't find mandator extern");
            return(undef);
         }
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write",
                                             "direct");
         $mandatorid=$mandrec->{grpid};
         if (in_array(\@mandators,200)){
            $mandatorid=200;
         }
         else{
            $mandatorid=$mandators[0];
         }
         if ($mandatorid eq ""){
            $self->LastMsg(ERROR,"Can't find any mandator");
            return(undef);
         }
      }

      my $systype="standard";
      my $newrec={name=>$sysrec->{systemname},
                  srcid=>$sysrec->{id},
                  srcsys=>'EWU2',
                  allowifupdate=>1,
                  mandatorid=>$mandatorid,
                  cistatusid=>4};
      if (exists($param->{databossid})){
         $newrec->{databossid}=$param->{databossid};
      }
      if ($sysrec->{type} eq "VirtualMachine"){
         $systype="virtualizedSystem";
         if ($sysrec->{vhostname} eq "" || $sysrec->{hostingcsid} eq ""){
            $self->LastMsg(ERROR,"EWU2 incomplete: ".
                           "no vhost information for virtualizedSystem");
            return(undef);
         }
         my $sys=getModuleObject($self->Config,"itil::system");
         $sys->SetFilter({
            cistatusid=>'4',
            srcsys=>'EWU2',
            srcid=>$sysrec->{hostingcsid}
         });
         my ($vmrec,$msg)=$sys->getOnlyFirst(qw(ALL));
         if (!defined($vmrec)){
            $self->LastMsg(WARN,"missing vmhost $sysrec->{vhostsystemname} ".
                                " - try to import it");
            my $pid=$self->Import({importname=>$sysrec->{vhostsystemname}});
            if (defined($pid)){
               $self->LastMsg(INFO,"Systemname $sysrec->{vhostsystemname} ".
                                   "imported");
            }
            else{
               $self->LastMsg(ERROR,"EWU2 incomplete: ".
                              "vmhost ".$sysrec->{vhostname}.
                              " needs to be imported at first");
               return(undef);
            }
         }
         else{
            $newrec->{vhostsystemid}=$vmrec->{id};
         }
      }
      elsif ($sysrec->{type} eq "PhysicalMachine"){
         if ($sysrec->{physicalelementid} eq ""){
            $self->LastMsg(ERROR,"EWU2 incomplete: ".
                           "missing PhysicalElement reference");
            return(undef);
         }
         my ($hwrec,$msg)=$self->ImportAsset($sysrec->{physicalelementid},
                                             $newrec->{mandatorid},
                                             $newrec->{databossid});

         if (!defined($hwrec)){
            $self->LastMsg(ERROR,"EWU2 incomplete: ".
                           "asset ".$sysrec->{asset}.
                           " needs to be imported at first");
            return(undef);
         }
         else{
            $newrec->{assetid}=$hwrec->{id};
         }
      }
      elsif ($sysrec->{type} eq "Service"){
         $self->LastMsg(WARN,"Systemname is a Service ".
                             "on $sysrec->{vhostsystemname} - try to import ".
                             $sysrec->{vhostsystemname});
         my $pid=$self->Import({importname=>$sysrec->{vhostsystemname}});
         if (defined($pid)){
            $self->LastMsg(INFO,"Systemname $sysrec->{vhostsystemname} ".
                                "imported");
            return($pid);
         }
         else{
            return(undef);
         }
      }
      else{
         $self->LastMsg(ERROR,"not suppored systemtyp ".
                              $sysrec->{type});
         return(undef);
      }

      # final: do the insert operation
      if (defined($admid)){
         $newrec->{admid}=$admid;
      }
      $newrec->{systemtype}=$systype;

      $identifyby=$sys->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      $sys->ResetFilter();
      $sys->SetFilter({'id'=>\$identifyby});
      my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         my $qc=getModuleObject($self->Config,"base::qrule");
         $qc->setParent($sys);
         $qc->nativQualityCheck($sys->getQualityCheckCompat($rec),$rec);
      }
   }
   return($identifyby);
}

sub ImportAsset
{
   my $self=shift;
   my $physicalelementid=shift;
   my $mandatorid=shift;
   my $databossid=shift;


   my $ass=getModuleObject($self->Config,"itil::asset");
   $ass->SetFilter({ srcsys=>'EWU2', srcid=>\$physicalelementid });
   my ($hwrec,$msg)=$ass->getOnlyFirst(qw(ALL));
   if (!defined($hwrec)){
      my $dlass=getModuleObject($self->Config,"ewu2::asset");
      $dlass->SetFilter({id=>\$physicalelementid});
      my ($arec,$msg)=$dlass->getOnlyFirst(qw(ALL));
      if ($arec->{serialno} eq ""){
         $self->LastMsg(ERROR,"EWU2 incomplete: ".
                        "missing asset attribut serialno for autoimport");
         return(undef);
      }
      if ($arec->{commonname} eq "" ||
          $arec->{locationid} eq "" ||
          $arec->{deleted} eq "1"   ||
          $arec->{serialno} eq ""){
         $self->LastMsg(ERROR,"EWU2 incomplete: ".
                        "missing asset attributes for autoimport");
         return(undef);
      }
      my $newarec={
         name=>$arec->{commonname},
         serialno=>$arec->{serialno},
         cistatusid=>4,
         allowifupdate=>1,
         locationid=>$arec->{locationid},
         srcsys=>'EWU2',
         srcid=>$physicalelementid
      };
      if (defined($databossid)){
         $newarec->{databossid}=$databossid;
      }
      if (defined($mandatorid)){
         $newarec->{mandatorid}=$mandatorid;
      }
      my $identifyby=$ass->ValidatedInsertRecord($newarec);
      if ($identifyby eq ""){
         $self->LastMsg(ERROR,"EWU2 incomplete: ".
                        "asset autoimport incomplete");
         return(undef);
      }
      $ass->ResetFilter();
      $ass->SetFilter({ srcsys=>'EWU2', srcid=>\$physicalelementid });
      ($hwrec,$msg)=$ass->getOnlyFirst(qw(ALL));
   }

   return($hwrec,$msg);
}




1;

