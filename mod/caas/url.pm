package caas::url;
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
use UUID::Tiny ':std';
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
      new kernel::Field::Text(
                name          =>'id',
                label         =>'ID',
                dataobjattr   =>'id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'URL',
                dataobjattr   =>'url'),

      new kernel::Field::Text(
                name          =>'projectid',
                group         =>'source',
                label         =>'ProjectID',
                dataobjattr   =>'projectid'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(name projectid));
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
   return("header","default","soure");
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

   my $requestPath="v1/ingressUrls?cmsunaligned=true";


   my ($flt,$requestToken)=$self->simplifyFilterSet($filterset);
   return(undef) if (!defined($flt));

   if (ref($flt) eq "HASH" &&
       exists($flt->{projectid}) && $flt->{projectid} ne ""){
      $requestPath="v1/cloudAreas/".$flt->{projectid}."/ingressUrls";
   }

   $requestToken.=$requestPath;

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
         $dataobjurl.=$requestPath;
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
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "404"){  # 404 bedeutet nicht gefunden
            return([],"200");
         }
         msg(ERROR,"HTTP code $code");
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data CaaS/IngressURLs response");
         return(undef);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         my @atomicSpecs=qw(domain port schema);

         my @fltdata=();

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
               if (exists($flt->{projectid}) && $flt->{projectid} ne ""){
                  $rec->{projectid}=$flt->{projectid};
               }
               $rec->{id}=uuid_to_string(create_uuid(UUID_V3,
                                         $rec->{url}.'@'.$rec->{projectid})) ;
               next if ($rec->{domain}=~m/^\s*$/);
               next if ($rec->{domain}=~m/\s/);
               next if (!($rec->{domain}=~m/\./));
               push(@fltdata,$rec);
            }
            @{$data}=@fltdata;
         }
         return();
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
