package azure::ipaddress;
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
      new kernel::Field::Text(     
            name              =>'id',
            group             =>'source',
            label             =>'virtualMachine ResourceID'),

     new kernel::Field::Text(
                name          =>'name',
                label         =>'IP-Address'),

      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>'DNS-Name'),

      new kernel::Field::Text(
                name          =>'mac',
                label         =>'MAC'),

      new kernel::Field::Text(
                name          =>'ifname',
                htmlwidth     =>'250px',
                label         =>'System Interface'),

      new kernel::Field::Boolean(
                name          =>'isprimary',
                label         =>'is primary'),

      new kernel::Field::Text(
                name          =>'netareatag',
                label         =>'NetArea Tag'),
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
   my $Authorization=$self->getAzureAuthorizationToken();

   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4azure(
      "subscriptions/{subscriptionId}/providers/Microsoft.Compute/".
      "virtualMachines","id",
      $filterset,
      {
         'api-version'=>'2021-03-01'
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
         my @subrec;
         foreach my $rawrec (@$data){
            my $machineId=azure::lib::Listedit::AzID2W5BaseID($rawrec->{id});
            if (ref($rawrec->{'properties'}) eq "HASH" &&
                ref($rawrec->{'properties'}
                           ->{'networkProfile'}) eq "HASH" &&
                ref($rawrec->{'properties'}
                           ->{'networkProfile'}
                           ->{'networkInterfaces'}) eq "ARRAY"){
               foreach my $ifrec (@{$rawrec->{'properties'}
                                           ->{'networkProfile'}
                                           ->{'networkInterfaces'}}){
                  my $id=$ifrec->{id};
                  if ($id ne ""){
                     $id=$self->AzureBase().$id."?api-version=2021-02-01";
                     my $rawifrec=$self->genReadAzureId($Authorization,$id);
                     #printf STDERR ("rawifrec=%s\n",Dumper($rawifrec));
                     my $tags=$rawifrec->{tags};
                     my $prop=$rawifrec->{properties};
                     my $ips=$prop->{ipConfigurations};
                     foreach my $rawip (@$ips){
                        my $mac=$prop->{macAddress};
                        $mac=~s/-/:/g;
                        my $ifname=$rawip->{etag};
                        $ifname=~s/[^a-z0-9-]//g;
                        my $ipprop=$rawip->{properties};
                        my $iprec={
                           id=>$machineId,
                           mac=>$mac,
                           ifname=>$ifname,
                           netareatag=>"ISLAND",
                           name=>$ipprop->{privateIPAddress},
                        };
                        if (exists($tags->{w5base_cndtag_ip_prefix}) &&
                            $tags->{w5base_cndtag_ip_prefix} ne ""){
                           $iprec->{netareatag}="CNDTAG";
                        }
                        push(@subrec,$iprec);
                        if (exists($ipprop->{publicIPAddress}) &&
                            ref($ipprop->{publicIPAddress}) eq "HASH"){
                           my $PubIPid=$ipprop->{publicIPAddress}->{id};
                           my $idref=$self->AzureBase().$PubIPid.
                                     "?api-version=2021-02-01";
                           my $pi=$self->genReadAzureId($Authorization,$idref);
                           if (defined($pi)){
                              my $ip=$pi->{properties}->{ipAddress};
                              if ($ip ne ""){
                                  my $iprec={
                                     id=>$machineId,
                                     mac=>$mac,
                                     ifname=>$ifname,
                                     netareatag=>"INTERNET",
                                     name=>$ip
                                  };
                                  push(@subrec,$iprec);
                              }
                           }
                        }
                     }
                  }

               }
            }
         }
         return(\@subrec);
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
         $self->LastMsg(ERROR,"unexpected data Azure virtualMachine response");
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


1;


