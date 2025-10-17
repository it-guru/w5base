package tardis::application;
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
            name              =>'id',
            dataobjattr       =>'id',
            RestFilterType    =>'CONST2PATH',
            group             =>'source',
            label             =>'ID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'name',
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'ictono',
            dataobjattr       =>'icto',
            htmldetail        =>'NotEmpty',
            label             =>'ICTO-ID'),

      new kernel::Field::Text(     
            name              =>'team',
            label             =>'Team'),

      new kernel::Field::Text(     
            name              =>'hub',
            label             =>'Hub'),

      new kernel::Field::Text(     
            name              =>'zone',
            label             =>'Zone'),

      new kernel::Field::SubList(
            name              =>'subscriptions',
            label             =>'Subscriptions',
            searchable        =>0,
            htmldetail        =>'NotEmpty',
            group             =>'subscriptions',
            vjointo           =>'tardis::apisubscription',
            vjoinon           =>['id'=>'applicationId'],
            vjoindisp         =>['name','approvalstatus']),

      new kernel::Field::SubList(
            name              =>'exposures',
            label             =>'Exposures',
            searchable        =>0,
            htmldetail        =>'NotEmpty',
            group             =>'exposures',
            vjointo           =>'tardis::apiexposure',
            vjoinon           =>['id'=>'applicationId'],
            vjoindisp         =>['name','statusstate'])

   );
   $self->setDefaultView(qw(id name ictono hub team zone));
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
      "/applications",  # Path-Templ with var
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
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{applications}) &&
             ref($data->{applications}) eq "ARRAY"){
            $data=$data->{applications};
         }
         elsif(ref($data) eq "HASH"){
            $data=[$data];
         }
         map({
            $_=FlattenHash($_);
            if ($_->{icto} ne ""){
               $_->{icto}=uc($_->{icto});
            }
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
   return(qw(header default exposures subscriptions source));
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
