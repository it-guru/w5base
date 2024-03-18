package tardis::apisubscripted;
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
      new kernel::Field::Text(
            name              =>'idpath',
            group             =>'source',
            RestFilterType    =>sub{
               my $self=shift;
               my $qval=shift;
               my $query=shift;
               my $const=shift;
               my $filter=shift;
               my ($apiExposureName,$parentApplicationId)=split(/\@/,$qval);
               if ($filter->{apiExposureName} ne $apiExposureName){
                  $filter->{apiExposureName}.=$apiExposureName;    
               }
               if ($filter->{parentApplicationId} ne $parentApplicationId){
                  $filter->{parentApplicationId}.=$parentApplicationId; 
               }
               delete($filter->{idpath});                  # already filtered
            },
            label             =>'ID'),

      new kernel::Field::Text(     
            name              =>'parentApplicationId',
            label             =>'parentApplicationId'),

      new kernel::Field::Text(     
            name              =>'subscriberApplicationId',
            label             =>'subscriberApplicationId'),

      new kernel::Field::Text(     
            name              =>'application',
            dataobjattr       =>'application', 
            htmlwidth         =>'200px',
            weblinkto         =>'tardis::application',
            weblinkon         =>['subscriberApplicationId'=>'id'],
            label             =>'Application'),

      new kernel::Field::Text(     
            name              =>'apiExposureName',
            label             =>'apiExposureName'),
   );
   $self->setDefaultView(qw(parentApplicationId apiExposureName applicationId));
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
      "/applications/{parentApplicationId}/apiexposures/".
      "{apiExposureName}/apisubscriptions",  
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
         if (ref($data) eq "HASH" && exists($data->{apiSubscriptions}) &&
             ref($data->{apiSubscriptions}) eq "ARRAY"){
            $data=$data->{apiSubscriptions};
         }
         elsif(ref($data) eq "HASH"){
            $data=[$data];
         }
         map({
            $_=FlattenHash($_);
            foreach my $k (keys(%$constParam)){
               if (!exists($_->{$k})){
                  $_->{$k}=$constParam->{$k};
               }
#               if (ref($_->{approval}) eq "HASH"){
#                  $_->{approvalstatus}=$_->{approval}->{status};
#               }
            }
            #print STDERR Dumper($_);
            $_->{subscriberApplicationId}=join("--",
                $_->{'team.hub'},
                $_->{'team.name'},
                $_->{'application'}
            );
                
            $_->{idpath}=join('@',$_->{apiExposureName},
                                  $_->{parentApplicationId});
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
   return(qw(header default source));
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
