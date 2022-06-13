package leanix::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use MIME::Base64;
use Text::ParseWords;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub ExternInternTimestampReformat
{
   my $self=shift;
   my $rec=shift;
   my $name=shift;

   if (exists($rec->{$name})){
      if (my ($Y,$M,$D,$h,$m,$s)=$rec->{$name}=~
              m/^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)(\..*Z){0,1}$/){
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

sub getLeanIXAuthorizationToken
{
   my $self=shift;

   $W5V2::Cache->{GLOBAL}={} if (!exists($W5V2::Cache->{GLOBAL}));
   my $gc=$W5V2::Cache->{GLOBAL};
   my $gckey="LEANIX_AuthCache";

   if (!exists($gc->{$gckey}) || $gc->{$gckey}->{Expiration}<time()){
      my $d=$self->CollectREST(
         method=>'POST',
         dbname=>'leanix',
         useproxy=>1,
         requesttoken=>'AuthLevel1',
         url=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            $baseurl.="/"  if (!($baseurl=~m/\/$/));
            my $dataobjurl=$baseurl."services/mtm/v1/oauth2/token";
            return($dataobjurl);
         },
         content=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            return("grant_type=client_credentials");
            my $qstr=kernel::cgi::Hash2QueryString(
               'grant_type'=>'client_credentials'
            );
            return($qstr);
         },
         headers=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            #printf STDERR ("DEBUG: apikey  = '%s'\n",$apikey);
            #printf STDERR ("DEBUG: apiuser = '%s'\n",$apiuser);
            my $headers=['Content-Type'  =>'application/x-www-form-urlencoded',
                         'Authorization' =>'Basic '.
                                  encode_base64($apiuser.':'.$apikey)];
            return($headers);
         },
         success=>sub{  # DataReformaterOnSucces
            my $self=shift;
            my $data=shift;
            if (ref($data) eq "HASH" && exists($data->{access_token}) &&
                                        exists($data->{token_type})){
               return($data);
               return($data->{token_type}." ".$data->{access_token});
            }
            return(undef);
         },
      );
      if (!defined($d)){
         if (!$self->LastMsg()){
            $self->SilentLastMsg(ERROR,"unknown problem while bearer token");
         }
         return(undef);
      }
      if (ref($d) eq "HASH"){
         my $cacheTPCauthRec={
            Authorization=>$d->{token_type}." ".$d->{access_token}
         };
         if (exists($d->{expires_in})){
            $cacheTPCauthRec->{Expiration}=time()+$d->{expires_in}-600;
         }
         else{
            $cacheTPCauthRec->{Expiration}=time()+600;
         }
         $gc->{$gckey}=$cacheTPCauthRec;
      }
      else{
         $self->LastMsg(ERROR,"missing valid refresh_token for authorisation");
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




sub decodeFilter2Query4LeanIX
{
   my $self=shift;
   my $dbclass=shift;
   my $idfield=shift;
   my $filter=shift;
   my $const={}; # for constances witch are derevided from query
   my $requesttoken="SEARCH.".time();
   my $query="";
   my %qparam;
   my $byId=0;
   my $type=$dbclass;

   if (ref($filter) eq "HASH"){
      if (!($dbclass=~m/\//)){
         $dbclass="services/pathfinder/v1/factSheets";
      }
      foreach my $filtername (keys(%{$filter})){
         my $f=$filter->{$filtername}->[0];
         foreach my $fn (keys(%{$f})){
            my $fld=$self->getField($fn);
            if (defined($fld)){
               if ($fn eq $idfield){  # Id Field handling
                  my $id; 
                  if (ref($f->{$fn}) eq "ARRAY" &&
                      $#{$f->{$fn}}==0){
                     $id=$f->{$fn}->[0];
                  }
                  elsif (ref($f->{$fn}) eq "SCALAR"){
                     $id=${$f->{$fn}};
                  }
                  else{
                     if (!($f->{$fn}=~m/[ *?]/)){
                        $id=$f->{$fn};
                     }
                  }
                  $const->{$fn}=$id;
                  $byId=1;
                  if ($dbclass=~m/\{$idfield\}/){
                     $dbclass=~s/\{$idfield\}/$id/g;
                  }
                  else{
                     $dbclass=$dbclass."/".$id;
                  }
                  $requesttoken=$dbclass;
               }
            }
         }
      }
   }
   else{
      printf STDERR ("invalid Filterset in $self:%s\n",Dumper($filter));
      $self->LastMsg(ERROR,"invalid filterset for LeanIX query");
      return(undef);
   }
   if (!$byId){
      $qparam{pageSize}="500";
      $qparam{pageSize}="2000";
      $qparam{type}=$type;
   }

   my $qstr=kernel::cgi::Hash2QueryString(%qparam);
   if ($qstr ne ""){
      $dbclass.="?".$qstr;
      $requesttoken=$dbclass;
   }
   
   return($dbclass,$requesttoken);
}



sub Ping
{
   my $self=shift;

   my $errors;
   my $d;
   # Ping is for checking backend connect, without any error displaying ...
   {
    #  open local(*STDERR), '>', \$errors;
    #  eval('
         my $Authorization=$self->getLeanIXAuthorizationToken();
    #  ');
       $d=$Authorization;
   }
   if (!defined($d) && !$self->LastMsg()){
      $self->LastMsg(ERROR,"fail to REST Ping to LeanIX");
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


sub genReadTPChref
{
   my $self=shift;
   my $auth=shift;
   my $hrefs=shift;
   if (ref($hrefs) eq "HASH"){
      if (exists($hrefs->{hrefs})){
         $hrefs=$hrefs->{hrefs};
      }
      elsif(exists($hrefs->{href})){
         $hrefs=$hrefs->{href};
      }
      else{
         $hrefs=undef;
      }
   }
   if (defined($hrefs)){
      $hrefs=[$hrefs] if (ref($hrefs) ne "ARRAY");
   }
   else{
      $hrefs=[];
   }


   my $dd=[];
   foreach my $href (@$hrefs){
      my $d=$self->CollectREST(
         dbname=>'TPC',
         url=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $base=shift;
            if (($baseurl=~m#/$#) && ($href=~m#^/#)){
               $baseurl=~s#/$##;
            }
            my $dataobjurl=$baseurl.$href;
            return($dataobjurl);
         },
         requesttoken=>$href,
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
    
           # if ($code eq "404"){  # 404 bedeutet nicht gefunden
           #    return([],"200");
           # }
            msg(ERROR,$reqtrace);
            $self->LastMsg(ERROR,"unexpected data TPC response in genReadHref");
            return(undef);
         }
      );
      push(@$dd,$d);
      #print STDERR "SubRecord:".Dumper($d);
   }
   return($dd);
}







1;
