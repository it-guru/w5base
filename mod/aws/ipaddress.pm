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
                label         =>'AWS-EC2-IdPath'),

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
                name          =>'vpcid',
                label         =>'VpcId'),

      new kernel::Field::Text(
                name          =>'vpcidpath',
                label         =>'VpcId Path'),

      new kernel::Field::Text(
                name          =>'id',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'NetworkInterfaceID'),

      new kernel::Field::Text(
                name          =>'accountid',
                FieldHelpType =>'GenericConstant',
                label         =>'AWS-AccountID'),

      new kernel::Field::Text(
                name          =>'region',
                selectsearch  =>sub{
                   my $self=shift;
                   return("eu-central-1");
                },
                FieldHelpType =>'GenericConstant',
                label         =>'AWS-Region'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name dnsname vpcid));
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

   my $ip=getModuleObject($self->Config,"itil::ipaddress");
   my $subnets=getModuleObject($self->Config,"aws::Subnet");

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
                   accountid=>$AWSAccount,
                   region=>$AWSRegion,
                   idpath=>$instance->{InstanceId}.'@'.
                           $AWSAccount.'@'.
                           $AWSRegion,
               );
               my %ifs;
               my %vpcpath;
               foreach my $if (@{$instance->NetworkInterfaces()}){
                  #p $if;
                  my %ifrec;
                  my @v6=@{$if->Ipv6Addresses()};
                  if ($#v6!=-1){
                     foreach my $v6rec (@v6){
                        my $rec={%rec};
                        my $ipv6=$v6rec->Ipv6Address();
                        $rec->{name}=$ip->Ipv6Expand($ipv6);
                        $rec->{isprimary}=0;
                        $rec->{ifname}=$if->NetworkInterfaceId();
                        $rec->{vpcid}=$if->VpcId();
                        $rec->{vpcidpath}=$rec->{vpcid}.'@'.
                                          $AWSAccount.'@'.
                                          $AWSRegion;
                        $vpcpath{$rec->{vpcidpath}}++;
                        $rec->{mac}=$if->MacAddress();
                        $rec->{netareatag}="ISLAND";
                        push(@result,$rec);
                     }
                  }
                  my @ips;
                  foreach my $iprec (@{$if->PrivateIpAddresses()}){
                     my $rec={%rec};
                     $rec->{name}=$iprec->PrivateIpAddress();
                     $rec->{dnsname}=$iprec->PrivateDnsName();
                     $rec->{isprimary}=0;
                     $rec->{ifname}=$if->NetworkInterfaceId();
                     $rec->{vpcid}=$if->VpcId();
                     $rec->{vpcidpath}=$rec->{vpcid}.'@'.
                                       $AWSAccount.'@'.
                                       $AWSRegion;
                     $vpcpath{$rec->{vpcidpath}}++;
                     $rec->{mac}=$if->MacAddress();
                     #########################################################
                     # netarea tag depend from $rec->{name}
                     $rec->{netareatag}="ISLAND";
                     #########################################################
                     if ($iprec->Primary()){
                        $rec->{isprimary}=1;
                     }
                     push(@result,$rec);
                  }
               }
               if (keys(%vpcpath)){
                  foreach my $vpc (keys(%vpcpath)){
                     my $vo=$self->getPersistentModuleObject("VPC","aws::VPC");
                     $vo->SetFilter({idpath=>$vpc});
                     my ($vpcrec,$msg)=$vo->getOnlyFirst(qw(id subnets));
                     $vpcpath{$vpc}=$vpcrec;
                  }
               }
               foreach my $rec (@result){
                  if ($rec->{vpcidpath} ne "" &&
                      exists($vpcpath{$rec->{vpcidpath}}) &&
                      ref($vpcpath{$rec->{vpcidpath}}) eq "HASH"){
                     foreach my $subnet (
                             @{$vpcpath{$rec->{vpcidpath}}->{subnets}}){
                        if ($ip->isIpInNet($rec->{name},$subnet->{ipnet})){
                           if ($subnet->{netareatag} ne ""){
                              $rec->{netareatag}=$subnet->{netareatag};
                           }
                        }
                     }
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
   return("header","default","ipaddresses","tags", "source");
}


1;
