package azure::lib::Listedit;
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
use Text::ParseWords;
use Time::HiRes qw(usleep);
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

sub getAzureAuthorizationToken
{
   my $self=shift;
   my $param=shift;


   my $resource="https://management.core.windows.net/";
   my $scope;
   my $tenant;
   if (ref($param) eq "HASH"){
      if (exists($param->{resource})){
         $resource=$param->{resource};
      }
      if (exists($param->{scope})){
         $scope=$param->{scope};
      }
      if (exists($param->{tenant})){
         $tenant=$param->{tenant};
      }
   }


   $W5V2::Cache->{GLOBAL}={} if (!exists($W5V2::Cache->{GLOBAL}));
   my $gc=$W5V2::Cache->{GLOBAL};
   my $gckey="AZURE_AuthCache";

   if (!exists($gc->{$gckey}) || $gc->{$gckey}->{Expiration}<time()){
      my $d=$self->CollectREST(
         method=>'POST',
         dbname=>'AZURE',
         useproxy=>1,
         url=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $base=shift;
            $baseurl.="/"  if (!($baseurl=~m/\/$/));
            if (defined($tenant)){
               $base=$tenant;
            }
            my $dataobjurl=$baseurl.$base."/oauth2/";
            if (defined($scope)){
               $dataobjurl.="v2.0/";
            }
            $dataobjurl.="token";
            msg(INFO,"AzureAuth url: ".$dataobjurl);
            return($dataobjurl);
         },
         content=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $apiuser=shift;
            my $base=shift;

            my %qparam=(
               grant_type    => 'client_credentials',
               client_id     => $apiuser,
               client_secret => $apikey
            );
            
            if (!defined($tenant) && $tenant ne "1"){
               $tenant=$base;
            }

            if (defined($resource)){
               $qparam{resource}=$resource;
            }
            if (defined($scope)){
               $qparam{scope}=$scope;
            }
            my $qstr=kernel::cgi::Hash2QueryString(%qparam);
            msg(INFO,"AzureAuth POST data: ".$qstr);
            return($qstr);
         },
         headers=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            my $headers=['Content-Type'=>'application/x-www-form-urlencoded',
                         'Accept'=>'application/json'];
            return($headers);
         },
      );
      if (ref($d) ne "HASH"){
         die("Request for access_token failed");
      }

      my $cacheAZUREauthRec={
         Authorization=>$d->{token_type}." ".$d->{access_token}
      };
     
      my $Authorization=$d->{token_type}." ".$d->{access_token};
     
      if (exists($d->{expires_inx})){
         $cacheAZUREauthRec->{Expiration}=time()+$d->{expires_in}-600;
      }
      else{
         $cacheAZUREauthRec->{Expiration}=time()+60;
      }
      $gc->{$gckey}=$cacheAZUREauthRec;
   }
  
   return($gc->{$gckey}->{Authorization});
}


sub caseHdl
{
   my $self=shift;
   my $fobj=shift;
   my $var=shift;
   my $exp=shift;

 #  if ($fobj->{ignorecase}){
 #     $var="tolower($var)";
 #     $exp=lc($exp);
 #  }
   if ($fobj->{uppersearch}){
      $exp=uc($exp);
   }
   if ($fobj->{lowersearch}){
      $exp=lc($exp);
   }
   


   return($var,$exp);
}


sub AzID2W5BaseID
{
   my $id=shift;

   $id=~s#^/##g;
   $id=~s#\.\./##g;  # prevent ../ paths
   $id=~s#/#|-#g;
   return($id);
}


sub W5BaseID2AzID
{
   my $id=shift;

   $id=~s#\|-#/#g;   # make |- as seperator (to get no colision with pipes
   return($id);      # f.e. in resourceGroup names).
}


