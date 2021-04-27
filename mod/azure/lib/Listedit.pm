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
            my $dataobjurl=$baseurl.$base."/oauth2/token";
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
               client_secret => $apikey,
               resource      => 'https://management.core.windows.net/',
               tenant        => $base
            );
            my $qstr=kernel::cgi::Hash2QueryString(%qparam);
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




sub decodeFilter2Query4azure
{
   my $self=shift;
   my $dbclass=shift;
   my $idfield=shift;
   my $filter=shift;
   my $const={}; # for constances witch are derevided from query
   my $requesttoken="SEARCH.".time();
   my $query="";
   my %qparam;

   if (ref($filter) eq "HASH"){
      my @andLst=();
      foreach my $filtername (keys(%{$filter})){
         my $f=$filter->{$filtername}->[0];
         # ODATA Filter translation
        
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
                  if ($dbclass=~m/\{$idfield\}/){
                     $dbclass=~s/\{$idfield\}/$id/g;
                  }
                  else{
                     $dbclass=$dbclass."/".$id;
                  }
                  $requesttoken=$dbclass;
               }
               if (0){   # ODATA $filter seems not to work
                  my @orLst;
                  my $fieldname=$fn;
                  if (exists($fld->{dataobjattr})){
                     $fieldname=$fld->{dataobjattr};
                  }
                  my $fstr=$f->{$fn};
                  if (ref($fstr) eq "SCALAR"){
                     my @l=($$fstr);
                     $fstr=\@l;
                  }
                  if (ref($fstr) eq "ARRAY"){
                     foreach my $word (@$fstr){
                        my $exp="'".$word."'";
                        my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                        push(@orLst,"$v eq $e");
                     }
                  }
                  else{
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
                           if ($val=~m/^\*[^*]+\*$/){
                              $val=~s/\*$//;
                              $val=~s/^\*//;
                              my $exp="'".$val."'";
                              my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                              push(@orLst,"substringof($e,$v)");
                           }
                           elsif ($val=~m/^[^*]+\*$/){
                              $val=~s/\*$//;
                              my $exp="'".$val."'";
                              my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                              push(@orLst,"startswith($v,$e)");
                           }
                           else{
                              my $exp="'".$val."'";
                              my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                              push(@orLst,"$v $compop $e");
                           }
                        }
                     }
                  }
                  if ($#orLst!=-1){
                     push(@andLst,"(".join(" or ",@orLst).")");
                  }
               }
            }
         }
      }
      if ($#andLst!=-1){
         $qparam{'$filter'}=join(" and ",@andLst);
      }
   }
   else{
      printf STDERR ("invalid Filterset in $self:%s\n",Dumper($filter));
      $self->LastMsg(ERROR,"invalid filterset for Azure query");
      return(undef);
   }
   $qparam{'api-version'}="2020-01-01";

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
   
   return($dbclass,$requesttoken,$const);
}




1;
