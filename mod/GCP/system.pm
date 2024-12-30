package GCP::system;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use GCP::lib::Listedit;
use JSON;
@ISA=qw(GCP::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(

      new kernel::Field::Id(
            name              =>'idpath',
            searchable        =>0,
            group             =>'source',
            align             =>'left',
            RestFilterType    =>[qw(id name projectId zonename)],
            label             =>'GCP Id-Path'),

      new kernel::Field::RecordUrl(),


      new kernel::Field::Text(     
            name              =>'id',
            searchable        =>1,
            group             =>'source',
            align             =>'left',
            dataobjattr       =>'id',
            label             =>'Instance ID'),

      new kernel::Field::Text(     
            name              =>'projectId',
            searchable        =>1,
            group             =>'source',
            align             =>'left',
            dataobjattr       =>'projectId',
            label             =>'Project ID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(      # https://www.ietf.org/rfc/rfc1035.txt
            name              =>'name',
            searchable        =>1,
            htmlwidth         =>'200px',
            label             =>'Name'),


      new kernel::Field::Text(     
            name              =>'status',
            dataobjattr       =>'status',
            label             =>'Online-State'),

      new kernel::Field::Text(     
            name              =>'cputype',
            dataobjattr       =>'cpuPlatform',
            label             =>'CPU Platform'),

      new kernel::Field::Text(
            name              =>'cpucount',
            searchable        =>0,
            label             =>'CPU-Count'),

      new kernel::Field::Text(
            name              =>'memory',
            searchable        =>0,
            label             =>'Memory'),

      new kernel::Field::SubList(
            name              =>'ipaddresses',
            label             =>'IP-Adresses',
            searchable        =>0,
            vjointo           =>'GCP::ipaddress',
            vjoinon           =>['idpath'=>'idpath'],
            vjoindisp         =>['name','netareatag','ifname']),


      new kernel::Field::Container(     
            name              =>'tags',
            dataobjattr       =>'tags',
            uivisible         =>sub{
               my $self=shift;
               return(1) if ($self->getParent->IsMemberOf("admin"));
               return(0);
            },
            label             =>'Tags'),

      new kernel::Field::Text(
            name              =>'zonename',
            group             =>'source',
            searchable        =>0,
            dataobjattr       =>'zonename',
            label             =>'Zone-Name'),

      new kernel::Field::Date(
            name              =>'laststart',
            group             =>'source',
            searchable        =>0,
            dataobjattr       =>'lastStartTimestamp',
            label             =>'Last-Start-Date'),

      new kernel::Field::CDate(
            name              =>'cdate',
            group             =>'source',
            searchable        =>0,
            label             =>'Creation-Date'),

   );
   $self->setDefaultView(qw(name id projectId status cdate));
   return($self);
}



