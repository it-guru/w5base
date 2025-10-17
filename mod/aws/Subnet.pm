package aws::Subnet;
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
                label         =>'VpcId'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'200',
                label         =>'Name'),

      new kernel::Field::Text(
                name          =>'ipnet',
                label         =>'IP-Net'),

      new kernel::Field::Text(
                name          =>'netareatag',
                label         =>'NetArea Tag'),

      new kernel::Field::Text(
                name          =>'vpcid',
                label         =>'VpcId'),

      new kernel::Field::Link(
                name          =>'vpcidpath',
                label         =>'VpcIdPath'),

      new kernel::Field::Text(
                name          =>'ownerid',
                label         =>'OwnerId'),

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

      new kernel::Field::Container(
                name          =>'tags',
                searchable    =>0,
                group         =>'tags',
                uivisible     =>1,
                label         =>'Tags'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name ipnet ownerid vpcid));
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

   my $query=$self->decodeFilter2Query4AWS("Subnet",$filter);
   if (!defined($query)){
      return(undef) if ($self->LastMsg());
      return([]);
   }
   my $AWSAccount=$query->{accountid};
   my $AWSRegion=$query->{region};

   my $ip=getModuleObject($self->Config,"itil::ipaddress");

   my @errStack;
   try {
      my ($stscred,$ua)=$self->GetCred4AWS($AWSAccount,$AWSRegion);
      my $obj=Paws->service('EC2',
            credentials=>$stscred,
            region =>$AWSRegion
      );
      my $blk=0;
      my $NextToken;
      do{
         my %param=();
         if ($NextToken ne ""){
            $param{NextToken}=$NextToken;
         }
         if (exists($query->{id}) && $query->{id} ne ""){
            $param{SubnetIds}=[$query->{id}];
         }
         else{
            $param{MaxResults}=20;
         }
         my $objItr=$obj->DescribeSubnets(%param);
         if ($objItr){
            my $Subnets=$objItr->Subnets();
            if ($Subnets){
               foreach my $subnet (@$Subnets){
                  my %tag;
                  foreach my $tag (@{$subnet->Tags()}){
                     $tag{$tag->Key()}=$tag->Value();
                  }
                  my $rec={
                      id=>$subnet->{SubnetId},
                      accountid=>$AWSAccount,
                      ipnet=>$subnet->CidrBlock(),
                      vpcid=>$subnet->VpcId(),
                      vpcidpath=>$subnet->VpcId().'@'.
                              $AWSAccount.'@'.
                              $AWSRegion,
                      ownerid=>$subnet->OwnerId(),
                      region=>$AWSRegion,
                      name=>$tag{Name},
                      tags=>\%tag,
                      idpath=>$subnet->{SubnetId}.'@'.
                              $AWSAccount.'@'.
                              $AWSRegion,
                  };

                  #########################################################
                  # netarea tag depend from $rec->{ipnet} and $rec->{ownerid}
                  if ($rec->{ownerid} eq "487587716831"){
                     $rec->{netareatag}="ISLAND";
                     if (($rec->{ipnet}=~m/^100\./)||
                         ($rec->{ipnet}=~m/^172\./)){
                        $rec->{netareatag}="AWSINTERN";
                     }
                     my $o=$ip->IpDecode($rec->{ipnet});
                     if ($ip->isIpInNet($rec->{ipnet},
                         $self->getIntranetworks())){
                        $rec->{netareatag}="CNDTAG";
                     }
                  }
                  #########################################################
                  push(@result,$rec);
               }
            }
            $NextToken=$objItr->NextToken();
         }
         $blk++;
      }while($NextToken ne "");
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
     Query->Param("search_accountid"=>'280962857063');
   }
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","ipaddresses","tags",
          "source");
}


sub getIntranetworks
{
   my $self=shift;
   my @l=qw(
            10.91.48.0/20
            10.175.0.0/17
            10.125.4.0/22
            10.125.64.0/18

            10.91.128.0/18
            10.175.128.0/17
            10.125.8.0/22 );
   return(@l);
}



1;
