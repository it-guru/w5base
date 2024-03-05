package GCP::ipaddress;
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

      new kernel::Field::Text(
            name              =>'idpath',
            group             =>'source',
            align             =>'left',
            RestFilterType    =>[qw(id sysname projectId zonename)],
            label             =>'GCP Id-Path'),

      new kernel::Field::Text(     
            name              =>'id',
            searchable        =>1,
            group             =>'source',
            align             =>'left',
            dataobjattr       =>'id',
            label             =>'Instance ID'),

      new kernel::Field::Text(     
            name              =>'projectId',
            searchable        =>1,
            group             =>'source',
            align             =>'left',
            dataobjattr       =>'projectId',
            label             =>'Project ID'),

      new kernel::Field::Text(
            name              =>'sysname',
            searchable        =>1,
            dataobjattr       =>'sysname',
            htmlwidth         =>'200px',
            label             =>'Name'),

      new kernel::Field::Text(
            name              =>'name',
            searchable        =>1,
            htmlwidth         =>'200px',
            label             =>'Name'),

      new kernel::Field::Text(
            name              =>'ifname',
            searchable        =>0,
            htmlwidth         =>'200px',
            label             =>'System Interface'),

      new kernel::Field::Text(
            name              =>'netareatag',
            htmlwidth         =>'200px',
            label             =>'System Interface'),

      new kernel::Field::Text(
            name              =>'zonename',
            group             =>'source',
            searchable        =>0,
            dataobjattr       =>'zonename',
            label             =>'Zone-Name'),
   );
   $self->setDefaultView(qw(name id projectId status cdate));
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
      [ "/compute/v1/projects/{projectId}/zones/{zonename}/instances/{sysname}",
        "/compute/v1/projects/{projectId}/aggregated/instances"],
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

         my $srcRecords={};
         if (ref($data) eq "HASH"){
            if (exists($data->{items})){
               $srcRecords=$data->{items};
            }
            if (exists($data->{zone})){
               my $zonename=$data->{zone};
               $zonename=~s#^.*/([^/]+/[^/]+)$#$1#;
               $srcRecords->{$zonename}->{instances}=[$data];
            }
         }

         my @l;
         foreach my $zonename (keys(%{$srcRecords})){
            if (exists($srcRecords->{$zonename}->{instances}) &&
                ref($srcRecords->{$zonename}->{instances}) eq "ARRAY"){
               my $n=0;
               foreach my $rec (@{$srcRecords->{$zonename}->{instances}}){
                 $n++;
                 if ($n==1 &&
                     $self->Config->Param("W5BaseOperationMode") eq "dev"){
         #           print STDERR Dumper($rec);
                 }
                 if (ref($rec->{networkInterfaces}) eq "ARRAY"){
                    foreach my $irec (@{$rec->{networkInterfaces}}){
                       # network und subnetwork u.U. noch auswerten
                       $irec->{id}=$rec->{id};
                       $irec->{sysname}=$rec->{name};
                       $irec->{ifname}=$irec->{name};
                       $irec->{name}=$irec->{networkIP};
                       $irec->{projectId}=$constParam->{projectId};
                       $irec->{zonename}=$zonename;
                       $irec->{netareatag}="CNDTAG";
                       $irec->{zonename}=~s/^.*\///;  
                       $irec->{idpath}=$rec->{id}.'@'.
                                       $rec->{name}.'@'.
                                       $constParam->{projectId}.'@'.
                                       $irec->{zonename};

                       push(@l,$irec);
                    }
                 }
               }
            }
         }
         #print STDERR Dumper(\@l);
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
