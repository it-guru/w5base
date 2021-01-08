package tpc::machine;
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
      new kernel::Field::Id(     
            name              =>'id',
            searchable        =>1,
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'MachineID'),

      new kernel::Field::Text(     
            name              =>'name',
            searchable        =>1,
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'orgId',
            searchable        =>1,
            label             =>'orgId'),

      new kernel::Field::Text(     
            name              =>'projectId',
            searchable        =>1,
            label             =>'projectId'),

      new kernel::Field::Text(     
            name              =>'project',
            vjointo           =>'tpc::project',
            vjoinon           =>['projectId'=>'id'],
            vjoindisp         =>'name',
            label             =>'Project'),

      new kernel::Field::Text(     
            name              =>'address',
            searchable        =>1,
            label             =>'IP-Address'),

      new kernel::Field::Textarea(     
            name              =>'description',
            searchable        =>1,
            label             =>'Description'),

      new kernel::Field::CDate(
                name          =>'createdAt',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'createdAt'),

      new kernel::Field::MDate(
                name          =>'updatedAt',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'updatedAt'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name));
   return($self);
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $Authorization=$self->getVRealizeAuthorizationToken();

   my $filter=$filterset->{FILTER}->[0];
   my $query=$self->decodeFilter2Query4vRealize($filter);

   my $dbclass="machines";
#
   my $requesttoken="SEARCH.".time();

   if ($query->{id} ne ""){  # change op, if machine id is direct addressed
      $dbclass="machines/$query->{id}";
      $requesttoken=$query->{id};
   }
   # ODATA Filters:
   # https://oliverleach.wordpress.com/2017/04/08/vrealize-automation-orchestrator-api-odata-filters/
  # else{
  #    $dbclass.="?\$filter=projectId eq '99536c11-452a-4bc5-9578-33bfee2ff121'";
  # }

   my $d=$self->CollectREST(
      dbname=>'TPC',
      requesttoken=>$requesttoken,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."iaas/".$dbclass;
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
        # foreach my $rec (@$data){
        #    $rec->{ictoNumber}=$rec->{systemNumber};
        #    delete($rec->{systemNumber});
        # }
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