sub getCredentialName
{
   my $self=shift;

   return("GCP");
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(ImportSystem));
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my @view=$self->GetCurrentView();

   my ($flt,$requestToken)=$self->simplifyFilterSet($filterset);
   return(undef) if (!defined($flt));

   my @curView=$self->getCurrentView();

   my $credentialName=$self->getCredentialName();
   my $Authorization=$self->getAuthorizationToken($credentialName);


   my ($restFinalAddr,$requesttoken,$constParam)=$self->Filter2RestPath(
      [ "/compute/v1/projects/{projectId}/zones/{zonename}/instances/{name}",
        "/compute/v1/projects/{projectId}/aggregated/instances"],  
      $filterset,
      {
      }
   );

   if (!defined($restFinalAddr)){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"unknown error while create restFinalAddr");
      }
      return(undef);
   }

   my $d=$self->CollectREST(
      dbname=>$credentialName,
      useproxy=>1,
      requesttoken=>$requesttoken,
      url=>sub{
         my $self=shift;
         my $baseurl="https://compute.googleapis.com";
         my $dataobjurl=$baseurl.$restFinalAddr;
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
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "404"){  # 404 bedeutet nicht gefunden
            return([],"200");
         }
         if ($code eq "403"){  # 403=forbitten means not found, because
            return([],"200");  # project is disabled. (=GCP Rotz)
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data GCP system response");
         return(undef);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         my $srcRecords={};
         if (ref($data) eq "HASH"){
            if (exists($data->{items})){
               $srcRecords=$data->{items};
            }
            if (exists($data->{zone})){ # war offensichtlich ein direct request
               my $zonename=$data->{zone};
               $zonename=~s#^.*/([^/]+/[^/]+)$#$1#;
               $srcRecords->{$zonename}->{instances}=[$data];
            }
         }

         my @l;
         foreach my $zonename (keys(%{$srcRecords})){
            if (exists($srcRecords->{$zonename}->{instances}) &&
                ref($srcRecords->{$zonename}->{instances}) eq "ARRAY"){
               my $n=0;
               foreach my $rec (@{$srcRecords->{$zonename}->{instances}}){
                 $n++;
                 if ($n==1 &&
                     $self->Config->Param("W5BaseOperationMode") eq "dev"){
                    #print STDERR Dumper($rec);
                 }
                 if (in_array(\@view,[qw(ALL cpucount memory)])){
                    my $machineType=$rec->{machineType};
                    $rec->{cpucount}=1;
                    $rec->{memory}=1;
                    my $mtRec=$self->genericReadRequest(
                       $credentialName,$Authorization,$machineType
                    );
                    if (defined($mtRec) && ref($mtRec) eq "HASH"){
                       $rec->{cpucount}=$mtRec->{guestCpus};
                       $rec->{memory}=$mtRec->{memoryMb};
                    }
                  
                 }

                 # if (in_array(\@curView,[qw(ALL srcrec)])){
                 #    my $jsonfmt=new JSON();
                 #    $jsonfmt->property(latin1 => 1);
                 #    $jsonfmt->property(utf8 => 0);
                 #    $jsonfmt->pretty(1);
                 #    my $d=$jsonfmt->encode($rec);
                 #    $rec->{srcrec}=$d;
                 # }
                 # if (in_array(\@curView,[qw(ALL cdate)])){
                 #    $rec->{cdate}=$rec->{vserverCreationDate};
                 # }
                  $rec->{projectId}=$constParam->{projectId};
                  $rec->{zonename}=$zonename;
                  $rec->{zonename}=~s/^.*\///;  
                  $rec->{idpath}=$rec->{id}.'@'.
                                 $rec->{name}.'@'.
                                 $constParam->{projectId}.'@'.
                                 $rec->{zonename};
                  if (exists($constParam->{projectId})){
                     $rec->{projectId}=$constParam->{projectId};
                  }
                  $self->GCP::lib::Listedit::ExternInternTimestampReformat(
                     $rec,['creationTimestamp','lastStartTimestamp']
                  );
                  if (exists($rec->{creationTimestamp}) && 
                      $rec->{creationTimestamp} ne ""){
                     $rec->{cdate}=$rec->{creationTimestamp};
                  }
                  else{
                     $rec->{cdate}=undef;
                  }
                  push(@l,$rec);
               }
            }
         }
         return(\@l);
      }
   );
   return($d);
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
                           title=>"GCP System Import");
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
      msg(INFO,"start Import in GCP::system with importname $importname");
      if (($sysuuid)=$importname
              =~m/^(\S+)$/){
         $flt={
            idpath=>$sysuuid
         };
      }
      else{
         $self->LastMsg(ERROR,"GCP sieht schlecht aus");
         return(undef);
      }
      $self->ResetFilter();
      $self->SetFilter($flt);
      my @l=$self->getHashList(qw(id name projectId status ipaddresses));
      if ($#l==-1){
         if ($self->isDataInputFromUserFrontend()){
            if ($#{$self->LastMsg()}==-1){
               $self->LastMsg(ERROR,"GCP machine not found");
            }
         }
         msg(ERROR,"requested importname $importname can not be resolved");
         return(undef);
      }
    
      if ($#l>0){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"Systemname '%s' not unique in GCP",
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
         $self->LastMsg(ERROR,"no active GCP Cloud in inventory");
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
         name=>$iprec->{name},
         netareatag=>$iprec->{netareatag}
      };
   }

   my $sysimporttempl={
      name=>[$sysrec->{name},"gcp".$sysrec->{id}],
      initialname=>"gcp".$sysrec->{id},
      id=>$sysrec->{id},
      srcid=>$sysrec->{idpath},
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
      checkForSystemExistsFilter=>sub{  # Nachfrage ob Reuse System-Candidat not
         my $osys=shift;                # exists in srcobj
         my $srcid=$osys->{srcid};
         return({idpath=>\$srcid});
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





1;
