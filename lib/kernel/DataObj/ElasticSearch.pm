package kernel::DataObj::ElasticSearch;
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::REST;

use JSON;
use Text::ParseWords;
use Digest::MD5 qw(md5_base64);
use MIME::Base64;

use POSIX ":sys_wait_h";

@ISA = qw(kernel::DataObj::REST);

sub new
{
   my $type=shift;

   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}


sub ESHash2Flt
{
   my $self=shift;
   my $fname=shift;
   my $filter=shift;


   my $res={must=>[],should=>[],minimum_should_match=>1};
   foreach my $fn (keys(%{$filter})){  # paas1 loop
      #msg(INFO,"ES: process filter field $fname -> $fn");
      my $bool={must=>[],should=>[],minimum_should_match=>1};
      my $fld=$self->getField($fn);
      if (defined($fld)){
         my $dataobjattr=$fn;
         if (defined($fld->{dataobjattr})){
            $dataobjattr=$fld->{dataobjattr};
         }
         $dataobjattr=~s/^_source\.//;
         if (exists($fld->{ElasticType}) && defined($fld->{ElasticType}) &&
             $fld->{ElasticType} eq "keyword"){
            $dataobjattr.=".keyword";
         }
         if (!ref($filter->{$fn})){
            my $fstr=$filter->{$fn};
            if ($fld->Type()=~m/Date/){
               $fstr=$self->PreParseTimeExpression($fstr,$fld->timezone());
               
            }
            my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
            if ($fstr ne "" && $#words==-1){
               $self->LastMsg(ERROR,"parse error '$fstr'");
               return(undef);
            }
            my $const=1;
            if (($fstr=~m/[ *?]/) || ($fstr=~m/^[<>!]/)){
               $const=0;
            }
            if ($dataobjattr eq "_id"){ # On ElasicSearch on _id no wildcard
               $const=1;                # filters posible
            }
            if ($const){
               push(@{$bool->{must}},{
                 match=>{
                    "$dataobjattr"=>$filter->{$fn}
                 }
               });
            }
            else{
               foreach my $sword (@words){
                  my $cmpop="="; 
                  if ($sword=~m/^<=[^*?]+$/){
                     $sword=~s/^<=//;
                     $cmpop="lte";
                  }
                  elsif ($sword=~m/^>=[^*?]+$/){
                     $sword=~s/^>=//;
                     $cmpop="gte";
                  }
                  elsif ($sword=~m/^>[^*?]+$/){
                     $sword=~s/^>//;
                     $cmpop="gt";
                  }
                  elsif ($sword=~m/^<[^*?]+$/){
                     $sword=~s/^<//;
                     $cmpop="lt";
                  }

                  if ($fld->Type()=~m/Date/){
                     my $raw=$self->ExpandTimeExpression($sword);
                
                     if (!defined($raw)){
                        $self->LastMsg(ERROR,
                                       "selected date expression can not be ".
                                       "translated to sysparam_query");
                        return(undef);
                     }
                     $raw=~s/ /T/;
                     $raw.="Z";
                     push(@{$bool->{must}},{
                       range=>{
                          "$dataobjattr"=>{
                             "$cmpop"=>$raw
                          }
                       }
                     });



                  } 
                  if ($cmpop eq "="){
                     if ($sword=~m/[*?]/){
                        push(@{$bool->{should}},{
#                          wildcard=>{
#                             "$dataobjattr"=>$sword
#                          }
                          wildcard=>{
                             "$dataobjattr"=>{
                                value=>$sword,
                                case_insensitive=>
                                  bless( do{\(my $o = 1)},'JSON::PP::Boolean')
                             }
                          }
                        });
                     }
                     else{
                        push(@{$bool->{should}},{
                          match=>{
                             "$dataobjattr"=>$sword
                          }
                        });
                     }
                  }


               }

            }
         }
         if (ref($filter->{$fn}) eq "SCALAR"){
            $filter->{$fn}=[${$filter->{$fn}}];
         }
         if (ref($filter->{$fn}) eq "ARRAY"){
            my @should;
            foreach my $val (@{$filter->{$fn}}){
               #push(@should,{
               #  match=>{
               #     $fn=>$val
               #  }
               #});
               push(@should,{
                 match=>{
                    "$dataobjattr"=>$val
                 }
               });
            }
            push(@{$bool->{should}},@should); 
         }
         if ($#{$bool->{should}}==-1){
            delete($bool->{should});
            delete($bool->{minimum_should_match});
         }
         if ($#{$bool->{must}}==-1){
            delete($bool->{must});
         }

         push(@{$res->{must}},{bool=>$bool});
      }
      else{
        msg(WARN,"ElasticSarchFilter: unkown filter attribute $fn");
      }
   }
   if ($#{$res->{should}}==-1){
      delete($res->{should});
      delete($res->{minimum_should_match});
   }
   return($res);

}






