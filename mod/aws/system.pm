package aws::system;
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
use kernel::cgi;
use aws::lib::Listedit;
@ISA=qw(aws::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(    name       =>'id',
                                  searchable =>0,
                                  htmlwidth  =>'150',
                                  label      =>'AWS-SystemID'),
      new kernel::Field::Text(    name       =>'ipaddress',
                                  searchable =>0,
                                  label      =>'private IP-Address',
                                  dataobjattr=>'private_ip_address'),
      new kernel::Field::Text(    name       =>'accountid',
                                  label      =>'AWS-AccountID'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id ipaddress accountid));
   return($self);
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;


   return(undef) if (!$self->genericSimpleFilterCheck4AWS($filterset));
   my $filter=$filterset->{FILTER}->[0];
   
   return(undef) if (!$self->checkMinimalFilter4AWS($filter,"accountid"));

   my $query=$self->decodeFilter2Query4AWS($filter);

   if (!exists($query->{accountid}) ||
       !($query->{accountid}=~m/^\d{3,20}$/)){
      $self->LastMsg(ERROR,"mandatary accountid filter not specifed");
      print STDERR Dumper($query);
      return(undef);
   }
   my $dbclass="systems";

   return($self->CollectREST(
      dbname=>'aws',
      cachetime=>600,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl.$dbclass;
         $dataobjurl.="?".kernel::cgi::Hash2QueryString({
            account=>$query->{accountid}
         });
         return($dataobjurl);
      },
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         return(['x-api-key'=>$apikey]);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{instances}) && 
             ref($data->{instances}) eq "HASH"){
            return([map({
                 $_->{accountid}=$query->{accountid};
                 $_->{ipaddress}=$_->{private_ip_address};
                 $_;
               } values(%{$data->{instances}}))]
            );
         }
         else{
            $self->LastMsg(ERROR,"unexpected data structure from REST call");
         }
         return(undef);
      },
      useproxy=>1
   ));
}




1;
