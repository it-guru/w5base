package aws::account;
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
      new kernel::Field::Text(
                name          =>'accountid',
                FieldHelpType =>'GenericConstant',
                label         =>'AWS-AccountID'),

      new kernel::Field::Text(
                name          =>'region',
                selectsearch  =>sub{
                   my $self=shift;
                   return("us-east-1");
                },
                FieldHelpType =>'GenericConstant',
                label         =>'AWS-Region'),

      new kernel::Field::Text(
                name          =>'users',
                searchable    =>0,
                label         =>'Users'),

      new kernel::Field::Container(
                name          =>'tags',
                searchable    =>0,
                group         =>'tags',
                uivisible     =>1,
                label         =>'Tags'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(accountid region users));
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

   my $query=$self->decodeFilter2Query4AWS("Account",$filter);
   if (!defined($query)){
      return(undef) if ($self->LastMsg());
      return([]);
   }
   my %AWSAccount;
   foreach my $AWSAccount (split(/\s+/,$query->{accountid})){
      $AWSAccount{$AWSAccount}++;
   }
   my @AWSAccount=sort(keys(%AWSAccount));
   my $AWSRegion=$query->{region};

   my @errStack;


   my $AWSAccount=$query->{accountid};


   foreach my $AWSAccount (@AWSAccount){
      try {
         my ($stscred,$ua)=$self->GetCred4AWS($AWSAccount,$AWSRegion);
         my $obj=Paws->service('IAM',
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
            my $objItr=$obj->GetAccountSummary(%param);
            if ($objItr){
               my %rec=(
                  accountid=>$AWSAccount,
                  region=>$AWSRegion
               );
               my $SummaryMap = $objItr->SummaryMap;
               $rec{users}=$SummaryMap->{Users};
               push(@result,\%rec);
            }
            $blk++;
         }while($NextToken ne "");
      }
      catch {
         my $eclass=blessed($_);
         if ($eclass eq "Paws::Exception"){
            if ($_->code ne "AccessDenied"){ # Account gibt es nicht mehr
               push(@errStack,"(".$_->code.") :".$_->message);
            }
         }
         else{
            push(@errStack,$_);
         }
      };
      last if ($#errStack!=-1);
   }
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


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(TriggerEndpoint),$self->SUPER::getValidWebFunctions());
}

#
# Endpoint URL to handle Trigger Events from AWS
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
      exitcode=>0,
      ptimestamp=>NowStamp(),
      exitmsg=>'OK'
   });
   print $d;


   my $userid=$self->getCurrentUserId();
   my $AccountID=$q->{AccountID}; 
   my $OP=$q->{OP};
   my $awsregion='eu-central-1';

   if ($AccountID ne "" && (
        ($OP=~m/add/i) ||
        ($OP=~m/remove/i)
       )){
      my $ca=$self->getPersistentModuleObject("_CloudA","itil::itcloudarea");
      $ca->SetFilter({cloud=>\'AWS',
                      srcid=>\$AccountID,
                      cistatusid=>'4'});
      my ($carec,$msg)=$ca->getOnlyFirst(qw(ALL));
      msg(INFO,"AWS TriggerEndpoint:".Dumper($q));
             
      if (defined($carec)){
         if ($OP=~m/add/i){
            if ($q->{InstanceID} ne ""){
               my $idpath=$q->{InstanceID}.'@'.$AccountID.'@'.$awsregion;
               my $o=getModuleObject($self->Config,"aws::system");
               $o->Import({importname=>$idpath,forceUnattended=>1});
            }
         }

         my %p=(eventname=>'AWS_QualityCheck',
                spooltag=>'AWS_QualityCheck-'.$carec->{id},
                redefine=>'1',
                retryinterval=>310,
                firstcalldelay=>490+300,
                maxretry=>12,
                eventparam=>$carec->{id},
                userid=>$userid);
         my $res;
         if (defined($res=$self->W5ServerCall("rpcCallSpooledEvent",%p)) &&
            $res->{exitcode}==0){
            msg(INFO,"AWS_QualityCheck ------------------------------");
            msg(INFO,"AWS_QualityCheck OP=".$OP);
            msg(INFO,"AWS_QualityCheck InstanceID=".$q->{InstanceID});
            msg(INFO,"AWS_QualityCheck Event for $AccountID sent OK");
            msg(INFO,"AWS_QualityCheck ------------------------------");
         }
         else{
            msg(ERROR,"AWS_QualityCheck Event sent failed");
         }
         return(0);
      }
      else{
         msg(ERROR,"aws::TriggerEndpoint - no active CloudArea for ".
                   "$AccountID");
         return(0);
      }
   }




   printf STDERR ("got not processed AWS Trigger:%s\n",$d);
   return(0);
}




1;
