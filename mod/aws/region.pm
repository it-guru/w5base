package aws::region;
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
use kernel::Field;
use kernel::cgi;
use aws::lib::Listedit;
use Data::Printer;
@ISA=qw(aws::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(       name       =>'id',
                                   htmlwidth  =>'150',
                                   label      =>'RegionName'),
      new kernel::Field::Text(    name       =>'endpoint',
                                  label      =>'EndPoint'),
      new kernel::Field::Text(    name       =>'accountid',
                                  label      =>'AWS-AccountID'),
      new kernel::Field::Text(    name       =>'region',
                                  label      =>'AWS-Region'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id endpoint));
   return($self);
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my @view=$self->GetCurrentView();


   my @result;

   return(undef) if (!$self->genericSimpleFilterCheck4AWS($filterset));
   my $filter=$filterset->{FILTER}->[0];

   my $query=$self->decodeFilter2Query4AWS($filter);
   if (exists($query->{idpath})){
      if (my ($id,$accountid,$region)=
          $query->{idpath}=~m/^(i-\S+)\@([0-9]+)\@(\S+)$/){
         if (exists($query->{id}) && 
             $query->{id} ne ""  &&
             $query->{id} ne $id){
            return([]);
         }
         $query->{id}=$id;
         if (exists($query->{accountid}) && 
             $query->{accountid} ne ""  &&
             $query->{accountid} ne $accountid){
            return([]);
         }
         $query->{accountid}=$accountid;
         if (exists($query->{region}) && 
             $query->{region} ne "" &&
             $query->{region} ne $region){
            return([]);
         }
         $query->{region}=$region;
      }
      else{
         return([]);
      }
   }


   if (!exists($query->{accountid}) ||
       !($query->{accountid}=~m/^\d{3,20}$/)){
      $self->LastMsg(ERROR,"mandatary accountid filter not specifed");
      #print STDERR Dumper($query);
      return(undef);
   }
   if (!exists($query->{region}) ||
       !($query->{region}=~m/^\S{3,20}$/)){
      $self->LastMsg(ERROR,"mandatary region filter not specifed");
      #print STDERR Dumper($query);
      return(undef);
   }
   my $AWSAccount=$query->{accountid};
   my $AWSRegion=$query->{region};

   my ($awsconnect,$awspass,$awsuser)=$self->GetRESTCredentials("aws");


   my $ua;
   eval('
      use LWP::UserAgent;
      #$ua=new LWP::UserAgent(env_proxy=>0,ssl_opts =>{verify_hostname=>0});
      $ua=new LWP::UserAgent(env_proxy=>0,timeout=>60);
      push(@{$ua->requests_redirectable},"POST");
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

   my $stscred=Paws::Credential::AssumeRole->new(
     sts=>Paws->service('STS', credentials=>$baseCred,region=>$AWSRegion),
     Name=>'W5Base',DurationSeconds=>900,
     RoleSessionName => 'SACMConfigAccess',
     RoleArn => 'arn:aws:iam::'.$AWSAccount.':'.$awsconnect
   );

   my $ec2=Paws->service('EC2',credentials=>$stscred,region =>$AWSRegion);
   my $blk=0;
   my $NextToken;
   my $RegionsItr=$ec2->DescribeRegions();
   foreach my $region (@{$RegionsItr->Regions()}){
      my %rec=(
         id=>$region->RegionName(),
         accountid=>$AWSAccount,
         region=>$AWSRegion,
         endpoint=>$region->Endpoint()
      );
      push(@result,\%rec);
   }


   return(\@result);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_accountid"))){
     Query->Param("search_accountid"=>'238834862221');
   }
   if (!defined(Query->Param("search_region"))){
     Query->Param("search_region"=>'eu-central-1');
   }
}





1;
