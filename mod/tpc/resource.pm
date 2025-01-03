package tpc::resource;
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
use tpc::lib::Listedit;
use kernel::DataObj::REST;
use JSON;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::REST tpc::lib::Listedit);

# https://developer.broadcom.com/xapis/vrealize-operation-apis/latest/


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::RecordUrl(),


      new kernel::Field::Id(     
            name              =>'id',
            searchable        =>1,
            RestFilterType    =>'CONST2PATH',
            group             =>'source',
            htmldetail        =>'NotEmpty',
            htmlwidth         =>'150px',
            align             =>'left',
            label             =>'ResourceID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'name',
            RestFilterType    =>"SIMPLEQUERY",
            RestFilterField   =>"search",
            htmlwidth         =>'200px',
            label             =>'Resource-Name'),

      new kernel::Field::Text(     
            name              =>'origin',
            searchable        =>1,
            label             =>'Origin'),

      new kernel::Field::Text(     
            name              =>'type',
            searchable        =>1,
            RestFilterType    =>"SIMPLEQUERY",
            RestFilterField   =>"resourceTypes",
            label             =>'Resource-Type'),

      new kernel::Field::CDate(
            name              =>'cdate',
            group             =>'source',
            label             =>'Creation-Date',
            dayonly           =>1,
            searchable        =>0,  # das tut noch nicht
            dataobjattr       =>'createdAt'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(cdate id type name origin));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TPCX");
}




sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my $Authorization=$self->getVRealizeAuthorizationToken($credentialName);

   my ($restFinalAddr,$requesttoken,$constParam)=$self->Filter2RestPath(
      "/deployment/api/resources",  # Path-Templ with var
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

   my $dataobjurl;
   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      retry_count=>3,
      retry_interval=>10,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl=~s#/$##;
         $dataobjurl=$baseurl.$restFinalAddr;
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
         map({
             $self->ExternInternTimestampReformat($_,"createdAt");
      #       printf STDERR ("RAW Record %s\n",Dumper($_));
         } @$data);
         return($data);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

#         if ($code eq "404"){  # 404 bedeutet nicht gefunden
#            return([],"200");
#         }
#         if ($code eq "403"){  # 403 Forbitten Problem 04/2023
#            msg(ERROR,"vRA Bug 403 forbitten on access '$dataobjurl'");
#            return([],"200");  # Workaround, to prevent Error Messages
#         }                     # in QualityChecks
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data TPC machine response");
         return(undef);
      }

   );
   #customProperties

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



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default tags source));
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_type"))){
     Query->Param("search_type"=>"Cloud.vSphere.Machine");
   }
}




1;
