package GCP::system;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use GCP::lib::Listedit;
use JSON;
@ISA=qw(GCP::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(

      new kernel::Field::Id(
            name              =>'idpath',
            searchable        =>0,
            group             =>'source',
            align             =>'left',
            RestFilterType    =>[qw(name projectId zonename)],
            label             =>'GCP Id-Path'),

      new kernel::Field::RecordUrl(),


      new kernel::Field::Text(     
            name              =>'projectId',
            searchable        =>1,
            group             =>'source',
            align             =>'left',
            dataobjattr       =>'projectId',
            label             =>'Project ID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(      # https://www.ietf.org/rfc/rfc1035.txt
            name              =>'name',
            searchable        =>1,
            htmlwidth         =>'200px',
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'status',
            dataobjattr       =>'status',
            label             =>'Online-State'),

      new kernel::Field::Container(     
            name              =>'tags',
            dataobjattr       =>'tags',
            uivisible         =>1,
            label             =>'Tags'),

      new kernel::Field::Text(
            name              =>'zonename',
            group             =>'source',
            searchable        =>0,
            dataobjattr       =>'zonename',
            label             =>'Zone-Name'),

      new kernel::Field::CDate(
            name              =>'cdate',
            group             =>'source',
            searchable        =>0,
            label             =>'Creation-Date'),

   );
   $self->setDefaultView(qw(projectId name status cdate));
   return($self);
}



sub getCredentialName
{
   my $self=shift;

   return("GCP");
}



sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my ($flt,$requestToken)=$self->simplifyFilterSet($filterset);
   return(undef) if (!defined($flt));

   my @curView=$self->getCurrentView();

   my $credentialName=$self->getCredentialName();
   my $Authorization=$self->getAuthorizationToken($credentialName);


   my ($restFinalAddr,$requesttoken,$constParam)=$self->Filter2RestPath(
      "/compute/v1/projects/{projectId}/aggregated/instances",  
      $filterset,
      {
      }
   );

   if (!defined($restFinalAddr)){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"unknown error while create restFinalAddr");
      }
      return(undef);
   }

   my $d=$self->CollectREST(
      dbname=>$credentialName,
      useproxy=>1,
      requesttoken=>$requesttoken,
      url=>sub{
         my $self=shift;
         my $baseurl="https://compute.googleapis.com";
         my $dataobjurl=$baseurl.$restFinalAddr;
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

         my $srcRecords=[];
         #$data->{items}->{REGION}->{instances}[]
         #{
         # name
         # status
         # tags
         # zone
         # id
         # creationTimestamp
         # lastStartTimestamp
         # cpuPlatform
         # networkInterfaces(name(ifname) networkIP network(URL) subnetwork(URL)
         #}
         #'selfLink' => 'https://www.googleapis.com/compute/v1/projects/de0360-dev-gcplz-trainees/zones/europe-west3-a/instances/jump-box',
         #print STDERR Dumper($data);
         if (ref($data) eq "HASH" &&
             exists($data->{items})){
            $srcRecords=$data->{items};
         }
         else{
           # if (ref($data) eq "HASH"){
           #    $srcRecords=[$data];
           # }
         }

         my @l;
         foreach my $zonename (keys(%{$srcRecords})){
            if (exists($srcRecords->{$zonename}->{instances}) &&
                ref($srcRecords->{$zonename}->{instances}) eq "ARRAY"){
               foreach my $rec (@{$srcRecords->{$zonename}->{instances}}){

                 # if (in_array(\@curView,[qw(ALL srcrec)])){
                 #    my $jsonfmt=new JSON();
                 #    $jsonfmt->property(latin1 => 1);
                 #    $jsonfmt->property(utf8 => 0);
                 #    $jsonfmt->pretty(1);
                 #    my $d=$jsonfmt->encode($rec);
                 #    $rec->{srcrec}=$d;
                 # }
                 # if (in_array(\@curView,[qw(ALL cdate)])){
                 #    $rec->{cdate}=$rec->{vserverCreationDate};
                 # }
                  $rec->{projectId}=$constParam->{projectId};
                  $rec->{zonename}=$zonename;
                  $rec->{zonename}=~s/^.*\///;  
                  $rec->{idpath}=$rec->{name}.'@'.
                                 $constParam->{projectId}.'@'.
                                 $rec->{zonename};
                  if (exists($constParam->{projectId})){
                     $rec->{projectId}=$constParam->{projectId};
                  }
                  $self->GCP::lib::Listedit::ExternInternTimestampReformat(
                     $rec,'creationTimestamp'
                  );
                  if (exists($rec->{creationTimestamp}) && 
                      $rec->{creationTimestamp} ne ""){
                     $rec->{cdate}=$rec->{creationTimestamp};
                  }
                  else{
                     $rec->{cdate}=undef;
                  }
                  push(@l,$rec);
               }
            }
         }
         return(\@l);
      }
   );
   return($d);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default tags source));
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


1;
