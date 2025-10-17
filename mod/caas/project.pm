package caas::project;
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
use kernel::App::Web;
use kernel::App::Web::Listedit;
use kernel::DataObj::Static;
use kernel::Field;
use MIME::Base64;
use kernel::Field::TextURL;
use Text::ParseWords;
use Time::HiRes qw(usleep);
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);


   $self->AddFields(
      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
            name              =>'id',
            group             =>'source',
            label             =>'id'),
                                                  
      new kernel::Field::Text(
            name              =>'name',
            label             =>'Name',
            dataobjattr       =>'name'),

      new kernel::Field::Text(
            name              =>'oname',
            label             =>'original Name',
            dataobjattr       =>'fullName'),

      new kernel::Field::Text(
            name              =>'cloudid',
            label             =>'CloudID',
            dataobjattr       =>'cloudId'),

      new kernel::Field::TextDrop(
            name              =>'appl',
            searchable        =>0,
            vjointo           =>'itil::appl',
            vjoinon           =>['applid'=>'id'],
            searchable        =>0,
            vjoindisp         =>'name',
            label             =>'W5Base Application'),

      new kernel::Field::Text(
            name              =>'applid',
            label             =>'Application W5BaseID',
            dataobjattr       =>'applicationId'),

      new kernel::Field::Text(
            name              =>'cluster',
            label             =>'Cluster',
            htmldetail        =>'NotEmpty',
            dataobjattr       =>'cluster'),

      new kernel::Field::Text(
            name              =>'project',
            label             =>'Projectname',
            htmldetail        =>'NotEmpty',
            dataobjattr       =>'project'),

      new kernel::Field::Text(
            name              =>'requestoraccount',
            label             =>'requestor account',
            htmldetail        =>'NotEmpty',
            dataobjattr       =>'requestorAccount'),

      new kernel::Field::SubList(
            name              =>'urls',
            group             =>'urls',
            label             =>'URLs',
            searchable        =>'0',
            htmldetail        =>'NotEmpty',
            vjointo           =>'caas::url',
            vjoinon           =>['id'=>'projectid'],
            vjoindisp         =>['name']),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(name id cluster project));
   return($self);
}



sub getCredentialName
{
   my $self=shift;

   return("CAASGATE");
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","urls","soure");
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $CredName=$self->getCredentialName();

   my @view=$self->GetCurrentView();

   my ($flt,$requestToken)=$self->simplifyFilterSet($filterset);
   return(undef) if (!defined($flt));

   my $d=$self->CollectREST(
      dbname=>$CredName,
      retry_count=>6,
      retry_interval=>30,
      requesttoken=>$requestToken,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $base=shift;
      
         my $dataobjurl=$baseurl;
         $dataobjurl.="/" if (!($dataobjurl=~m/\/$/));
         $dataobjurl.="v1/cloudAreas";
         return($dataobjurl);
      },

      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apiuser=shift;
         my $headers=[Authorization =>'Basic '.
                                      encode_base64($apiuser.':'.$apikey)];
         return($headers);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;

         my @atomicSpecs=qw(cluster project);
         if (ref($data) eq "ARRAY"){
            #print STDERR Dumper($data);
            foreach my $rec (@$data){
               foreach my $k (@atomicSpecs){
                  $rec->{$k}=undef;
               }
               if (ref($rec->{atomicSpecs}) eq "HASH"){
                  foreach my $k (@atomicSpecs){
                     if (exists($rec->{atomicSpecs}->{$k})){
                        $rec->{$k}=$rec->{atomicSpecs}->{$k};
                     }
                  }
                 
               }
               if ($rec->{operationalModel} eq "unknown"){
                  $rec->{operationalModel}=undef;
               }
               $rec->{operationalModel}=uc($rec->{operationalModel});
               $rec->{name}=$rec->{fullName};
               $rec->{name}=~s/[^a-z0-9\/\(\)-]/_/gi;
               $rec->{name}=TextShorter($rec->{name},70);
            }
         }
         return();
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "503"){  # 503 means not all CaaS Envs are available
            $self->SilentLastMsg(ERROR,"HTTP 503 - ".
                                       "incomplete result from backend system");
            return(undef,"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data CaaS project response");
         return(undef);
      }
   );

   return($d);
}



#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_isexcluded"))){
#     Query->Param("search_isexcluded"=>$self->T("no"));
#   }
#}


1;
