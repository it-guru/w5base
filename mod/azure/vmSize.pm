package azure::vmSize;
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
use azure::lib::Listedit;
use UUID::Tiny;
use JSON;
@ISA=qw(azure::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(     
            name              =>'id',
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'ResourceID'),

      new kernel::Field::Linenumber(
            name              =>'linenumber',
            label             =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'name',
            ignorecase        =>1,
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'subscriptionId',
            weblinkto         =>'azure::subscription',
            weblinkon         =>['subscriptionId'=>'subscriptionId'],
            label             =>'SubscriptionID'),

      new kernel::Field::Number(
                name          =>'cpucount',
                editrange     =>[1,4096],
                label         =>'CPU-Count'),

      new kernel::Field::Number(
                name          =>'memory',
                label         =>'Memory',
                unit          =>'MB',
                editrange     =>[1,2147483647]),

      new kernel::Field::Text(     
            name              =>'vmId',
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'vmId'),

#      new kernel::Field::Text(     
#            name              =>'resourceGroup',
#            ignorecase        =>1,
#            group             =>'source',
#            label             =>'ResourceGroup'),
#
#      new kernel::Field::Textarea(     
#            name              =>'rawrec',
#            group             =>'source',
#            htmlheight        =>'400',
#            htmldetail        =>sub{
#               my $self=shift;
#               my $app=$self->getParent();
#               return(1) if ($app->IsMemberOf("admin"));
#               return(0);
#            },
#            label             =>'RawRecord')
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(name memory cpucount));
   return($self);
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;
   my $subscriptionId;

   my @view=$self->GetCurrentView();
   #printf STDERR ("view=%s\n",Dumper(\@view));

   my $Authorization=$self->getAzureAuthorizationToken();
   

   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4azure(
      "subscriptions/{subscriptionId}/providers/Microsoft.Compute/".
      "locations/westeurope/".
      "vmSizes","id",
      $filterset,
      {
         'api-version'=>'2021-11-01'
      }
   );
   ($subscriptionId)=$dbclass=~m#subscriptions/([^/]+)/#;

   my $d=$self->CollectREST(
      dbname=>'AZURE',
      requesttoken=>$requesttoken,
      useproxy=>1,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $base=shift;
      
         my $dataobjurl=$self->AzureBase()."/";
         $dataobjurl.=$dbclass;
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
         if (ref($data) eq "HASH" && exists($data->{value})){
            $data=$data->{value};
         }
         if (ref($data) ne "ARRAY"){
            $data=[$data];
         }
         my @data;
         foreach my $rawrec (@$data){
            my $rec={};
            $rec->{id}=$rawrec->{name};
            $rec->{name}=$rawrec->{name};
            ($rec->{subscriptionId})=$subscriptionId;
            $rec->{cpucount}=$rawrec->{numberOfCores};
            $rec->{memory}=$rawrec->{memoryInMB};
            push(@data,$rec);
         }
         return(\@data);
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
         if ($code eq "400"){
            my $json=eval('decode_json($content);');
            if ($@ eq "" && ref($json) eq "HASH" &&
                $json->{error}->{message} ne ""){
               $self->LastMsg(ERROR,$json->{error}->{message});
               return(undef);
            }
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data AZURE vmSizes response");
         return(undef);
      }
   );

   return($d);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_subscriptionId"))){
     Query->Param("search_subscriptionId"=>
                  '2154c4f5-9af8-4e0f-9ee9-6782b9e3bf52');
   }
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

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default ipaddresses tags source));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(TriggerEndpoint),$self->SUPER::getValidWebFunctions());
}

#
# Endpoint URL to handle Trigger Events from Azure Cloud
#

sub TriggerEndpoint
{
   my $self=shift;
   my %param;

   $param{charset}="UTF8";

   my $q=Query->MultiVars();

   delete($q->{MOD});
   delete($q->{FUNC});
   print $self->HttpHeader("application/javascript",%param);

   my $json=new JSON;
   $json->utf8(1);

   my $d=$json->pretty->encode({
      request=>$q,
      handler=>$self->Self,
      exitcode=>0,
      ptimestamp=>NowStamp(),
      exitmsg=>'OK'
   });
   print $d;
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
      $importname=azure::lib::Listedit::AzID2W5BaseID($importname);
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
                           title=>"AZURE System Import");
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
   if ($param->{importname} ne ""){
      $importname=$param->{importname};
      $importname=~s/\s//i; # prevent wildcard and or filters
      if ($importname ne ""){
         $flt={id=>$importname};
      }
      else{
         return(undef);
      }
      ########################################################################
      # Detect System Record from Remote System
      ########################################################################
      $self->ResetFilter();
      $self->SetFilter($flt);
      my @l=$self->getHashList(qw(name 
                                  id zone vmId
                                  subscriptionId ipaddresses));
      if ($#l==-1){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"Systemname not found in AZURE");
         }
         return(undef);
      }
      if ($#l>0){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"Systemname '%s' not unique in AZURE",
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

   my $system=getModuleObject($self->Config,"TS::system");

   ########################################################################
   # Detect Cloud Record
   ########################################################################
   my $itcloud=getModuleObject($self->Config,"itil::itcloud");
   my $cloudrec;
   {
      $itcloud->ResetFilter();
      $itcloud->SetFilter({name=>'AZURE_DTIT',cistatusid=>'4'});
      my ($crec,$msg)=$itcloud->getOnlyFirst(qw(ALL));
      if (defined($crec)){
         $cloudrec=$crec;
      }
   }


   my %ipaddresses;
   foreach my $iprec (@{$sysrec->{ipaddresses}}){
      $ipaddresses{$iprec->{name}}={
         name=>$iprec->{name}
      };
   }

   # sysimporttempl is needed for 1st generic insert an refind a redeployment
   my $sysimporttempl={
      name=>$sysrec->{name},
      initialname=>$sysrec->{vmId},
      altname=>$sysrec->{vmId},
      id=>$sysrec->{id},
      srcid=>$sysrec->{id},
      ipaddresses=>[values(%ipaddresses)]
   };


   my $w5carec;

   ########################################################################
   # Detect CloudArea Record and Appl-Record
   ########################################################################
   my $appl=getModuleObject($self->Config,"TS::appl");
   my $cloudarea=getModuleObject($self->Config,"itil::itcloudarea");
   if ($sysrec->{subscriptionId} ne ""){
      $cloudarea->SetFilter({srcsys=>\'AZURE',
                             srcid=>\$sysrec->{subscriptionId}
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
      srcsys=>'AZURE',
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
      $ImportResult->{IdentifedBy};
   }
   return();
}


1;


