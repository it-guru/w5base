package tpc::projecttag;
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
use tpc::lib::Listedit;
use JSON;
@ISA=qw(tpc::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
            name              =>'projectid',
            searchable        =>1,
            label             =>'projectId'),

      new kernel::Field::Text(     
            name              =>'key',
            searchable        =>1,
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'value',
            searchable        =>0,
            label             =>'Value'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(key value));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TPX");
}




sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my $Authorization=$self->getVRealizeAuthorizationToken($credentialName);


   my ($dbclass,$requesttoken,$const)=$self->decodeFilter2Query4vRealize(
      "projects/{projectid}/resource-metadata","projectid",
      $filterset
   );
   return(undef) if (!defined($dbclass));

   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      retry_count=>3,
      retry_interval=>10,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."iaas/api/".$dbclass;
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
      preprocess=>sub{   # create a valid JSON response
         my $self=shift;
         my $d=shift;
         my $code=shift;
         my $message=shift;
         return($d);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{tags})){
            $data=$data->{tags};
         }
         if (ref($data) ne "ARRAY"){
            $data=[];
         }
         map({
            foreach my $k (keys(%$const)){
               $_->{$k}=$const->{$k};
            }
         } @$data);
         return($data);
      }
   );


   return($d);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}

sub isUploadValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
#}


1;
