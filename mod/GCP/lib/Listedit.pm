package GCP::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use Digest::MD5 qw(md5_base64);
use MIME::Base64;
use Crypt::OpenSSL::RSA;
use JSON;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::REST);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
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


sub ExternInternTimestampReformat
{
   my $self=shift;
   my $rec=shift;
   my $name=shift;

   my $nameList=$name;
   if (ref($name) ne "ARRAY"){
      $nameList=[$name];
   }

   foreach my $name (@$nameList){
      if (exists($rec->{$name})){
         if (my ($Y,$M,$D,$h,$m,$s)=$rec->{$name}=~
                 m/^(\d+)-(\d+)-(\d+)T(\d+):([0-9]+):([0-9]+)(\..*Z){0,1}$/){
            $rec->{$name}=sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                                  $Y,$M,$D,$h,$m,$s);
         }
         # Achtung: Zeitzone wird noch nicht korret bereuecksichtig!
         if (my ($Y,$M,$D,$h,$m,$s)=$rec->{$name}=~
                 m/^(\d+)-(\d+)-(\d+)T([0-9]+):([0-9]+):([0-9]+)\..*$/){ # TZ miss!
            $rec->{$name}=sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                                  $Y,$M,$D,$h,$m,$s);
         }
         if (my ($Y,$M,$D)=$rec->{$name}=~
                 m/^(\d+)-(\d+)-(\d+)$/){
            $rec->{$name}=sprintf("%04d-%02d-%02d 12:00:00",
                                  $Y,$M,$D);
         }
      }
   }
}


sub oneLineBase64
{
   my $d=shift;

   my $b64str=encode_base64($d);
   $b64str=~s/=//g;
   $b64str=~s/\//_/g;
   $b64str=~s/\+/-/g;
   $b64str=~s/[\r\n]//g;
   return($b64str);
}



sub encodeJSONbase64
{
   my $d=shift;

   my $json=encode_json($d);
   my $b64jstring=oneLineBase64($json);

   return($b64jstring);
}


sub signRSAbase64
{
   my $key=shift;
   my $data=shift;

   my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($key);
   $rsa_priv->use_sha256_hash();
   my $binSignature=$rsa_priv->sign($data);
   my $b64Signature=oneLineBase64($binSignature);

   return($b64Signature);
}



sub getAuthorizationToken
{
   my $self=shift;
   my $credentialName=shift;
   my $noImpersonate=shift;

   $W5V2::Cache->{GLOBAL}={} if (!exists($W5V2::Cache->{GLOBAL}));
   my $gc=$W5V2::Cache->{GLOBAL};
   my $gckey=$credentialName."_AuthCache";

   if (!exists($gc->{$gckey}) || $gc->{$gckey}->{Expiration}<time()){
      my $GCPscope="https://www.googleapis.com/auth/cloud-platform";
      my $GCPauth2="https://oauth2.googleapis.com/token";
      my $GCPimpersonateEMail;


      my $pred=$self->CollectREST(
         method=>'POST',
         dbname=>$credentialName,
         useproxy=>1,
         requesttoken=>'AuthLevel1',
         url=>$GCPauth2,
         content  => sub{
            my $self=shift;
            my $baseconnect=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $apibase=shift;
            $GCPimpersonateEMail=$baseconnect;

            my $issuedAt=time();
            my $expiredAt=time()+3600;
          
            my $header=oneLineBase64('{"alg":"RS256","type":"JWT"}');
            my $payload=encodeJSONbase64({
               iss   => $apiuser,
               scope => $GCPscope,
               aud   => $GCPauth2,
               iat   => $issuedAt,
               exp   => $expiredAt
            });

            my $signature=signRSAbase64($apikey,$header.'.'.$payload);
            my $assertion=$header.'.'.$payload.'.'.$signature;

            my $data=kernel::cgi::Hash2QueryString(
               grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
               assertion=>$assertion
            );
            return($data);
         },
         headers  => sub{

            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $headers=['Content-Type'=>'application/x-www-form-urlencoded',
                         'Accept'=>'application/json'];
            return($headers);
         },
         onfail=>sub{
            my $self=shift;
            my $code=shift;
            my $statusline=shift;
            my $content=shift;
            my $reqtrace=shift;

            #print STDERR ("fail data=%s\n",Dumper(\$content));
            if ($code eq "400"){  # 400 logon Fehler
               if ($content=~m/Invalid username or password/i){
                  $self->SilentLastMsg(ERROR,"invalid username or password - ".
                                       "authentication refused");
               }
               return(undef,$code);
            }
            msg(ERROR,$reqtrace);
            $self->LastMsg(ERROR,"unexpected data while GCP Bearer Token gen");
            return(undef);
         }
      );
      if (!defined($pred)){
         if (!$self->LastMsg()){
            $self->SilentLastMsg(ERROR,"unknown problem while access_token");
         }
         return(undef);
      }
      if (ref($pred) ne "HASH"){
         $self->SilentLastMsg(ERROR,"Request for access_token failed");
         return(undef);
      }
      my $access_token=$pred->{access_token};
      if ($noImpersonate){
         return("Bearer ".$access_token);
      }
      my $generateAccessTokenURL="https://iamcredentials.googleapis.com/".
                                 "v1/projects/-/serviceAccounts/".
                                 $GCPimpersonateEMail.
                                 ":generateAccessToken";
      #printf STDERR ("generateAccessTokenURL = %s\n",$generateAccessTokenURL);
      if ($access_token ne ""){
         my $d=$self->CollectREST(
            method=>'POST',
            dbname=>$credentialName,
            requesttoken=>'AuthLevel2',
            useproxy=>1,
            url=>$generateAccessTokenURL,
            content=>sub{
               my $self=shift;
               my $baseurl=shift;
               my $apikey=shift;
               my $apiuser=shift;
               my $json=new JSON;
        
               $json->utf8(1);
               $json->property(utf8=>1);
               my $postd=$json->encode({
                  scope     =>[$GCPscope],
                  lifetime  => '700s'
               });
               return($postd);
            },
            headers=>sub{
               my $self=shift;
               my $baseurl=shift;
               my $apikey=shift;
               my $headers=['Authorization'=>"Bearer ".$access_token,
                            'Content-Type'=>'application/json; charset=utf-8',
                            'Accept'=>'application/json'];
               return($headers);
            },
         );
         if (ref($d) ne "HASH"){
            die("Request for access_token_privileged failed");
         }
         #print STDERR "access_token_privileged:".Dumper($d);
         $d->{tokenType}="Bearer";
         my $cacheTPCauthRec={
            Authorization=>$d->{tokenType}." ".$d->{accessToken}
         };
     
         #my $Authorization=$d->{tokenType}." ".$d->{accessToken};
     
         if (exists($d->{expires_inx})){
            $cacheTPCauthRec->{Expiration}=time()+$d->{expires_in}-600;
         }
         else{
            $cacheTPCauthRec->{Expiration}=time()+600;
         }
         $gc->{$gckey}=$cacheTPCauthRec;
      }
      else{
         $self->LastMsg(ERROR,"missing valid GCP access_token_privileged ".
                              "authorisation");
      }

   }
  
   return($gc->{$gckey}->{Authorization});
}


