package tpc::machine;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use tpc::lib::Listedit;
use JSON;
@ISA=qw(tpc::lib::Listedit);

# API at https://code.vmware.com/apis/39/vrealize-automation
# https://code.vmware.com/apis/978

# alles neu, macht der Mai
# https://developer.broadcom.com/xapis/vrealize-automation-cloud-infrastructure-as-a-service-iaas-api/latest/iaas/api/machines/get/

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::RecordUrl(),


      new kernel::Field::Id(     
            name              =>'id',
            searchable        =>1,
            group             =>'source',
            htmldetail        =>'NotEmpty',
            htmlwidth         =>'150px',
            align             =>'left',
            label             =>'MachineID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'name',
            searchable        =>1,
            htmlwidth         =>'200px',
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'genname',
            ODATA_filter      =>'name',
            searchable        =>1,
            htmlwidth         =>'200px',
            label             =>'generic name'),

      new kernel::Field::Text(     
            name              =>'powerState',
            searchable        =>1,
            label             =>'Online-State'),

      new kernel::Field::Text(     
            name              =>'orgId',
            searchable        =>1,
            label             =>'orgId'),

      new kernel::Field::Text(     
            name              =>'projectId',
            searchable        =>1,
            ODATA_filter      =>1,
            label             =>'projectId'),

      new kernel::Field::Text(     
            name              =>'project',
            vjointo           =>'tpc::project',
            vjoinon           =>['projectId'=>'id'],
            vjoindisp         =>'name',
            label             =>'Project'),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>'OS-Release'),

      new kernel::Field::Text(
                name          =>'osclass',
                label         =>'OS-Class'),

      new kernel::Field::Number(
            name              =>'cpucount',
            label             =>'CPU-Count'),

      new kernel::Field::Number(
            name              =>'memory',
            label             =>'Memory',
            unit              =>'MB'),

      new kernel::Field::Boolean(
            name              =>'ismcos',
            searchable        =>0,
            label             =>'MCOS'),

      new kernel::Field::Text(     
            name              =>'address',
            ODATA_filter      =>'1',
            searchable        =>1,
            label             =>'IP-Address'),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                searchable    =>0,
                vjointo       =>'tpc::ipaddress',
                vjoinon       =>['id'=>'id'],
                vjoindisp     =>['name','netareatag','ifname','mac']),

      new kernel::Field::Textarea(     
            name              =>'description',
            searchable        =>1,
            label             =>'Description'),

      new kernel::Field::Container(
            name              =>'tags',
            label             =>'Tags',
            uivisible         =>1,
            searchable        =>0,
            group             =>'tags'),

      new kernel::Field::Container(
            name              =>'custprops',
            label             =>'customProperties',
            uivisible         =>sub{
               my $self=shift;
               return(1) if ($self->getParent->IsMemberOf("admin"));
               return(0);
            },
            searchable        =>0,
            group             =>'tags'),

      new kernel::Field::Text(     
            name              =>'resourceId',
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'ResourceID'),

      new kernel::Field::Text(     
            name              =>'instanceUUID',
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'instanceUUID'),

      new kernel::Field::Text(     
            name              =>'UCinstanceUUID',
            searchable        =>0,
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'UCinstanceUUID'),

      new kernel::Field::Text(     
            name              =>'cloudAccountId',
            searchable        =>0,
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'CloudAccountId'),

      new kernel::Field::Text(     
            name              =>'cloudAccountName',
            vjointo           =>'tpc::cloudaccount',
            vjoinon           =>['cloudAccountId'=>'id'],
            vjoindisp         =>'name',
            group             =>'source',
            label             =>'CloudAccountName'),

      new kernel::Field::Text(     
            name              =>'cloudAccountHost',
            vjointo           =>'tpc::cloudaccount',
            vjoinon           =>['cloudAccountId'=>'id'],
            vjoindisp         =>'cloudAccountControlHostName',
            group             =>'source',
            label             =>'CloudAccountHost'),


      new kernel::Field::Text(     
            name              =>'vcUuid',
            searchable        =>0,
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'vcUuid'),

      new kernel::Field::CDate(
            name              =>'cdate',
            group             =>'source',
            label             =>'Creation-Date',
            dayonly           =>1,
            searchable        =>0,  # das tut noch nicht
            dataobjattr       =>'createdAt'),

      new kernel::Field::MDate(
            name              =>'mdate',
            group             =>'source',
            label             =>'Modification-Date',
            dayonly           =>1,
            searchable        =>0,  # das tut noch nicht
            dataobjattr       =>'updatedAt'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TPCX");
}




sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my $Authorization=$self->getVRealizeAuthorizationToken($credentialName);

   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4vRealize(
      "machines","id",
      $filterset
   );
   my $dataobjurl;
   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      retry_count=>6,
      retry_interval=>15,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         $dataobjurl=$baseurl."iaas/".$dbclass;
         return($dataobjurl);
      },

      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $headers=['Authorization'=>$Authorization,
                      'Content-Type'=>'application/json'];
 
         return($headers);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{content})){
            $data=$data->{content};
         }
         if (ref($data) ne "ARRAY"){
            $data=[$data];
         }
         map({
             $self->ExternInternTimestampReformat($_,"createdAt");
             $self->ExternInternTimestampReformat($_,"updatedAt");
             $_->{cpucount}=$_->{customProperties}->{cpuCount};
             $_->{memory}=$_->{customProperties}->{memoryInMB};
             $_->{osclass}=$_->{customProperties}->{osType};
             $_->{osrelease}=$_->{customProperties}->{softwareName};
             $_->{custprops}=$_->{customProperties};
             if (exists($_->{customProperties}->{vcUuid})){
                $_->{vcUuid}=$_->{customProperties}->{vcUuid};
             }
             if (exists($_->{customProperties}->{instanceUUID})){
                $_->{instanceUUID}=$_->{customProperties}->{instanceUUID};
                $_->{UCinstanceUUID}=uc($_->{customProperties}->{instanceUUID});
             }
             $_->{genname}=$_->{name};
             if ($_->{hostname} ne ""){
                $_->{name}=$_->{hostname};
             }
             else{  # hostname is not known at this time. try to extract from
                my $bootconfig;  # bootConfig
                if (ref($_->{bootConfig}) eq "HASH"){
                   $bootconfig=$_->{bootConfig}->{content};
                }
                my @l=grep(/^\s*hostname\s*:/,split(/\n/,$bootconfig));
                if ($#l==0){
                   my ($tmpname)=$l[0]=~m/^\s*hostname\s*:\s*(.*)\s*$/;
                   if (length($tmpname)>3){
                      $_->{name}=$tmpname;
                   }
                }
             }

             $_->{name}=~s/[\. ].*$//;
             if (ref($_->{tags}) eq "ARRAY"){
                my %h;
                foreach my $rec (@{$_->{tags}}){
                   $h{$rec->{key}}=$rec->{value} 
                }
                $_->{tags}=\%h;
             }
             if (exists($_->{tags}->{mcos})){
                $_->{ismcos}=1;
             }
             else{
                $_->{ismcos}=0;
             }
             $_->{cloudAccountId}=undef;
             if (ref($_->{cloudAccountIds}) eq "ARRAY"){
                $_->{cloudAccountId}=join(" ",@{$_->{cloudAccountIds}});
             }
             #printf STDERR ("RAW Record %s\n",Dumper($_));
         } @$data);
         return($data);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "404"){  # 404 bedeutet nicht gefunden
            return([],"200");
         }
         if ($code eq "403"){  # 403 Forbitten Problem 04/2023
            msg(ERROR,"vRA Bug 403 forbitten on access '$dataobjurl'");
            return([],"200");  # Workaround, to prevent Error Messages
         }                     # in QualityChecks
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data TPC machine response");
         return(undef);
      }

   );
   #customProperties

   return($d);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}

