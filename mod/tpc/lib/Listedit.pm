package tpc::lib::Listedit;
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
use kernel::App::Web;
use kernel::DataObj::Static;
use kernel::Field;
use kernel::Field::TextURL;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getVRealizeAuthorizationToken
{
   my $self=shift;

   $W5V2::Cache->{GLOBAL}={} if (!exists($W5V2::Cache->{GLOBAL}));
   my $gc=$W5V2::Cache->{GLOBAL};
   my $gckey="TPC_AuthCache";

   if (!exists($gc->{$gckey}) || $gc->{$gckey}->{Expiration}<time()){
      my $d=$self->CollectREST(
         method=>'POST',
         dbname=>'TPC',
         url=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            $baseurl.="/"  if (!($baseurl=~m/\/$/));
            my $dataobjurl=$baseurl."csp/gateway/am/api/login?access_token";
            return($dataobjurl);
         },
         content=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $json=new JSON;
     
            my ($domain,$apiuser)=$apiuser=~m/^(.*)\/(.*)$/;
            $json->utf8(1);
            $json->property(utf8=>1);
            my $d=$json->encode({
               username=>$apiuser,
               domain=>$domain,
               password=>$apikey
            });
            return($d);
         },
         headers=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $headers=['Content-Type'=>'application/json',
                         'Accept'=>'application/json'];
            return($headers);
         },
      );
      if (ref($d) ne "HASH"){
         die("Request for access_token failed");
      }

      my $cacheTPCauthRec={
         Authorization=>$d->{token_type}." ".$d->{access_token}
      };
     
      my $Authorization=$d->{token_type}." ".$d->{access_token};
     
      if (exists($d->{expires_inx})){
         $cacheTPCauthRec->{Expiration}=time()+$d->{expires_in}-600;
      }
      else{
         $cacheTPCauthRec->{Expiration}=time()+60;
      }
      $gc->{$gckey}=$cacheTPCauthRec;
      #printf STDERR ("fifi getNewAuth=%s\n",$gc->{$gckey}->{Authorization});
   }
  
   return($gc->{$gckey}->{Authorization});
}




sub decodeFilter2Query4vRealize
{
   my $self=shift;
   my $filter=shift;

   my $query={};

   foreach my $fn (keys(%$filter)){
      $query->{$fn}=$filter->{$fn};
      $query->{$fn}=${$query->{$fn}} if (ref($query->{$fn}) eq "SCALAR");
      $query->{$fn}=join(" ",@{$query->{$fn}}) if (ref($query->{$fn}) eq "ARRAY");
   }
   return($query);
}




1;
