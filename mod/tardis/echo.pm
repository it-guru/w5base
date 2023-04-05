package tardis::echo;
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
use tardis::lib::Listedit;
use JSON;
@ISA=qw(tardis::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(     
            name              =>'url',
            dataobjattr       =>'url',
            ignorecase        =>1,
            label             =>'URL'),

      new kernel::Field::Text(     
            name              =>'origin',
            label             =>'Origin'),

      new kernel::Field::Container(     
            name              =>'headers',
            dataobjattr       =>'headers',
            desccolwidth      =>'130',
            uivisible         =>1,
            searchable        =>0,
            label             =>'Headers'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(url origin headers));
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
   my $Authorization=$self->getTardisAuthorizationToken($credentialName);
   return(undef) if (!defined($Authorization));

   my $requesttoken="SEARCH.".time();
   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $echoP="/eni/echo/v1";
         my $dataobjurl=tardis::lib::Listedit::resplaceURLPath($baseurl,$echoP);
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
         if (ref($data) ne "ARRAY"){
            if (!$self->IsMemberOf("admin")){
               delete($data->{headers}->{Authorization});
            }
            $data=[$data];
         }
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
