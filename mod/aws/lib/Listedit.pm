package aws::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::Static;
use kernel::Field;

use Data::Printer;

use Paws;
use Paws::Credential;
use Paws::Credential::Explicit;
use Paws::Credential::AssumeRole;
use Paws::Net::LWPCaller;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub genericSimpleFilterCheck4AWS
{
   my $self=shift;
   my $filterset=shift;

   if (!ref($filterset) eq "HASH" ||
       keys(%{$filterset})!=1 ||
       !exists($filterset->{FILTER}) ||
       ref($filterset->{FILTER}) ne "ARRAY" ||
       $#{$filterset->{FILTER}}!=0){
      $self->LastMsg(ERROR,"requested filter not supported by REST backend");
      print STDERR Dumper($filterset);
      return(undef);
   }
   return(1);
}

sub checkMinimalFilter4AWS
{
   my $self=shift;
   my $filter=shift;
   my @fields=@_;   # at now only 1 field works

   my $field=$fields[0];

   if (!exists($filter->{$field}) ||
       !($filter->{$field}=~m/^\S{3,20}$/)){
      $self->LastMsg(ERROR,"mandatary filter not specifed");
      print STDERR Dumper($filter);
      return(undef);
   }
   return(1);
}


sub decodeFilter2Query4AWS
{
   my $self=shift;
   my $keyhandling=shift;
   my $filter=shift;

   my $query={};

   foreach my $fn (keys(%$filter)){
      $query->{$fn}=$filter->{$fn};
      if (ref($query->{$fn}) eq "SCALAR"){
         $query->{$fn}=${$query->{$fn}};
      }
      if (ref($query->{$fn}) eq "ARRAY"){
         $query->{$fn}=join(" ",@{$query->{$fn}});
      }
   }

   foreach my $qvar (keys(%$query)){
      if (my ($qvarpref)=$qvar=~m/^(\S*)idpath$/){
         if (exists($query->{$qvarpref.'idpath'})){
            if (my ($id,$accountid,$region)=
                $query->{$qvarpref.'idpath'}
                =~m/^([a-z]{1,6}-[a-z0-9]{15,20})\@([0-9]+)\@(\S+)$/){
               if (exists($query->{$qvarpref.'id'}) && 
                   $query->{$qvarpref.'id'} ne ""  &&
                   $query->{$qvarpref.'id'} ne $id){
                  # query parameters combination can't get a valid result
                  return(undef);
               }
               $query->{$qvarpref.'id'}=$id;
               if (exists($query->{'accountid'}) && 
                   $query->{'accountid'} ne ""  &&
                   $query->{'accountid'} ne $accountid){
                  # query parameters combination can't get a valid result
                  return(undef);
               }
               $query->{'accountid'}=$accountid;
               if (exists($query->{region}) && 
                   $query->{region} ne "" &&
                   $query->{region} ne $region){
                  # query parameters combination can't get a valid result
                  return(undef);
               }
               $query->{region}=$region;
            }
            elsif (my ($type,$region,$accountid,$objectpath)=
                $query->{$qvarpref.'idpath'}
                =~m/^arn:aws:([^:]+):([^:]+):([^:]+):(.+)$/){
               if (exists($query->{$qvarpref.'id'}) && 
                   $query->{$qvarpref.'id'} ne ""  &&
                   $query->{$qvarpref.'id'} ne $query->{$qvarpref.'idpath'}){
                  # query parameters combination can't get a valid result
                  return(undef);
               }
               $query->{$qvarpref.'id'}=$query->{$qvarpref.'idpath'};
               if (exists($query->{'accountid'}) && 
                   $query->{'accountid'} ne ""  &&
                   $query->{'accountid'} ne $accountid){
                  # query parameters combination can't get a valid result
                  return(undef);
               }
               $query->{'accountid'}=$accountid;
               if (exists($query->{region}) && 
                   $query->{region} ne "" &&
                   $query->{region} ne $region){
                  # query parameters combination can't get a valid result
                  return(undef);
               }
               $query->{region}=$region;
            }
            else{
               printf STDERR ("decodeFilter2Query4AWS: invalid idpath ".
                              "$qvar : %s\n",Dumper($query));
               Stacktrace(1);
               return(undef);
            }
         }
      }
   }

   if ($keyhandling eq "Account"){
      if (!exists($query->{accountid}) ||
          (trim($query->{accountid}) eq "")){
         $self->LastMsg(ERROR,
                        'mandatary search parameter missing: %s',"accountid");
         return(undef);
      }
   }
   else{
      if (!exists($query->{accountid}) ||
          !($query->{accountid}=~m/^\d{3,20}$/)){
         $self->LastMsg(ERROR,
                        'mandatary search parameter missing: %s',"accountid");
         printf STDERR ("decodeFilter2Query4AWS: missing accountid:".
                        " %s\n",Dumper($query));
         Stacktrace(1);
         return(undef);
      }
   }
   if ($keyhandling eq "Account"){
      if (!exists($query->{region}) ||
          $query->{region} eq ""){
         $query->{region}="us-east-1";
      }
   }
   else{
      if (!exists($query->{region}) ||
          !($query->{region}=~m/^\S{8,20}$/)){
         $self->LastMsg(ERROR,
                        'mandatary search parameter missing: %s',"region");
         printf STDERR ("decodeFilter2Query4AWS: missing region:".
                        " %s\n",Dumper($query));
         return(undef);
      }
   }

   return($query);
}


sub GetCred4AWS
{
   my $self=shift;
   my $AWSAccount=shift;   # if STS 
   my $AWSRegion=shift;   # if STS 

   my ($awsconnect,$awspass,$awsuser)=$self->GetRESTCredentials("aws");

   my $ua;
   eval('
      use LWP::UserAgent;
      #$ua=new LWP::UserAgent(env_proxy=>0,ssl_opts =>{verify_hostname=>0});
      $ua=new LWP::UserAgent(env_proxy=>0,timeout=>60);
      push(@{$ua->requests_redirectable},"POST");
      push(@{$ua->requests_redirectable},"GET");
   ');
   if ($@ ne ""){
      $self->LastMsg(ERROR,"fail to create UserAgent for DoRESTcall");
      return(undef);
   }
   $ua->protocols_allowed( ['https','connect'] );
   my $probeipproxy=$self->Config->Param("http_proxy");
   if ($probeipproxy ne ""){
      $ua->proxy(['https'],$probeipproxy);
   }
   Paws->default_config->caller(new Paws::Net::LWPCaller(ua=>$ua));
   my $baseCred=Paws::Credential::Explicit->new(
         access_key=>$awsuser,
         secret_key=>$awspass
   );
   if ($AWSAccount eq ""){  # no STS
      #msg(INFO,"return AWS basecred");
      return($baseCred);
   }

   my $stscred=Paws::Credential::AssumeRole->new(
     sts=>Paws->service('STS', credentials=>$baseCred,region=>$AWSRegion),
     Name=>'W5Base',DurationSeconds=>900,
     RoleSessionName => 'SACMConfigAccess',
     RoleArn => 'arn:aws:iam::'.$AWSAccount.':'.$awsconnect
   );
   my $access_key=$stscred->access_key();
   my $secret_key=$stscred->secret_key();
   my $stsBaseCred=Paws::Credential::Explicit->new(
         access_key=>$access_key,
         secret_key=>$secret_key
   );

   return($stscred);

}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



1;
