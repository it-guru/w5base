package aws::NetworkInterface;
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

      new kernel::Field::Id(
                name          =>'idpath',
                htmlwidth     =>'150',
                searchable    =>0,
                FieldHelpType =>'GenericConstant',
                group         =>'source',
                label         =>'AWS-IdPath'),

      new kernel::Field::Text(
                name          =>'id',
                htmlwidth     =>'150',
                label         =>'NetworkInterfaceId'),

      new kernel::Field::Text(
                name          =>'mac',
                label         =>'MAC-Address'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description'),

      new kernel::Field::Objects(
                name          =>'ipadresses',
                uivisible     =>1,
                label         =>'IP-Adresses'),

      new kernel::Field::Boolean(
                name          =>'isremote',
                label         =>'is remote interface'),

      new kernel::Field::Text(
                name          =>'eniownerid',
                FieldHelpType =>'GenericConstant',
                label         =>'ENI OwnerID'),

      new kernel::Field::Text(
                name          =>'accountid',
                FieldHelpType =>'GenericConstant',
                label         =>'AWS-AccountID'),

      new kernel::Field::Text(
                name          =>'vpcid',
                weblinkto     =>'aws::VPC',
                weblinkon     =>['vpcidpath'=>'idpath'],
                label         =>'VpcId'),

      new kernel::Field::Text(
                name          =>'vpcidpath',
                label         =>'VpcId Path'),

      new kernel::Field::Text(
                name          =>'region',
                selectsearch  =>sub{
                   my $self=shift;
                   return("eu-central-1");
                },
                FieldHelpType =>'GenericConstant',
                label         =>'AWS-Region'),

     # new kernel::Field::Container(
     #           name          =>'tags',
     #           searchable    =>0,
     #           group         =>'tags',
     #           uivisible     =>1,
     #           label         =>'Tags'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id description ipadresses));
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

   my $ip=getModuleObject($self->Config,"itil::ipaddress");

   my $query=$self->decodeFilter2Query4AWS("NetworkInterface",$filter);
   if (!defined($query)){
      return(undef) if ($self->LastMsg());
      return([]);
   }
   my $AWSAccount=$query->{accountid};
   my $AWSRegion=$query->{region};

   my @errStack;
   my $cnt=0;
   try {
      my ($stscred,$ua)=$self->GetCred4AWS($AWSAccount,$AWSRegion);
      my $obj=Paws->service('EC2',
            credentials=>$stscred,
            region =>$AWSRegion
      );
      my $blk=0;
      my $NextToken;
      my %vpcpath;
      do{
         my %param=();
         if ($NextToken ne ""){
            $param{NextToken}=$NextToken;
         }
         if (exists($query->{id}) && $query->{id} ne ""){
            $param{NetworkInterfaceIds }=[$query->{id}];
         }
         else{
            $param{MaxResults}=100;
            if (exists($filter->{isremote}) &&
                ($filter->{isremote} eq "0" ||
                (ref($filter->{isremote}) eq "ARRAY" &&
                 in_array("0",$filter->{isremote})) ||
                (ref($filter->{isremote}) eq "SCALAR" &&
                 ${$filter->{isremote}} eq "0"))){
               $param{'Filters'}=[
                  {
                     Name=>'owner-id',
                     Values=>[$AWSAccount]
                  }
               ];
            }
         }
         my $objItr=$obj->DescribeNetworkInterfaces(%param);
         #p $objItr;
         if ($objItr){
            $NextToken=$objItr->NextToken();
            my $netIfs=$objItr->NetworkInterfaces();
            if ($netIfs){
              # p $netIfs;
               foreach my $netIf (@$netIfs){
                  my %tag;
                  my $rec={
                      id=>$netIf->{NetworkInterfaceId},
                      accountid=>$AWSAccount,
                      region=>$AWSRegion,
                      name=>$netIf->PrivateDnsName(),
                      eniownerid=>$netIf->OwnerId(),
                      description=>$netIf->Description(),
                      mac=>$netIf->MacAddress(),
                      idpath=>$netIf->{NetworkInterfaceId}.'@'.
                              $AWSAccount.'@'.
                              $AWSRegion,
                  };
                  if ($rec->{accountid} ne $rec->{eniownerid}){
                     $rec->{isremote}="1";
                  }
                  else{
                     $rec->{isremote}="0";
                  }
                  $rec->{vpcid}=$netIf->VpcId();
                  $rec->{vpcidpath}=$rec->{vpcid}.'@'.
                                    $AWSAccount.'@'.
                                    $AWSRegion;
                  if (!exists($vpcpath{$rec->{vpcidpath}})){
                     $vpcpath{$rec->{vpcidpath}}++;
                  }

                  my @ip;
                  foreach my $ip4rec (@{$netIf->PrivateIpAddresses()}){
                     my $iprec={
                        name=>$ip4rec->PrivateIpAddress(),
                        isprimary=>$ip4rec->Primary(),
                        dnsname=>$ip4rec->PrivateDnsName(),
                        isipv4=>1,
                        netareatag=>"ISLAND"
                     };
                     push(@ip,$iprec);
                  }
                  my $asso=$netIf->Association();
                  if (defined($asso)){
                     my $iprec={
                        name=>$asso->PublicIp(),
                        isprimary=>0,
                        dnsname=>$asso->PublicDnsName(),
                        isipv4=>1,
                        netareatag=>"INTERNET"
                     };
                     push(@ip,$iprec);

                  }
                  foreach my $ip6rec (@{$netIf->Ipv6Addresses()}){
                     my $ipv6=$ip6rec->Ipv6Address();
                     my $iprec={
                        name=>$ip->Ipv6Expand($ipv6),
                        isprimary=>0,
                        isipv6=>1,
                        netareatag=>"ISLAND"
                     };
                     push(@ip,$iprec);
                    # p $ip6rec;
                  }
                  $rec->{ipadresses}=\@ip;
                  push(@result,$rec);
               }
            }
         }
         $blk++;
      }while($NextToken ne "");

      if (keys(%vpcpath)){
         foreach my $vpc (keys(%vpcpath)){
            my $vo=$self->getPersistentModuleObject("VPC",
                                                    "aws::VPC");
            $vo->SetFilter({idpath=>$vpc});
            my ($vpcrec,$msg)=$vo->getOnlyFirst(qw(id subnets));
            if (defined($vpcrec)){
               $vpcpath{$vpc}=$vpcrec;
            }
         }
      }

      foreach my $rec (@result){
         if ($rec->{vpcidpath} ne "" &&
             exists($vpcpath{$rec->{vpcidpath}}) &&
             ref($vpcpath{$rec->{vpcidpath}}) eq "HASH"){
            foreach my $subnet (
                    @{$vpcpath{$rec->{vpcidpath}}->{subnets}}){
               foreach my $iprec (@{$rec->{ipadresses}}){
                  if ($ip->isIpInNet($iprec->{name},
                                     $subnet->{ipnet})){
                     if ($subnet->{netareatag} ne ""){
                        $iprec->{netareatag}=$subnet->{netareatag};
                     }
                  }
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



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_accountid"))){
     Query->Param("search_accountid"=>'154101356188');
   }
   if (!defined(Query->Param("search_isremote"))){
     Query->Param("search_isremote"=>"\"".$self->T("boolean.false")."\"");
   }
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","subnets","tags",
          "source");
}



1;
