package aws::system;
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
                name          =>'status',
                label         =>'Status'),

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

      new kernel::Field::Text(
                name          =>'azone',
                searchable    =>0,
                label         =>'Availability-Zone'),

      new kernel::Field::Text(
                name          =>'azoneid',
                searchable    =>0,
                label         =>'Availability-ZoneID'),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                group         =>'ipaddresses',
                searchable    =>0,
                vjointo       =>'aws::ipaddress',
                vjoinon       =>['idpath'=>'idpath'],
                vjoindisp     =>['name','netareatag','dnsname','ifname','mac']),

      new kernel::Field::Text(
                name          =>'cpucount',
                searchable    =>0,
                label         =>'CPU-Count'),

      new kernel::Field::Text(
                name          =>'memory',
                searchable    =>0,
                label         =>'Memory'),

      new kernel::Field::Text(
                name          =>'type',
                searchable    =>0,
                label         =>'Instance type'),

      new kernel::Field::Text(
                name          =>'imageid',
                searchable    =>0,
                label         =>'ImageID'),

      new kernel::Field::Text(
                name          =>'imagename',
                searchable    =>0,
                htmldetail    =>'NotEmpty',
                label         =>'ImageName'),

      new kernel::Field::Text(
                name          =>'imageowner',
                searchable    =>0,
                htmldetail    =>'NotEmpty',
                label         =>'ImageOwner'),

      new kernel::Field::Text(
                name          =>'platform',
                searchable    =>0,
                htmldetail    =>'NotEmpty',
                label         =>'Platform'),

      new kernel::Field::Text(
                name          =>'autoscalinggroup',
                htmldetail    =>'NotEmpty',
                label         =>'AutoScalingGroup'),

      new kernel::Field::Text(
                name          =>'vpcid',
                label         =>'VpcId'),

      new kernel::Field::Link(
                name          =>'vpcidpath',
                label         =>'VpcIdPath'),

      new kernel::Field::Container(
                name          =>'tags',
                searchable    =>0,
                group         =>'tags',
                uivisible     =>1,
                label         =>'Tags'),

      new kernel::Field::Date(
                name          =>'cdate',
                searchable    =>0,
                group         =>'source',
                label         =>'Creation-Date'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id ipaddress accountid vpcid cdate));
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
   my %avzone;
   try {
      my $stscred=$self->GetCred4AWS($AWSAccount,$AWSRegion);
      my $ec2=Paws->service('EC2',credentials=>$stscred,region =>$AWSRegion);

      if (in_array(\@view,"azoneid")){
         my $az=$ec2->DescribeAvailabilityZones();
         foreach my $z (@{$az->AvailabilityZones()}){
            $avzone{$z->ZoneName()}=$z->ZoneId();
         }
         if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
            msg(INFO,"AvailabilityZoneIds: ".join(", ",sort(values(%avzone))));
         }
      }
      my $blk=0;
      my $NextToken;
      do{
         my %param=();
         if ($NextToken ne ""){
            $param{NextToken}=$NextToken;
         }
         if (exists($query->{id}) && $query->{id} ne ""){
            $param{InstanceIds}=[$query->{id}];
         }
         else{
            $param{MaxResults}=20;
         }
         my $InstanceItr=$ec2->DescribeInstances(%param);
         if ($InstanceItr){
            foreach my $res (@{$InstanceItr->Reservations()}){
               foreach my $instance (@{$res->Instances}){
                  #p $instance;
                  msg(INFO,"load instance $instance->{InstanceId}");

                  my $cdate=$instance->{LaunchTime};
                  $cdate=~s/^(\S+)T(\S+).000Z$/$1 $2/;
                  my %tag;
                  foreach my $tag (@{$instance->Tags()}){
                     $tag{$tag->Key()}=$tag->Value(); 
                  }
                  my $rec={
                      id=>$instance->{InstanceId},
                      type=>$instance->{InstanceType},
                      imageid=>$instance->{ImageId},
                      platform=>$instance->{platform},
                      accountid=>$AWSAccount,
                      region=>$AWSRegion,
                      name=>$instance->{InstanceId},
                      tags=>\%tag,
                      autoscalinggroup=>$tag{'aws:autoscaling:groupName'},
                      cdate=>$cdate,
                      idpath=>$instance->{InstanceId}.'@'.
                              $AWSAccount.'@'.
                              $AWSRegion,
                  };
                  if (length($tag{Name})>2){
                     $rec->{name}=$tag{Name};
                     $rec->{name}=~s/\..*//;
                  }

                  if (in_array(\@view,[qw(all imagename imageowner platform)])){
                     my $descImg =$ec2->DescribeImages(
                        'ImageIds'=>[$instance->{ImageId}]
                     );
                     my $ImgDesc=$descImg->Images;
                     if (ref($ImgDesc) eq "ARRAY" && $#{$ImgDesc}==0){
                        $rec->{imagename}=$ImgDesc->[0]->{Name};
                        $rec->{imageowner}=$ImgDesc->[0]->{OwnerId};
                        if ($ImgDesc->[0]->{PlatformDetails} ne "" &&
                            $rec->{platform} eq ""){
                           $rec->{platform}=$ImgDesc->[0]->{PlatformDetails};
                        }
                     }
                  }
                  if (in_array(\@view,"status")){
                     my $status="unknown";
                     my $DIRes =
                         $ec2->DescribeInstanceStatus(
                           'IncludeAllInstances'=>1,
                           'InstanceIds'=>[$instance->{InstanceId}]
                     );
                     my $InstanceStatuses=$DIRes->InstanceStatuses;
                     if ($InstanceStatuses){
                        foreach my $strec (@$InstanceStatuses){
                           my $sysst=$strec->SystemStatus();
                           $status=$sysst->Status();
                        }
                     }
                     $rec->{status}=$status;
                  }
                  if (in_array(\@view,"azone") ||
                      in_array(\@view,"azoneid")){
                     my $placement=$instance->Placement();
                     if (defined($placement)){
                        my $azone=$placement->AvailabilityZone();
                        $rec->{azone}=$azone;
                     }
                     if (in_array(\@view,"azoneid")){
                        $rec->{azoneid}=$avzone{$rec->{azone}};
                     }
                  }

                  my $vpcid=$instance->VpcId();
                  if ($vpcid ne ""){
                     $rec->{vpcid}=$vpcid;
                     $rec->{vpcidpath}=$vpcid.'@'.
                              $AWSAccount.'@'.
                              $AWSRegion;
                  }
                  if (in_array(\@view,"cpucount")){
                     my $cpucount;
                     my $CpuOptions=$instance->CpuOptions();
                     if ($CpuOptions){
                        my $n=$CpuOptions->CoreCount();
                        $cpucount+=$n;
                     }
                     $rec->{cpucount}=$cpucount;
                  }
                  if (in_array(\@view,"memory")){
                     my $mem;
                     my $type=$instance->{InstanceType};
                     if ($type ne ""){
                        my $types=$ec2->DescribeInstanceTypes(
                          InstanceTypes=>[$type],
                        );
                        foreach my $t (@{$types->InstanceTypes()}){
                           my $MemoryInfo=$t->MemoryInfo()->SizeInMiB();
                           $mem=$MemoryInfo;
                        }
                     }
                     $rec->{memory}=$mem;
                  }
                  push(@result,$rec);
               }
            }
            $NextToken=$InstanceItr->NextToken();
         }
         $blk++;
      }while($NextToken ne "");
   }
   catch {
      my $eclass=blessed($_);
      if ($eclass eq "Paws::Exception"){
         if ($_->code ne "InvalidInstanceID.NotFound"){ # no error - if EC2ID 
            push(@errStack,"(".$_->code."): ".$_->message);  # not found
         }
      }
      else{
         push(@errStack,$_);
      }
   };
   if ($#errStack!=-1){
      foreach my $emsg (@errStack){
         $self->LastMsg(ERROR,"errStack:".$emsg);
      }
      return(undef);
   }
   return(\@result);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_accountid"))){
     Query->Param("search_accountid"=>'238834862221');
   }
