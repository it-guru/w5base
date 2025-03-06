package kernel::DataObj::REST;
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
use kernel::DataObj::Static;

use JSON;
use Text::ParseWords;

use POSIX ":sys_wait_h";

@ISA = qw(kernel::DataObj::Static);

sub new
{
   my $type=shift;

   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}



sub Initialize
{
   my $self=shift;
   $self->{'data'}=\&_DataCollector;
   return(1);
}


sub _DataCollector
{
   my $self=shift;

   return($self->DataCollector(@_));
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;
   msg(ERROR,"default DataCollector called in $self");
   return(undef);
}


sub Filter2RestPath
{
   my $self=shift;
   my $pathTmpl=shift;
   my $filterSet=shift;
   my $param=shift;

   my $restFinalAddr=$pathTmpl;
   if (ref($restFinalAddr) ne "ARRAY"){
      $restFinalAddr=[$pathTmpl];
   }
   my $constParam={};
   my $requesttoken=undef;
   my %qparam;

   if (ref($param) eq "HASH" && ref($param->{initQueryParam}) eq "HASH"){
      %qparam=%{$param->{initQueryParam}};
   }


   my $isODATA=0;
   my @ODATAandLst;

   my $isSIMPLE=0;

   my $filterCnt=0;

   
   my $isSYSPARMQUERY=0;
   my @SYSPARMQUERYandList;
   

   foreach my $fname (keys(%$filterSet)){
      my $filterBlock=$filterSet->{$fname};
      $filterBlock=[$filterBlock] if (ref($filterBlock) ne "ARRAY");
      foreach my $filter (@$filterBlock){
         $filterCnt++;
         foreach my $fn (keys(%{$filter})){  # paas1 loop
            my $fld=$self->getField($fn);
            if (defined($fld)){
               if ($fld->{RestFilterType} eq "ODATA"){
                  $isODATA++;
               }
               if ($fld->{RestFilterType} eq "SYSPARMQUERY"){
                  $isSYSPARMQUERY++;
               }
               if ($fld->{RestFilterType} eq "SIMPLE"){
                  $isSIMPLE++;
               }
            }
         }
      }
   }
   if ($isSIMPLE && $isSYSPARMQUERY){
      $self->LastMsg(ERROR,"RestFilterType SIMPLE and SYSPARMQUERY can not ".
                           "be used together in the same call");
      return(undef); 

   }
   if ($filterCnt>1){
      $self->LastMsg(ERROR,"DATAOBJ::REST only support one dimension filters");
      return(undef); 

   }

   
   # ToDo: check if ODATA filtering - if yes, allow in simplifyFilterSet
   #       flat SCALAR and ARRAY values

   my $simplifyParam=[];
   if ($isSYSPARMQUERY){  # in SYSPARMQUERY quoates ca be handled correct
      push(@{$simplifyParam},"NOREMOVEQUOTES");
   }

   my ($filter,$queryToken)=$self->simplifyFilterSet($filterSet,$simplifyParam);
   return(undef) if (!defined($filter));


   foreach my $fn (keys(%{$filter})){  # paas1 loop
      my $fld=$self->getField($fn);
      if (defined($fld)){
         my $const=1;
         if ($filter->{$fn}=~m/[ *?]/){
            $const=0;
         }
         if (ref($fld->{RestFilterType}) eq "CODE"){
            if ($const){  # works only with cons values (normaly IdField)
               my $bk=&{$fld->{RestFilterType}}($fld,$filter->{$fn},
                                                \%qparam,$constParam,$filter);
            }
         }
         if (ref($fld->{RestFilterType}) eq "ARRAY"){  # idpath default handling
            my $RestFilterPathSep=$fld->{RestFilterPathSep};
            if ($RestFilterPathSep eq ""){
               $RestFilterPathSep='@';
            }
            if ($const){
               my @pathVar=split($RestFilterPathSep,$filter->{$fn});
               for(my $c=0;$c<=$#{$fld->{RestFilterType}};$c++){
                  my $pvar=$fld->{RestFilterType}->[$c];
                   $filter->{$pvar}=$pathVar[$c];
               }
               delete($filter->{$fn});
            }
         }
      }
   }
   foreach my $fn (keys(%{$filter})){
      my $fld=$self->getField($fn);
      if (defined($fld)){
         my $const=1;
         if ($filter->{$fn}=~m/[ *?]/){
            $const=0;
         }
         if ($const){
            my $constHandeled=0;
            $constParam->{$fn}=$filter->{$fn};
            foreach my $subRestFinalAddr (@{$restFinalAddr}){
               if ($fld->{RestFilterType} eq "CONST2PATH"){
                  $subRestFinalAddr.="/" if (!($subRestFinalAddr=~m/\/$/));
                  $subRestFinalAddr.=$filter->{$fn};
                  $constHandeled++;
               }
               if ($subRestFinalAddr=~m/\{$fn\}/){
                  my $constVal=$filter->{$fn};
                  $subRestFinalAddr=~s/\{$fn\}/$constVal/g;
                  $constHandeled++;
               }
            }
            if ($constHandeled){
               delete($filter->{$fn});
            }
         }
         if ($fld->{RestFilterType} eq "SYSPARMQUERY"){
            my $fieldname=$fn;
            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
            my @data;
            my $fstr=$filter->{$fn};
            if ($fld->Type()=~m/Date/){
               $fstr=$self->PreParseTimeExpression($fstr,$fld->timezone());
            }
            $fstr=~s/\\\*/[|*|]/g;   # \* handling maybe wrong (02/2025)
            $fstr=~s/\\/\\\\/g;      # \  handling maybe wrong (02/2025)
            my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
            if ($fstr ne "" && $#words==-1){
               $self->LastMsg(ERROR,"parse error '$fstr'");
               return(undef);
            }

            my @fieldQuery;
            for(my $c=0;$c<=$#words;$c++){
               my $sword=$words[$c];
               foreach my $cword (qw(AND OR)){
                  if ($sword eq $cword && $c>0 && $c<$#words){
                     $self->LastMsg(ERROR,"concatenation $cword is not ".
                                          "supported in sysparam_query ".
                                          "translation");
                     return(undef);
                  }
               }
               my $cmpop="="; 
               if ($sword=~m/^<=[^*?]+$/){
                  $sword=~s/^<=//;
                  $cmpop="<=";
               }
               elsif ($sword=~m/^>=[^*?]+$/){
                  $sword=~s/^>=//;
                  $cmpop=">=";
               }
               elsif ($sword=~m/^>[^*?]+$/){
                  $sword=~s/^>//;
                  $cmpop=">";
               }
               elsif ($sword=~m/^<[^*?]+$/){
                  $sword=~s/^<//;
                  $cmpop="<";
               }
               elsif ($sword=~m/^[^*?]+\*$/){
                  my $fstrmod=$sword;
                  $sword=~s/\*$//;
                  $cmpop=" STARTSWITH";
               }
               elsif ($sword=~m/^\*[^*?]+$/){
                  my $fstrmod=$sword;
                  $sword=~s/^\*//;
                  $cmpop=" ENDSWITH";
               }
               elsif ($sword=~m/^\*[^*?]+\*$/){
                  my $fstrmod=$sword;
                  $sword=~s/^\*//;
                  $sword=~s/\*$//;
                  $cmpop=" LIKE";
               }
               elsif ($sword=~m/[*?]/){
                  $self->LastMsg(ERROR,
                                 "selected wildcard filter can not be ".
                                 "translated to sysparam_query");
                  return(undef);
               }


               if ($fld->Type()=~m/Date/){
                  my $raw=$self->ExpandTimeExpression($sword);

                  if (defined($raw)){
                     $raw=~s/ /','/;
                  }
                  else{
                     $self->LastMsg(ERROR,
                                    "selected date expression can not be ".
                                    "translated to sysparam_query");
                     return(undef);
                  }
                  $sword="javascript:gs.dateGenerate('${raw}.000Z')";
               } 

               push(@fieldQuery,"${fieldname}${cmpop}${sword}");
            } 
            push(@SYSPARMQUERYandList,join("^OR",@fieldQuery));



         }
         elsif ($fld->{RestFilterType} eq "SIMPLEQUERY"){
            my $fieldname=$fn;
            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
            if (defined($fld->{RestFilterField})){
               $fieldname=$fld->{RestFilterField};
            }

            my @data;
            my $fstr=$filter->{$fn};
            if (ref($fstr) eq "SCALAR"){
               my @l=($$fstr);
               $fstr=\@l;
            }
            elsif (ref($fstr) eq "ARRAY"){
               foreach my $word (@$fstr){
                  my $exp=$word;
                  my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                  push(@data," $e");
               }
            }
            else{
               $fstr=~s/\*//g;
               @data=($fstr);
            }

            $qparam{$fieldname}=join(" ",@data);

         }
         elsif ($fld->{RestFilterType} eq "SIMPLE"){
            my $fieldname=$fn;
            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
            my @data;
            my $fstr=$filter->{$fn};
            if (ref($fstr) eq "SCALAR"){
               my @l=($$fstr);
               $fstr=\@l;
            }
            elsif (ref($fstr) eq "ARRAY"){
               foreach my $word (@$fstr){
                  my $exp="'".$word."'";
                  my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                  push(@data,"$v eq $e");
               }
            }
            else{
               @data=($fstr);
            }

            $qparam{$fieldname}=join(" ",@data);

         }
         elsif ($fld->{RestFilterType} eq "ODATA"){
            $isODATA++;
            my @ODATAorLst;
            my $fieldname=$fn;
            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
            $fieldname=$fld->{ODATA_filter} if (defined($fld->{ODATA_filter}));

            #
            # ToDo - in ODATA filters, SCALAR and ARRAY refs processing
            #

            my $fstr=$filter->{$fn};
            if (ref($fstr) eq "SCALAR"){
               my @l=($$fstr);
               $fstr=\@l;
            }
            if (ref($fstr) eq "ARRAY"){
               foreach my $word (@$fstr){
                  my $exp="'".$word."'";
                  my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                  push(@ODATAorLst,"$v eq $e");
               }
            }


            my $isdate=0;
            if (grep(/kernel::Field::Date/,
                   Class::ISA::self_and_super_path($fld->Self))
                   >0) {
               $isdate=1;
            }
            if ($fld->{ODATA_constFilter}){
               my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
               $qparam{$fieldname}=join(",",@words);
            }
            else{
               my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
               for(my $c=0;$c<=$#words;$c++){
                  if ($words[$c] eq "AND" || $words[$c] eq "OR"){
                     $self->LastMsg(ERROR,
                                    "no ODATA support for AND or OR");
                     return(undef);
                  }
                  if ($words[$c]=~m/'/){
                     $self->LastMsg(ERROR,
                                    "no ODATA support for ".
                                    "single quotes");
                     return(undef);
                  }
                  my $val=$words[$c];
                  my $compop="eq";
                  my $compopcount=0;
                  while($val=~m/^[<>]/){
                     if ($compopcount>0){
                        $self->LastMsg(ERROR,"illegal usage of ".
                                             "comparison operator");
                        return(undef);
                     }
                     if ($val=~m/^<=/){
                        $val=~s/^<=//;
                        $compop="le";
                     }
                     elsif ($val=~m/^</){
                        $val=~s/^<//;
                        $compop="lt";
                     }
                     elsif ($val=~m/^>=/){
                        $val=~s/^>=//;
                        $compop="ge";
                     }
                     elsif ($val=~m/^>/){
                        $val=~s/^>//;
                        $compop="gt";
                     }

                     elsif ($val=~m/^</){
                        $val=~s/^<//;
                        $compop="lt";
                     }
                     if ($val=~m/^>/){
                        $val=~s/^>//;
                        $compop="tg";
                     }
                     $compopcount++;
                  }
                  if ($isdate){
                     my $tz=$fld->timezone();
                     my $usertz=$self->UserTimezone();
                     my $d=$self->ExpandTimeExpression(
                            $val,"EDM", $usertz, $tz);
                     return(undef) if (!defined($d));
                     $val=$d;
                  }
                     my $exp="'".$val."'";
                     my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                     push(@ODATAorLst,"$v $compop $e");
               }
            }
            if ($#ODATAorLst!=-1){
               push(@ODATAandLst,join(" or ",@ODATAorLst));
            }
         }
         elsif (ref($fld->{RestFilterType}) eq "CODE"){
            if ($const){  # works only with cons values (normaly IdField)
               my $bk=&{$fld->{RestFilterType}}($fld,$filter->{$fn},
                                                \%qparam,$constParam,$filter);
            }
         }
      }
   }
   if ($isSYSPARMQUERY){
      my $sysquery=join("^",@SYSPARMQUERYandList);
      $qparam{'sysparm_query'}=$sysquery;
      msg(INFO,"sysparm_query=$sysquery in $self");
      $qparam{'sysparm_input_display_value'}="false"; # ensure working on UTC
      $qparam{'sysparm_display_value'}="true"; # resolv links to values
      $qparam{'sysparm_exclude_reference_link'}="true"; # link ids?
   }

   if ($isODATA){
      if ($#ODATAandLst!=-1){
         $qparam{'$filter'}=join(" and ",@ODATAandLst);
      }
      if ($self->{_LimitStart}==0 && $self->{_Limit}>0 &&
          !($self->{_UseSoftLimit})){
         $qparam{'$top'}=$self->{_Limit};
         if ($self->{_LimitStart}>0){
            $qparam{'$skip'}=$self->{_LimitStart};
         }
      }
      else{
         $qparam{'$top'}=99999;
      }
   }

   my $qstr=kernel::cgi::Hash2QueryString(%qparam);

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
   }

   if ($qstr ne ""){
      if ($restFinalAddrString=~m/\?/){
         $restFinalAddrString.="&".$qstr;
      }
      else{
         $restFinalAddrString.="?".$qstr;
      }
   }
   $requesttoken=$restFinalAddrString;

   return($restFinalAddrString,$requesttoken,$constParam);
}


sub Ping
{
   my $self=shift;

   if ($self->can("getCredentialName") && $self->can("getAuthorizationToken")){
      my $credentialN=$self->getCredentialName();
      my $Authorization;
      my $errors;
      open local(*STDERR), '>', \$errors;
      eval('$Authorization=$self->getAuthorizationToken($credentialN);');
      if ($Authorization ne ""){
         return(1);
      }
      if (!$self->LastMsg()){
         if ($errors){
            foreach my $emsg (split(/[\n\r]+/,$errors)){
               $self->SilentLastMsg(ERROR,$emsg);
            }
         }
         else{
            $self->SilentLastMsg(ERROR,"unknown Auth problem in $self");
         }
      }
      return(0);
   }
   return($self->SUPER::Ping());
}





1;