sub Filter2RestPath
{
   my $self=shift;
   my $indexname=shift;
   my $filterSet=shift;
   my $param=shift;
   my $postData;

   my $pathTmpl=[
      "/".$indexname."/_doc/{id}",
      "/".$indexname."/_search"
   ];

   my $restFinalAddr=$pathTmpl;
   my $constParam={};
   my $requesttoken=undef;
   my %qparam;

   if (ref($param) eq "HASH" && ref($param->{initQueryParam}) eq "HASH"){
      %qparam=%{$param->{initQueryParam}};
   }

   my $filterCnt=0;

   my $fullQuery={must=>[],should=>[],minimum_should_match=>1};


   foreach my $fname (keys(%$filterSet)){
      my $filterBlock=$filterSet->{$fname};
      $filterBlock=[$filterBlock] if (ref($filterBlock) ne "ARRAY");
      #msg(INFO,"ES: start processich filterblock $fname");
      my $localfnameQuery={must=>[],should=>[],minimum_should_match=>1};
      foreach my $filter (@$filterBlock){
         my $ESfltBlk=$self->ESHash2Flt($fname,$filter);
         push(@{$localfnameQuery->{should}},{bool=>$ESfltBlk});
      }
      if ($#{$localfnameQuery->{should}}==-1){
         delete($localfnameQuery->{should});
         delete($localfnameQuery->{minimum_should_match});
      }
      if ($#{$localfnameQuery->{must}}==-1){
         delete($localfnameQuery->{must});
      }
      push(@{$fullQuery->{must}},{bool=>$localfnameQuery});
   }

   if ($#{$fullQuery->{should}}==-1){
      delete($fullQuery->{should});
      delete($fullQuery->{minimum_should_match});
   }
   if ($#{$fullQuery->{must}}==-1){
      delete($fullQuery->{must});
   }



   my $json;
   eval('use JSON;$json=new JSON;');
   $json->property(pretty => 1);
   $json->property(utf8 => 1);

   print STDERR Dumper({query=>{bool=>$fullQuery}});

   $postData=$json->encode({query=>{bool=>$fullQuery}});
printf STDERR ("postData=%s\n",$postData);

#   $postData='
#
#{
#  "query": {
#    "term": {
#      "ictoNumber.keyword": "ICTO-21743"
#    }
#  }
#}
#
#';




   
#   # ToDo: check if ODATA filtering - if yes, allow in simplifyFilterSet
#   #       flat SCALAR and ARRAY values
#
   my $simplifyParam=[];

   my ($filter,$queryToken)=$self->simplifyFilterSet($filterSet,$simplifyParam);
   return(undef) if (!defined($filter));


#   foreach my $fn (keys(%{$filter})){  # paas1 loop
#      my $fld=$self->getField($fn);
#      if (defined($fld)){
#         my $const=1;
#         if ($filter->{$fn}=~m/[ *?]/){
#            $const=0;
#         }
#         if (ref($fld->{RestFilterType}) eq "CODE"){
#            if ($const){  # works only with cons values (normaly IdField)
#               my $bk=&{$fld->{RestFilterType}}($fld,$filter->{$fn},
#                                                \%qparam,$constParam,$filter);
#            }
#         }
#         if (ref($fld->{RestFilterType}) eq "ARRAY"){  # idpath default handling
#            my $RestFilterPathSep=$fld->{RestFilterPathSep};
#            if ($RestFilterPathSep eq ""){
#               $RestFilterPathSep='@';
#            }
#            if ($const){
#               my @pathVar=split($RestFilterPathSep,$filter->{$fn});
#               for(my $c=0;$c<=$#{$fld->{RestFilterType}};$c++){
#                  my $pvar=$fld->{RestFilterType}->[$c];
#                   $filter->{$pvar}=$pathVar[$c];
#               }
#               delete($filter->{$fn});
#            }
#         }
#      }
#   }

   # Handling Const-Parameters in restFinalAddr
   foreach my $fn (keys(%{$filter})){
      my $fld=$self->getField($fn);
      if (defined($fld)){
         my $const=1;
         my $constVal=$filter->{$fn};

         if (ref($constVal) eq "ARRAY" && $#{$constVal}==0){
            $constVal=$constVal->[0];
         }
         else{
            if ($constVal=~m/[ *?]/){
               $const=0;
            }
         }
         if ($const){
            my $constHandeled=0;
            $constParam->{$fn}=$filter->{$fn};
            foreach my $subRestFinalAddr (@{$restFinalAddr}){
               if ($subRestFinalAddr=~m/\{$fn\}/){
                  $subRestFinalAddr=~s/\{$fn\}/$constVal/g;
                  $constHandeled++;
               }
            }
            if ($constHandeled){
               delete($filter->{$fn});
               $postData=undef;
            }
         }
      }
   }


   my $restFinalAddrString=$restFinalAddr->[0];
   if (grep(/\{[^{}]+\}/,@$restFinalAddr)){
      my $c=0;
      for($c=0;$c<=$#{$restFinalAddr};$c++){
         my $subRestFinalAddr=$restFinalAddr->[$c];
         my @varlist;
         while ($subRestFinalAddr =~ /\{([^{}]+)\}/g) {
             my $fn=$1;
             my $fld=$self->getField($fn);
             if (defined($fld)){
                $fn=$fld->Label();
             }
             push(@varlist,$fn);
         }
         if (!($subRestFinalAddr =~ /\{([^{}]+)\}/)){
            last;
         }
         if ($c==$#{$restFinalAddr}){
            if ($#varlist>0){
               $self->LastMsg(ERROR,"missing constant query '%s' parameters ".
                                    "at ".$self->Self(),
                                    join(",",@varlist));
            }
            else{
               $self->LastMsg(ERROR,"missing constant query '%s' parameter ".
                                    "at ".$self->Self(),
                                    join(",",@varlist));
            }
            return(undef);
         }
      }
      $restFinalAddrString=$restFinalAddr->[$c];
      if ($restFinalAddrString=~m/_search$/){
         my $LimitBackend=$self->LimitBackend();
         $LimitBackend=10000  if ($LimitBackend==0);
         $LimitBackend=10000  if ($LimitBackend>10000);
         $qparam{'size'}=$LimitBackend;
      }
   }

   my $qstr=kernel::cgi::Hash2QueryString(%qparam);

   if ($qstr ne ""){
      if ($restFinalAddrString=~m/\?/){
         $restFinalAddrString.="&".$qstr;
      }
      else{
         $restFinalAddrString.="?".$qstr;
      }
   }
   $requesttoken=md5_base64($restFinalAddrString.$postData);

   return($restFinalAddrString,$requesttoken,$constParam,$postData);
}