#   if (!defined(Query->Param("search_region"))){
#     Query->Param("search_region"=>'eu-central-1');
#   }
}



sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(ImportSystem));
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","ipaddresses","tags",
          "source");
}




sub ImportSystem
{
   my $self=shift;
   my $importname=trim(Query->Param("importname"));
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"system has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"AWS System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   my $importname;
   my ($ec2id,$accountid,$region);
   my $sysrec;
   if ($param->{importname} ne ""){
      $importname=$param->{importname};
      msg(INFO,"start Import in aws::system with importname $importname");
      if (($ec2id,$accountid,$region)=$importname
              =~m/^(\S+)\@([0-9]+)\@(\S+)$/){
         $flt={
            id=>$ec2id,
            accountid=>$accountid,
            region=>$region
         };
      }
      else{
         $self->LastMsg(ERROR,"sieht schlecht aus");
         return(undef);
      }

      $self->ResetFilter();
      $self->SetFilter($flt);
      my @l=$self->getHashList(qw(id name idpath ipaddresses));
      if ($#l==-1){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"EC2 Instanz not found in AWS");
         }
         return(undef);
      }
     
      if ($#l>0){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"Systemname '%s' not unique in AWS",
                                 $param->{importname});
         }
         return(undef);
      }
      $sysrec=$l[0];
   }
   elsif (ref($param->{importrec}) eq "HASH"){
      $sysrec=$param->{importrec};
   }
   else{
      msg(ERROR,"no importname specified while ".$self->Self." Import call");
      return(undef);
   }
   my $syssrcid=$sysrec->{idpath};
   my $system=getModuleObject($self->Config,"TS::system");

   ########################################################################
   # Detect Cloud Record
   ########################################################################

   my $itcloud=getModuleObject($self->Config,"itil::itcloud");
   my $cloudrec;
   {
      $itcloud->ResetFilter();
      $itcloud->SetFilter({name=>'AWS',cistatusid=>'4'});
      my ($crec,$msg)=$itcloud->getOnlyFirst(qw(ALL));
      if (defined($crec)){
         $cloudrec=$crec;
      }
      else{
         $self->LastMsg(ERROR,"no active AWS Cloud in inventory");
         return(undef);
      }
   }


   # sysimporttempl is needed for 1st generic insert an refind a redeployment
   my $sysimporttempl={
      name=>$sysrec->{name},
      initialname=>$sysrec->{id},
      autoscalinggroup=>$sysrec->{autoscalinggroup},
      id=>$sysrec->{idpath},
      srcid=>$sysrec->{idpath},
      ipaddresses=>$sysrec->{ipaddresses}
   };

   if (exists($sysrec->{tags})){
      if (exists($sysrec->{tags}->{'eks:nodegroup-name'}) &&
          $sysrec->{tags}->{'eks:nodegroup-name'} ne ""){
         $sysimporttempl->{autoscalingsubgroup}=
              $sysrec->{tags}->{'eks:nodegroup-name'};
      }
   }

   if ($sysimporttempl->{autoscalinggroup} ne "" &&
       $sysimporttempl->{name} ne "" &&
       (length($sysimporttempl->{autoscalinggroup})<40) &&
       ($sysimporttempl->{name}=~m/[^a-z0-9-]/) &&
       !($sysimporttempl->{autoscalinggroup}=~m/[^a-z0-9-]/)){
      $sysimporttempl->{name}=$sysimporttempl->{autoscalinggroup};
      $sysimporttempl->{name}=~s/[^a-z0-9_-]/_/gi;
   }


   my $appl=getModuleObject($self->Config,"TS::appl");
   my $cloudarea=getModuleObject($self->Config,"itil::itcloudarea");

   my $w5carec;

   if ($accountid ne ""){
      $cloudarea->SetFilter({
         cloudid=>$cloudrec->{id},
         srcid=>$accountid
      });
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec)){
         $w5carec=$w5cloudarearec;
      }
   }



   my $ImportRec={
      cloudrec=>$cloudrec,
      cloudarearec=>$w5carec,
      imprec=>$sysimporttempl,
      srcsys=>'AWS',
      checkForSystemExistsFilter=>sub{  # Nachfrage ob Reuse System-Candidat not
         my $osys=shift;                # exists in srcobj
         my $srcid=$osys->{srcid};
         return({idpath=>\$srcid});
      }
   };
   if ($param->{forceUnattended}){
      $ImportRec->{forceUnattended}=1;
   }
   my $ImportObjects={   # Objects are in seperated Structur for better Dumping
      itcloud=>$itcloud,
      itcloudarea=>$cloudarea,
      appl=>$appl,
      system=>$system,
      srcobj=>$self
   };

   #printf STDERR ("ImportRec(imprec):%s\n",Dumper($ImportRec->{imprec}));
   my $ImportResult=$system->genericSystemImport($ImportObjects,$ImportRec);
   #printf STDERR ("ImportResult:%s\n",Dumper($ImportResult));
   if ($ImportResult){
      return($ImportResult->{IdentifedBy});
   }
   return();
}





1;
