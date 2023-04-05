package neo::version;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use neo::lib::Listedit;
use JSON;
@ISA=qw(neo::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(     
            name              =>'name',
            dataobjattr       =>'name',
            ignorecase        =>1,
            label             =>'Name'),

      new kernel::Field::Container(     
            name              =>'info',
            dataobjattr       =>'info',
            searchable        =>0,
            uivisible         =>1,
            label             =>'Info'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(name info));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("NEO");
}




sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my $Authorization=$self->getTardisAuthorizationToken($credentialName);

   return(undef) if (!defined($Authorization));

   #my ($dbclass,$requesttoken)=$self->decodeFilter2Query4vRealize(
   #   "deployments","id",
   #   $filterset
   #);
   my $dbclass="neo/extern/allVersions";

   return(undef) if (!defined($dbclass));

   my $requesttoken="SEARCH.".time();
   #printf STDERR ("dbclass=%s\n",$dbclass);
   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl.$dbclass;
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
         if (ref($data) eq "HASH" && exists($data->{content})){
            $data=$data->{content};
         }
         if (ref($data) ne "ARRAY"){
            $data=[$data];
         }
         if ($#{$data}==0 && ref($data->[0]) eq "HASH" &&
             exists($data->[0]->{services})){
            $data=$data->[0]->{services};
         }
         else{
            return(undef);
         }
         map({
             my %info=();
             foreach my $irec (@{$_->{infos}}){
                foreach my $k (keys(%$irec)){
                   $info{$k}=$irec->{$k};
                }
             }
             $_->{info}=\%info;
         } @$data);
         return($data);
      }
   );

   return($d);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default resources source));
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