sub isUploadValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
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
                           title=>"TPC System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   my $importname;
   my $sysrec;

   my $credentialName=$self->getCredentialName();

   if ($param->{importname} ne ""){
      my $sysuuid;
      $importname=$param->{importname};
      msg(INFO,"start Import in aws::system with importname $importname");
      if (($sysuuid)=$importname
              =~m/^(\S+)$/){
         $flt={
            id=>$sysuuid
         };
      }
      else{
         $self->LastMsg(ERROR,"sieht schlecht aus");
         return(undef);
      }
      $self->ResetFilter();
      $self->SetFilter($flt);
      my @l=$self->getHashList(qw(id name projectId ipaddresses));
      if ($#l==-1){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"TPC machine not found");
         }
         msg(ERROR,"requested importname $importname can not be resolved");
         return(undef);
      }
    
      if ($#l>0){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"Systemname '%s' not unique in TPC",
                                 $param->{importname});
         }
         return(undef);
      }
      $sysrec=$l[0];
   }
   elsif (ref($param->{importrec}) eq "HASH"){
      $sysrec=$param->{importrec};
   }
   else{
      msg(ERROR,"no importname specified while ".$self->Self." Import call");
      return(undef);
   }
   my $appl=getModuleObject($self->Config,"TS::appl");
   my $cloudarea=getModuleObject($self->Config,"itil::itcloudarea");
   my $itcloud=getModuleObject($self->Config,"itil::itcloud");

   my $cloudrec;
   my $w5carec;
   {
      $itcloud->ResetFilter();
      $itcloud->SetFilter({shortname=>\$credentialName ,cistatusid=>'4'});
      my ($crec,$msg)=$itcloud->getOnlyFirst(qw(id name fullname cistatusid));
      if (defined($crec)){
         $cloudrec=$crec;
      }
      else{
         $self->LastMsg(ERROR,"no active TPC Cloud in inventory");
         return(undef);
      }
   }

   if ($sysrec->{projectId} ne ""){
      msg(INFO,"try to add CloudArea to system ".$sysrec->{name});
      $cloudarea->SetFilter({cloudid=>$cloudrec->{id},
                             srcid=>\$sysrec->{projectId}
      });
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec)){
         $w5carec=$w5cloudarearec;
      }
   }






   my $syssrcid=$sysrec->{id};
   my $system=getModuleObject($self->Config,"TS::system");

   if (!defined($w5carec)){
      my $msg;
      if (exists($param->{importname})){
         $msg=$param->{importname};
      }
      else{
         $msg=$param->{importrec}->{id};
      }
      if ($self->isDataInputFromUserFrontend()){
         # if import is from Job (W5Server f.e.) no error on missing
         # ca rec is needed - ca's are guranted by other processes
         $self->LastMsg(ERROR,"missing CloudArea for TPC import of '%s'",$msg);
      }
      return(undef);
   }

   my %ipaddresses;
   foreach my $iprec (@{$sysrec->{ipaddresses}}){
      $ipaddresses{$iprec->{name}}={
         name=>$iprec->{name}
      };
   }

   my $sysimporttempl={
      name=>[lc($sysrec->{name}),lc($sysrec->{genname})],
      initialname=>$sysrec->{id},
      id=>$sysrec->{id},
      srcid=>$sysrec->{id},
      ipaddresses=>[values(%ipaddresses)]
   };

   #if ($sysrec->{address} ne ""){
   #   $sysimporttempl->{ipaddresses}=[{
   #       name=>$sysrec->{address},
   #       netareatag=>'CNDTAG'
   #   }];
   #}

   if ($sysrec->{projectId} ne ""){
      msg(INFO,"try to add CloudArea to system ".$sysrec->{name});
      $cloudarea->SetFilter({cloudid=>$cloudrec->{id},
                             srcid=>\$sysrec->{projectId}
      });
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec)){
         $w5carec=$w5cloudarearec;
      }
   }


   my $ImportRec={
      cloudrec=>$cloudrec,
      cloudarearec=>$w5carec,
      imprec=>$sysimporttempl,
      srcsys=>$credentialName,
      srcsyslist=>[$credentialName,
                   'AssetManager', # for MCOS Systems
                   'TPC1'],        # for cleanup/retiere of TPC1
      checkForSystemExistsFilter=>sub{  # Nachfrage ob Reuse System-Candidat not
         my $osys=shift;                # exists in srcobj
         my $srcid=$osys->{srcid};
         return({id=>\$srcid});
      }
   };

   my $ImportObjects={   # Objects are in seperated Structur for better Dumping
      itcloud=>$itcloud,
      itcloudarea=>$cloudarea,
      appl=>$appl,
      system=>$system,
      srcobj=>$self
   };

   #printf STDERR ("ImportRec(imprec):%s\n",Dumper($ImportRec->{imprec}));
   my $ImportResult=$system->genericSystemImport($ImportObjects,$ImportRec);
   #printf STDERR ("ImportResult:%s\n",Dumper($ImportResult));
   if ($ImportResult){
      return($ImportResult->{IdentifedBy});
   }
   return();
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default tags source));
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


1;
