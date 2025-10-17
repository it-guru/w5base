package tardis::lib::Listedit;
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
use kernel::DataObj::Static;
use kernel::Field;
use kernel::Field::TextURL;
use kernel::QRule;
use Text::ParseWords;
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


sub resplaceURLPath
{
   my $url=shift;
   my $newpath=shift;

   $url=~s#//([^/]+)/.*$#//$1$newpath#;

   return($url);
}


sub deriveIrisUrl
{
   my $dataurl=shift;
   my $irisPath="/auth/realms/default/protocol/openid-connect/token";

   $dataurl=~s#//stargate([\.-])#//iris$1#;
   $dataurl=resplaceURLPath($dataurl,$irisPath);


   return($dataurl);
}


sub getTardisAuthorizationToken
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
         url=>sub{
            my $self=shift;
            my $baseurl=shift;

            my $dataobjurl=deriveIrisUrl($baseurl);
            msg(INFO,"request Authorization at $dataobjurl");
            return($dataobjurl);
         },
         content=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $d="grant_type=client_credentials";
            return($d);
         },
         headers=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $headers=[
                'Content-Type'  =>'application/x-www-form-urlencoded',
                'Authorization' =>'Basic '.encode_base64($apiuser.':'.$apikey)
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

            if ($code eq "401"){  # 401 logon Fehler
               if ($content=~m/Invalid client or Invalid client credentials/i){
                  $self->SilentLastMsg(ERROR,
                       "invalid username or password - ".
                       "TARDIS authentication refused");
               }
               return(undef,$code);
            }
            msg(ERROR,$reqtrace);
            $self->LastMsg(ERROR,"unexpected data TARDIS project response ".
                                 "- code $code");
            return(undef);
         }
      );
      if (!defined($d)){
         return(undef);
      }
      if (ref($d) ne "HASH"){
         die("Request for access_token failed");
      }
      my $cacheTPCauthRec={
         Authorization=>$d->{token_type}." ".$d->{access_token}
      };
     
      if (exists($d->{expires_in})){
         $cacheTPCauthRec->{Expiration}=time()+$d->{expires_in}-10;
      }
      else{
         $cacheTPCauthRec->{Expiration}=time()+290;
      }
      $gc->{$gckey}=$cacheTPCauthRec;

   }
  
   return($gc->{$gckey}->{Authorization});
}


#sub Ping
#{
#   my $self=shift;
#
#   my $credentialN=$self->getCredentialName();
#
#   my $errors;
#   my $d;
#   # Ping is for checking backend connect, without any error displaying ...
#   {
#    #  open local(*STDERR), '>', \$errors;
#      eval('
#         my $Authorization=$self->getVRealizeAuthorizationToken($credentialN);
#         if ($Authorization ne ""){
#            $d=$self->CollectREST(
#               dbname=>$credentialN,
#               url=>sub{
#                  my $self=shift;
#                  my $baseurl=shift;
#                  my $apikey=shift;
#                  $baseurl.="/"  if (!($baseurl=~m/\/$/));
#                  my $dataobjurl=$baseurl."iaas/deployments";
#                  $dataobjurl.="?top=2";
#                  return($dataobjurl);
#               },
#               headers=>sub{
#                  my $self=shift;
#                  my $baseurl=shift;
#                  my $apikey=shift;
#                  my $headers=["Authorization"=>$Authorization,
#                               "Content-Type"=>"application/json"];
#        
#                  return($headers);
#               },
#               onfail=>sub{
#                  my $self=shift;
#                  my $code=shift;
#                  my $statusline=shift;
#                  my $content=shift;
#                  my $reqtrace=shift;
#        
#                  my $gc=globalContext(); 
#                  $gc->{LastMsg}=[] if (!exists($gc->{LastMsg}));
#                  push(@{$gc->{LastMsg}},"ERROR: ".$statusline);
#        
#                  return(undef);
#               }
#            );
#         }
#      ');
#   }
#   if (!defined($d) && !$self->LastMsg()){
#      $self->LastMsg(ERROR,"fail to REST Ping to TPC");
#   }
#   if (!$self->LastMsg()){
#      if ($errors){
#         foreach my $emsg (split(/[\n\r]+/,$errors)){
#            $self->SilentLastMsg(ERROR,$emsg);
#         }
#      }
#   }
#
#   return(0) if (!defined($d));
#   return(1);
#
#}


#sub genReadTPChref
#{
#   my $self=shift;
#   my $credentialName=shift;
#   my $auth=shift;
#   my $hrefs=shift;
#   if (ref($hrefs) eq "HASH"){
#      if (exists($hrefs->{hrefs})){
#         $hrefs=$hrefs->{hrefs};
#      }
#      elsif(exists($hrefs->{href})){
#         $hrefs=$hrefs->{href};
#      }
#      else{
#         $hrefs=undef;
#      }
#   }
#   if (defined($hrefs)){
#      $hrefs=[$hrefs] if (ref($hrefs) ne "ARRAY");
#   }
#   else{
#      $hrefs=[];
#   }
#
#
#   my $dd=[];
#   foreach my $href (@$hrefs){
#      my $d=$self->CollectREST(
#         dbname=>$credentialName,
#         url=>sub{
#            my $self=shift;
#            my $baseurl=shift;
#            my $apikey=shift;
#            my $apiuser=shift;
#            my $base=shift;
#            if (($baseurl=~m#/$#) && ($href=~m#^/#)){
#               $baseurl=~s#/$##;
#            }
#            my $dataobjurl=$baseurl.$href;
#            return($dataobjurl);
#         },
#         requesttoken=>$href,
#         headers=>sub{
#            my $self=shift;
#            my $baseurl=shift;
#            my $apikey=shift;
#            my $headers=['Authorization'=>$auth,
#                         'Content-Type'=>'application/json'];
# 
#            return($headers);
#         },
#         onfail=>sub{
#            my $self=shift;
#            my $code=shift;
#            my $statusline=shift;
#            my $content=shift;
#            my $reqtrace=shift;
#    
#           # if ($code eq "404"){  # 404 bedeutet nicht gefunden
#           #    return([],"200");
#           # }
#            msg(ERROR,$reqtrace);
#            $self->LastMsg(ERROR,"unexpected data TPC response in genReadHref");
#            return(undef);
#         }
#      );
#      push(@$dd,$d);
#      #print STDERR "SubRecord:".Dumper($d);
#   }
#   return($dd);
#}




1;
