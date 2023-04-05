package neo::ipaddressAnalyse;
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
use neo::lib::Listedit;
use JSON;
@ISA=qw(neo::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(     
            name              =>'id',
            searchable        =>0,
            group             =>'source',
            label             =>'Id'),

      new kernel::Field::Text(     
            name              =>'cidr',
            dataobjattr       =>'cidr',
            ignorecase        =>1,
            label             =>'IP-Address'),

      new kernel::Field::Text(     
            name              =>'customer',
            dataobjattr       =>'customer.name',
            ignorecase        =>1,
            label             =>'Customer'),

      new kernel::Field::Text(     
            name              =>'network_cidr',
            dataobjattr       =>'network.cidr',
            group             =>'network',
            ignorecase        =>1,
            label             =>'Network CIDR'),

      new kernel::Field::Text(     
            name              =>'network_contact',
            dataobjattr       =>'network.responsibleContact',
            group             =>'network',
            ignorecase        =>1,
            label             =>'Network Contact'),

      new kernel::Field::Text(     
            name              =>'network_contact2',
            dataobjattr       =>'network.responsibleContact2',
            group             =>'network',
            ignorecase        =>1,
            label             =>'Network Contact2'),

      new kernel::Field::Text(     
            name              =>'network_comment',
            dataobjattr       =>'network.comment',
            group             =>'network',
            ignorecase        =>1,
            label             =>'Network Comment'),

      new kernel::Field::Text(     
            name              =>'subnet_cidr',
            dataobjattr       =>'subnet.cidr',
            group             =>'subnet',
            ignorecase        =>1,
            label             =>'SubNet CIDR'),

      new kernel::Field::Text(     
            name              =>'subnet_contact',
            dataobjattr       =>'subnet.responsibleContact',
            group             =>'subnet',
            ignorecase        =>1,
            label             =>'SubNet Contact'),

      new kernel::Field::Text(     
            name              =>'subnet_contact2',
            dataobjattr       =>'subnet.responsibleContact2',
            group             =>'subnet',
            ignorecase        =>1,
            label             =>'SubNet Contact2'),

      new kernel::Field::Text(     
            name              =>'subnet_comment',
            dataobjattr       =>'subnet.comment',
            group             =>'subnet',
            ignorecase        =>1,
            label             =>'SubNet Comment'),

      new kernel::Field::Text(     
            name              =>'vlan_id',
            dataobjattr       =>'vlan.vlanId',
            group             =>'vlan',
            ignorecase        =>1,
            label             =>'VLAN ID'),

      new kernel::Field::Text(     
            name              =>'vlan_contact',
            dataobjattr       =>'vlan.vlanDomain.contact',
            group             =>'vlan',
            ignorecase        =>1,
            label             =>'VLAN Contact'),

      new kernel::Field::Text(     
            name              =>'vlan_comment',
            dataobjattr       =>'vlan.comment',
            group             =>'vlan',
            ignorecase        =>1,
            label             =>'VLAN Comment'),

      new kernel::Field::Boolean(     
            name              =>'isdhcp',
            group             =>'source',
            dataobjattr       =>'dhcpRange',
            label             =>'DHCP Range'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(cidr customer network_cidr subnet_cidr));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("NEO");
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cidr"))){
     Query->Param("search_cidr"=>'10.161.62.20');
   }
   if (!defined(Query->Param("search_customer"))){
     Query->Param("search_customer"=>'CN-DTAG');
   }
}



sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();
   my $Authorization=$self->getTardisAuthorizationToken($credentialName);
   return(undef) if (!defined($Authorization));

   my ($dbclass,$requesttoken,$const)=$self->decodeFilter2Query4neo(
      "neo/security/ipaddress","none",{'id'=>['cidr','customer.name']},
      $filterset
   );


   return(undef) if (!defined($dbclass));

   my $requesttoken="SEARCH.".time();
   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl.$dbclass;
         if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
            msg(INFO,"Call:".$dataobjurl);
         }
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
         if (ref($data) eq "HASH"){
            foreach my $k (keys(%$const)){
              if (!exists($data->{$k})){
                 $data->{$k}=$const->{$k};
              }
            }
            $data=[FlattenHash($data)];
         }

         return($data);
      },
      onfail=>\&neo::lib::Listedit::onFailNeoHandler
   );
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      msg(INFO,"Call-Result:".Dumper($d));
   }

   return($d);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default network subnet vlan source));
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


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/ipaddress.jpg?".$cgi->query_string());
}


1;
