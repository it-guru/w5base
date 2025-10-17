package itncmdb::asset;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use itncmdb::lib::Listedit;
use JSON;
@ISA=qw(itncmdb::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(


      new kernel::Field::Id(     
            name              =>'id',
            searchable        =>1,
            RestFilterType    =>'CONST2PATH',
            group             =>'source',
            align             =>'left',
            dataobjattr       =>'pserverUid',
            label             =>'Asset UID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'name',
            searchable        =>1,
            dataobjattr       =>'pserverHostname',
            label             =>'pserverName'),

      new kernel::Field::Number(     
            name              =>'pserverCorecount',
            searchable        =>0,
            dataobjattr       =>'pserverCorecount',
            label             =>'pserverCorecount'),

      new kernel::Field::Number(     
            name              =>'pserverCpucount',
            searchable        =>0,
            dataobjattr       =>'pserverCpucount',
            label             =>'pserverCpucount'),

      new kernel::Field::Number(     
            name              =>'pserverCpuspeed',
            searchable        =>0,
            dataobjattr       =>'pserverCpuspeed',
            label             =>'pserverCpuspeed'),

      new kernel::Field::Number(     
            name              =>'pserverMemory',
            searchable        =>0,
            dataobjattr       =>'pserverMemory',
            label             =>'pserverMemory'),

      new kernel::Field::Text(     
            name              =>'pserverCustomer',
            searchable        =>0,
            dataobjattr       =>'pserverCustomer',
            label             =>'pserverCustomer'),

      new kernel::Field::Text(     
            name              =>'Location_address1',
            searchable        =>0,
            dataobjattr       =>'Location_address1',
            label             =>'Location_address1'),

      new kernel::Field::Text(     
            name              =>'Location_country',
            searchable        =>0,
            dataobjattr       =>'Location_country',
            label             =>'Location_country'),

      new kernel::Field::Text(     
            name              =>'Location_zipcode',
            searchable        =>0,
            dataobjattr       =>'Location_zipcode',
            label             =>'Location_zipcode'),

      new kernel::Field::Text(     
            name              =>'Location_location',
            searchable        =>0,
            dataobjattr       =>'Location_location',
            label             =>'Location_location'),

      new kernel::Field::Text(
                name          =>'w5locid',
                label         =>'W5Base Location ID',
                group         =>'w5baselocation',
                searchable    =>0,
                depend        =>[qw(Location_location Location_address1 
                                    Location_country  Location_zipcode)],
                onRawValue    =>\&findW5LocID),

      new kernel::Field::TextDrop(
                name          =>'w5loc_name',
                group         =>'w5baselocation',
                label         =>'W5Base Location: Fullname',
                vjointo       =>\'base::location',
                vjoindisp     =>'name',
                vjoinon       =>['w5locid'=>'id'],
                searchable    =>0),

      new kernel::Field::Text(     
            name              =>'pserverManufacturer',
            searchable        =>0,
            dataobjattr       =>'pserverManufacturer',
            label             =>'pserverManufacturer'),

      new kernel::Field::Text(     
            name              =>'pserverModel',
            searchable        =>0,
            dataobjattr       =>'pserverModel',
            label             =>'pserverModel'),

      new kernel::Field::Text(     
            name              =>'serialno',
            searchable        =>0,
            dataobjattr       =>'pserverSerialNo',
            label             =>'pserverSerialNo'),

      new kernel::Field::CDate(
            name              =>'cdate',
            group             =>'source',
            sqlorder          =>'desc',
            label             =>'Creation-Date',
            dataobjattr       =>'cdate'),

      new kernel::Field::Textarea(
            name              =>'srcrec',
            searchable        =>0,
            htmldetail        =>"AdminOrSupport",
            group             =>'source',
            dataobjattr       =>'srcrec',
            label             =>'original source record')

   );
   $self->{ASSETKWORDS}=['ITENOS-RZ','virtuelles Asset ITENOS-RZ Frankfurt'];
   $self->setDefaultView(qw(id name));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("ITNCMDB");
}


sub findW5LocID
{
   my $self=shift;
   my $current=shift;

   my $p="Location_";

   my $loc=getModuleObject($self->getParent->Config,"base::location");
   my $address1=$self->getParent->getField("${p}address1")->RawValue($current);
   my $location=$self->getParent->getField("${p}location")->RawValue($current);
   my $zipcode=$self->getParent->getField("${p}zipcode")->RawValue($current);
   my $country=$self->getParent->getField("${p}country")->RawValue($current);
   my $newrec;
   $newrec->{country}=$country;
   $newrec->{location}=$location;
   $newrec->{address1}=$address1;
   $newrec->{zipcode}=$zipcode;
   $newrec->{cistatusid}="4";

   return(undef) if ($newrec->{address1}=~m/^\s*$/);

   foreach my $k (keys(%$newrec)){
      delete($newrec->{$k}) if (!defined($newrec->{$k}));
   }
   my $d;
   my @locid=$loc->getIdByHashIOMapped($self->getParent->Self,$newrec,
                                       DEBUG=>\$d,
                                       ForceLikeSearch=>1);

   if ($newrec->{zipcode} ne "" && $#locid==-1){ # try without zipcode
      delete($newrec->{zipcode});
      @locid=$loc->getIdByHashIOMapped($self->getParent->Self,$newrec,
                                       DEBUG=>\$d,
                                       ForceLikeSearch=>1);
   }

   if ($#locid!=-1){
      return(\@locid);
   }
   return(undef);
}




sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my ($flt,$requestToken)=$self->simplifyFilterSet($filterset);
   return(undef) if (!defined($flt));

   my $credentialName=$self->getCredentialName();
   my $Authorization=$self->getITENOSAuthorizationToken($credentialName);

   if ($Authorization eq ""){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"unable to create Authorization token");
      }
      return(undef);
   }

   my @curView=$self->getCurrentView();

   my ($restFinalAddr,$requesttoken,$constParam)=$self->Filter2RestPath(
      "/cmdb/pServer",  # Path-Templ with var
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
      requesttoken=>$requestToken,
      verify_hostname=>0,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl=~s#/$##;
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
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;

         if (ref($data) eq "HASH" &&
             exists($data->{returnData}) &&
             ref($data->{returnData}) eq "ARRAY"){
            my @l;
            foreach my $rec (@{$data->{returnData}}){
               if (in_array(\@curView,[qw(ALL srcrec)])){
                  my $jsonfmt=new JSON();
                  $jsonfmt->property(latin1 => 1);
                  $jsonfmt->property(utf8 => 0);
                  $jsonfmt->pretty(1);
                  my $d=$jsonfmt->encode($rec);
                  $rec->{srcrec}=$d;
               }
               if (in_array(\@curView,[qw(ALL cdate)])){
                  $rec->{cdate}=$rec->{vserverCreationDate};
               }
               $rec->{Location_address1}="";
               $rec->{Location_address1}.=$rec->{pserverStreet};
               if ($rec->{Location_address1} ne ""){
                  if ($rec->{pserverHouseNo} ne ""){
                     $rec->{Location_address1}.=" ".
                              $rec->{pserverHouseNo};
                  }
               }
               $rec->{Location_country}="DE";
               $rec->{Location_zipcode}=$rec->{pserverPostalCode};
               $rec->{Location_location}=$rec->{pserverCity};
               push(@l,$rec);
            }
            return(\@l);
         }
         return(undef);
      }

   );

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


