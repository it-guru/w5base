package azure::subscription;
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
use kernel::cgi;
use kernel::Field;
use azure::lib::Listedit;
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

      new kernel::Field::Text(     
            name              =>'subscriptionId',
            group             =>'source',
            htmldetail        =>'NotEmpty',
            dataobjattr       =>'subscriptionId',
            label             =>'SubscriptionID'),

      new kernel::Field::Linenumber(
            name              =>'linenumber',
            label             =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'name',
            ignorecase        =>1,
            dataobjattr       =>'displayName',
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'state',
            ignorecase        =>1,
            dataobjattr       =>'state',
            label             =>'State'),

      new kernel::Field::TextDrop(
            name              =>'appl',
            searchable        =>0,
            vjointo           =>'itil::appl',
            vjoinon           =>['w5baseid'=>'id'],
            searchable        =>0,
            vjoindisp         =>'name',
            label             =>'W5Base Application'),

      new kernel::Field::Interface(     
            name              =>'w5baseid',
            container         =>'tags',
            label             =>'Application W5BaseID'),

      new kernel::Field::Interface(     
            name              =>'requestor',
            container         =>'tags',
            label             =>'Requestor'),

      new kernel::Field::SubList(
                name          =>'virtualmachines',
                label         =>'virtual Machines',
                group         =>'virtualmachines',
                searchable    =>0,
                vjointo       =>'azure::virtualMachine',
                vjoinon       =>['subscriptionId'=>'subscriptionId'],
                vjoindisp     =>['name']),

      new kernel::Field::Container(
            name              =>'tags',
            group             =>'tags',
            searchable        =>0,
            uivisible         =>1,
            onRawValue        =>sub{
               my $self=shift;
               my $current=shift;
               my $subscriptionid=$current->{id};
               return({}) if ($subscriptionid eq "");
               my $subrequest=$self->getParent->DataCollector({
                  filter=>[{id=>\$subscriptionid}]
               });
               if (defined($subrequest) && ref($subrequest) eq "ARRAY" &&
                   $#{$subrequest}==0){
                  return($subrequest->[0]->{tags});
               }
               return({});
            },
            label             =>'Tags'),

      new kernel::Field::Text(     
            name              =>'tenantid',
            ignorecase        =>1,
            group             =>'source',
            dataobjattr       =>'tenantId',
            label             =>'TenantId'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name appl));
   return($self);
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my @view=$self->GetCurrentView();
   #printf STDERR ("view=%s\n",Dumper(\@view));

   my $Authorization=$self->getAzureAuthorizationToken();

   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4azure(
      "subscriptions","id",
      $filterset,{
      }
   );
   my $d=$self->CollectREST(
      dbname=>'AZURE',
      requesttoken=>$requesttoken,
      useproxy=>1,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $base=shift;
      
         my $dataobjurl="https://management.azure.com/";
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
            my $rec;
            foreach my $v (qw(id displayName subscriptionId tenantId tags
                              state)){
               if (exists($rawrec->{$v})){
                  $rec->{$v}=$rawrec->{$v};
                  if ($v eq "id"){
                     $rec->{$v}=azure::lib::Listedit::AzID2W5BaseID($rec->{$v});
                  }
               }
            }
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
            msg(ERROR,"got http 404 on azure::subscription call");
            return([],"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data Azure subscription response");
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

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default virtualmachines tags source));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/itcloudarea.jpg?".$cgi->query_string());
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

   my $userid=$self->getCurrentUserId();
   my $subscriptionId=$q->{subscriptionId}; 
   my $action=$q->{action};

   if ($subscriptionId ne "" && (
        ($action=~m/\/virtualMachines\/write/i) ||
        ($action=~m/\/virtualMachines\/delete/i)
       )){
      my $ca=$self->getPersistentModuleObject("_CloudA","itil::itcloudarea");
      $ca->SetFilter({srcsys=>\'AZURE',
                      srcid=>\$subscriptionId,
                      cistatusid=>'4'});
      my ($carec,$msg)=$ca->getOnlyFirst(qw(ALL));
      if (defined($carec)){
         msg(INFO,"AZURE TriggerEndpoint:".Dumper($q));


         my %p=(eventname=>'AZURE_QualityCheck',
                spooltag=>'AZURE_QualityCheck-'.$carec->{id},
                redefine=>'1',
                retryinterval=>310,
                firstcalldelay=>290+300,
                maxretry=>13,
                eventparam=>$carec->{id},
                userid=>$userid);
         my $res;
         if (defined($res=$self->W5ServerCall("rpcCallSpooledEvent",%p)) &&
            $res->{exitcode}==0){
            msg(INFO,"AZURE_QualityCheck ------------------------------");
            msg(INFO,"AZURE_QualityCheck action=".$action);
            msg(INFO,"AZURE_QualityCheck resourceId=".$q->{resourceId});
            msg(INFO,"AZURE_QualityCheck Event for $subscriptionId sent OK");
            msg(INFO,"AZURE_QualityCheck ------------------------------");
         }
         else{
            msg(ERROR,"AZURE_QualityCheck Event sent failed");
         }
         return(0);
      }
      else{
         msg(ERROR,"azure::TriggerEndpoint - no active CloudArea for ".
                   "$subscriptionId");
         return(0);
      }
   }
   if ($action=~m/\/Microsoft.DBforPostgreSQL\//){
      # ignore this action
      return(0);
   }
   printf STDERR ("got not processed AZURE Trigger:%s\n",$d);
   return(0);
}


sub loadSkusTable
{
   my $self=shift;
   my $subscriptionId=shift;

   my $Authorization=$self->getAzureAuthorizationToken();

   my $d=$self->CollectREST(
      dbname=>'AZURE',
      useproxy=>1,
      requesttoken=>"t=".time(),
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $base=shift;
      
         my $dataobjurl="https://management.azure.com/";
         $dataobjurl.="subscriptions/".$subscriptionId."/providers/".
                      "Microsoft.Compute/skus?api-version=2019-04-01";
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
         return($data);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data Azure subscription response");
         return(undef);
      }
   );

   return($d);
}


sub createNewSecret
{
   my $self=shift;

   my $Authorization=$self->getAzureAuthorizationToken({
      resource=>'https://app-regeneratesptoken-telit.azurewebsites.net'
   });
   if ($Authorization ne ""){
      my $d=$self->CollectREST(
         dbname=>'AZURE',
         useproxy=>1,
         requesttoken=>"azureAccessSecret=".time(),
         method=>'GET',
         url=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $base=shift;
         
            my $apiurl="https://app-regeneratesptoken-telit.azurewebsites.net".
                       "/api/RegenerateSPToken";

            my $q=kernel::cgi::Hash2QueryString({
               'clearall'=>'false'
            });
            $apiurl.="?".$q;

            return($apiurl);
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
            return($data);
         },
         onfail=>sub{
            my $self=shift;
            my $code=shift;
            my $statusline=shift;
            my $content=shift;
            my $reqtrace=shift;
    
            msg(ERROR,$reqtrace);
            $self->LastMsg(ERROR,"unexpected data Azure subscription response");
            return(undef);
         }
      );
      if (ref($d) eq "HASH" &&
          exists($d->{secret})){
         return($d->{secret});
      }
      else{
         msg(ERROR,"fail: ".Dumper($d));
      }
   }
   return(undef);
}


1;


