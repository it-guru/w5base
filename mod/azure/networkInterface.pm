package azure::networkInterface;
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



#      new kernel::Field::TextDrop(
#            name              =>'appl',
#            searchable        =>0,
#            vjointo           =>'itil::appl',
#            vjoinon           =>['w5baseid'=>'id'],
#            searchable        =>0,
#            vjoindisp         =>'name',
#            label             =>'W5Base Application'),
#
#      new kernel::Field::Interface(     
#            name              =>'w5baseid',
#            container         =>'tags',
#            label             =>'Application W5BaseID'),
#
      new kernel::Field::Container(
            name              =>'tags',
            group             =>'tags',
            searchable        =>0,
            uivisible         =>1,
            label             =>'Tags'),

      new kernel::Field::Text(     
            name              =>'resourceGroup',
            ignorecase        =>1,
            group             =>'source',
            label             =>'ResourceGroup'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name));
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
      "subscriptions/{subscriptionId}/providers/Microsoft.Compute/".
      "networkInterfaces","id",
      $filterset,
      {
         'api-version'=>'2021-02-01'
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
         #printf STDERR ("dataobjurl=$dataobjurl\n");
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
            foreach my $v (qw(name id location zones tags type)){
               if (exists($rawrec->{$v})){
                  $rec->{$v}=$rawrec->{$v};
               }
               if ($v eq "id"){
                  $rec->{$v}=azure::lib::Listedit::AzID2W5BaseID($rec->{$v});
               }

            }
            if (my (@idpath)=split(/\|-/,$rec->{id})){
               $rec->{subscriptionId}=$idpath[1];
               $rec->{resourceGroup}=$idpath[3];
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
         $self->LastMsg(ERROR,"unexpected data Azure networkInterface response");
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
   return(qw(header default machines tags source));
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



1;


