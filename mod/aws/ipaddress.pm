package aws::ipaddress;
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
use Try::Tiny;
use Paws::Exception;
use Scalar::Util(qw(blessed));

@ISA=qw(aws::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'idpath',
                group         =>'source',
                label         =>'AWS-IdPath'),

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
                label         =>'System Interface'),

      new kernel::Field::Boolean(
                name          =>'isprimary',
                label         =>'is primary'),

      new kernel::Field::Text(
                name          =>'netareatag',
                label         =>'NetArea Tag'),

      new kernel::Field::Text(
                name          =>'id',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'EC2-InstanceID'),

      new kernel::Field::Link(
                name          =>'accountid',
                label         =>'AWS-AccountID'),

      new kernel::Field::Link(
                name          =>'region',
                label         =>'AWS-Region'),


   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name dnsname));
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

   my $query=$self->decodeFilter2Query4AWS("EC2.instanceid",$filter);
   if (!defined($query)){
      return(undef) if ($self->LastMsg());
      return([]);
   }
   my $AWSAccount=$query->{accountid};
   my $AWSRegion=$query->{region};

   my @errStack;
   try {
      my $stscred=$self->GetCred4AWS($AWSAccount,$AWSRegion);
      my $ec2=Paws->service('EC2',credentials=>$stscred,region =>$AWSRegion);
      my %param=();
      if (exists($query->{id}) && $query->{id} ne ""){
         $param{InstanceIds}=[$query->{id}];
      }
      my $InstanceItr=$ec2->DescribeInstances(%param);
      if ($InstanceItr){
         foreach my $res (@{$InstanceItr->Reservations()}){
            foreach my $instance (@{$res->Instances}){
               #p $instance;
               my %rec=(
                   id=>$instance->{InstanceId},
                   region=>$AWSRegion,
                   idpath=>$instance->{InstanceId}.'@'.
                           $AWSAccount.'@'.
                           $AWSRegion,
               );
               my %ifs;
               foreach my $if (@{$instance->NetworkInterfaces()}){
                  #p $if;
                  my %ifrec;
                  my @v6=@{$if->Ipv6Addresses()};
                  if ($#v6!=-1){
                     msg(WARN,
                       "ipv6 handling not yet implemented in aws::ipaddress");
                  }
                  my @ips;
                  foreach my $iprec (@{$if->PrivateIpAddresses()}){
                     my $rec={%rec};
                     $rec->{name}=$iprec->PrivateIpAddress();
                     $rec->{dnsname}=$iprec->PrivateDnsName();
                     $rec->{isprimary}=0;
                     $rec->{ifname}=$if->NetworkInterfaceId();
                     $rec->{mac}=$if->MacAddress();
                     $rec->{netareatag}="ISLAND";
                     if (($rec->{name}=~m/^100\./)||
                         ($rec->{name}=~m/^172\./)){
                        $rec->{netareatag}="AWSINTERN";
                     }
                     if ($iprec->Primary()){
                        $rec->{isprimary}=1;
                     }
                     push(@result,$rec);
                  }
               }
               my $publicip=$instance->PublicIpAddress();
               if ($publicip ne ""){
                  my $rec={%rec};
                  $rec->{name}=$publicip;
                  $rec->{dnsname}=$instance->PublicDnsName();
                  $rec->{isprimary}=0;
                  $rec->{netareatag}="INTERNET";
                  push(@result,$rec);
               }
            }
         }
      }
   }
   catch {
      my $eclass=blessed($_);
      if ($eclass eq "Paws::Exception"){
         push(@errStack,"(".$_->code.") :".$_->message);
      }
      else{
         push(@errStack,$_);
      }
   };
   if ($#errStack!=-1){
      $self->LastMsg(ERROR,@errStack);
      return(undef);
   }
   return(\@result);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","ipaddresses","tags",
          "source");
}


1;
