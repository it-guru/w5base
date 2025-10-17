package GCP::project;
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
      new kernel::Field::RecordUrl(),


      new kernel::Field::Text(     
            name              =>'projectno',
            searchable        =>1,
            group             =>'source',
            align             =>'left',
            dataobjattr       =>'projectNumber',
            label             =>'Project Number'),

      new kernel::Field::Id(     
            name              =>'id',
            searchable        =>1,
            RestFilterType    =>'CONST2PATH',
            group             =>'source',
            align             =>'left',
            dataobjattr       =>'projectId',
            label             =>'Project ID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'name',
            searchable        =>1,
            htmlwidth         =>'200px',
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'state',
            dataobjattr       =>'lifecycleState',
            label             =>'State'),

      new kernel::Field::SubList(
            name              =>'systems',
            label             =>'Systems',
            searchable        =>0,
            group             =>'systems',
            vjointo           =>'GCP::system',
            vjoinon           =>['id'=>'projectId'],
            vjoindisp         =>['name','status']),

      new kernel::Field::Container(     
            name              =>'labels',
            dataobjattr       =>'labels',
            group             =>'labels',
            uivisible         =>sub{
               my $self=shift;
               return(1) if ($self->getParent->IsMemberOf("admin"));
               return(0);
            },
            label             =>'Labels'),


      new kernel::Field::TextDrop(
            name              =>'appl',
            searchable        =>0,
            vjointo           =>'itil::appl',
            vjoinon           =>['w5baseid'=>'id'],
            searchable        =>0,
            vjoindisp         =>'name',
            label             =>'W5Base Application'),

      new kernel::Field::Interface(
            name              =>'w5baseid',
            container         =>'labels',
            label             =>'Application W5BaseID'),

      new kernel::Field::CDate(
            name              =>'cdate',
            group             =>'source',
            searchable        =>0,
            label             =>'Creation-Date'),

   );
   $self->setDefaultView(qw(id name cdate));
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
      "/v1/projects",  # Path-Templ with var
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
         my $baseurl="https://cloudresourcemanager.googleapis.com";
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
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "404"){  # 404 bedeutet nicht gefunden
            return([],"200");
         }
         if (exists($constParam->{id}) && $constParam->{id} ne "" &&
             $code eq "403"){ # this means on GCP a rundown of project
            return([],"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data GCP project response");
         return(undef);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;

         my $srcRecords=[];
         if (ref($data) eq "HASH" &&
             exists($data->{projects}) &&
             ref($data->{projects}) eq "ARRAY"){
            $srcRecords=$data->{projects};
         }
         else{
            if (ref($data) eq "HASH"){
               $srcRecords=[$data];
            }
         }

         my @l;
         foreach my $rec (@{$srcRecords}){
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
            $self->GCP::lib::Listedit::ExternInternTimestampReformat(
               $rec,'createTime'
            );
            if (exists($rec->{createTime}) && $rec->{createTime} ne ""){
               $rec->{cdate}=$rec->{createTime};
            }
            else{
               $rec->{cdate}=undef;
            }
            push(@l,$rec);
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
   return(qw(header default systems labels source));
}




#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
#}


1;