sub decodeFilter2Query4azure
{
   my $self=shift;
   my $dbclass=shift;
   my $idfield=shift;
   my $filter=shift;
   my $qparam=shift;
   my $const={}; # for constances witch are derevided from query
   my $requesttoken="SEARCH.".time();
   my $query="";
   my %qparam;

   if (ref($qparam) eq "HASH"){
      %qparam=%{$qparam};
   }
   #printf STDERR ("filter=%s\n",Dumper($filter));
   #printf STDERR ("dbclassTemplate=%s\n",Dumper(\$dbclass));

   usleep(600);

   if (ref($filter) eq "HASH"){
      foreach my $filtername (keys(%{$filter})){
         my $f=$filter->{$filtername}->[0];
         # ODATA Filter translation
        
         foreach my $fn (keys(%{$f})){
            my $fld=$self->getField($fn);
            if (defined($fld)){
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
                  if ($fn eq "idpath"){
                     if (my ($vmId,$subscriptionId)=
                $id=~m/^\s*([a-z0-9-]{30,40})\s*\@\s*([a-z0-9-]{30,40})\s*$/){
                        delete($f->{$fn});
                        $f->{vmId}=$vmId;
                        $const->{vmId}=$vmId;
                        $f->{subscriptionId}=$subscriptionId;
                        $const->{subscriptionId}=$subscriptionId;
                     }
                  }
                  $const->{$fn}=$id;
            }
         }
      }
      foreach my $fn (keys(%$const)){
          my $id=$const->{$fn};
          if ($dbclass=~m/\{$fn\}/){
             $dbclass=~s/\{$fn\}/$id/g;
          }
          else{
             if ($fn eq $idfield){
                $dbclass=azure::lib::Listedit::W5BaseID2AzID($id);
             }
          }
      }
   }
   else{
      msg(ERROR,"invalid Filterset in $self:".Dumper($filter));
      $self->LastMsg(ERROR,"invalid filterset for Azure query");
      return(undef);
   }
   if (!exists($qparam{'api-version'})){
      $qparam{'api-version'}="2022-12-01";
   }

   if ($self->{_LimitStart}==0 && $self->{_Limit}>0 &&
       !($self->{_UseSoftLimit})){
      $qparam{'$top'}=$self->{_Limit};
      if ($self->{_LimitStart}>0){
         $qparam{'$skip'}=$self->{_LimitStart};
      }
   }
   if ($dbclass=~m/\{[^{}]+\}/){
      $self->LastMsg(ERROR,"missing constant query parameter");
      return(undef);
   }

   my @order=$self->GetCurrentOrder();
   if (!($#order==0 && $order[0] eq "NONE")){
      my @ODATA_order=();
      foreach my $fieldname (@order){
         my $oMethod="";
         if ($fieldname=~m/^\+/){
            $fieldname=~s/^\+//;
            $oMethod="asc";
         }
         if ($fieldname=~m/^\-/){
            $fieldname=~s/^\-//;
            $oMethod="desc";
         }
         my $fld=$self->getField($fieldname);
         if (defined($fld)){
            my $sqlorder=$fld->{sqlorder};
            if ($sqlorder eq ""){
               $sqlorder="asc";
            }
            if ($oMethod ne ""){
               $sqlorder=$oMethod;
            }
            my $backendname=$fieldname;
            if (exists($fld->{dataobjattr})){
               $backendname=$fld->{dataobjattr};
            }
            push(@ODATA_order,"$backendname $sqlorder");
         }
      }
      if ($#ODATA_order!=-1){
         $qparam{'$orderby'}=join(",",@ODATA_order);
      }
   }


   #printf STDERR ("qparam=%s\n",Dumper(\%qparam));

   my $qstr=kernel::cgi::Hash2QueryString(%qparam);
   if ($qstr ne ""){
      $dbclass.="?".$qstr;
      $requesttoken=$dbclass;
   }
   #printf STDERR ("dbclass=%s\n",Dumper(\$dbclass));
   
   return($dbclass,$requesttoken,$const);
}


sub AzureBase
{
   my $self=shift;

   return("https://management.azure.com");
}


sub genReadAzureId
{
   my $self=shift;
   my $auth=shift;
   my $id=shift;

   my $d=$self->CollectREST(
      dbname=>'AZURE',
      useproxy=>1,
      url=>$id,
      requesttoken=>$id,
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
         if ($code eq "400"){
            my $json=eval('decode_json($content);');
            if ($@ eq "" && ref($json) eq "HASH" &&
                $json->{error}->{message} ne ""){
               $self->LastMsg(ERROR,$json->{error}->{message});
               return(undef);
            }
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data Azure response in genReadId");
         return(undef);
      }
   );
   return($d);
}







sub Ping
{
   my $self=shift;

   my $errors;
   my $d;
   # Ping is for checking backend connect, without any error displaying ...
   {
      open local(*STDERR), '>', \$errors;
      eval('
         my $Authorization=$self->getAzureAuthorizationToken();
         $d=$Authorization;
      ');
   }
   if (!defined($d) && !$self->LastMsg()){
      $self->LastMsg(ERROR,"bad Ping on Azure");
   }
   if (!$self->LastMsg()){
      if ($errors){
         my $gc=globalContext();  # and errors are silent transfered to LastMsg
         $gc->{LastMsg}=[] if (!exists($gc->{LastMsg}));
         foreach my $emsg (split(/[\n\r]+/,$errors)){
            push(@{$gc->{LastMsg}},$emsg);
         }
      }
   }

   return(0) if (!defined($d));
   return(1);

}



1;