sub ESindexName
{
   my $self=shift;

   my $indexname=lc($self->Self());
   $indexname=~s/:/_/g;
   return($indexname);
}

sub ESgetAliases
{
   my $self=shift;

   #msg(INFO,"Call ESgetAliases");
   my $credentialName=$self->getCredentialName();
   my ($baseurl,$ESuser,$ESpass)=$self->GetRESTCredentials($credentialName);
   if (($baseurl=~m#/$#)){
      $baseurl=~s#/$##;
   }
   $baseurl.="/_alias";
   my $headers=[
      Authorization =>'Basic '.encode_base64($ESpass.':'.$ESuser)
   ];

   my @data;
   my $errors;
   if (1){
      open local(*STDERR), '>', \$errors;
      eval('
         @data=$self->DoRESTcall(
            method=>\'GET\',
            headers=>$headers,
            url=>$baseurl
         );
      ');
      if (ref($data[0]) ne "HASH"){
         if (!$self->LastMsg()){
            $self->Log(ERROR,"backlog",
                             "fail to Elasic Ping to $credentialName");
         }
      }
      if (!$self->LastMsg()){
         if ($errors){
            foreach my $emsg (split(/[\n\r]+/,$errors)){
               $self->SilentLastMsg(ERROR,$emsg);
            }
         }
      }
   }

   if (ref($data[0]) eq "HASH"){
      return($data[0]);
   }
   
   return(-1,"HTTP Error $data[1] $data[2]");
}

sub EScreateIndex
{
   my $self=shift;
   my $indexname=shift;
   my $param=shift;

   my $credentialName=$self->getCredentialName();
   my ($baseurl,$ESpass,$ESuser)=$self->GetRESTCredentials($credentialName);

   my $strparam;
   my $json;
   eval('use JSON;$json=new JSON;');
   $json->utf8(1);
   my $strparam=$json->encode($param);


   my $cmd=join(" ",
         "curl -u '${ESuser}:${ESpass}' ",
         "--output - -s ",
         "-d '$strparam' ",
         "-H 'Content-Type: application/json' ",
         "-X PUT '$baseurl/$indexname'",
         "2>&1"
   );
   my $out=qx($cmd);
   my $exit_code = $? >> 8;


   if ($exit_code==0){
      my $d;
      eval('use JSON; $d=decode_json($out);');
      if ($@ eq ""){
         return($d);
      }
      else{
         return(-1,$@);
      }
   }
   return($exit_code,$out);
}

sub ESdeleteIndex
{
   my $self=shift;
   my $indexname=shift;
   if (!defined($indexname)){
      $indexname=$self->ESindexName();
   }

   my $credentialName=$self->getCredentialName();
   my ($baseurl,$ESpass,$ESuser)=$self->GetRESTCredentials($credentialName);

   my $cmd=join(" ",
         "curl -u '${ESuser}:${ESpass}' ",
         "--output - -s ",
         "-X DELETE '$baseurl/$indexname'",
         "2>&1"
   );
   my $out=qx($cmd);
   my $exit_code = $? >> 8;


   if ($exit_code==0){
      my $d;
      eval('use JSON; $d=decode_json($out);');
      if ($@ eq ""){
         return($d);
      }
      else{
         return(-1,$@);
      }
   }
   return($exit_code,$out);
}




sub ESdeleteByQuery
{
   my $self=shift;
   my $indexname=shift;
   my $query;
   if (ref($indexname) eq "HASH"){
      $query=$indexname;
      $indexname=$self->ESindexName();
   }
   else{
      $query=shift;
   }

   msg(INFO,"ESdeleteByQuery start in $indexname");
   my $credentialName=$self->getCredentialName();
   my ($baseurl,$ESpass,$ESuser)=$self->GetRESTCredentials($credentialName);

   my $strquery;
   my $json;
   eval('use JSON;$json=new JSON;');
   $json->utf8(1);
   my $strquery=$json->encode($query);


   my $cmd=join(" ",
         "curl -u '${ESuser}:${ESpass}' ",
         "--output - -s ",
         "-d '{\"query\":$strquery}' ",
         "-H 'Content-Type: application/json' ",
         "-X POST '$baseurl/$indexname/_delete_by_query'",
         "2>&1"
   );
   msg(INFO,"ESdeleteByQuery cmd=$cmd");
   my $out=qx($cmd);
   my $exit_code = $? >> 8;

   if ($exit_code==0){
      my $d;
      eval('use JSON; $d=decode_json($out);');
      if ($@ eq ""){
         msg(INFO,"ESdeleteByQuery finished $indexname OK");
         return($d);
      }
      else{
         return(-1,$@);
      }
   }
   return($exit_code,$out);
}

sub ESensureIndex
{
   my $self=shift;
   my $indexname=shift;
   my $param;
   if (ref($indexname) eq "HASH"){
      $param=$indexname;
      $indexname=$self->ESindexName();
   }
   else{
      $param=shift;
   }

   my ($out,$emsg)=$self->ESgetAliases();
   if (ref($out)){
      if (!exists($out->{$indexname})){
         msg(INFO,"try to create missing index $indexname");
         my ($out,$emsg)=$self->EScreateIndex($indexname,$param);
         return($out,$emsg);
      }
      else{
         my ($meta,$emsg)=$self->ESmetaData();
         if (ref($meta) ne "HASH"){
            return($meta,$emsg);
         }
         my $definitionHash;
         my $json;
         eval('use JSON;$json=new JSON;');
         $json->utf8(1);
         my $definitionHash=md5_base64($json->encode($param));


         my $vField="DefinitionHash";
         my $vValue=$definitionHash;
         if (exists($param->{mappings}) && 
             exists($param->{mappings}->{_meta}) &&
             exists($param->{mappings}->{_meta}->{version})){
            $vField="version";
            $vValue=$param->{mappings}->{_meta}->{version};;
            msg(INFO,"ESensureIndex: using version mapping");
         }

         if ($meta->{$vField} eq ""){
            msg(INFO,"ESensureIndex: store missing $vField=$vValue");
            $self->ESmetaData({$vField=>$vValue});
         }
         if ($meta->{$vField} ne $vValue){
            msg(INFO,"ESensureIndex: recreate index due $vField ".
                     "change from '$meta->{$vField}' to '$vValue'");
            my ($out,$emsg)=$self->ESdeleteIndex();
            if (ref($out) ne "HASH"){
               return($out,$emsg);
            }
            my ($out,$emsg)=$self->EScreateIndex($indexname,$param);
            if (ref($out) ne "HASH"){
               return($out,$emsg);
            }
            $self->ESmetaData({DefinitionHash=>$definitionHash});
            return($out,$emsg);
           
         }
      }
      return({'acknowledged'=>bless( do{\(my $o = 1)},'JSON::PP::Boolean')});
   }
   return($out,$emsg);
}

sub ESmetaData
{
   my $self=shift;
   my $indexname=shift;
   my $param;
   if (ref($indexname) eq "HASH"){
      $param=$indexname;
      $indexname=$self->ESindexName();
   }
   else{
      $param=shift;
   }
   if ($indexname eq ""){
      $indexname=$self->ESindexName();
   }

   my $credentialName=$self->getCredentialName();
   my ($baseurl,$ESpass,$ESuser)=$self->GetRESTCredentials($credentialName);

   my ($out,$emsg);
   if (!defined($param)){
     
      my $cmd=join(" ",
            "curl -u '${ESuser}:${ESpass}' ",
            "--output - -s ",
            "-X GET '$baseurl/$indexname/_mapping'",
            "2>&1"
      );
      msg(INFO,"ESmeta query $indexname");
      my $out=qx($cmd);
      my $exit_code = $? >> 8;
     
      if ($exit_code==0){
         my $d;
         eval('use JSON; $d=decode_json($out);');
         if ($@ eq ""){
            if (!exists($d->{$indexname}->{mappings}->{_meta})){
               $d->{$indexname}->{mappings}->{_meta}={};
            }
            return($d->{$indexname}->{mappings}->{_meta});
         }
         else{
            return(-1,$@);
         }
      }
   }
   else{

      my ($cparam,$emsg)=$self->ESmetaData($indexname);
      if (ref($cparam) ne "HASH"){
         return($cparam,$emsg);
      }
      foreach my $k (keys(%$param)){
         $cparam->{$k}=$param->{$k};
      }
      my $strquery;
      my $json;
      eval('use JSON;$json=new JSON;');
      $json->utf8(1);
      msg(INFO,"ESmeta store at $indexname ".Dumper($cparam));
      my $strquery=$json->encode({_meta=>$cparam});
      my $cmd=join(" ",
            "curl -u '${ESuser}:${ESpass}' ",
            "--output - -s ",
            "-d '$strquery' ",
            "-H 'Content-Type: application/json' ",
            "-X POST '$baseurl/$indexname/_mapping'",
            "2>&1"
      );
      my $out=qx($cmd);
      my $exit_code = $? >> 8;
     
      if ($exit_code==0){
         my $d;
         eval('use JSON; $d=decode_json($out);');
         if ($@ eq ""){
            return($d);
         }
         else{
            return(-1,$@);
         }
      }
   }


#      my $strquery;
#      my $json;
#      eval('use JSON;$json=new JSON;');
#      $json->utf8(1);
#      my $strquery=$json->encode($query);
     


   return($out,$emsg);
}


sub ESrestETLload
{
   my $self=shift;
   my $ESindexDefinition=shift;
   my $backcall=shift;
   my $indexname=shift;
   my $param=shift;

   msg(INFO,"ESrestETLload: start load for $indexname");
   my $session=$param->{session};
   $session={} if (!defined($session));

   my $baseCredName=$self->getCredentialName();
   my ($ESbaseurl,$ESpass,$ESuser)=$self->GetRESTCredentials($baseCredName);


   my ($out,$emsg)=$self->ESensureIndex($indexname,$ESindexDefinition);

   my @loopResults;
   if (ref($out) && $out->{acknowledged}){
      my ($meta,$metaemsg)=$self->ESmetaData();
      if (ref($meta) ne "HASH"){
         return($meta,$metaemsg);   
      }
      my $loopCount=0;
      while(!exists($session->{loopBreak})){
         $session->{loopCount}=$loopCount;
       
         my ($restOrignMethod,$restOriginFinalAddr,
             $restOriginHeaders,$ESjqTransform)=$backcall->($session,$meta);
         last if (!defined($restOrignMethod) || $restOrignMethod eq "BREAK");
       
         my $i;
         my $curlHeaderParam=join("",map({
           $i++;
           ($i % 2==0) ? "-H '".join(':',@$restOriginHeaders[$i-2],$_)."' ":()
         } @$restOriginHeaders));
       
         my $jq_arg="";
         if (exists($param->{jq}) && exists($param->{jq}->{arg})){
            $jq_arg=join(" ",map({
                                   "--arg ".$_." '".$param->{jq}->{arg}->{$_}."'"
                                 } keys(%{$param->{jq}->{arg}}))); 
         }
       
         msg(INFO,"ESIndex '$indexname' is OK start import - loop=$loopCount");
         my $tmpLastRequestRawDump="last.ESrestETLload.$indexname.".
                                   $loopCount.".raw.dump.tmp";
         my $tmpLastRequestJqDump="last.ESrestETLload.$indexname.".
                                   $loopCount.".jq.dump.tmp";
         my $ESwaitfor="?refresh=wait_for";
         if (exists($session->{LastRequest}) && $session->{LastRequest}==0){
            $ESwaitfor="";
         }
         my $cmd="curl -N ".
                     " -s ".$curlHeaderParam.
                     " --max-time 300 ".
                     "'$restOriginFinalAddr' ".
                     "| tee /tmp/".$tmpLastRequestRawDump." | ".
                     "jq ".$jq_arg." ".        #--arg now '$nowstamp' ".
                     "-c '".$ESjqTransform."'".
                     "| tee /tmp/".$tmpLastRequestJqDump." | ".
                     "curl -u '${ESuser}:${ESpass}' ".
                     "--output - -s ".
                     "-H 'Content-Type: application/x-ndjson' ".
                     "--data-binary \@- ".
                     "-X POST  '$ESbaseurl/$indexname/_bulk".$ESwaitfor."' ".
                     '2>&1';
       
         msg(INFO,"ORIGIN_Load: cmd=$cmd");
         my $out=qx($cmd);
         my $exit_code = $? >> 8;
         if ($exit_code!=0){
            return($exit_code,$@);
         }
         my $d;
         eval('use JSON; $d=decode_json($out);');
         msg(INFO,"out=$out");
         if ($@ eq ""){
            if (ref($d) eq "HASH"){
               my %localSession=%{$session};
               $localSession{'acknowledged'}=
                              bless( do{\(my $o = 1)},'JSON::PP::Boolean');
               push(@loopResults,\%localSession);
            }
         }
         else{
           return(-1,"ERROR: $@");
         }
         if (!exists($session->{LastRequest})){  # LastRequest must be set to
            last;                                # 0|1 if we want to do a loop
         }
         $session->{lastRequestRawDumpFile}=$tmpLastRequestRawDump;
         $session->{lastRequestJqDumpFile}=$tmpLastRequestJqDump;
         $loopCount++;
      }
   }
   else{
      return($out,$emsg);
   }

   if (exists($param->{jq}->{arg})){ # store all jq ars in meta
      $self->ESmetaData($param->{jq}->{arg});
   }
   if (exists($session->{EScleanupIndex})){
      msg(INFO,"ESIndex '$indexname' ESdeleteByQuery");
      my ($out,$emsg)=$self->ESdeleteByQuery($indexname,
         $session->{EScleanupIndex}
      );
      $self->ESmetaData({lastEScleanupIndex=>NowStamp("ISO")});
   }
   else{
      # generell cleanup removes _noop_ _id records (dummies while loading
      # emtpy datasets with jq)
      my ($out,$emsg)=$self->ESdeleteByQuery($indexname,
         {
          bool=>{
            should=>[
               {
                 match=>{
                    _id=>'__noop__'
                 }
               }
            ],
            'minimum_should_match'=>'1'
          }
        }
      );
   }
   return({
      'acknowledged'=>bless( do{\(my $o = 1)},'JSON::PP::Boolean'),
      'session'=>\@loopResults
   });
}


sub getCredentialName
{
   my $self=shift;
   my $mod=$self->Self();
   $mod=~s/::.*$//;

   return($mod);
}




# Default DataCollector for ElasicSearch 



sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my $indexname=$self->ESindexName();

   my ($restFinalAddr,$requesttoken,$constParam,$data)=
      $self->Filter2RestPath(
         $indexname,$filterset
   );
   if (!defined($restFinalAddr)){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"unknown error while create restFinalAddr");
      }
      return(undef);
   }

   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      data=>$data,
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apiuser=shift;
         my $headers=[
            Authorization =>'Basic '.encode_base64($apiuser.':'.$apikey)
         ];
         if ($data ne ""){
            push(@$headers,"Content-Type","application/json");
         }
         return($headers);
      },
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apipass=shift;
         my $dataobjurl=$baseurl.$restFinalAddr;
         msg(INFO,"ESqueryURL=$dataobjurl");
         return($dataobjurl);
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
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data from backend %s",$self->Self());
         return(undef);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         #print STDERR Dumper($data);
         if (ref($data) eq "HASH"){
            if (exists($data->{hits})){
               if (exists($data->{hits}->{hits})){
                  $data=$data->{hits}->{hits};
               }
            }
            else{
               $data=[$data]
            }
         }
         #print STDERR Dumper($data->[0]);
         map({
            $_=FlattenHash($_);
            if ($self->can("ESprepairRawRecord")){
               $self->ESprepairRawRecord($_);
            }
         } @$data);
         return($data);
      }
   );
   return($d);
}


