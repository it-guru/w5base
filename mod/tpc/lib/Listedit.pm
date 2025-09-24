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
use kernel::QRule;
use Text::ParseWords;
use Digest::MD5 qw(md5_base64);
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

sub getVRealizeAuthorizationToken
{
   my $self=shift;
   my $credentialName=shift;

   $W5V2::Cache->{GLOBAL}={} if (!exists($W5V2::Cache->{GLOBAL}));
   my $gc=$W5V2::Cache->{GLOBAL};
   my $gckey=$credentialName."_AuthCache";

   if (!exists($gc->{$gckey}) || $gc->{$gckey}->{Expiration}<time()){
      my $pred=$self->CollectREST(
         method=>'POST',
         dbname=>$credentialName,
         requesttoken=>'AuthLevel1',
         retry_count=>10,
         retry_interval=>10,
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
         #success=>sub{  # DataReformaterOnSucces
         #   my $self=shift;
         #   my $data=shift;
         #   if (ref($data) eq "HASH" && exists($data->{content})){
         #      $data=$data->{content};
         #   }
         #   if (ref($data) ne "ARRAY"){
         #      $data=[$data];
         #   }
         #   return($data);
         #},
         onfail=>sub{
            my $self=shift;
            my $code=shift;
            my $statusline=shift;
            my $content=shift;
            my $reqtrace=shift;

            if ($code eq "400"){  # 400 logon Fehler
               if ($content=~m/Invalid username or password/i){
                  $self->SilentLastMsg(ERROR,"invalid username or password - ".
                                       "authentication refused");
               }
               return(undef,$code);
            }
           # msg(ERROR,$reqtrace);
           # $self->LastMsg(ERROR,"unexpected data TPC project response");
            return(undef);
         }
      );
      if (!defined($pred)){
         if (!$self->LastMsg()){
            $self->SilentLastMsg(ERROR,"unknown problem while preaccess_token");
         }
         return(undef);
      }
      if (ref($pred) ne "HASH"){
         $self->SilentLastMsg(ERROR,"Request for preaccess_token failed");
         return(undef);
      }
      my $refresh_token=$pred->{refresh_token};
      if ($refresh_token ne ""){
         my $d=$self->CollectREST(
            method=>'POST',
            retry_count=>10,
            retry_interval=>10,
            dbname=>$credentialName,
            requesttoken=>'AuthLevel2',
            url=>sub{
               my $self=shift;
               my $baseurl=shift;
               my $apikey=shift;
               $baseurl.="/"  if (!($baseurl=~m/\/$/));
               my $dataobjurl=$baseurl."iaas/api/login";
               return($dataobjurl);
            },
            content=>sub{
               my $self=shift;
               my $baseurl=shift;
               my $apikey=shift;
               my $apiuser=shift;
               my $json=new JSON;
        
               $json->utf8(1);
               $json->property(utf8=>1);
               my $postd=$json->encode({
                  refreshToken=>$refresh_token
               });
               return($postd);
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
            Authorization=>$d->{tokenType}." ".$d->{token}
         };
     
         my $Authorization=$d->{tokenType}." ".$d->{token};
     
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




sub decodeFilter2Query4vRealize
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

# &&          # ODATA Filters are verry simple!
#       keys(%$filter)==1 &&
#       exists($filter->{FILTER}) &&
#       ref($filter->{FILTER}) eq "ARRAY" &&
#       $#{$filter->{FILTER}}==0 &&
#       ref($filter->{FILTER}->[0]) eq "HASH"){
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
                     if ($f->{$fn}=~m/^\s*".+"\s*$/){
                        $f->{$fn}=~s/^\s*"//;
                        $f->{$fn}=~s/"\s*$//;
                     }
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
               else{   # "normal" field handling
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
                  elsif ($fld->{ODATA_filter}){
                     if ($fld->{ODATA_filter} ne "1"){
                        $fieldname=$fld->{ODATA_filter};
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
                         #
                         #   * works on eq operations
                         # 
                         #  if ($val=~m/^\*[^*]+\*$/){
                         #     $val=~s/\*$//;
                         #     $val=~s/^\*//;
                         #     my $exp="'".$val."'";
                         #     my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                         #     push(@orLst,"substringof($e,$v)");
                         #  }
                         #  elsif ($val=~m/^[^*]+\*$/){
                         #     $val=~s/\*$//;
                         #     my $exp="'".$val."'";
                         #     my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                         #     push(@orLst,"startswith($v,$e)");
                         #  }
                         #  else{
                              my $exp="'".$val."'";
                              my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                              push(@orLst,"$v $compop $e");
                         #  }
                        }
                     }
                  }
                  if ($#orLst!=-1){
                   #  push(@andLst,"(".join(" or ",@orLst).")");
                     push(@andLst,join(" or ",@orLst));
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
      $self->LastMsg(ERROR,"invalid filterset for vRealize query");
      return(undef);
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
 #     $qparam{'resourceTypes'}="Cloud.vSphere.Machine";
 #     $qparam{'search'}="ede188-mcm370670-280508727773";
 #     $qparam{'search'}="ede188*";
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



sub Ping
{
   my $self=shift;

   my $credentialN=$self->getCredentialName();

   my $errors;
   my $d;
   # Ping is for checking backend connect, without any error displaying ...
   if (1){
      open local(*STDERR), '>', \$errors;
      eval('
         my $Authorization=$self->getVRealizeAuthorizationToken($credentialN);
         if ($Authorization ne ""){
            $d=$self->CollectREST(
               dbname=>$credentialN,
               url=>sub{
                  my $self=shift;
                  my $baseurl=shift;
                  my $apikey=shift;
                  $baseurl.="/"  if (!($baseurl=~m/\/$/));
                  my $dataobjurl=$baseurl."iaas/api/about";
                  return($dataobjurl);
               },
               headers=>sub{
                  my $self=shift;
                  my $baseurl=shift;
                  my $apikey=shift;
                  my $headers=["Authorization"=>$Authorization,
                               "Content-Type"=>"application/json"];
        
                  return($headers);
               },
               preprocess=>sub{   # create a valid JSON response
                  my $self=shift;
                  my $d=shift;
                  my $code=shift;
                  my $message=shift;
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
         }
      ');
   }
   #
   # $d muss ein HASH sein und den Key $d->{latestApiVersion} haben. Das
   # könnte man noch verifizieren.
   #
   if (!defined($d) && !$self->LastMsg()){
      #$self->LastMsg(ERROR,"fail to REST Ping to $credentialN");
      $self->Log(ERROR,"backlog","fail to REST Ping to $credentialN");
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
   my $credentialName=shift;
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
         dbname=>$credentialName,
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
    
            if ($code eq "404"){  # 404 bedeutet nicht gefunden
               return([],"200");
            }
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



sub TPC_CloudAreaSync
{
   my $self=shift;
   my $tpccode=shift;
   my $queryparam=shift;


   my $inscnt=0;

   my @a;
   my %itcloud;

   my $pro=getModuleObject($self->Config,$tpccode."::project");
   my $mach=getModuleObject($self->Config,$tpccode."::machine");
   my $dep=getModuleObject($self->Config,$tpccode."::deployment");
   my $itcloudobj=getModuleObject($self->Config,"itil::itcloud");
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $sys=getModuleObject($self->Config,"itil::system");
   my $itcloudarea=getModuleObject($self->Config,"itil::itcloudarea");

   if ($pro->isSuspended() ||
       $dep->isSuspended()){
      return({exitcode=>0,exitmsg=>'ok'});
   }


   if (!($pro->Ping()) ||
       !($dep->Ping()) ||
       !($itcloudobj->Ping())){
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      if ($infoObj->NotifyInterfaceContacts($pro)){
         return({exitcode=>0,exitmsg=>'Interface notified'});
      }
      return({exitcode=>1,exitmsg=>'not all dataobjects available'});
   }

   $itcloudobj->ResetFilter();
   $itcloudobj->SetFilter({shortname=>\$tpccode});
   my ($tpccloudrec)=$itcloudobj->getOnlyFirst(qw(ALL));
   if (!defined($tpccloudrec)){
      msg(ERROR,"invalid to find cloud $tpccode in cloud list");
      return(undef);
   }
   my $tpcname=$tpccloudrec->{name};




   my $StreamDataobj=$tpccode."::CloudAreaSync";


   my $joblog=getModuleObject($self->Config,"base::joblog");
   my $eventlabel='IncStreamAnalyse::'.$dep->Self;
   my $method=(caller(0))[3];

   $joblog->SetFilter({name=>\$method,
                       exitcode=>\'0',
                       exitmsg=>'last:*',
                       cdate=>">now-4d",
                       event=>\$eventlabel});
   $joblog->SetCurrentOrder('-cdate');

   $joblog->Limit(1);
   my ($firstrec,$msg)=$joblog->getOnlyFirst(qw(ALL));


   my %jobrec=( name=>$method, event=>$eventlabel, pid=>$$);
   my $exitmsg="done";
   my $ncnt=0;
   my $laststamp;
   my @msg;
   my $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
   msg(DEBUG,"jobid=$jobid");

   my %flt=('status'=>'CREATE_SUCCESSFUL');
   if (1){    
      $flt{cdate}=">now-14d";
      if (defined($firstrec)){
         my $lastmsg=$firstrec->{exitmsg};
         if (($laststamp)=
             $lastmsg=~m/^last:(\d+-\d+-\d+ \d+:\d+:\d+)$/){
            $flt{cdate}=">=\"$laststamp GMT\"";
            $exitmsg=$lastmsg;
         }
      }
      else{
         my $d=$joblog->ExpandTimeExpression("now-1h","en","GMT","GMT");
         $exitmsg="last:$d";
      }
   }



   if (1){
      $pro->ResetFilter();
      $pro->SetFilter({});
      my @ss=$pro->getHashList(qw(id name applid cistatusid));
      my @s;
      if ($#ss==-1){
         my $msg="no projects found in TPC - sync abborted";
         msg(ERROR,$msg);
         return({exitcode=>1,exitmsg=>$msg});
      }
      foreach my $rec (@ss){
         next if ($rec->{cistatusid} ne "4");
         my $crec={
            id=>$rec->{id},
            name=>$rec->{name},
         };
         if ($rec->{applid}=~m/^[0-9]{2,20}$/){
            $crec->{applid}=$rec->{applid};
         }
         push(@s,$crec);
      }
      $itcloudarea->ResetFilter();
      my $cursrcsys=\$tpccode;
      $cursrcsys=['TPC','TPC1'] if ($tpccode eq "TPC1");  # migration TPC->TPC1
      $itcloudarea->SetFilter({srcsys=>$cursrcsys});
      my @c=$itcloudarea->getHashList(qw(name itcloud applid 
                                         srcsys srcid cistatusid));

      my @opList;


      #printf STDERR ("fifi c=%s\n",Dumper(\@c));
      #printf STDERR ("fifi s=%s\n",Dumper(\@s));

      my $res=kernel::QRule::OpAnalyse(
         sub{  # comperator
            my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
            my $eq;          # undef= nicht gleich
            if ( $a->{srcid} eq $b->{id}){
               $eq=0;  # rec found - aber u.U. update notwendig
               my $aname=$a->{name};
               $aname=~s/\[.*\]$//;
               my $bname=$b->{name};
               $bname=~s/\s+/_/g;
               if ($aname eq $bname &&
                   $a->{cistatusid}<6 &&
                   $a->{applid} eq $b->{applid} &&
                   $a->{srcsys} eq $b->{srcsys}){
                  $eq=1;   # alles gleich - da braucht man nix machen
               }
            }
            return($eq);
         },
         sub{  # oprec generator
            my ($mode,$oldrec,$newrec,%p)=@_;
            if ($mode eq "insert" || $mode eq "update"){
               my $name=$newrec->{name};
               $name=~s/\s+/_/g;
               my $oprec={
                  OP=>$mode,
                  DATAOBJ=>'itil::itcloudarea',
                  DATA=>{
                     name    =>$name,
                     applid  =>$newrec->{applid},
                     cloud   =>$tpcname,
                     srcsys  =>$tpccode,
                     srcid   =>$newrec->{id}
                  }
               };
               if ($mode eq "insert"){
                  $oprec->{DATA}->{cistatusid}="3";
               }
               if ($mode eq "update"){
                  if ($oldrec->{cistatusid}==6){
                     if ($oldrec->{applid} ne $newrec->{applid}){
                        $oprec->{DATA}->{cistatusid}="3";
                     }
                     else{
                        $oprec->{DATA}->{cistatusid}="4";
                     }
                  }
                  if ($oldrec->{cistatusid}!=3 &&
                      $oldrec->{applid} ne $newrec->{applid}){
                     $oprec->{DATA}->{cistatusid}="3";
                  }
                  $oprec->{IDENTIFYBY}=$oldrec->{id};
               }
               return($oprec);
            }
            elsif ($mode eq "delete"){
               my $oprec={
                  OP=>"update",
                  DATAOBJ=>'itil::itcloudarea',
                  IDENTIFYBY=>$oldrec->{id},
                  DATA=>{
                     cistatusid  =>6
                  }
               };
               return(undef) if ($oldrec->{cistatusid} eq "6");
               return($oprec);
            }
            return(undef);
         },
         \@c,\@s,\@opList
      );
      for(my $c=0;$c<=$#opList;$c++){
         if ($opList[$c]->{OP} eq "insert" ||
             ($opList[$c]->{OP} eq "update" && 
              exists($opList[$c]->{DATA}->{applid}))){
            my ($arec,$msg);
            $appl->ResetFilter();
            if ($opList[$c]->{DATA}->{applid} ne ""){
               $appl->SetFilter({id=>\$opList[$c]->{DATA}->{applid}});
               ($arec,$msg)=$appl->getOnlyFirst(qw(id cistatusid name));
            }
            if (!defined($arec) || $opList[$c]->{DATA}->{applid} eq ""){
               $opList[$c]->{OP}="invalid";
               push(@msg,"ERROR: invalid application (W5BaseID) in project ".
                         $opList[$c]->{DATA}->{name});
            }
            else{
               if ($arec->{cistatusid} ne "3" &&
                   $arec->{cistatusid} ne "4"){
                  $opList[$c]->{OP}="invalid";
                  push(@msg,"ERROR: invalid cistatus for application ".
                            $arec->{name}.
                            " in project ".$opList[$c]->{DATA}->{name});
               }
            }
         }
      }
      if (!$res){
         my $opres=ProcessOpList($itcloudarea,\@opList);
      }
   }

   my ($dlast)=$laststamp=~m/^(\S+)\s/;
   my ($dnow)=NowStamp("en")=~m/^(\S+)\s/;

   if ($dlast eq $dnow){
      @msg=();     # project sync messages only on daychange
   }

   if (1){
      $dep->ResetFilter();
      $dep->SetFilter(\%flt);
      $dep->Limit(1000,0,0);
      $dep->SetCurrentOrder(qw(cdate id));
      my %machineid;
      DEPCHK: foreach my $deprec ($dep->getHashList(qw(opname cdate 
                                               projectid resources))){
         $ncnt++;
         if ($laststamp ne ""){  # filter of cdate on backend not working
            my $d=CalcDateDuration($laststamp,$deprec->{cdate});
            if (defined($d) && $d->{totalminutes}<=0){
               next DEPCHK;
            }
         }

         my $ismachine=0;
         my $resources=$deprec->{resources};
         if (ref($resources) eq "ARRAY"){
            foreach my $resrec (@$resources){
               if ($resrec->{type}=~m/machine/i){
                  $machineid{$resrec->{id}}++;
                  $ismachine++;
               }
            }
         }
         if ($ismachine){
            $exitmsg="last:".$deprec->{cdate};
            msg(INFO,"$ncnt) op:".$deprec->{opname});
            msg(INFO,"cdate:".$deprec->{cdate});
            msg(INFO,"project:".$deprec->{projectid}."\n--\n");
         }
      }
      foreach my $machineid (sort(keys(%machineid))){
         $mach->ResetFilter();
         $mach->SetFilter({id=>\$machineid});
         my ($mrec,$msg)=$mach->getOnlyFirst(qw(id 
                                                urlofcurrentrec projectId
                                                name));
         if (defined($mrec)){
            $sys->ResetFilter();
            $sys->SetFilter([
               {srcsys=>\'TPC',srcid=>\$mrec->{id}},
               {srcsys=>\'AssetManager',srcid=>\$mrec->{id}},  # MCOS case
            ]);
            my ($srec,$msg)=$sys->getOnlyFirst(qw(id cistatusid));
            if (!defined($srec)){
               # run import
               $mach->Import({importrec=>$mrec});
            }
            else{
               # initiate QualityCheck on sysrec
            }
         }
      }
   }

   if ($#msg!=-1){
         my %notifyParam=();
         my $informationHash=md5_base64(join("\n",@msg));
         $notifyParam{infoHash}=$informationHash; # reduce
                                                  # duped infos
         $itcloudobj->NotifyWriteAuthorizedContacts(
                      $tpccloudrec,{},
                      \%notifyParam,{},sub{
            my ($subject,$ntext);
            my $subject=$tpccode." CloudArea Sync";
            my $tmpl=join("\n",@msg);
            return($subject,$tmpl);
         });
   }
   my $nmsg=$#msg+1;
   $joblog->ValidatedUpdateRecord({id=>$jobid},
                                 {exitcode=>"0",
                                  exitmsg=>$exitmsg,
                                  exitstate=>"ok - cnt:$ncnt/msg:$nmsg"},
                                 {id=>\$jobid});

   return({exitcode=>0,exitmsg=>'ok'});
}





1;
