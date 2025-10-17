package tpc::deployment;
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

# Docu:
# https://developer.broadcom.com/xapis/vrealize-automation-deployment-api/8.1.0/Deployments/index

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(     
            name              =>'id',
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'DeploymentID'),

      new kernel::Field::Text(     
            name              =>'opname',
            ODATA_filter      =>'1',
            dataobjattr       =>'name',
            ignorecase        =>1,
            label             =>'Operation label'),

      new kernel::Field::Text(     
            name              =>'status',
            ODATA_filter      =>'1',
            ODATA_constFilter =>'1',
            uppersearch       =>1,
            label             =>'Status'),

      new kernel::Field::Interface(
            name              =>'projectid',
            dataobjattr       =>'projectId',
            label             =>'projectId'),

      new kernel::Field::Container(
            name              =>'inputs',
            searchable        =>1,
            uivisible         =>1,
            label             =>'Inputs'),

      new kernel::Field::Text(
            name              =>'project',
            vjointo           =>'tpc::project',
            vjoinon           =>['projectid'=>'id'],
            vjoindisp         =>'name',
            label             =>'Project'),

      new kernel::Field::SubList(
                name          =>'resources',
                label         =>'Resources',
                searchable    =>0,
                group         =>'resources',
                vjointo       =>'tpc::deploymentresource',
                vjoinon       =>['id'=>'deploymentid'],
                vjoindisp     =>['name','type','id']),

      new kernel::Field::CDate(     
            name              =>'cdate',
            dataobjattr       =>'createdAt',
            sqlorder          =>'desc',
            group             =>'source',
            label             =>'Creation-Date'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(cdate id opname status project));
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


   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4vRealize(
      "deployments","id",
      $filterset
   );
   return(undef) if (!defined($dbclass));

   my $requesttoken="SEARCH.".time();
   #printf STDERR ("dbclass=%s\n",$dbclass);
   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      retry_count=>6,
      retry_interval=>15,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."deployment/api/".$dbclass;
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
             if (exists($_->{inputs}) && ref($_->{inputs}) eq "HASH"){
                foreach my $k (keys(%{$_->{inputs}})){
                   if ($k=~m/pass/i){
                      $_->{inputs}->{$k}="***";
                   }
                }
             }
         } @$data);
         return($data);
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
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data TPC deployment response");
         return(undef);
      }
   );
   #print STDERR Dumper($d);

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