#sub getValidWebFunctions
#{
#   my ($self)=@_;
#   return($self->SUPER::getValidWebFunctions(),
#          qw(ImportSystem));
#}
#
#
#
#sub ImportSystem
#{
#   my $self=shift;
#   my $importname=trim(Query->Param("importname"));
#   if (Query->Param("DOIT")){
#      if ($self->Import({importname=>$importname})){
#         Query->Delete("importname");
#         $self->LastMsg(OK,"system has been successfuly imported");
#      }
#      Query->Delete("DOIT");
#   }
#
#
#   print $self->HttpHeader("text/html");
#   print $self->HtmlHeader(style=>['default.css','work.css',
#                                   'kernel.App.Web.css'],
#                           static=>{importname=>$importname},
#                           body=>1,form=>1,
#                           title=>"TPC System Import");
#   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
#   print $self->HtmlBottom(body=>1,form=>1);
#}
#
#
#sub Import
#{
#   my $self=shift;
#   my $param=shift;
#
#   my $flt;
#   my $importname;
#   my $sysrec;
#
#   my $credentialName=$self->getCredentialName();
#
#   if ($param->{importname} ne ""){
#      my $sysuuid;
#      $importname=$param->{importname};
#      msg(INFO,"start Import in aws::system with importname $importname");
#      if (($sysuuid)=$importname
#              =~m/^(\S+)$/){
#         $flt={
#            id=>$sysuuid
#         };
#      }
#      else{
#         $self->LastMsg(ERROR,"sieht schlecht aus");
#         return(undef);
#      }
#      $self->ResetFilter();
#      $self->SetFilter($flt);
#      my @l=$self->getHashList(qw(id name projectId ipaddresses));
#      if ($#l==-1){
#         if ($self->isDataInputFromUserFrontend()){
#            $self->LastMsg(ERROR,"TPC machine not found");
#         }
#         msg(ERROR,"requested importname $importname can not be resolved");
#         return(undef);
#      }
#    
#      if ($#l>0){
#         if ($self->isDataInputFromUserFrontend()){
#            $self->LastMsg(ERROR,"Systemname '%s' not unique in TPC",
#                                 $param->{importname});
#         }
#         return(undef);
#      }
#      $sysrec=$l[0];
#   }
#   elsif (ref($param->{importrec}) eq "HASH"){
#      $sysrec=$param->{importrec};
#   }
#   else{
#      msg(ERROR,"no importname specified while ".$self->Self." Import call");
#      return(undef);
#   }
#   my $appl=getModuleObject($self->Config,"TS::appl");
#   my $cloudarea=getModuleObject($self->Config,"itil::itcloudarea");
#   my $itcloud=getModuleObject($self->Config,"itil::itcloud");
#
#   my $cloudrec;
#   my $w5carec;
#   {
#      $itcloud->ResetFilter();
#      $itcloud->SetFilter({shortname=>\$credentialName ,cistatusid=>'4'});
#      my ($crec,$msg)=$itcloud->getOnlyFirst(qw(id name fullname cistatusid));
#      if (defined($crec)){
#         $cloudrec=$crec;
#      }
#      else{
#         $self->LastMsg(ERROR,"no active TPC Cloud in inventory");
#         return(undef);
#      }
#   }
#
#   if ($sysrec->{projectId} ne ""){
#      msg(INFO,"try to add CloudArea to system ".$sysrec->{name});
#      $cloudarea->SetFilter({cloudid=>$cloudrec->{id},
#                             srcid=>\$sysrec->{projectId}
#      });
#      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
#      if (defined($w5cloudarearec)){
#         $w5carec=$w5cloudarearec;
#      }
#   }
#
#
#
#
#
#
#   my $syssrcid=$sysrec->{id};
#   my $system=getModuleObject($self->Config,"TS::system");
#
#   if (!defined($w5carec)){
#      my $msg;
#      if (exists($param->{importname})){
#         $msg=$param->{importname};
#      }
#      else{
#         $msg=$param->{importrec}->{id};
#      }
#      if ($self->isDataInputFromUserFrontend()){
#         # if import is from Job (W5Server f.e.) no error on missing
#         # ca rec is needed - ca's are guranted by other processes
#         $self->LastMsg(ERROR,"missing CloudArea for TPC import of '%s'",$msg);
#      }
#      return(undef);
#   }
#
#   my %ipaddresses;
#   foreach my $iprec (@{$sysrec->{ipaddresses}}){
#      $ipaddresses{$iprec->{name}}={
#         name=>$iprec->{name}
#      };
#   }
#
#   my $sysimporttempl={
#      name=>[$sysrec->{name},$sysrec->{genname}],
#      initialname=>$sysrec->{id},
#      id=>$sysrec->{id},
#      srcid=>$sysrec->{id},
#      ipaddresses=>[values(%ipaddresses)]
#   };
#
#   #if ($sysrec->{address} ne ""){
#   #   $sysimporttempl->{ipaddresses}=[{
#   #       name=>$sysrec->{address},
#   #       netareatag=>'CNDTAG'
#   #   }];
#   #}
#
#   if ($sysrec->{projectId} ne ""){
#      msg(INFO,"try to add CloudArea to system ".$sysrec->{name});
#      $cloudarea->SetFilter({cloudid=>$cloudrec->{id},
#                             srcid=>\$sysrec->{projectId}
#      });
#      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
#      if (defined($w5cloudarearec)){
#         $w5carec=$w5cloudarearec;
#      }
#   }
#
#
#   my $ImportRec={
#      cloudrec=>$cloudrec,
#      cloudarearec=>$w5carec,
#      imprec=>$sysimporttempl,
#      srcsys=>$credentialName,
#      checkForSystemExistsFilter=>sub{  # Nachfrage ob Reuse System-Candidat not
#         my $osys=shift;                # exists in srcobj
#         my $srcid=$osys->{srcid};
#         return({id=>\$srcid});
#      }
#   };
#
#   my $ImportObjects={   # Objects are in seperated Structur for better Dumping
#      itcloud=>$itcloud,
#      itcloudarea=>$cloudarea,
#      appl=>$appl,
#      system=>$system,
#      srcobj=>$self
#   };
#
#   #printf STDERR ("ImportRec(imprec):%s\n",Dumper($ImportRec->{imprec}));
#   my $ImportResult=$system->genericSystemImport($ImportObjects,$ImportRec);
#   #printf STDERR ("ImportResult:%s\n",Dumper($ImportResult));
#   if ($ImportResult){
#      return($ImportResult->{IdentifedBy});
#   }
#   return();
#}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default  w5baselocation tags source));
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


sub getPrimaryAssetW5BaseID
{
   my $self=shift;

   my $o=$self->getPersistentModuleObject("ass","itil::asset");

   $o->SetFilter({cistatusid=>[4],kwords=>$self->{ASSETKWORDS}});
   my ($arec)=$o->getOnlyFirst(qw(ALL));
   if (defined($arec)){
      if (wantarray()){
         return($arec->{id},$arec);
      }
      else{
         return($arec->{id});
      }
   }

   return(undef);
}


1;
