package itncmdb::lib::Listedit;
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
use kernel::DataObj::REST;
use kernel::Field;
use kernel::Field::TextURL;
use kernel::QRule;
use Text::ParseWords;
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::REST);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getAuthorizationToken
{
   my $self=shift;
   return($self->getITENOSAuthorizationToken(@_));
}


sub getITENOSAuthorizationToken
{
   my $self=shift;
   my $credentialName=shift;

   $W5V2::Cache->{GLOBAL}={} if (!exists($W5V2::Cache->{GLOBAL}));
   my $gc=$W5V2::Cache->{GLOBAL};
   my $gckey=$credentialName."_AuthCache";


   if (!exists($gc->{$gckey}) || $gc->{$gckey}->{Expiration}<time()){
      my $d=$self->CollectREST(
         method=>'POST',
         dbname=>$credentialName,
         requesttoken=>'AuthLevel1',
         verify_hostname=>0,
         url=>sub{
            my $self=shift;
            my $baseurl=shift;

            my $dataobjurl=$baseurl;
            if (!($dataobjurl=~m/\/$/)){
               $dataobjurl.="/";
            }
            $dataobjurl.="token";
            #msg(INFO,"request Authorization at $dataobjurl");
            return($dataobjurl);
         },
         content=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $cgi=new CGI({
               client_id=>$apiuser,
               client_secret=>$apikey,
               grant_type=>'client_credentials'
            });
            my $d=$cgi->query_string();
            $d=~s/;/&/g;   # itenos can only handle & seperator
            return($d);
         },
         headers=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $headers=[
                'Content-Type'  =>'application/x-www-form-urlencoded',
            ];
            return($headers);
         },
         success=>sub{ 
            my $self=shift;
            my $data=shift;
            return($data);
         },
         onfail=>sub{
            my $self=shift;
            my $code=shift;
            my $statusline=shift;
            my $content=shift;
            my $reqtrace=shift;

            msg(ERROR,$reqtrace);
            my $msg="unexpected ITNCMDB auth response code HTTP $code";
            $msg.=" ($statusline)";
            my $gc=globalContext();
            $gc->{LastMsg}=[] if (!exists($gc->{LastMsg}));
            push(@{$gc->{LastMsg}},"ERROR: $msg");

            #$self->LastMsg(ERROR,$msg);
            return(undef);
         }
      );
      if (!defined($d)){
         return(undef);
      }
      if (ref($d) ne "HASH"){
         die("Request for access_token failed");
      }
      my $cacheITENOSauthRec={
         Authorization=>$d->{token_type}." ".$d->{access_token}
      };
     
      if (exists($d->{expires_in})){
         $cacheITENOSauthRec->{Expiration}=time()+$d->{expires_in};
      }
      else{
         $cacheITENOSauthRec->{Expiration}=time()+600;
      }
      $gc->{$gckey}=$cacheITENOSauthRec;

   }
  
   return($gc->{$gckey}->{Authorization});
}

1;
