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
         #$dataobjattr.=".keyword";
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
                          wildcard=>{
                             "$dataobjattr"=>$sword
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

   $postData=$json->encode({query=>{bool=>$fullQuery}});

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


#         if ($fld->{RestFilterType} eq "SYSPARMQUERY"){
#            my $fieldname=$fn;
#            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
#            my @data;
#            my $fstr=$filter->{$fn};
#            if ($fld->Type()=~m/Date/){
#               $fstr=$self->PreParseTimeExpression($fstr,$fld->timezone());
#            }
#            $fstr=~s/\\\*/[|*|]/g;   # \* handling maybe wrong (02/2025)
#            $fstr=~s/\\/\\\\/g;      # \  handling maybe wrong (02/2025)
#            my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
#            if ($fstr ne "" && $#words==-1){
#               $self->LastMsg(ERROR,"parse error '$fstr'");
#               return(undef);
#            }
#
#            my @fieldQuery;
#            for(my $c=0;$c<=$#words;$c++){
#               my $sword=$words[$c];
#               foreach my $cword (qw(AND OR)){
#                  if ($sword eq $cword && $c>0 && $c<$#words){
#                     $self->LastMsg(ERROR,"concatenation $cword is not ".
#                                          "supported in sysparam_query ".
#                                          "translation");
#                     return(undef);
#                  }
#               }
#               my $cmpop="="; 
#               if ($sword=~m/^<=[^*?]+$/){
#                  $sword=~s/^<=//;
#                  $cmpop="<=";
#               }
#               elsif ($sword=~m/^>=[^*?]+$/){
#                  $sword=~s/^>=//;
#                  $cmpop=">=";
#               }
#               elsif ($sword=~m/^>[^*?]+$/){
#                  $sword=~s/^>//;
#                  $cmpop=">";
#               }
#               elsif ($sword=~m/^<[^*?]+$/){
#                  $sword=~s/^<//;
#                  $cmpop="<";
#               }
#               elsif ($sword=~m/^[^*?]+\*$/){
#                  my $fstrmod=$sword;
#                  $sword=~s/\*$//;
#                  $cmpop=" STARTSWITH";
#               }
#               elsif ($sword=~m/^\*[^*?]+$/){
#                  my $fstrmod=$sword;
#                  $sword=~s/^\*//;
#                  $cmpop=" ENDSWITH";
#               }
#               elsif ($sword=~m/^\*[^*?]+\*$/){
#                  my $fstrmod=$sword;
#                  $sword=~s/^\*//;
#                  $sword=~s/\*$//;
#                  $cmpop=" LIKE";
#               }
#               elsif ($sword=~m/[*?]/){
#                  $self->LastMsg(ERROR,
#                                 "selected wildcard filter can not be ".
#                                 "translated to sysparam_query");
#                  return(undef);
#               }
#
#
#               if ($fld->Type()=~m/Date/){
#                  my $raw=$self->ExpandTimeExpression($sword);
#
#                  if (defined($raw)){
#                     $raw=~s/ /','/;
#                  }
#                  else{
#                     $self->LastMsg(ERROR,
#                                    "selected date expression can not be ".
#                                    "translated to sysparam_query");
#                     return(undef);
#                  }
#                  $sword="javascript:gs.dateGenerate('${raw}.000Z')";
#               } 
#
#               push(@fieldQuery,"${fieldname}${cmpop}${sword}");
#            } 
#            push(@SYSPARMQUERYandList,join("^OR",@fieldQuery));
#
#
#
#         }
#         elsif ($fld->{RestFilterType} eq "SIMPLEQUERY"){
#            my $fieldname=$fn;
#            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
#            if (defined($fld->{RestFilterField})){
#               $fieldname=$fld->{RestFilterField};
#            }
#
#            my @data;
#            my $fstr=$filter->{$fn};
#            if (ref($fstr) eq "SCALAR"){
#               my @l=($$fstr);
#               $fstr=\@l;
#            }
#            elsif (ref($fstr) eq "ARRAY"){
#               foreach my $word (@$fstr){
#                  my $exp=$word;
#                  my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
#                  push(@data," $e");
#               }
#            }
#            else{
#               $fstr=~s/\*//g;
#               @data=($fstr);
#            }
#
#            $qparam{$fieldname}=join(" ",@data);
#
#         }
#         elsif ($fld->{RestFilterType} eq "SIMPLE"){
#            my $fieldname=$fn;
#            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
#            my @data;
#            my $fstr=$filter->{$fn};
#            if (ref($fstr) eq "SCALAR"){
#               my @l=($$fstr);
#               $fstr=\@l;
#            }
#            elsif (ref($fstr) eq "ARRAY"){
#               foreach my $word (@$fstr){
#                  my $exp="'".$word."'";
#                  my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
#                  push(@data,"$v eq $e");
#               }
#            }
#            else{
#               @data=($fstr);
#            }
#
#            $qparam{$fieldname}=join(" ",@data);
#
#         }
#         elsif ($fld->{RestFilterType} eq "ODATA"){
#            $isODATA++;
#            my @ODATAorLst;
#            my $fieldname=$fn;
#            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
#            $fieldname=$fld->{ODATA_filter} if (defined($fld->{ODATA_filter}));
#
#            #
#            # ToDo - in ODATA filters, SCALAR and ARRAY refs processing
#            #
#
#            my $fstr=$filter->{$fn};
#            if (ref($fstr) eq "SCALAR"){
#               my @l=($$fstr);
#               $fstr=\@l;
#            }
#            if (ref($fstr) eq "ARRAY"){
#               foreach my $word (@$fstr){
#                  my $exp="'".$word."'";
#                  my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
#                  push(@ODATAorLst,"$v eq $e");
#               }
#            }
#
#
#            my $isdate=0;
#            if (grep(/kernel::Field::Date/,
#                   Class::ISA::self_and_super_path($fld->Self))
#                   >0) {
#               $isdate=1;
#            }
#            if ($fld->{ODATA_constFilter}){
#               my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
#               $qparam{$fieldname}=join(",",@words);
#            }
#            else{
#               my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
#               for(my $c=0;$c<=$#words;$c++){
#                  if ($words[$c] eq "AND" || $words[$c] eq "OR"){
#                     $self->LastMsg(ERROR,
#                                    "no ODATA support for AND or OR");
#                     return(undef);
#                  }
#                  if ($words[$c]=~m/'/){
#                     $self->LastMsg(ERROR,
#                                    "no ODATA support for ".
#                                    "single quotes");
#                     return(undef);
#                  }
#                  my $val=$words[$c];
#                  my $compop="eq";
#                  my $compopcount=0;
#                  while($val=~m/^[<>]/){
#                     if ($compopcount>0){
#                        $self->LastMsg(ERROR,"illegal usage of ".
#                                             "comparison operator");
#                        return(undef);
#                     }
#                     if ($val=~m/^<=/){
#                        $val=~s/^<=//;
#                        $compop="le";
#                     }
#                     elsif ($val=~m/^</){
#                        $val=~s/^<//;
#                        $compop="lt";
#                     }
#                     elsif ($val=~m/^>=/){
#                        $val=~s/^>=//;
#                        $compop="ge";
#                     }
#                     elsif ($val=~m/^>/){
#                        $val=~s/^>//;
#                        $compop="gt";
#                     }
#
#                     elsif ($val=~m/^</){
#                        $val=~s/^<//;
#                        $compop="lt";
#                     }
#                     if ($val=~m/^>/){
#                        $val=~s/^>//;
#                        $compop="tg";
#                     }
#                     $compopcount++;
#                  }
#                  if ($isdate){
#                     my $tz=$fld->timezone();
#                     my $usertz=$self->UserTimezone();
#                     my $d=$self->ExpandTimeExpression(
#                            $val,"EDM", $usertz, $tz);
#                     return(undef) if (!defined($d));
#                     $val=$d;
#                  }
#                     my $exp="'".$val."'";
#                     my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
#                     push(@ODATAorLst,"$v $compop $e");
#               }
#            }
#            if ($#ODATAorLst!=-1){
#               push(@ODATAandLst,join(" or ",@ODATAorLst));
#            }
#         }
#         elsif (ref($fld->{RestFilterType}) eq "CODE"){
#            if ($const){  # works only with cons values (normaly IdField)
#               my $bk=&{$fld->{RestFilterType}}($fld,$filter->{$fn},
#                                                \%qparam,$constParam,$filter);
#            }
#         }
#      }
#   }

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
   msg(INFO,"Call ESgetAliases");
   my $credentialName=$self->getCredentialName();
   my ($baseurl,$ESpass,$ESuser)=$self->GetRESTCredentials($credentialName);
   if (($baseurl=~m#/$#)){
      $baseurl=~s#/$##;
   }
   my $cmd=join(" ",
         "curl -u '${ESuser}:${ESpass}' ",
         "--output - -s ",
         "-X GET '$baseurl/_alias'",
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

   my $session=$param->{session};
   $session={} if (!defined($session));

   my $baseCredName=$self->getCredentialName();
   my ($ESbaseurl,$ESpass,$ESuser)=$self->GetRESTCredentials($baseCredName);


   my ($out,$emsg)=$self->ESensureIndex($indexname,$ESindexDefinition);


   my ($meta,$metaemsg)=$self->ESmetaData();
   if (ref($meta) ne "HASH"){
      return($meta,$metaemsg);   
   }

   my ($restOrignMethod,$restOriginFinalAddr,$restOriginHeaders,$ESjqTransform)=$backcall->($session,$meta);

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

   if (ref($out) && $out->{acknowledged}){
      msg(INFO,"ESIndex '$indexname' is online starting import");
      my $cmd="curl -N ".
                  " -s ".$curlHeaderParam.
                  " --max-time 300 ".
                  "'$restOriginFinalAddr' ".
                  "| tee /tmp/Last.ElasticSearch.ESrestETLload | ".
                  "jq ".$jq_arg." ".        #--arg now '$nowstamp' ".
                  "-c '".$ESjqTransform."'".
                  "| ".
                  "curl -u '${ESuser}:${ESpass}' ".
                  "--output - -s ".
                  "-H 'Content-Type: application/x-ndjson' ".
                  "--data-binary \@- ".
                  "-X POST  '$ESbaseurl/$indexname/_bulk?refresh=wait_for' ".
                  '2>&1';

      #msg(INFO,"ORIGIN_Load: cmd=$cmd");
      my $out=qx($cmd);
      my $exit_code = $? >> 8;
      if ($exit_code==0){
         my $d;
         eval('use JSON; $d=decode_json($out);');
         if ($@ eq ""){
            # cleanup
            if (exists($param->{jq}->{arg})){ # store all jq ars in meta
               $self->ESmetaData($param->{jq}->{arg});
            }
            if (exists($session->{EScleanupIndex})){
               msg(INFO,"ESIndex '$indexname' cleanup");
               my ($out,$emsg)=$self->ESdeleteByQuery($indexname,{
                  range=>$session->{EScleanupIndex}
               });
               $self->ESmetaData({lastEScleanupIndex=>NowStamp("ISO")});
            }
            return($d);
         }
         else{
            return(-1,$@);
         }
      }
   }

}





1;
