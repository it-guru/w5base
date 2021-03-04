package aws::IAM;
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
                label         =>'EC2-InstanceID'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name'),

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
   $self->setDefaultView(qw(id ipaddress accountid cdate));
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

   my $query=$self->decodeFilter2Query4AWS("Lambda",$filter);
   if (!defined($query)){
      return(undef) if ($self->LastMsg());
      return([]);
   }
   my $AWSAccount=$query->{accountid};
   my $AWSRegion=$query->{region};

   my @errStack;
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
         #if (exists($query->{id}) && $query->{id} ne ""){
         #   $param{InstanceIds}=[$query->{id}];
         #}
         #else{
         #   $param{MaxResults}=20;
         #}
         #$param{MaxItems}=20;
         my $objItr=$obj->GetAccountSummary(%param);
p $objItr;
         if ($objItr){
            #      push(@result,$rec);
            #   }
            #}
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



1;
