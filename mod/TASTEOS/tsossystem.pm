package TASTEOS::tsossystem;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use aws::lib::Listedit;
use JSON;
@ISA=qw(aws::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(     
            name               =>'id',
            searchable         =>1,
            label              =>'SystemID'),
      new kernel::Field::Text(     
            name               =>'name',
            searchable         =>1,
            label              =>'Name'),
      new kernel::Field::Text(     
            name               =>'description',
            searchable         =>1,
            label              =>'Description'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name description));
   return($self);
}

sub DataCollector
{
   my $self=shift;

   my $dbclass="icto/system-metadata";

   return($self->CollectREST(
      dbname=>'TASTEOS',
      cachetime=>600,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl.$dbclass;
         return($dataobjurl);
      },
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         return(['access-token'=>$apikey,'Content-Type','application/json']);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{accounts}) && 
             ref($data->{accounts}) eq "HASH"){
            return([map({
                      #######################################################
                      # remap tags field to Container Strukture
                  #    my $tags=$_->{tags};
                  #    my %k;
                  #    if (ref($tags) eq "ARRAY"){
                  #       foreach my $l (@$tags){
                  #          if ($l->{Key} ne ""){
                  #             push(@{$k{$l->{Key}}},$l->{Value});
                  #          }
                  #       }
                  #    }
                  #    $_->{tags}=\%k;
                      #######################################################
                      $_;
                   } values(%{$data->{accounts}}))]);
         }
         else{
            $self->LastMsg(ERROR,"unexpected data structure from REST call");
         }
         return(undef);
      },
      useproxy=>0
   ));
}






1;