sub caseHdl
{
   my $self=shift;
   my $fobj=shift;
   my $var=shift;
   my $exp=shift;

   if ($fobj->{ignorecase}){
      $var="tolower($var)";
      $exp=lc($exp);
   }
   if ($fobj->{uppersearch}){
      $exp=uc($exp);
   }
   if ($fobj->{lowersearch}){
      $exp=lc($exp);
   }
   


   return($var,$exp);
}





sub Ping
{
   my $self=shift;

   my $errors;
   my $d;
   # Ping is for checking backend connect, without any error displaying ...
   if (1){
      open local(*STDERR), '>', \$errors;
      eval('
            $d=$self->CollectREST(
               url=>"https://www.googleapis.com/auth/cloud-platform",
               useproxy=>1,
               headers=>sub{
                  my $self=shift;
                  my $baseurl=shift;
                  my $apikey=shift;
                  my $headers=["Content-Type"=>"application/json"];
        
                  return($headers);
               },
               preprocess=>sub{   # create a valid JSON response
                  my $self=shift;
                  my $d=shift;
                  my $code=shift;
                  my $message=shift;
                  $d="{\"content\":\"".$d."\"}";
                  return($d);
               },
               onfail=>sub{
                  my $self=shift;
                  my $code=shift;
                  my $statusline=shift;
                  my $content=shift;
                  my $reqtrace=shift;

                  my $gc=globalContext(); 
                  $gc->{LastMsg}=[] if (!exists($gc->{LastMsg}));
                  push(@{$gc->{LastMsg}},"ERROR: ".$statusline);
        
                  return(undef);
               }
            );
      ');
   }
   #
   # $d muss ein HASH sein und den Key $d->{content} haben. Das
   # könnte man noch verbessern.
   #
   if (!defined($d) && !$self->LastMsg()){
      $self->LastMsg(ERROR,"fail to HTTPS Ping to GCP");
   }
   if (!$self->LastMsg()){
      if ($errors){
         foreach my $emsg (split(/[\n\r]+/,$errors)){
            $self->SilentLastMsg(ERROR,$emsg);
         }
      }
   }

   return(0) if (!defined($d));
   return(1);

}

sub genericReadRequest
{
   my $self=shift;
   my $db=shift;
   my $auth=shift;
   my $url=shift;

   my $d=$self->CollectREST(
      dbname=>$db,
      useproxy=>1,
      url=>$url,
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $headers=['Authorization'=>$auth,
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
         #if ($code eq "400"){
         #   my $json=eval('decode_json($content);');
         #   if ($@ eq "" && ref($json) eq "HASH" &&
         #       $json->{error}->{message} ne ""){
         #      $self->LastMsg(ERROR,$json->{error}->{message});
         #      return(undef);
         #   }
         #}
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data $db response ".
                              "in genericReadRequest");
         return(undef);
      }
   );
   return($d);
}



1;
