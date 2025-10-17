package tardis::apiexposure;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::REST;
use tardis::lib::Listedit;
use JSON;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::REST tardis::lib::Listedit);

#
# Stargate API:
#
# https://developer.telekom.de/catalog/eni/stargate/enterprise/production/1.0.0
#
#

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(     
            name              =>'idpath',
            group             =>'source',
            RestFilterType    =>sub{
               my $self=shift;
               my $qval=shift;
               my $query=shift;
               my $const=shift;
               my $filter=shift;
               my ($name,$applicationId)=split(/\@/,$qval);
               if ($filter->{name} ne $name){
                  $filter->{name}.=$name;                   # to get not found
               }
               if ($filter->{applicationId} ne $applicationId){
                  $filter->{applicationId}.=$applicationId; # if parameters 
               }
               delete($filter->{idpath});                  # already filtered
            },
            label             =>'ID'),

      new kernel::Field::Text(     
            name              =>'name',
            RestFilterType    =>'CONST2PATH',
            htmlwidth         =>'250px',
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'applicationId',
            weblinkto         =>'tardis::application',
            weblinkon         =>['applicationId'=>'id'],
            label             =>'ApplicationId'),

      new kernel::Field::Text(     
            name              =>'statusstate',
            label             =>'State'),

      new kernel::Field::Text(     
            name              =>'basepath',
            dataobjattr       =>'basePath',
            label             =>'base path'),

      new kernel::Field::SubList(
                name          =>'subscripteds',
                label         =>'Subscripted by',
                searchable    =>0,
                htmldetail    =>'NotEmpty',
                group         =>'subscripteds',
                vjointo       =>'tardis::apisubscripted',
                vjoinon       =>['idpath'=>'idpath'],
                vjoindisp     =>['application','subscriberApplicationId']),

      new kernel::Field::Text(     
            name              =>'upstream',
            label             =>'upstream')

   );
   $self->setDefaultView(qw(idpath name approval basepath upstream));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TARDIS");
}




sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();
   my $Authorization=$self->tardis::lib::Listedit::getTardisAuthorizationToken(
      $credentialName
   );
   return(undef) if (!defined($Authorization));

   my ($restFinalAddr,$requesttoken,$constParam)=$self->Filter2RestPath(
      "/applications/{applicationId}/apiexposures",  # Path-Templ with var
      $filterset,
      {   # translation parameters - for future use
         P1=>'xx'
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
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $dataobjurl=$baseurl.$restFinalAddr;
         printf STDERR ("REST URL access='%s'\n",$dataobjurl);
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
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data from backend %s",$self->Self());
         return(undef);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{apiExposures}) &&
             ref($data->{apiExposures}) eq "ARRAY"){
            $data=$data->{apiExposures};
         }
         elsif(ref($data) eq "HASH"){
            $data=[$data];
         }
         map({
            foreach my $k (keys(%$constParam)){
               if (!exists($_->{$k})){
                  $_->{$k}=$constParam->{$k};
               }
            }
            if (ref($_->{status}) eq "HASH"){
               $_->{statusstate}=$_->{status}->{state};
            }
            $_->{idpath}=join('@',$_->{name},$_->{applicationId});
         } @$data);

         #print STDERR "success:".Dumper($data);
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
   return(qw(header default subscripteds source));
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


1;