sub InsertRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   print STDERR "InsertRecord:".Dumper($newdata)."\n";
#   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my $idobj=$self->IdField();
   my $idfield=$idobj->Name();
   my $id;

   return(undef);
}

#   my ($worktable,$workdb)=$self->getWorktable();
#   $workdb=$self->{DB} if (!defined($workdb));
#
#   if (!defined($worktable) || $worktable eq ""){
#      $self->LastMsg(ERROR,"can't InsertRecord in $self - no Worktable");
#      return(undef);
#   }
#   if (!defined($workdb)){
#      $self->LastMsg(ERROR,"can't InsertRecord in $self - no workdb");
#      return(undef);
#   }
#   if (!defined($newdata->{$idfield})){
#      if ($idobj->autogen==1){
#         my $res=$self->W5ServerCall("rpcGetUniqueId");
#         my $retry=30;
#         while(!defined($res=$self->W5ServerCall("rpcGetUniqueId"))){
#            sleep(1);
#            last if ($retry--<=0);
#            # next lines are a test, to handle break of W5Server better
#            if (getppid()==1){  # parent (W5Server) killed in event context
#               msg(ERROR,"Parent Process is killed - not good in DB.pm !");
#               return();
#            }
#            msg(WARN,"W5Server problem for user $ENV{REMOTE_USER} ($retry)");
#         }
#         if (defined($res) && $res->{exitcode}==0){
#            $id=$res->{id};
#         }
#         else{
#            msg(ERROR,"InsertRecord: W5ServerCall returend %s",Dumper($res));
#            $self->LastMsg(ERROR,"W5Server unavailable ".
#                          "- can't get unique id - ".
#                          "please try later or contact the admin");
#            return(undef);
#         }
#         $newdata->{$idfield}=$id;
#      }
#   }
#   else{
#      $id=$newdata->{$idfield};
#   }
#   my %raw=$self->QuoteHashData("insert",$workdb,oldrec=>undef,
#                                current=>$newdata);
#   my $cmd;
#   #   if ($self->{UseSqlReplace}==1){  # bisher kein alternatives Verhalten
#   #                                    # im SQL Replace modus !!!
#   #   }                                # Kann ansonsten probleme im Arikel
#   {                                    # Katalog geben
#      my @flist=keys(%raw);
#      $cmd="insert into $worktable (".
#           join(",",@flist).") ".
#           "values(".join(",",map({$raw{$_}} @flist)).")";
#   }
#   #msg(INFO,"fifi InsertRecord data=%s into '$worktable'\n",Dumper($newdata));
#   if (length($cmd)<65535){
#      $self->Log(INFO,"sqlwrite",$cmd);
#   }
#   else{
#      $self->Log(INFO,"sqlwrite","(long insert >64k)");
#   }
#   $workdb->{deadlockHandler}=1;
#   my $bk=$workdb->do($cmd);
#   if (!$bk){
#      my $retrycnt=0;
#      while(my $retryErrorNo=_checkCommonRetryErrors($workdb->getErrorMsg())){
#        $retrycnt++;
#        if ($retrycnt>1){
#           if ($retryErrorNo==1){
#              msg(ERROR,"found Deadlock - retry $retrycnt");
#           }
#        }
#        sleep($retrycnt); # increase the sleep
#        $bk=$workdb->do($cmd);
#        last if ($bk);
#        if ($retryErrorNo==1 && $retrycnt>4){
#           msg(ERROR,"Deadlock problem - giving up");
#           last;
#        }
#        if ($retryErrorNo==2 && $retrycnt>4){
#           msg(ERROR,"readonly problem - giving up");
#           last;
#        }
#        {
#           msg(INFO,"do sleep for $retryErrorNo with $retrycnt*$retrycnt for:".
#                    $cmd);
#           sleep($retrycnt*$retrycnt); # 1 4 9 16 sleeps (in sum 30sec)
#        }
#      }
#   }
#   delete($workdb->{deadlockHandler});
#   if ($bk){
#      $workdb->finish();
#      if (!defined($id)){
#         # id was not created by w5base, soo we need to read it from the
#         # table
#         # getHashList
#         my $cmd;
#         my %q=();
#         my @fieldlist=$self->getFieldList();
#         foreach my $field (@fieldlist){
#            my $fo=$self->getField($field);
#            if ($fo->{id} && defined($fo->{dataobjattr})){
#               if (defined($newdata->{$fo->{name}})){
#                  $q{$fo->{dataobjattr}}=$workdb->quotemeta(
#                                      $newdata->{$fo->{name}});
#               }
#               else{
#                  $q{$fo->{dataobjattr}}="NULL";
#               }
#            }
#         }
#         if (defined($idobj->{dataobjattr}) &&          # id is automatic gen
#             ref($idobj->{dataobjattr}) ne "ARRAY"){    # by the database 
#            if (keys(%q)==0){     # SCOPE_IDENTIY should work on ODBC databases
#               my @l;
#               if (lc($self->{DB}->{db}->{Driver}->{Name}) eq "mysql"){
#                  @l=$workdb->getArrayList("select LAST_INSERT_ID()");
#               }
#               else{
#                  @l=$workdb->getArrayList("select SCOPE_IDENTITY()");
#               }
#               my $rec=pop(@l);
#               if (defined($rec)){
#                  $id=$rec->[0];
#               }
#            }
#            else{
#               $cmd="select $idobj->{dataobjattr} from $worktable ".
#                    "where ".join(" and ",map({$_.="=".$q{$_}} keys(%q)));
#               msg(INFO,"reading id by=%s",$cmd);
#               my @l=$workdb->getArrayList($cmd);
#               my $rec=pop(@l);
#               if (defined($rec)){
#                  $id=$rec->[0];
#               }
#            }
#         }
#         if (defined($idobj->{dataobjattr}) &&          # no one simple unique
#             ref($idobj->{dataobjattr}) eq "ARRAY"){    # ... id more fields
#          #  $cmd="select $idobj->{dataobjattr} from $worktable ".
#          #       "where ".join(" and ",map({$_.="=".$q{$_}} keys(%q)));
#          #  msg(INFO,"reading id by=%s",$cmd);
##
##            my @l=$workdb->getArrayList($cmd);
##            my $rec=pop(@l);
##            if (defined($rec)){
##               $id=$rec->[0];
##            }
#         }
#         if (!defined($id)){
#            $self->LastMsg(ERROR,"no record identifier returned by insert");
#         }
#      }
#      return($id);
#   }
#   $self->LastMsg(ERROR,$self->preProcessDBmsg($workdb->getErrorMsg()));
#   return(undef);
#}
#
#



sub Ping
{
   my $self=shift;

   my $credentialN=$self->getCredentialName();

   msg(INFO,"Ping-Start: $credentialN");
   my ($out,$emsg)=$self->ESgetAliases();
   if (ref($out) eq "HASH"){
      my $indexname=$self->ESindexName();
      if ($indexname ne ""){
         if (!exists($out->{$indexname})){
            if ($self->can("getESindexDefinition")){
               my $indexDef=$self->getESindexDefinition();
               my ($out,$emsg)=$self->EScreateIndex($indexname,$indexDef);
               if (ref($out) ne "HASH"){
                  return(0);
               }
            }
         }
      }
      return(1);
   }
   return(0);
}






1;
