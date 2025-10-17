package caas::cloud;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'fullName'),

      new kernel::Field::Text(
                name          =>'fancyname',
                label         =>'fancy name',
                dataobjattr   =>'fancyname'),

      new kernel::Field::Text(
                name          =>'env',
                label         =>'Environment',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'environment'),

      new kernel::Field::Text(
                name          =>'itnormodel',
                label         =>'NOR Model',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'operationalModel'),

      new kernel::Field::SubList(
                name          =>'projects',
                group         =>'projects',
                label         =>'Projects',
                htmldetail    =>'0',
                searchable    =>'0',
                vjointo       =>'caas::project',
                vjoinon       =>['id'=>'cloudid'],
                vjoindisp     =>['name','cluster']),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(name id env itnormodel));
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
   return("header","default","projects","soure");
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
      requesttoken=>$requestToken,
      retry_count=>6,
      retry_interval=>30,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $base=shift;
      
         my $dataobjurl=$baseurl;
         $dataobjurl.="/" if (!($dataobjurl=~m/\/$/));
         $dataobjurl.="v1/clouds";
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
         my @atomicSpecs=qw(environment operationalModel);
         if (ref($data) eq "ARRAY"){
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
               $rec->{fancyname}=$rec->{fullName};
               $rec->{fancyname}=~s/^caas-/CaaS-/;
               $rec->{fancyname}=~s/-([^-]+)$/-\U\1/i;
               $rec->{operationalModel}=uc($rec->{operationalModel});
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
         $self->LastMsg(ERROR,"unexpected data CaaS cloud response");
         return(undef);
      }
   );

   return($d);
}





sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_isexcluded"))){
     Query->Param("search_isexcluded"=>$self->T("no"));
   }
}













1;
