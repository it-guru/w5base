package kernel::DataObj;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use Class::ISA;
use Time::HiRes;
use UUID::Tiny ':std';
use kernel;
use kernel::App;
use kernel::WSDLbase;
use kernel::Field::IndividualAttr;
use Text::ParseWords;

@ISA    = qw(kernel::App kernel::WSDLbase);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   $self->{isInitalized}=0;
   $self->{use_distinct}=1 if (!exists($self->{use_distinct}));
   $self->{use_dirtyread}=0 if (!exists($self->{use_dirtyread}));
   $self->{dontSendRemoteEvent}=1 if (!exists($self->{dontSendRemoteEvent}));
   $self->{InternExternRemapping}=0;
   
   return($self);
}


sub Clone
{
   my $self=shift;
   my $name=$self->Self;
   my $config=$self->Config;
   my $o=getModuleObject($config,$name);
   if (defined($o)){
      if (my $p=$self->getParent()){
         $o->setParent($p);
      }
   }
   return($o);
}

sub getFilterSet
{
   my $self=shift;
   my @l=();
   foreach my $set (keys(%{$self->{FilterSet}})){
      #push(@l,@{$self->{FilterSet}->{$set}});
      push(@l,@{$self->{FilterSet}->{$set}});
   }
   return(@l);
}


# check if a specifed field/fieldlist is referenced in current request.
# this is needed to create dynamisc outerjoins
sub isFieldReferencedInCurrentRequest
{
   my $self=shift;
   my $field=shift;

   $field=[$field] if (ref($field) ne "ARRAY");
   if (in_array([$self->getCurrentView()],[@$field,"ALL"])){
      return(1);
   }
   foreach my $flt ($self->getFilterSet()){
      $flt=[$flt] if (ref($flt) ne "ARRAY");
      foreach my $hflt (@$flt){
         if (ref($hflt) eq "HASH" && in_array([keys(%$hflt)],$field)){
            return(1);
         }
      }
   }
   return(0);
}


sub SetNamedFilter
{
   my $self=shift;
   my $name=shift;
   return($self->_SetFilter($name,@_));
}

sub GetNamedFilter
{
   my $self=shift;
   my $name=shift;
   return($self->{FilterSet}->{$name});
}

sub ResetFilter
{
   my $self=shift;
   my $base=$self->{FilterSet}->{BASE}; # store BASE filter
   $self->Limit(0);
   $self->{FilterSet}={};
   $self->{FilterSet}->{BASE}=$base if (defined($base)); # restore BASE filter
   delete($self->Context->{'CurrentOrder'}); # if there is a new view set,
                                             # the last order must be deleted
}

sub Ping
{
   return(1);
}

sub SetFilterForQualityCheck    # prepaire dataobject for automatic 
{                               # quality check (nightly)
   my $self=shift;
   my $stateparam=shift;
   my @view=@_;                 # predefinition for request view
   my @flt;

   # eine alternative wäre es, in einem qualityState objekt die letzte
   # geprüfte ID (mit Zeitstempel) zu speichern. Die IDs müsten aufsteigend
   # sortiert werden. 

   if ($stateparam->{checkProcess} eq "idBased"){
      if (exists($stateparam->{lastid})){
         $flt[0]->{$stateparam->{idname}}=">\"$stateparam->{lastid}\"";
      }
   }

   if (my $cistatusid=$self->getField("cistatusid")){
      $flt[0]->{cistatusid}=[1,2,3,4,5];
      if (my $cdate=$self->getField("cdate")){ # prevent qcheck at night 
         $flt[0]->{cdate}="<now-1h";           # on fresh created elements
      }
      if (my $lastqcheck=$self->getField("lastqcheck")){
         $flt[0]->{lastqcheck}="<now-6h";  # prevent double checks  of active
      }                                    # CIs in nighly QCheck
      if (my $mdate=$self->getField("mdate")){
         $flt[0]->{mdate}="<now-10m";  # prevent recheck of element, if it is
                                       # recently modified.
         if (my $lastqcheck=$self->getField("lastqcheck")){
            # check  of cistatus=6 is only posible, if LastQualityCheck is
            # older then 7 days (in 5 weeks range).
            $flt[1]->{cistatusid}=[6];     
            $flt[1]->{mdate}=">now-35d";  
            $flt[1]->{lastqcheck}="<now-7d"; 
            # check  of cistatus=6 is only posible, if LastQualityCheck is
            # older then 4 weeks (in 100 day range).
            $flt[2]->{cistatusid}=[6];     
            $flt[2]->{mdate}=">now-100d";  
            $flt[2]->{lastqcheck}="<now-28d"; 
         }                                  
      }                                    
      my %fltadd=%{$flt[0]};
      $fltadd{lastqcheck}=undef;    # handle uncheckt records prefered
      push(@flt,\%fltadd);
   }
   #msg(WARN,sprintf("SetFilterForQualityCheck=%s\n",Dumper(\@flt)));
   $self->SetFilter(\@flt);
   $self->SetCurrentView(@view);
   return(1);
}

sub preQualityCheckRecord
{
   my $self=shift;
   my $rec=shift;

   return(1);
}

sub postQualityCheckRecord
{
   my $self=shift;
   my $rec=shift;

   return(1);
}

sub SecureSetFilter
{
   my $self=shift;
   $self->isDataInputFromUserFrontend(1);
   return($self->SetFilter(@_));
}

sub SetFilter
{
   my $self=shift;
   #$self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   $self->Limit(0);
   $self->{use_distinct}=1 if (!exists($self->{use_distinct}));
   return($self->_SetFilter("FILTER",@_));
}

sub simplifyFilterSet
{
   my $self=shift;
   my $filterset=shift;
   my $mode=shift;

   $mode=[$mode] if (ref($mode) ne "ARRAY");

   # mode  
   # NOARRAYRESOLVE
   # NOSCALARRESOLVE
   # NOREMOVEQUOTES
   # TIMECACHE60   # default
   # TIMECACHE10
   

   if (ref($filterset) ne "HASH"){
      $self->LastMsg(ERROR,"query filterset misstructured");
      return(undef);
   }

   if (keys(%{$filterset})!=1){
      $self->LastMsg(ERROR,"multiple filter names not supported");
      return(undef);
   }
   my @f=%{$filterset};
   my $onlyOneFlt=$f[1];
   if (ref($onlyOneFlt) eq "ARRAY"){
      if ($#{$onlyOneFlt}!=0){
         $self->LastMsg(ERROR,"multiple OR filters supported");
         return(undef);
      }
      $onlyOneFlt=$onlyOneFlt->[0];
   } 
   if (ref($onlyOneFlt) ne "HASH"){
      $self->LastMsg(ERROR,"no final HASH filter - this is not suppored");
      return(undef);
   }
   my %fltDup=%{$onlyOneFlt};


   my @qparam;
   
   foreach my $k (sort(keys(%fltDup))){
      if (ref($fltDup{$k}) eq "ARRAY"){
         if (!in_array($mode,"NOARRAYRESOLVE")){
            $fltDup{$k}=join(" ",map({
                $_=~s/^"//; 
                $_=~s/"$//; 
                $_;
            } @{$fltDup{$k}}));
         }
      }
      if (ref($fltDup{$k}) eq "SCALAR"){
         if (!in_array($mode,"NOSCALARRESOLVE")){
            my $v=${$fltDup{$k}};
            $fltDup{$k}=$v;
         }
      }
      else{
         if (!in_array($mode,"NOREMOVEQUOTES")){
            my $v=$fltDup{$k};
            if (($v=~m/^"/) && ($v=~m/"$/)){
               $v=~s/^"//;
               $v=~s/"$//;
               $fltDup{$k}=$v;
            }
         }
      }
      push(@qparam,$k,$fltDup{$k});
   }
   my $qstring=join("|",@qparam);
   my $time=time();
   my $modtime=$time % 60;
   my $ttime=$time-$modtime;
   my $queryToken=uuid_to_string(create_uuid(UUID_V3,$ttime.":".$qstring));


   return(\%fltDup,$queryToken);
}

sub _preProcessFilter
{
   my $self=shift;
   my $hflt=shift;


   my $changed=0;
   do{ 
      $changed=0;
      foreach my $field (keys(%{$hflt})){
         my $fobj=$self->getField($field);
         if (!defined($fobj)){
            msg(ERROR,"can't find field object for name ".
                      "'%s' at %s (_preProcessFilter)",
                      $field,$self);
            # Last Message handling
            #
            return(undef);
         } 
         else{
            if (exists($fobj->{onRawValue}) &&
                !defined($fobj->{onPreProcessFilter}) &&
                !$self->isa('kernel::DataObj::Static') &&  # only Static can
                $fobj->searchable){                        # handle calculated
               my $d=$hflt->{$field};                      # searches
               $self->LastMsg(ERROR,
                     "filter '%s' request on calculated field '%s(%s)'\@'%s'",
                        $d,$field,$fobj->Type(),$self->Self);
               return(undef);
            }
            my ($subchanged,$err)=$fobj->preProcessFilter($hflt);
            if ($err ne ""){
               $self->LastMsg(ERROR,$err);
               return(undef);
            }
            $changed=$changed+$subchanged;
         }
      }
   }until($changed==0);
   return($hflt);
}


sub _SetFilter
{
   my $self=shift;
   my $filtername=shift;
   my @list=@_;
   $self->{FilterSet}->{$filtername}=[];



   @list={@list} if (!ref($list[0]));
   my $fail=0;
   do{
      if (ref($list[0]) eq "ARRAY"){
         my @l=@{$list[0]};
         my @finelist;
         for(my $c=0;$c<=$#l;$c++){
            my %f=%{$l[$c]};  # copy filter-hash to prevent SCALAR convert
            my $flt=\%f;      # to ARRAY lists (in SubList vjoins)
            $flt=$self->_preProcessFilter($flt);
            $fail++ if (!defined($flt));
            push(@finelist,$flt);
         }
         push(@{$self->{FilterSet}->{$filtername}},\@finelist);
      }
      elsif (ref($list[0]) eq "HASH"){
         my %f=%{$list[0]};
         my $flt=\%f;
         my $h=$self->_preProcessFilter($flt);
         $fail++ if (!defined($h));
         push(@{$self->{FilterSet}->{$filtername}},$h);
      }
      shift(@list); 
   } until(!defined($list[0]));

   if ($fail){
      return(0);
   }

   return(1);
}

sub StringToFilter
{
   my $self=shift;
   my $str=shift;
   my %param=@_;
   my @flt;

   my @words=parse_line('[,;]{0,1}\s+',0,$str);

   my $curhash;
   my $andclose=0;
   my $andopen=0;
   my $inrawmode=0;
   my $closerawmode=0;
   my $lastrawmodefield;
   #msg(INFO,"StringToFilter words=%s\n",Dumper(\@words));
   for(my $c=0;$c<=$#words;$c++){
      #msg(INFO,"parse word '\%s' andopen=$andopen",$words[$c]);
      while ($words[$c]=~m/^([a-z,0-9]+)=\[/){
         if ($inrawmode){
            $self->LastMsg(ERROR,"structure error in []");
            return;
         }
         $words[$c]=~s/^([a-z,0-9]+)=\[/$1=/;
         $inrawmode++;
      }
      while($words[$c]=~m/^\[/){
         $words[$c]=~s/^\[//;
         if ($inrawmode){
            $self->LastMsg(ERROR,"structure error in []");
            return;
         }
         $inrawmode++;
      }
      while($words[$c]=~m/^\(/){
         $words[$c]=~s/^\(//;
         if ($andopen){
            $self->LastMsg(ERROR,"structure error in ()");
            return;
         }
         $andopen++;
      }
      while($words[$c]=~m/\)$/){
         $words[$c]=~s/\)$//;
         if ($andopen<1){
            $self->LastMsg(ERROR,"structure error in ()");
            return;
         }
         $andopen--;
      }
      while ($words[$c]=~m/\]$/){
         $words[$c]=~s/\]$//;
         if (!$inrawmode){
            $self->LastMsg(ERROR,"structure error while closing []");
            return;
         }
         $closerawmode++;
      }
      #msg(INFO,"parse inrawmode=$inrawmode closerawmode=$closerawmode");
      if (lc($words[$c]) eq "and"){
         if ($andopen!=1){
            $self->LastMsg(ERROR,"and only allowed in ()");
            return;
         }
      }
      elsif (lc($words[$c]) eq "or"){
         if ($andopen!=0){
            $self->LastMsg(ERROR,"or not allowed in ()");
            return;
         }
         if (!defined($curhash)){
            $self->LastMsg(ERROR,"or not allowed at begin of expression");
            return;
         }
         push(@flt,$curhash);
         $curhash=undef;
      }
      elsif (my ($vari,$vali)=$words[$c]=~m/^([a-z,0-9]+)=(.*)$/){
         if (!$param{nofieldcheck}){
            my $fobj=$self->getField($vari);
            if (!defined($fobj)){
               $self->LastMsg(ERROR,"invalid attribute '\%s' used",$vari);
               return;
            }
         }
         if (!defined($curhash)){
            if ($inrawmode){
               $curhash={$vari=>[$vali]};
               $lastrawmodefield=$vari;
            }
            else{
               $curhash={$vari=>$vali};
            }
         }
         else{
            if (exists($curhash->{$vari}) && !$inrawmode){
               $self->LastMsg(ERROR,"multiple definition of same attribute");
               return;
            }
            if ($inrawmode){
               push(@{$curhash->{$vari}},$vali);
               $lastrawmodefield=$vari;
            }
            else{
               $curhash->{$vari}=$vali;
            }
         }
      }
      elsif($inrawmode && defined($lastrawmodefield)){
         push(@{$curhash->{$lastrawmodefield}},$words[$c]);
      }
      if ($andclose==1){
         push(@flt,$curhash);
         $curhash=undef;
         $andclose--;
      }
      if ($closerawmode==1 && !$inrawmode){
         $self->LastMsg(ERROR,"invalid close ] of raw mode");
         return;
      }
      if ($closerawmode==1){
         $inrawmode=0;
         $closerawmode--;
         $lastrawmodefield=undef;
      }
   }
   if (defined($curhash)){   # save the last or statement
      push(@flt,$curhash);
      $curhash=undef;
   }
   if ($inrawmode){
      $self->LastMsg(ERROR,"unclosed expression []");
      return;
   }
   if ($andopen){
      $self->LastMsg(ERROR,"unclosed expression ()");
      return;
   }


   return(@flt);
}

sub Initialize
{
   my $self=shift;
   $self->{dontSendRemoteEvent}=1 if (!exists($self->{dontSendRemoteEvent}));
   if ($self->can("AddDatabase")){
      my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
      return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
      return(1) if (defined($self->{DB}));
   }
   return(0);
}

sub getFirst
{
   return(undef);
}

sub getNext
{
   return(undef);
}

sub preProcessReadedRecord
{
   my $rec=shift;

   return(undef);
}

sub allowHtmlFullList
{
   my $self=shift;

   return(1);
}

sub allowFurtherOutput
{
   my $self=shift;

   return(1);
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};
   if ($p eq "StandardDetail"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      my $OpenURL=Query->Param("OpenURL");
      if ($OpenURL=~m/^#/){   # allow ancor access fia OpenURL param
         $urlparam.=$OpenURL;
      }
      Query->Delete("OpenURL");

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" ".
            "id=HtmlDetailPage ".
            "class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"HtmlDetail?$urlparam\"></iframe>";
   }
   elsif ($p eq "HtmlHistory"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"HtmlHistory?$urlparam\"></iframe>";
   }
   elsif ($p eq "HtmlWorkflowLink"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"HtmlWorkflowLink?$urlparam\"></iframe>";
   }
   elsif ($p eq "HtmlInterviewLink"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      my $IMODE=Query->Param("IMODE");
      if ($IMODE ne ""){
         $q->Param('IMODE'=>$IMODE);
      }
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"HtmlInterviewLink?$urlparam\"></iframe>";
   }
   elsif ($p eq "HtmlAutoDiscManager"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval,view=>'SelUnproc');
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"HtmlAutoDiscManager?$urlparam\"></iframe>";
   }
   elsif ($p eq "ContextMapView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"ContextMapView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   if (defined($rec)){
      my @pa=('StandardDetail'=>$self->T("Standard-Detail"));
      if (!exists($rec->{cistatusid}) || $rec->{cistatusid}!=7){
         if (defined($self->{history})){
            push(@pa,'HtmlHistory'=>$self->T("History"));
         }
         if (defined($self->{workflowlink})){
            push(@pa,'HtmlWorkflowLink'=>$self->T("Workflows"));
         }
         if ($self->can("HtmlInterviewLink")){
            push(@pa,'HtmlInterviewLink'=>$self->T("Interview"));
         }
      }
      if ($self->can("Map") && $self->can("generateContextMap")){
         push(@pa,"ContextMapView"=>$self->T("Context map"));
      }
      return(@pa);
   }
   return('new'=>$self->T("New"));
}

sub getDefaultHtmlDetailPage
{
   my $self=shift;

   my $d="StandardDetail";
   return($d);
}

sub doInitialize
{
   my $self=shift;
   my $raiseErrors=shift;

   if (!($self->Self=~m/^base::/) && $self->isSuspended()){
      $self->{isInitalized}=0;
      return(undef);
   }
   if (!$self->{isInitalized}){
      my @result=$self->Initialize();
      if (defined($result[0]) && $result[0] eq "InitERROR"){
         $self->{isInitalized}=0;
         if ($raiseErrors){
            shift(@result);
            foreach my $msg (@result){
               $self->LastMsg(ERROR,$msg);
            }
         }
         return(undef,@result);
      }
      $self->{isInitalized}=1;
   }
   return($self->{isInitalized});
}

sub getHashIndexed
{
   my $self=shift;
   my @key=@_;
   my $res={};

   $self->doInitialize();
   @key=($self->{'fields'}->[0]) if ($#key==-1);
   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         foreach my $key (@key){
            my $v=$rec->{$key};
            next if (!defined($v));
            my @vl=($v);
            @vl=@$v if (ref($v) eq "ARRAY"); 
            foreach my $v (@vl){
               next if (!defined($v));
               if (exists($res->{$key}->{$v})){
                  if (ref($res->{$key}->{$v}) ne "ARRAY"){
                     $res->{$key}->{$v}=[$res->{$key}->{$v}];
                  }
                  push(@{$res->{$key}->{$v}},$rec);
               }
               else{
                  $res->{$key}->{$v}=$rec;
               }
            }
         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   #else{
   #   msg(ERROR,"getHashIndexed returned '%s' on getFirst",$msg);
   #}
   return($res);
}

sub getHashList
{
   my $self=shift;
   my @view=@_;
   my @l=();

   $self->doInitialize();
   if ($#view!=-1){
      $self->SetCurrentView(@view);
   }
   else{
      $self->SetCurrentView($self->getDefaultView());
   }
   my ($rec,$msg)=$self->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         push(@l,$rec);
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   if ($msg ne "" && $msg ne "Limit reached"){
      msg(INFO,"getHashList: (".$self->Self()." <- ".join(",",caller()).") ".
          "msg=".$msg);
   }
   return(@l) if (wantarray());
   return(\@l);
}

sub getVal
{
   my $self=shift;
   my $field=shift;
   my @l;

   $self->SetCurrentView($field);
   if ($#_!=-1){
      $self->SetFilter(@_);
   }
   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         if (!wantarray()){
            return($rec->{$field});
         }
         else{
            push(@l,$rec->{$field});
         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   else{
      return();
   }
   return(@l);
}


sub getRelatedWorkflows
{
   my $self=shift;
   my $dataobj=$self->Self;    # dataobject 
   my $dataobjectid=shift;     # id of record to find related workflows
   my $param=shift;
   my $q={};
   my @internalWfView=qw(id isdeleted eventend stateid eventstart prio
                         srcid srcsys name class fwdtarget fwdtargetid
                         urlofcurrentrec closedate);

   my $idobj=$self->IdField();

   my $dataobjectidflt=$dataobjectid;
   if (!ref($dataobjectidflt)){   # ensure id is a scalar or array ref
      $dataobjectidflt=\$dataobjectid;
   }
   if (ref($dataobjectidflt) eq "ARRAY" && $#{$dataobjectidflt}>=50){
      $self->LastMsg(ERROR,
             $self->T("direct id filter is limited to 50 entries"));
      return(undef);
   }

   my $idname;
   if (defined($idobj)){
      $idname=$idobj->Name();
   }
   my $h=$self->getPersistentModuleObject("getRelatedWorkflows",
                                          "base::workflow");
   $h->setParent(undef); # reset parent link
   if (!$h->{IsFrontendInitialized}){
      $h->{IsFrontendInitialized}=$h->FrontendInitialize();
   }
   if (!defined($param->{'limit'})){
      $param->{'limit'}=1500;
   }
   my $limit=$param->{'limit'};

   my $tt=$param->{'timerange'};

   if ($tt=~m/[\(\)]/ ||
       $tt eq "currentyear"  || $tt eq "lastyear" ||
       $tt eq "currentmonth" || $tt eq "lastmonth" ||
       $tt eq "lastweek"     || $tt eq "last2weeks"
      ){     # if a month or year is specified, the open
      $q->{eventend}=$tt;     # entrys will not be displayed
   }
   elsif ($tt eq ""){
      $q->{eventend}=[undef];
   }
   else{
      $q->{eventend}=[$tt,undef];
   }

   my $class=$param->{class};

   if ($class ne "*" && $class ne ""){
      $q->{class}=[$class];
   }
   if (ref($self->{workflowlink})){
      if ($class eq "*" && defined($self->{workflowlink}->{workflowtyp})){
         $q->{class}=$self->{workflowlink}->{workflowtyp};
      }
   }
   my %qorg=%$q;

   if (ref($self->{workflowlink})){
      if (ref($self->{workflowlink}->{workflowkey}) eq "ARRAY" &&
          $self->{workflowlink}->{workflowkey}->[0] eq $idname){
         $q->{$self->{workflowlink}->{workflowkey}->[1]}=$dataobjectidflt;
       #  $q{affectedapplication}="ASS_ADSL-NI(P)";
      }
      else{
         if (ref($self->{workflowlink}->{workflowkey}) eq "CODE"){
            &{$self->{workflowlink}->{workflowkey}}($self,$q,$dataobjectidflt);
         }
         else{
            $q->{id}="none";
         }
      }
   }

   my %qmax=%$q;
   $h->ResetFilter();
   $h->SetFilter(\%qmax);
   $h->Limit($limit+2);
   $h->SetCurrentOrder("id");
   my %idl=();
   map({$idl{$_->{id}}=$_;
      my $d=$_->{urlofcurrentrec};  # ensure field is resolved
   } $h->getHashList(@internalWfView));
   if ($h->LastMsg()){
      return();
   }
   if ($W5V2::OperationContext eq "WebFrontend"){
      if (keys(%idl)>$limit){
         $self->LastMsg(ERROR,$self->T("selection not sufficiently specified",
                                       "kernel::App::Web::WorkflowLink"));
         return(undef);
      }
   }
   if ($q->{class} eq "" || $q->{class}=~m/::(DataIssue|mailsend)$/ ||
       (ref($q->{class}) eq "ARRAY" && 
        grep(/::(DataIssue|mailsend)$/,@{$q->{class}}))){
      my $fo=$h->getField("directlnktype");
      if (defined($fo)){
         my $mode="*";
         if ($q->{class} eq ""){
            $mode=['DataIssue','W5BaseMail'];
         }
         if ($q->{class}=~m/::(DataIssue)$/ ||
             (ref($q->{class}) eq "ARRAY" && 
              grep(/::(DataIssue)$/,@{$q->{class}}))){
            push(@$mode,'DataIssue') if (ref($mode) eq "ARRAY");
         }
         if ($q->{class}=~m/::(mailsend)$/ ||
             (ref($q->{class}) eq "ARRAY" && 
              grep(/::(mailsend)$/,@{$q->{class}}))){
            push(@$mode,'W5BaseMail') if (ref($mode) eq "ARRAY");
         }
        
         my %qadd=%qorg; # now add the DataIssue Workflows to 
                         # DataSelection idl
         $qadd{directlnktype}=[$self->Self,$self->SelfAsParentObject()];
         $qadd{directlnkid}=$dataobjectidflt;
         $qadd{directlnkmode}=$mode;
         $qadd{isdeleted}=\'0';
         $h->ResetFilter();
         $h->SetFilter(\%qadd);
         $h->Limit($limit+2);
         $h->SetCurrentOrder("id");
         map({
            $idl{$_->{id}}=$_;
            my $d=$_->{urlofcurrentrec};  # ensure field is resolved
         } $h->getHashList(@internalWfView));
      }
   }
   if ($W5V2::OperationContext eq "WebFrontend"){
      if (keys(%idl)>$limit){
         $self->LastMsg(ERROR,$self->T("selection not sufficiently specified",
                                       "kernel::App::Web::WorkflowLink"));
         return(undef);
      }
   }
   my %q=(id=>[keys(%idl)],isdeleted=>\'0');

   my $fulltext=$param->{'fulltext'};

   if (!$fulltext=~m/^\s*$/){
      if (keys(%idl)!=0){
         my %ftname=%q;
         $ftname{name}="*$fulltext*";
         $ftname{id}=[keys(%idl)];
         my %ftdesc=%q;
         $ftdesc{detaildescription}="*$fulltext*";
         $ftdesc{id}=[keys(%idl)];
         $h->ResetFilter();
         $h->SetFilter([\%ftdesc,\%ftname]);
         $h->SetCurrentOrder("id");
         my %idl1=();
         my %idl2=();
         my %idl3=();
         my @l=$h->getHashList("id");
         map({$idl1{$_->{id}}=$idl{$_->{id}}} @l);

         { # and now the note search
            $h->{Action}->ResetFilter(); 
            $h->{Action}->SetFilter({comments=>"*$fulltext*",
                                     wfheadid=>[keys(%idl)]}); 
            $h->SetCurrentOrder("wfheadid");
            my @l=$h->{Action}->getHashList("wfheadid");
            $h->{Action}->ResetFilter(); 
            map({$idl2{$_->{wfheadid}}=1} @l);
         }
         map({$idl3{$_}=$idl{$_}} keys(%idl2));
         map({$idl3{$_}=$idl{$_}} keys(%idl1));
         return(\%idl3);
      }
      else{
         return({});
      }
   }
   return(\%idl);
}




sub getWriteRequestHash
{
   my $self=shift;
   my $mode=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($mode)){
      msg(WARN,"getWriteRequestHash no mode specified");
      $mode="web";
   }
   my $rec={};
   if ($mode eq "nativweb"){
      my %rec=Query->MultiVars(); 
      foreach my $k (keys(%rec)){
         delete($rec{$k}) if ($k eq "");
         if (my ($v)=$k=~m/^Formated_(.*)$/){ 
            $rec{$v}=$rec{$k};
            delete($rec{$k});
         }
      }
      return(\%rec);
   }
   elsif ($mode eq "ajaxcall"){
      my %rec=Query->MultiVars(); 
      my @fieldlist=$self->getFieldObjsByView(["ALL"]);
      foreach my $k (keys(%rec)){
         delete($rec{$k}) if ($k eq "");
         if (my ($v)=$k=~m/^Formated_(.*)$/){ 
            $rec{$v}=utf8_to_latin1($rec{$k});
            utf8::downgrade($rec{$v},1);
            delete($rec{$k});
         }
      }
      return(\%rec);
   }
   else{
      my @fieldlist=$self->getFieldObjsByView(["ALL"],
                                              oldrec=>$oldrec,
                                              opmode=>'getWriteRequestHash');
      foreach my $fobj (@fieldlist){
         my $field=$fobj->Name();
         if ($mode eq "web" || $mode eq "Modify"){
            my @val=Query->Param("Formated_".$field);
            if ($#val!=-1){
               $rec->{$field}=$val[0];
               $rec->{$field}=\@val  if ($#val>0);
            }
         }
      }
      foreach my $fobj (@fieldlist){
         my $field=$fobj->Name();
        # Das muss raus, da ansonsten bei Select Boxen zweimal der Inhalt
        # vom XLS Upload versucht wird zu übersetzen
        # if ($mode eq "upload"){   
        #    if (!($fobj->prepUploadRecord($newrec,$oldrec))){
        #       return(undef);
        #    }
        # }
         if ($mode eq "Modify"){
            if (!($fobj->prepUploadRecord($rec,$oldrec))){
               return(undef);
            }
         }
      }


      foreach my $fobj (@fieldlist){
         my $field=$fobj->Name();
         if ($mode eq "web" || $mode eq "Modify"){
            my @val=Query->Param($field);
            if ($#val==-1){
               @val=Query->Param("Formated_".$field);
               if ($#val!=-1){
                  if ($mode eq "Modify"){ # allow direct access in API mode
                     if ($#val==0){
                        $rec->{$field}=$val[0];
                     }
                     else{
                        $rec->{$field}=\@val;
                     }
                  }
                  my $rawWrRequest=$fobj->doUnformat(\@val,$rec);
                  #msg(INFO,"getWriteRequestHash: var=$field $rawWrRequest");
                  if (!defined($rawWrRequest)){
                     msg(WARN,"can not unformat $field");
                     if ($self->LastMsg()!=0){
                        msg(ERROR,"break getWriteRequestHash() doe LastMsgs");
                        return(undef);
                     }
                     next;
                  }
                  #msg(INFO,"Unformated $field:%s",Dumper($rawWrRequest));
                  foreach my $k (keys(%{$rawWrRequest})){
                     $rec->{$k}=$rawWrRequest->{$k};
                  }
               }
            }
            else{
               $rec->{$field}=$val[0];
               $rec->{$field}=\@val if ($#val>0);
            }
         }
         if ($mode eq "upload"){
            if (!($fobj->prepUploadRecord($newrec,$oldrec))){
               return(undef);
            }
         }
      }
      if ($mode eq "Modify"){   # es könnte sein, das dieser Block raus muss
         if (!($self->prepUploadRecord($rec))){
            return(undef);
         }
      }
      return($newrec) if ($mode eq "upload");
   }
   return($rec);
}


sub finishWriteRequestHash
{
   my $self=shift;
   my $rec={};
   my $oldrec=shift;
   my $newrec=shift;

   my @fieldlist=$self->getFieldList();
   foreach my $field (@fieldlist){
      my $fo=$self->getField($field);
      if (defined($fo)){
         $fo->finishWriteRequestHash($oldrec,$newrec);
      }
   }
   return($rec);
}

sub validateFields
{
   my $self=shift;
   my $rec={};
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;

   $self->SetCurrentView(qw(ALL));
   my @fieldlist=$self->getFieldObjsByView([$self->getCurrentView()],
                                           oldrec=>$oldrec,
                                           current=>$newrec,
                                           opmode=>'validateFields');
   my @keyhandler=();
   sub vProcessField
   {
      my $fo=shift;
      my $oldrec=shift;
      my $newrec=shift;
      my $rec=shift;
      my $comprec=shift;

      my $rawWrRequest=$fo->Validate($oldrec,$newrec,$rec,$comprec);
      if (!defined($rawWrRequest)){
         #msg(ERROR,"Validate to $fo did'nt return a WrRequest");
         return(undef);
      }
      foreach my $k (keys(%{$rawWrRequest})){
         $rec->{$k}=$rawWrRequest->{$k};
      }
      return(1);
   }
   foreach my $fo (@fieldlist){
      if ($fo->Type() eq "KeyHandler"){
         push(@keyhandler,$fo);
      }
      else{
         my $bk=vProcessField($fo,$oldrec,$newrec,$rec,$comprec);
         return(undef) if (!$bk);
      }
   }
   foreach my $kh (@keyhandler){
      vProcessField($kh,$oldrec,$newrec,$rec,$comprec);
   }
   return($rec);
}

sub preValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   #msg(INFO,"preValidate in $self");
   return(1);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      msg(INFO,"default SecureValidate in $self called");
   }
   return(1);
}

sub SecureValidateFieldAccess
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;
   #msg(INFO,"SecureValidate in $self");
   if (!defined($oldrec) && defined($newrec)){
      if ($self->can("expandByDataACL")){
         @{$wrgroups}=$self->expandByDataACL($newrec->{mandatorid},
                                             @{$wrgroups});
      }
   }
   foreach my $wrfield (keys(%{$newrec})){
       my $fo=$self->getField($wrfield,$oldrec);
       if (defined($fo)){
          my @fieldgrouplist=($fo->{group});
          if (ref($fo->{group}) eq "ARRAY"){
             @fieldgrouplist=@{$fo->{group}};
          }
          if ($#fieldgrouplist==-1 || 
              ($#fieldgrouplist==0 && !defined($fieldgrouplist[0]))){
             @fieldgrouplist=("default");
          }
          my $writeok=0;
          if ($fo->Type() eq "IndividualAttr" &&
              keys(%{$newrec})==1){   # Individuell Attributes can only be write
             $writeok=1;              # sperated !
          }
          if ($fo->Name() eq "srcid" && !defined($oldrec)){
             if (defined($newrec->{srcid}) &&
                 $newrec->{srcid} ne ""){
                $writeok=1;
                my $sys="upload:".$ENV{REMOTE_USER};
                $newrec->{srcsys}=$sys;
             }
          }
          else{
             foreach my $group (@fieldgrouplist){
                if (grep(/^$group$/,@$wrgroups)){
                   $writeok=1;last;
                }
             }
          }
          if ($fo->Type() eq "SubList" ||
              grep(/^!.*\.$wrfield$/,@$wrgroups) ||
              (!grep(/^ALL$/,@$wrgroups) && 
               !grep(/^.*\.$wrfield$/,@$wrgroups) && 
               !$writeok &&
               !($fo->Type() eq "Id"))){
             if (grep(/^!.*\.$wrfield$/,@$wrgroups)){
                if (exists($newrec->{$wrfield}) && $newrec->{$wrfield} eq ""){
                   delete($newrec->{$wrfield});
                }
             }
             if (exists($newrec->{$wrfield})){
                my $fieldname=$wrfield;
                msg(INFO,"wrgroups=".join(",",@$wrgroups));
                msg(INFO,"writeok=$writeok");
                if (defined($fo)){
                   my $label=$fo->Label();
                   my $fieldHeader="";
                   $fo->extendFieldHeader(
                       "Upload",{},\$fieldHeader,
                       $self->Self);
                   $label.=$fieldHeader;
                   $fieldname.="(".$label.")";
                }
                my $msg=sprintf($self->T(
                                "write request to field '\%s' rejected"),
                                $fieldname);
                $self->LastMsg(ERROR,$msg);
                return(0);
             }
          }
       }
   }

   return(1);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   msg(INFO,"Validate in $self");
   return(1);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
                   # (1/ALL=Ok) or undef if record could/should be not deleted
   my @l=grep(!/^$/,grep(!/^\!.*$/,grep(!/^.*\..+$/,
              $self->isWriteValid($rec))));
   return if ($#l==-1);
   return(@l);
}


sub globalOpValidate
{
   my $self=shift;
   my $op=shift;
   my @param=@_;

   if (!exists($self->{globalOpValidate})){
      $self->LoadSubObjs("ext/globalOpValidate","globalOpValidate");
   }
   foreach my $k (sort(keys(%{$self->{globalOpValidate}}))){
      my $so=$self->{globalOpValidate}->{$k};
      if ($so->can($op)){
         my $bk;
         eval("\$bk=\$so->$op(\$self,\@param);");
         if ($@){
            msg(ERROR,"Module Error: $@");
         }
         else{
            return(0) if (!$bk);
         }
      }

   }
   return(1);
}




sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   return(1);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;   # if $rec is undefined, general access to app is checked
   my %param=@_;  

   if (exists($self->{useMenuFullnameAsACL})){
      my $func=["Main","MainWithNew"];
      if ($self->{useMenuFullnameAsACL} eq "1"){
         $self->{useMenuFullnameAsACL}=$self->Self();
      }
      my $acl=$self->getMenuAcl($ENV{REMOTE_USER},
                        $self->{useMenuFullnameAsACL},
                        func=>$func);
      if (defined($acl)){
         if (!defined($rec) && grep(/^(read|write)$/,@$acl)){
            return("header","default");
         }
         return("ALL") if (grep(/^(read|write)$/,@$acl));
      }
      return();
   }

   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   if (exists($self->{useMenuFullnameAsACL})){
      my $func=["Main","MainWithNew"];
      $func=["MainWithNew","New"] if (!defined($rec));
      my $acl=$self->getMenuAcl($ENV{REMOTE_USER},
                        $self->{useMenuFullnameAsACL},
                        func=>$func);
      if (defined($acl)){
         return("ALL") if (grep(/^write$/,@$acl));
      }
      return();
   }
   return();  # ALL means all groups - else return list of fieldgroups
}

sub isWriteOnFieldGroupValid
{
   my $self=shift;
   my $idval=shift;
   my $group=shift;

   my $idfield=$self->IdField();
   $idval=~s/[\*\? ]//g;
   if (defined($idfield) && $idval ne ""){
      $self->SetFilter({$idfield->Name()=>\$idval});
      my ($crec,$msg)=$self->getOnlyFirst(qw(ALL));
      my @g=$self->isWriteValid($crec);
      if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
         return(1);
      }
   }
   return(0);
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef);  # ALL means all groups - else return list of fieldgroups
}


#
# isDataInputFromUserFrontend is usefull to do validation of data's which
# input is from the user frontend/Web-Interface
#
sub isDataInputFromUserFrontend
{
   my $self=shift;
   $self->Context->{DataInputFromUserFrontend}=$_[0] if (defined($_[0]));
   if (!exists($self->Context->{DataInputFromUserFrontend})){
      # doing default isDataInputFromUserFrontend handling (from kernel.pm)
      if (($ENV{SCRIPT_URI} ne "" || getClientAddrIdString() ne "" ) &&
          $W5V2::OperationContext ne "QualityCheck"){
         return(1);
      }
   }
   return($self->Context->{DataInputFromUserFrontend});
}

#
# isDirectFilter checks, if a filter expression is a direct search to
# ohne unique IdField Record
#
sub isDirectFilter
{
  my $self=shift;
  my @flt=@_;
  my $idfieldobj=$self->IdField();
  return(0) if (!defined($idfieldobj));
  my $idfieldname=$idfieldobj->Name();
  if ($#flt==0){
     if (ref($flt[0]) eq "HASH"){
        if (defined($flt[0]->{$idfieldname})){
           if (ref($flt[0]->{$idfieldname}) eq "ARRAY"){
              if ($#{$flt[0]->{$idfieldname}}==0){
                 if ($flt[0]->{$idfieldname}->[0]=~m/[\*\?]/){
                    return(0);
                 }
                 return(1);
              }
           }
           elsif (ref($flt[0]->{$idfieldname}) eq "SCALAR"){
              if (${$flt[0]->{$idfieldname}}=~m/[\*\?]/){
                 return(0);
              }
              return(1);
           }
           else{
              if (!ref($flt[0]->{$idfieldname}) &&
                  ($flt[0]->{$idfieldname}=~m/^[0-9a-z_\-.]+$/i)){
                 return(1);
              }
           }
        }
     }
  }
  return(0);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   foreach my $fo ($self->getFieldObjsByView([qw(ALL)],
                                             oldrec=>$oldrec,
                                             opmode=>'FinishDelete')){
      if ($fo){
         $fo->FinishDelete($oldrec);
      }
   }
   #
   # FinishSubDelete based on RefFromId is buggy because all operations
   # can only be done on the direkt parent of the sublist field. If there
   # are operations on other objects done, there are errors inevitable
   #
   #my $pid=Query->Param("RefFromId");
   #my $p=$self->getParent();
   #if (defined($p) && defined($pid) && $p->can("FinishSubDelete")){
   #   $p->FinishSubDelete($pid);
   #}
   my $selfname=$self->SelfAsParentObject();
   my $idfield=$self->IdField();
   if (defined($idfield) && $self->Self() ne "base::history"){
      my $id=$idfield->RawValue($oldrec);
      if ($id ne ""){
         #####################################################################
         # BulkDelete interviewCache
         my $itodo=getModuleObject($self->Config,"base::interviewtodocache");
         $itodo->BulkDeleteRecord({
            dataobject=>[$self->SelfAsParentObject()],
            dataobjectid=>\$id
         });
         #####################################################################
         my $history=getModuleObject($self->Config,"base::history");
         $history->BulkDeleteRecord({dataobject=>[$self->SelfAsParentObject()],
                                     dataobjectid=>\$id});
         my $wf=getModuleObject($self->Config,"base::workflow");
         $wf->SetFilter({stateid=>"<20",class=>\"base::workflow::DataIssue",
                         directlnktype=>\$selfname,
                         directlnkid=>\$id});
         my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
         if (defined($WfRec)){
            $wf->Store($WfRec,{stateid=>'25',
                               note=>'related data record deleted',
                               fwddebtarget=>undef,
                               fwddebtargetid=>undef,
                               fwdtarget=>undef,
                               fwdtarget=>undef});
         }
      }
   }
}

#sub FinishSubDelete                  # called, if a record in 
#{                                    # SubList has been deleted
#   my $self=shift;
#   my $id=shift;
#   return($self->FinishSubWrite($id));
#}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @keyhandler=(); # keyhandler must be processed at last

   sub ProcessField
   {
      my $fo=shift;
      my $oldrec=shift;
      my $newrec=shift;

      if ($fo){
         my $field=$fo->Name();
         $fo->FinishWrite($oldrec,$newrec);
      }
   }
   foreach my $fo ($self->getFieldObjsByView([qw(ALL)],
                                             current=>$newrec,
                                             oldrec=>$oldrec,
                                             opmode=>'FinishWrite')){
      if ($fo->Type() eq "KeyHandler"){
         push(@keyhandler,$fo);
      }
      else{
         ProcessField($fo,$oldrec,$newrec);
      }
   }
   foreach my $kh (@keyhandler){
      ProcessField($kh,$oldrec,$newrec);
   }


   #
   # FinishSubWrite based on RefFromId is buggy because all operations
   # can only be done on the direkt parent of the sublist field. If there
   # are operations on other objects done, there are errors inevitable
   #
   #my $pid=Query->Param("RefFromId");
   #my $p=$self->getParent();
   #if (defined($p) && defined($pid) && $p->can("FinishSubWrite")){
   #   $p->FinishSubWrite($pid);
   #}


}



sub UpdateParentMdate
{
   my $self=shift;
   my $parentobj=shift;
   my $refid=shift;

   if ($parentobj ne "" && $refid ne ""){
      my $p=getModuleObject($self->Config,$parentobj);
      my $mdate;
      if (defined($p)){
         $mdate=$p->getField("mdate");
      }
      if (defined($p) && defined($mdate)){
         my $idname=$p->IdField->Name();
         my %flt=($idname=>\$refid);
         $p->SetFilter(\%flt);
         my @l=$p->getHashList(qw(ALL));
         if ($#l==0){
            my $now=NowStamp("en");
            #msg(INFO,"lnkcontact parent mdate update to $now");
            $p->ValidatedUpdateRecord($l[0],{mdate=>$now},\%flt);
         }
      }
   }

}


#
# FinishSubWrite based on RefFromId is buggy because all operations
# can only be done on the direkt parent of the sublist field. If there
# are operations on other objects done, there are errors inevitable
#
#sub FinishSubWrite
#{
#   my $self=shift;
#   my $id=shift;
#   my %rec=();
#   #msg(INFO,"default FinishSubWrite in $self on $id"); 
#   my $idname=$self->IdField->Name();
#
#   $self->SetFilter($idname=>\$id);
#   $self->SetCurrentView(qw(ALL));
#   $self->ForeachFilteredRecord(sub{
#         my $rec=$_;
#         $self->ValidatedUpdateRecord($rec,{},{$idname=>\$rec->{$idname}});
#   });
#   return(undef);
#}

sub StoreUpdateDelta
{
   my $self=shift;
   my $mode=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $deltanote=shift;

   if (defined($self->{history})){
      if (ref($self->{history}) ne "HASH"){
         $self->{history}={
            'update'=>'local'
         };
      }
      if (exists($self->{history}->{$mode})){
         my $logto=$self->{history}->{$mode};
         $logto=[$logto] if (ref($logto) ne "ARRAY");
         if ($mode eq "delete"){
            foreach my $histtarget (@$logto){
               if ($histtarget eq "local"){
                  my $label=$self->getRecordHeader($oldrec);
                  $self->HandleHistory(
                     $mode,
                     $histtarget,
                     $oldrec,
                     $newrec,"ALL",$label,undef,$deltanote
                  );
               }
               else{
                  $self->SetCurrentView(qw(ALL));
                  my @fieldlist=$self->getFieldObjsByView(
                     [$self->getCurrentView()],
                     oldrec=>$oldrec,
                     current=>$newrec,
                     opmode=>'StoreUpdateDelta'
                  );
                  foreach my $fobj (@fieldlist){
                     my $field=$fobj->Name;
                     my $old=$oldrec->{$field};
                     my $new=undef;
                     $old=[$old] if (ref($old) ne "ARRAY");
                     $old=join(", ",sort(@{$old}));
                     $old=~s/\r\n/\n/gs;
                     $self->HandleHistory(
                        $mode,
                        $histtarget,
                        $oldrec,
                        $newrec,$field,$old,$new,$deltanote
                     );
                  }
               }
            }
         }
         if ($mode eq "update" || $mode eq "insert"){
            $self->SetCurrentView(qw(ALL));
            my @fieldlist=$self->getFieldObjsByView([$self->getCurrentView()],
                                                    oldrec=>$oldrec,
                                                    current=>$newrec,
                                                    opmode=>'StoreUpdateDelta');
            my %delta=();
            foreach my $fobj (@fieldlist){
               if ($fobj->history){
                  my $field=$fobj->Name;
                  next if ($field eq "srcload" || $field eq "mdate" ||
                           $fobj->Type() eq "File");
                  if (exists($newrec->{$field})){
                     next if (ref($oldrec->{$field}) eq "HASH" ||
                              ref($newrec->{$field}) eq "HASH");
                     my $old=$oldrec->{$field};
                     my $new=$newrec->{$field};
                     $old=[$old] if (ref($old) ne "ARRAY");
                     $new=[$new] if (ref($new) ne "ARRAY");
                     $old=join(", ",sort(@{$old}));
                     if ($fobj->can("allowAnyLatin1")){
                        if ($fobj->allowAnyLatin1()){
                           $new=rmAnyNonLatin1(join(", ",sort(@{$new})));
                        }
                        else{
                           $new=rmNonLatin1(join(", ",sort(@{$new})));
                        }
                     }
                     else{
                        $new=rmNonLatin1(join(", ",sort(@{$new})));
                     }
                     $new=~s/\r\n/\n/gs;
                     $old=~s/\r\n/\n/gs;
                     if (trim($new) ne trim($old)){
                        $delta{$field}={'old'=>$old,'new'=>$new};
                     }
                  }
               }
            }
            if (keys(%delta)){   # optimices the request of field object list
               foreach my $field (keys(%delta)){
                  my $old=$delta{$field}->{'old'};
                  my $new=$delta{$field}->{'new'};
                  foreach my $fobj (@fieldlist){
                     if ($fobj->Name eq $field &&
                         $fobj->history){
                        foreach my $histtarget (@$logto){
                           $self->HandleHistory(
                              $mode,
                              $histtarget,
                              $oldrec,
                              $newrec,$field,$old,$new,$deltanote);
                        }
                     }
                  }
               }
            }
         }
      }
   }

   return(1);
}

sub HandleHistory
{
   my $self=shift;
   my $mode=shift;
   my $histtarget=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $field=shift;
   my $oldval=shift;
   my $newval=shift;
   my $deltanote=shift;

   my $logparent;
   my $h;
   my $id;
   my $dataobject;
   my $histreclogid;

   if ($histtarget ne "local"){
      my $histfield=$histtarget->{field};
      if (ref($histfield) eq "CODE"){
         $histfield=&{$histfield}($mode,$oldrec,$newrec);
      }
      return(1) if ($field ne "ALL" && $field ne $histfield); 
      my $dataobj=$histtarget->{dataobj};
      my $dataobjid=$histtarget->{id};
      if (ref($dataobj) eq "CODE"){
         $dataobj=&{$dataobj}($mode,$oldrec,$newrec);
      }
      if (ref($dataobjid) eq "CODE"){
         $dataobjid=&{$dataobjid}($mode,$oldrec,$newrec);
      }
      $logparent=getModuleObject($self->Config,$dataobj);
      $h=getModuleObject($self->Config,"base::history");
      $id=effVal($oldrec,$newrec,$dataobjid);
      $field=$histtarget->{as};
   }
   else{
      $logparent=$self;
      my $idname=$logparent->IdField->Name();
      $h=$logparent->getPersistentModuleObject("History","base::history");
      $id=effVal($oldrec,$newrec,$idname);
   }
   
   if (defined($logparent) && defined($h) && $id ne "" && $field ne ""){
      $dataobject=$logparent->SelfAsParentObject();
      my $idname=$logparent->IdField->Name();
      my $histrec={name=>$field,
                   dataobject=>$dataobject,
                   dataobjectid=>$id,
                   oldstate=>$oldval,
                   newstate=>$newval,
                   operation=>$mode};
      my $comments;
      my $addr=getClientAddrIdString();
      if ($addr ne ""){
         $comments.="ClientIP = $addr \n";
      }
      if ($W5V2::OperationContext ne "WebFrontend" &&
          $W5V2::OperationContext ne ""){
         $comments.="CONTEXT = $W5V2::OperationContext \n";
      }
      if ($W5V2::HistoryComments ne ""){
         $comments.=$W5V2::HistoryComments;
      }
      if (defined($comments)){
         $histrec->{comments}=$comments;
      }
      if (defined($deltanote)){
         $histrec->{comments}.="\n\n".$deltanote;
      }

      $histreclogid=$h->ValidatedInsertRecord($histrec);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      msg(INFO,"DELTAWRITE (%s(%s): %-10s : old=%s new=%s as base::history(%s)",
               $dataobject,$id,$field,$oldval,$newval,$histreclogid);
      if ($newval=~m/^HASH\(/){
         Stacktrace();
      }
   }
}


sub NormalizeByIOMap
{
   my $self=shift;
   my $queryfrom=shift;
   my $flt=shift;
   my %param=@_;
   my $debug;

   if (defined($param{DEBUG}) &&
       ref($param{DEBUG}) eq "SCALAR"){
      $debug=$param{DEBUG};
   }

   my $map=$self->getIOMap($queryfrom);
   if ($#{$map}!=-1){
      $$debug.="\nStart mapping:\n" if ($debug);
      foreach my $mrec (@$map){
         my $match=0;
         my $check=0;
         if ($debug){
            my $cmt=$mrec->{comments};
            $cmt=~s/\n/ /g;
            $cmt=limitlen($cmt,40,1);
            $$debug.="RULE($mrec->{id}) $cmt\n";
         }
         CHK: for(my $fnum=1;$fnum<=5;$fnum++){
            my $fname=$mrec->{'on'.$fnum.'field'};
            if ($fname ne ""){
               my $mexp=$mrec->{'on'.$fnum.'exp'};
               if ($mexp ne ""){
                  $check++;
                  my $cmd;
                  my $fltval="";
                  next CHK if (!exists($flt->{$fname}));
                  $fltval=$flt->{$fname};

                  if ($mexp=~m/^!/){
                     $mexp=~s/^!//;
                     if ($mexp=~m/^\/.*\/[i]*$/){
                        $cmd="\$fltval!=~m$mexp ? \$match++ : \$fail++;";
                     }
                     else{
                        $mexp=~s/'/\\'/g;
                        $cmd="(\$fltval ne '$mexp') ? \$match++ : \$fail++;";
                     }
                  }
                  else{
                     if ($mexp=~m/^\/.*\/[i]*$/){
                        $cmd="\$fltval=~m$mexp ? \$match++ : \$fail++;";
                     }
                     else{
                        $mexp=~s/'/\\'/g;
                        $cmd="(\$fltval eq '$mexp') ? \$match++ : \$fail++;";
                     }
                  }
                  my $fail=0;
                  eval($cmd);
                  last if ($fail);
                  
               }
            }
         }
         if ($match==$check && $check>0){     # do modifications
            $$debug.=" -> matched:" if ($debug);
            for(my $fnum=1;$fnum<=5;$fnum++){
               my $fname=$mrec->{'op'.$fnum.'field'};
               if ($fname ne ""){
                  my $mexp=$mrec->{'op'.$fnum.'exp'};
                  if ($mexp ne ""){
                     my $n;
                     my $cmd="\$n=\$flt->{\$fname}=~$mexp;";
                     eval($cmd);
                     if ($@ ne ""){
                        $$debug.=" $fname(ERROR)" if ($debug);
                     }
                     else{
                        if ($n){
                           $$debug.=" $fname($n)" if ($debug);
                        }
                     }
                  }
               }
            }
            $$debug.="\n" if ($debug);
         }
         else{
            $$debug.=" -> failed\n" if ($debug);
         }
      }
   }
}

sub getIdByHashIOMapped
{
   my $self=shift;
   my $queryfrom=shift;
   my $q=shift;
   my %param=@_;
   my $id;
   my $debug;
   if (defined($param{DEBUG}) &&
       ref($param{DEBUG}) eq "SCALAR"){
      $debug=$param{DEBUG};
   }

   my %flt;
   $$debug.=$self->Self."::getIdByHashIOMapped from $queryfrom\n\n" if ($debug);


   $$debug.="Request:\n" if ($debug);
   foreach my $k (keys(%$q)){
      $flt{$k}=$q->{$k};
      $$debug.=sprintf("%-10s => %s\n","'".$k."'","'".$q->{$k}."'") if ($debug);
   }

   $self->NormalizeByIOMap($queryfrom,\%flt,%param);

   %{$q}=%flt; # return the mapped query structure to the calling process

   $$debug.="\nRequest after mappings:\n" if ($debug);
   foreach my $k (keys(%flt)){  # fix search (no like)
      if (exists($param{iomapped}) && ref($param{iomapped}) eq "HASH"){
         $param{iomapped}->{$k}=$flt{$k};   # return the mapped record
      }
      my $v=$flt{$k};
      $$debug.=sprintf("%-10s => %s\n","'".$k."'","'".$v."'") if ($debug);
      if ($v ne ""){
         if ($param{ForceLikeSearch} eq "1" || 
             ($v=~m/^".*"/)){  # $ nicht am Ende, damit mehrfach Suchen
            if (!($v=~m/^".*/)){
               $v="\"$v\"";
            }
            $flt{$k}=$v;       # möglich werden!
         }
         else{
            $flt{$k}=\$v;
         }
      }
   }
   if (!defined($flt{cistatusid})){
      if ($self->getField("cistatusid")){
         $flt{cistatusid}="<=5";
      }
   }

   $self->ResetFilter();
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      $$debug.="\nFlt: ".Dumper(\%flt),"\n" if ($debug);
   }
   $self->SetFilter(\%flt);
   my $idfield=$self->IdField();
   my @l=$self->getVal($idfield->Name());
   $$debug.="\nResult ".$idfield->Name()." = ".join(", ",@l) if ($debug);

   return() if ($#l==-1);

   if (wantarray()){
      return(@l);
   }
   return($l[0]);
}

sub getIOMap
{
   my $self=shift;
   my $queryfrom=shift;
   my $force=shift;
   my $project=shift;

   if (!defined($project)){
      $project=0;
   }

   my $c=$self->Cache;

   if ($force){
      delete($c->{'IOMap'});
   }
   $c->{'IOMap'}={} if (!exists($c->{'IOMap'}));
   $c=$c->{'IOMap'};
   
   if (!exists($c->{$queryfrom}) ||
       $c->{$queryfrom}->{t}<time()-120){
      my $iomap=$self->getPersistentModuleObject("IOMap","base::iomap");
      my $flt={dataobj=>[$self->Self]};
      if (defined($queryfrom)){
         $flt->{queryfrom}=[$queryfrom,"any"];
         $flt->{cistatusid}=[4];
      }
      if ($project){
         $flt->{cistatusid}=[3,4];
      }
      
      $iomap->SetFilter($flt);
    
      my @data=$iomap->getHashList(qw(mapprio cdate queryfrom comments
                                     on1field on1exp
                                     on2field on2exp
                                     on3field on3exp
                                     on4field on4exp
                                     on5field on5exp
                                     on5field on5exp
                                     op1field op1exp
                                     op2field op2exp
                                     op3field op3exp
                                     op4field op4exp
                                     op5field op5exp
                                     op5field op5exp
                                     id ));
      my @ndata;
      foreach my $rec (@data){  # ensure, that all data has been expanded
         my %n;
         foreach my $k (keys(%$rec)){
            $n{$k}=$rec->{$k};
         }
         push(@ndata,\%n);
      }
      $c->{$queryfrom}->{e}=\@ndata;
      $c->{$queryfrom}->{t}=time();
   }
   return($c->{$queryfrom}->{e});
}

sub ValidatedInsertOrUpdateRecord
{
   my $self=shift;
   my $newrec=shift;
   my @filter=@_;

   $self->SetCurrentView(qw(ALL));
   $self->SetFilter(@filter);
   $self->SetCurrentOrder("NONE");  # needed because MSSQL cant order text flds
   my $idfname=$self->IdField()->Name();
   my $found=0;
   my @idlist=();
   my $opobj=$self->Clone();
   $self->ForeachFilteredRecord(sub{
      my $rec=$_;
      my $changed=0;
      my $restoremdate=1;
      foreach my $k (keys(%$newrec)){
         if ($k ne $idfname){
            if (exists($rec->{$k})){
               my $o=$rec->{$k};
               my $n=$newrec->{$k};
               if (defined($o)){
                  $o=rmAnyNonLatin1(trim($o));
                  $o=~s/\r\n/\n/gs;
               }
               if (defined($n)){
                  $n=rmAnyNonLatin1(trim($n));
                  $n=~s/\r\n/\n/gs;
               }
               if ($o ne $n){
                  $changed=1;
                  if ($k ne "srcload"){
                     $restoremdate=0;
                  }
               }
            }
         }
         else{
            if (exists($newrec->{$k})){
               delete($newrec->{$k});
            }
         }
      }
      if ($changed){
         if ($restoremdate){  # handling if only srcload has been changed
            if (exists($rec->{mdate}) && $rec->{mdate} ne ""){
               $newrec->{mdate}=$rec->{mdate};
            }
         }
         if (!($opobj->ValidatedUpdateRecord($rec,$newrec,
               {$idfname=>$rec->{$idfname}}))){
            msg(ERROR,"internal error on ValidatedInsertOrUpdateRecord %s ".
                      "in $self",
                Dumper(\@filter));
            return(0); # better do not process forther records
         }
      }
      push(@idlist,$rec->{$idfname});
      $found++;
      return(1);  # return true - further records should be processed
   });
   if (!$found){
      my $id=$self->ValidatedInsertRecord($newrec);
      push(@idlist,$id) if ($id);
   }
   return(@idlist);
}


########################################################################
sub SecureValidatedInsertRecord
{
   my $self=shift;
   my $newrec=shift;

   $self->isDataInputFromUserFrontend(1);
   my @groups=$self->isWriteValid();
   if ($#groups>-1 && defined($groups[0])){
      if ($self->SecureValidateFieldAccess(undef,$newrec,\@groups)){
         return($self->ValidatedInsertRecord($newrec));
      }
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"SecureValidatedInsertRecord: ".
                              "unknown error in ${self}::Validate()");
      }
   }
   else{
      $self->LastMsg(ERROR,"you are not autorized to insert the ".
                           "requested record");
   }
   return(undef);
}

sub StartTransaction
{
   my ($self,$operation,$oldrec,$newrec)=@_;

   return(1);
}

sub RoolbackTransaction
{
   my ($self,$operation,$oldrec,$newrec)=@_;

   return(1);
}

sub FinishTransaction
{
   my ($self,$operation,$oldrec,$newrec)=@_;

   return(1);
}


sub isAnonymousAccessValid
{
    my $self=shift;
    my $method=shift;
    return(0);
}

sub rejectAnonymousAccess
{
   my $self=shift;
   my $method=shift;

   printf("Status: 403 Forbidden - no anonymous access allowed\n");
   printf("Content-type: text/xml\n\n".
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".
          "<root>".
          "<error>403 Forbidden - no anonymous access allowed</error>".
          "</root>\n");
}



sub validateAnonymousAccess
{
   my $self=shift;
   my $method=shift;

   if (lc($ENV{REMOTE_USER}) eq "anonymous" ||
       $ENV{REMOTE_USER} eq ""){
      if (!$self->isAnonymousAccessValid($method)){
         $self->rejectAnonymousAccess($method);
         return(undef);
      }
   }
   return(1);
}


sub ValidatedInsertRecord
{
   my $self=shift;
   my $newrec=shift;

   my $bk;
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
      $self->LastMsg(ERROR,"W5BaseOperationMode=readonly");
      return(undef);
   }
   if ($self->StartTransaction("insert",undef,$newrec)){
      $bk=$self->ValidatedInsertRecordTransactionless($newrec);
   }
   else{
      $self->LastMsg(ERROR,"can not start insert transaction");
   }
   if ($self->LastMsg()){
      $self->RoolbackTransaction("insert",undef,$newrec);
   }
   $self->FinishTransaction("insert",undef,$newrec);

   return($bk);
}
sub ValidatedInsertRecordTransactionless
{
   my $self=shift;
   my $newrec=shift;

   $self->doInitialize();
   if (!$self->preValidate(undef,$newrec)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"ValidatedInsertRecord: ".
                              "unknown error in ${self}::preValidate()");
      }
   }
   else{
      $self->NormalizeByIOMap("preWrite",$newrec);
      if ($newrec=$self->validateFields(undef,$newrec)){
         # check, if call is Secure
         if (in_array([map({(caller($_))[3];} (2..5))],
              'kernel::DataObj::SecureValidatedInsertRecord')){
            if (!$self->SecureValidate(undef,$newrec)){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"ValidatedInsertRecord: ".
                                 "unknown error in ${self}::SecureValidate()");
               }
               return(undef);
            }
         }
         if ($self->Validate(undef,$newrec)){
            $self->finishWriteRequestHash(undef,$newrec);
            my $bak=$self->InsertRecord($newrec);
            $self->SendRemoteEvent("ins",undef,$newrec,$bak) if ($bak);
            $self->FinishWrite(undef,$newrec) if ($bak);
            $self->StoreUpdateDelta("insert",undef,$newrec) if ($bak);
            return($bak);
         }
         else{
            if ($self->LastMsg()==0){
               $self->LastMsg(ERROR,"ValidatedInsertRecord: ".
                                    "unknown error in ${self}::Validate()");
            }
         }
      }
      else{
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"ValidatedInsertRecord: ".
                                 "unknown error in ${self}::validateFields()");
         }
      }
   }
   return(undef);
}


sub InsertRecord
{
   my $self=shift;
   my $newrec=shift;  # hash ref
   msg(ERROR,"insertRecord not implemented in DataObj '$self'");
   return(0);
}
########################################################################
sub SecureValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $self->isDataInputFromUserFrontend(1);

   my $wrok=0;
   if (defined($self->{individualAttr})){
      my @fieldnames=keys(%$newrec);
      if ($#fieldnames==0){
         my $fld=$self->getField($fieldnames[0]);
         if (defined($fld) && $fld->Type() eq "IndividualAttr"){
            $wrok=1;
         }
      }
   }
   my @groups=$self->isWriteValid($oldrec);
   if (($#groups>-1 && defined($groups[0])) || $wrok){
      if ($self->SecureValidateFieldAccess($oldrec,$newrec,\@groups)){
         return($self->ValidatedUpdateRecord($oldrec,$newrec,@filter));
      }
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"SecureValidatedUpdateRecord: ".
                              "unknown error in ${self}::Validate()");
      }
   }
   else{
      $self->LastMsg(ERROR,"you are not autorized to update the ".
                           "requested record");
   }
   return(undef);
}

sub UserReCertHandling
{
   my $self=shift;
   my $rec=shift;
   my $editgroups=shift;

   if (exists($rec->{lrecertreqdt}) && $rec->{lrecertreqdt} ne "" &&
       exists($rec->{lrecertdt})){
      if (!defined($editgroups) || $#{$editgroups}!=-1){
         my @certUserIds=$self->getReCertificationUserIDs($rec);
         my $userid=$self->getCurrentUserId();

         # reCertification is only allowed from UserIds which are returned
         # from getReCertificationUserIDs (on base::grp per Default OrgAdmins
         # and on all other per Default the databoss)
         if (in_array($userid,\@certUserIds)){
            my $op=$self->Clone();
            my $idfield=$self->IdField();
            my $idname=$idfield->Name();
            $op->ValidatedUpdateRecord($rec,{
                 lrecertreqdt=>undef,
                 lrecertdt=>NowStamp("en"),
                 lrecertuser=>$userid,
                 mdate=>$rec->{mdate}
            },{$idname=>\$rec->{$idname}});
         }

      }
   }
}


sub loadPrivacyAcl
{
   my $self=shift;
   my $parentobj=shift;
   my $parentrefid=shift;
   my $foundrw=0;
   my $foundro=0;
   my $userid=$self->getCurrentUserId();

   my $pobj=getModuleObject($self->Config,$parentobj);
   if (defined($pobj) && $parentrefid ne ""){
      my $idobj=$pobj->IdField();
      if (defined($idobj)){
         $pobj->SetFilter({$idobj->Name()=>\$parentrefid});
         my @fl=qw(contacts);
         if ($pobj->getField("databossid")){
            push(@fl,"databossid");
         }
         my ($prec,$msg)=$pobj->getOnlyFirst(@fl);
         if (exists($prec->{databossid}) && $userid==$prec->{databossid}){
            $foundrw=1;
            $foundro=1;
         }
         else{
            if (defined($prec) && defined($prec->{contacts}) &&
                ref($prec->{contacts}) eq "ARRAY"){
               my %grps=$self->getGroupsOf($userid,["RMember"],"both");
               my @grpids=keys(%grps);
               foreach my $contact (@{$prec->{contacts}}){
                  if ($contact->{target} eq "base::user" &&
                      $contact->{targetid} ne $userid){
                     next;
                  }
                  if ($contact->{target} eq "base::grp"){
                     my $grpid=$contact->{targetid};
                     next if (!grep(/^$grpid$/,@grpids));
                  }
                  my @roles=($contact->{roles});
                  if (ref($contact->{roles}) eq "ARRAY"){
                     @roles=@{$contact->{roles}};
                  }
                  if (grep(/^(write)$/,@roles)){
                     $foundrw=1;
                     $foundro=1;
                  }
                  if (grep(/^(privread)$/,@roles)){
                     $foundro=1;
                  }
               }
            }
         }
      }
   }
   return({ro=>$foundro,rw=>$foundrw});
}


sub getWriteAuthorizedContacts
{
   my $self=shift;
   my $current=shift;
   my $depend=shift;
   my $maxlevel=shift;   # check against which maxresposelevel
   my $resbuf=shift;     # hash to store result

   sub  addUid
   {
      my $uid=shift; 
      my $id=shift;
      my $responselevel=shift;

      if (!exists($uid->{$id})){
         $uid->{$id}={
            userid=>$id,
            responselevel=>$responselevel
         };                      
         if (!defined($id)){
            $uid->{$id}->{fullname}="further";
         }
      }                          
      else{                      
         if ($uid->{$id}->{responselevel}>$responselevel){
            $uid->{$id}->{responselevel}=$responselevel;
         }
      }
   }

   foreach my $depfld (@{$depend}){
      my $fld=$self->getField($depfld);
      if (defined($fld)){
         my $d=$fld->RawValue($current);
         if ($depfld eq "contacts"){
            if (ref($d) eq "ARRAY"){
               foreach my $crec (@$d){
                  my $r=$crec->{roles};
                  $r=[$r] if (ref($r) ne "ARRAY");
                  if (in_array($r,["write","admin"])){
                     if ($crec->{target} eq "base::user"){
                        if ($maxlevel>=30){
                           addUid($resbuf,$crec->{targetid},30);
                        }
                     }
                     if ($crec->{target} eq "base::grp"){
                        if ($maxlevel>=50){
                           my @l=$self->getMembersOf($crec->{targetid},
                              "RMember",
                              "direct"
                           );
                           foreach my $userid (@l){
                              addUid($resbuf,$userid,50);
                           }
                           if ($maxlevel>=99){
                              addUid($resbuf,undef,99);
                           }
                        }
                     }
                  }
               }
            }
         }
         else{
            my $responselevel=1;
            if ($depfld ne "databossid"){
               $responselevel=20;
            }
            if ($maxlevel>=$responselevel){
               addUid($resbuf,$d,$responselevel);
            }
         }
      }
   }
   my @fill=grep({!exists($_->{fullname})} values(%$resbuf));
   if ($#fill!=-1){
      my $user=getModuleObject($self->Config,"base::user");
      my @uid=map({$_->{userid}} @fill);
      $user->SetFilter({userid=>\@uid,cistatusid=>\'4'});
      foreach my $urec ($user->getHashList(qw(fullname talklang email 
                                              cistatusid))){
         if ($urec->{cistatusid} eq "4"){
            $resbuf->{$urec->{userid}}->{fullname}=$urec->{fullname};
            $resbuf->{$urec->{userid}}->{talklang}=$urec->{talklang};
            $resbuf->{$urec->{userid}}->{email}=$urec->{email};
         }
         else{
            delete($resbuf->{$urec->{userid}});
         }
      }
   }
}

sub NotifyLangContacts
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $notifyparam=shift;
   my $notifycontrol=shift;
   my $gentext=shift;               # function callback to get subject/text
   my %notifyparam=%$notifyparam;

   my $subject;
   my $text;

   my $langSplit=$notifyparam{langsplit};      # bisher die einig unterstützt
   if (!in_array($langSplit,[qw(langsplit)])){ # sprachabhängige Behandlung
      $langSplit="langsplit";
   }

   my $idfield=$self->IdField();
   if (defined($idfield)){
      my $id=$idfield->RawValue($oldrec);
      if ($id ne ""){
         if (!exists($notifyparam{dataobj})){
            $notifyparam{dataobj}=$self->Self;
         }
         if (!exists($notifyparam{dataobjid})){
            $notifyparam{dataobjid}=$id;
         }
      }
   }
   my %userid;
   my @emailto;
   my @emailcc;
   if (ref($notifyparam{emailto}) eq "ARRAY"){
      @emailto=@{$notifyparam{emailto}};
      foreach my $uid (@{$notifyparam{emailto}}){
         $userid{$uid}++;
      }
   }
   if (ref($notifyparam{emailcc}) eq "ARRAY"){
      @emailcc=@{$notifyparam{emailcc}};
      foreach my $uid (@{$notifyparam{emailcc}}){
         $userid{$uid}++;
      }
   }
   my %talklang;
   my $resbuf;
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({userid=>[keys(%userid)],cistatusid=>\'4'});
   foreach my $urec ($user->getHashList(qw(fullname talklang email))){
      $resbuf->{$urec->{userid}}->{fullname}=$urec->{fullname};
      $resbuf->{$urec->{userid}}->{talklang}=$urec->{talklang};
      $resbuf->{$urec->{userid}}->{email}=$urec->{email};
      $talklang{$urec->{talklang}}++; 
   }

   my $lastlang;
   if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
      $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
   }
   foreach my $lang (keys(%talklang)){
      $ENV{HTTP_FORCE_LANGUAGE}=$lang;
      my @cleanemailto;
      my @cleanemailcc;
      foreach my $uid (@emailto){
         if ((exists($resbuf->{$uid}) && $resbuf->{$uid}->{talklang} eq $lang) ||
             !exists($resbuf->{$uid})){
            push(@cleanemailto,$uid);
         }
      }
      $notifyparam{emailto}=\@cleanemailto;
      foreach my $uid (@emailcc){
         if ((exists($resbuf->{$uid}) && $resbuf->{$uid}->{talklang} eq $lang) ||
             !exists($resbuf->{$uid})){
            push(@cleanemailcc,$uid);
         }
      }
      $notifyparam{emailcc}=\@cleanemailcc;
     
      my ($subject,$text)=&{$gentext}($self,\%notifyparam,$notifycontrol);
     
      my $mode=$notifycontrol->{mode};
      $mode="INFO" if ($mode eq "");
     
      if (defined($subject) && defined($text)){
         if (!defined($notifycontrol->{wfact})){
            $notifycontrol->{wfact}=getModuleObject($self->Config,
                                                    "base::workflowaction");
         }
         $notifycontrol->{wfact}->Notify($mode,$subject,$text,%notifyparam);
      }
   }
   if (defined($lastlang)){
      $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
   }
   else{
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
}




sub NotifyWriteAuthorizedContacts   # write an info to databoss and contacts
{                                   # with write role
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $notifyparam=shift;
   my $notifycontrol=shift;
   my $gentext=shift;               # function callback to get subject/text
   my %notifyparam=%$notifyparam;

   my $subject;
   my $text;

   # target calculation

   my $databossfld=$self->getField("databossid");
   my $contactsfld=$self->getField("contacts");


   my $idfield=$self->IdField();
   if (defined($idfield)){
      my $id=$idfield->RawValue($oldrec);
      if ($id ne ""){
         if (!exists($notifyparam{dataobj})){
            $notifyparam{dataobj}=$self->Self;
         }
         if (!exists($notifyparam{dataobjid})){
            $notifyparam{dataobjid}=$id;
         }
      }
   }

   my %ul;
   $self->getWriteAuthorizedContacts($oldrec,[qw(databossid contacts)],30,\%ul);
   my @ul=sort({$a->{responselevel}<=>$b->{responselevel}} values(%ul));

   my %mailto;
   if (defined($notifyparam{emailto})){
      if (ref($notifyparam{emailto}) eq "ARRAY"){
         %mailto=map({$_=>1} @{$notifyparam{emailto}});
      }
      else {
         $mailto{$notifyparam{emailto}}++;
      }
   }

   if ($ul[0]->{responselevel}==1){
      my $cont=shift(@ul);
      $mailto{$cont->{userid}}++;
      $notifyparam{lang}=$cont->{talklang};
   }

   my %mailcc;
   if (defined($notifyparam{emailcc})){
      if (ref($notifyparam{emailcc}) eq "ARRAY") {
         %mailcc=map({$_=>1} @{$notifyparam{emailcc}});
      }
      else {
         $mailcc{$notifyparam{emailcc}}++;
      }
   }
   
   if ($#ul!=-1){ 
      foreach my $crec (@ul){
         if (defined($crec->{userid})){
            $mailcc{$crec->{userid}}++;
            if (!defined($notifyparam{lang})){
               $notifyparam{lang}=$crec->{talklang};
            }
         }
      }
   }

   foreach my $to (keys(%mailto)) {
      delete($mailcc{$to}) if (exists($mailcc{$to}));
   }
   if (keys(%mailto)==0 && keys(%mailcc)==0){
      msg(INFO,"no mail targets - skip mailing");
      return(0);
   }
   $notifyparam{emailto}=[keys(%mailto)];
   $notifyparam{emailcc}=[keys(%mailcc)];
   $notifyparam{emailcategory}=['AutoDataUpdate'];
   if ($notifycontrol->{datasource} ne ""){
      my $datasource=$notifycontrol->{datasource};
      $datasource=~s/\s/_/g;
      push(@{$notifyparam{emailcategory}},'AutoDataUpdate_'.$datasource);
   }

   my $lastlang;
   if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
      $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
   }
   $ENV{HTTP_FORCE_LANGUAGE}=$notifyparam{lang};

   my ($subject,$text)=&{$gentext}($self,\%notifyparam,$notifycontrol);

   if ($notifycontrol->{autosubject}){
      $subject="" if (!defined($subject));
      my $nsubject=$self->T("Automatic data update");
      $nsubject.=" ".$subject if ($subject ne "");
      if ($notifycontrol->{datasource} ne ""){  # automatische zusammenstellen
         if ($notifycontrol->{datasource}=~m/::qrule::/){
            $nsubject.=" ".$self->T("based on QualityRule")." \"". # der subject
                $self->T($notifycontrol->{datasource},
                         $notifycontrol->{datasource})."\"";
         }
         else{
            $nsubject.=" ".$self->T("based on datasource")." ". # der subject
                       $notifycontrol->{datasource};            # zeile
         }
      }
      $subject=$nsubject;
   }
   if (defined($text) && $notifycontrol->{autotext}){  # automatischen header
      my $ntext=$self->T("Dear databoss",'kernel::QRule'); # und fooder an den
      $ntext.=",\n\n";                                     # text anhängen
      $ntext.=$self->T("an update has been made on a record for which ".
                       "you are responsible - based on",'kernel::QRule');
      if ($notifycontrol->{datasource} ne ""){
         $ntext.=" ".$self->T("the datasource")." ".
                 $notifycontrol->{datasource};
      }
      $ntext.=" ".$notifycontrol->{mode}.".";
      $ntext.="\n";
      if ($notifycontrol->{datasource}=~m/::qrule::/){
         $ntext.="For Details of underlying ruleset, check QualityRule ...\n";
         $ntext.="$notifycontrol->{datasource}\n\n";
      }
      $ntext.="\n".$text."\n\n\n".
               $self->T("This update does not relieve you of the ".
                        "data responsibility!",'kernel::QRule');
      $ntext.="\n";
      $text=$ntext;
   }
   my $mode=$notifycontrol->{mode};
   $mode="INFO" if ($mode eq "");

   if (defined($subject) && defined($text)){
      if (!defined($notifycontrol->{wfact})){
         $notifycontrol->{wfact}=getModuleObject($self->Config,
                                                 "base::workflowaction");
      }
      $notifycontrol->{wfact}->Notify($mode,$subject,$text,%notifyparam);
   }
   if (defined($lastlang)){
      $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
   }
   else{
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
   return(1);
}

sub NotifiedValidatedUpdateRecord
{
   my $self=shift;
   my $notifycontrol=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   return(undef) if (ref($notifycontrol) ne "HASH");

   my %oldval;  # Backup field values, which are going to be changed
   foreach my $k (keys(%$newrec)){
      $oldval{$k}=$oldrec->{$k};
   }

   my $bk;
   if ($self->StartTransaction("update",$oldrec,$newrec)){
      $bk=$self->ValidatedUpdateRecordTransactionless($oldrec,$newrec,@filter);
   }
   else{
      $self->LastMsg(ERROR,"can not start update transaction");
   }
   if ($self->LastMsg()){
      $self->RoolbackTransaction("update",$oldrec,$newrec);
   }
   $self->FinishTransaction("update",$oldrec,$newrec);

   if ($bk){ # now create a notification mail
      my $namefld=$self->getField("fullname");
      if (!defined($namefld)){
         $namefld=$self->getField("name");
      }

      my %notifyparam=(
      #  adminbcc=>1,
         lang=>'en',
      );
      $notifycontrol->{autosubject}=1;

      $self->NotifyWriteAuthorizedContacts($oldrec,$newrec,
                                           \%notifyparam,$notifycontrol,sub {
         my $self=shift;
         my $notifyparam=shift;

        # my $subject=$self->T("Automatic data update",'kernel::QRule');
        # if (defined($namefld)){
        #    my $name=$namefld->FormatedDetail($oldrec,"AscV01");
        #    $subject.=" : ".$name;
        # }
        # if ($notifycontrol->{datasource} ne ""){  #automatische zusammenstellen
        #    $subject.=" ".$self->T("based on datasource")." ". # der subject
        #               $notifycontrol->{datasource};            # zeile
        # }
         my $text=$self->T("Dear databoss",'kernel::QRule');
         $text.=",\n\n";
         $text.=$self->T("an update has been made on a record for which ".
                          "you are responsible - based on",'kernel::QRule');

         $text.=" ".$notifycontrol->{mode}.".\n";
       
         my $fldtext=""; 
         foreach my $k (keys(%$newrec)){
            my $kfld=$self->getField($k);
            if (defined($kfld) && $kfld->uivisible()){
               $fldtext.="\n" if ($fldtext ne "");
               $fldtext.="\n<b>".$kfld->Label().":</b>";
               my $told=$kfld->FormatedDetail(\%oldval,"HtmlV01");
               my $tnew=$kfld->FormatedDetail($newrec,"HtmlV01");
               if (length($tnew.$told)>30){
                  $fldtext.="\n";
                  $fldtext.="<u>".
                            $self->T("old value",'kernel::QRule').":</u>\n";
                  $fldtext.=$told;
                  $fldtext.="\n";                                  
                  $fldtext.="<u>".
                            $self->T("new value",'kernel::QRule').":</u>\n";
                  $fldtext.=$tnew;
               }
               else{
                  $fldtext.=" '".$told."' -> '".$tnew."'";
               }
            }
         }
         return(undef) if ($fldtext eq "");
        
         $text.="\n".$fldtext."\n\n\n";

         if (($notifycontrol->{datasource}=~m/::qrule::/) &&
             $self->can("getAbsolutByIdUrl")){
            my $url=$self->getAbsolutByIdUrl($notifycontrol->{datasource},{
               dataobj=>'base::qrule',
               path=>'FView'
            });
            if (defined($url)){
               $text.=$self->T(
                   "For Details of underlying ruleset, check QualityRule",
                   'kernel::DataObj').
                   " ...\n";
               $text.="$url\n\n";
            }
         }
         $text.=$self->T("This update does not relieve you of the ".
                        "data responsibility!",'kernel::QRule');
         $text.="\n";
         return("",$text);

      });
   }

   return($bk);
}

sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   my $bk;
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
      $self->LastMsg(ERROR,"W5BaseOperationMode=readonly");
      return(undef);
   }
   if ($self->StartTransaction("update",$oldrec,$newrec)){
      $bk=$self->ValidatedUpdateRecordTransactionless($oldrec,$newrec,@filter);
   }
   else{
      $self->LastMsg(ERROR,"can not start update transaction");
   }
   if ($self->LastMsg()){
      $self->RoolbackTransaction("update",$oldrec,$newrec);
   }
   $self->FinishTransaction("update",$oldrec,$newrec);

   return($bk);
}

sub HtmlStatSetList
{
   my $self=shift;
   return(undef);
}

sub ValidatedUpdateRecordTransactionless
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $self->doInitialize();
   my %comprec=%{$newrec};
   if (!$self->preValidate($oldrec,$newrec,\%comprec)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"ValidatedUpdateRecord: ".
                              "unknown error in ${self}::preValidate()");
      }
   }
   else{
      $self->NormalizeByIOMap("preWrite",$newrec);

      #######################################################################
      # Individual Attribute Handling
      if (defined($self->{individualAttr})){
         my @fieldnames=keys(%$newrec);
         if ($self->Self eq "base::workflow"){       # in Workflow-Engine class 
            @fieldnames=grep(!/^class$/,@fieldnames);# is always set, but can
         }                                           # be ignored
         if ($#fieldnames==0 && ($fieldnames[0]=~m/^individualattribute_/)){
            my $fld=$self->getField($fieldnames[0]);
            if (defined($fld)){
               if ($fld->Type() eq "IndividualAttr"){
                  # Write data to "IndividualAttr"
                  my $idfld=$self->IdField();
                  my $id=effVal($oldrec,$newrec,$idfld->Name());
                  my $dataobj=$self->SelfAsParentObject();
                  my $ifieldid=$fld->{grpindivfldid};
                  my $o=getModuleObject($self->Config,
                                        $self->{individualAttr}->{dataobj});
                  $o->SetFilter({indivfieldid=>\$ifieldid,srcdataobjid=>\$id});
                  my ($irec,$msg)=$o->getOnlyFirst(qw(ALL));
                  if (defined($irec)){
                     if (!$o->SecureValidatedUpdateRecord($irec,{
                           indivfieldvalue=>$newrec->{$fieldnames[0]}
                         },{id=>[$irec->{id}]})){
                     }
                  }
               }
               else{
                  msg(ERROR,"try to access IndividualAttr $fieldnames[0] ".
                            "in OperationContext $W5V2::OperationContext ".
                            "by $ENV{REMOTE_USER}");
                  $self->LastMsg(ERROR,"invalid individual Attribut");
                  return(0);
               }
               return(1); 
            }
            else{
               msg(ERROR,"try to access invalid IndividualAttr $fieldnames[0] ".
                         "in OperationContext $W5V2::OperationContext ".
                         "by $ENV{REMOTE_USER}");
               $self->LastMsg(ERROR,"invalid individual Attribut");
               return(0);
            }
         }
      }
      #######################################################################
      if (my $validatednewrec=$self->validateFields($oldrec,$newrec,\%comprec)){
         if (in_array([map({(caller($_))[3];} (2..5))],
              'kernel::DataObj::SecureValidatedUpdateRecord')){
            if (!$self->SecureValidate($oldrec,$validatednewrec)){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"ValidatedInsertRecord: ".
                                 "unknown error in ${self}::SecureValidate()");
               }
               return(undef);
            }
         }
         if ($self->Validate($oldrec,$validatednewrec,\%comprec)){
            $self->finishWriteRequestHash($oldrec,$validatednewrec);
            if (keys(%{$validatednewrec})==0){
               return(1);
            }
            else{
               my $bak=$self->UpdateRecord($validatednewrec,@filter);
               if ($bak){
                  if (effChanged($oldrec,$newrec,"stateid")){
                     $self->SendRemoteEvent("sch",$oldrec,$newrec);
                  }
                  if (effChanged($oldrec,$newrec,"cistatusid")){
                     $self->SendRemoteEvent("sch",$oldrec,$newrec);
                  }
                  $self->SendRemoteEvent("upd",$oldrec,$newrec);
                  $self->FinishWrite($oldrec,$validatednewrec,\%comprec);
                  $self->StoreUpdateDelta("update",$oldrec,\%comprec) if ($bak);
                  foreach my $v (keys(%$newrec)){
                     $oldrec->{$v}=$newrec->{$v};
                  }
               }
               return($bak);
             }
         }
         else{
            if ($self->LastMsg()==0){
               $self->LastMsg(ERROR,"ValidatedUpdateRecord: ".
                                    "unknown error in ${self}::Validate()");
            }
         }
      }
      else{
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"ValidatedUpdateRecord: ".
                                 "unknown error in ${self}::validateFields()");
         }
      }
   }
   return(undef);
}
sub UpdateRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   my @updfilter=@_;   # update filter
   msg(ERROR,"updateRecord not implemented in DataObj '$self'");
   return(0);
}
########################################################################
sub ForeachFilteredRecord
{
   my $self=shift;
   my $method=shift;
   my @paramarray=@_;

   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         $_=$rec;
         if (&$method(@paramarray)){
            ($rec,$msg)=$self->getNext();
         }
         else{
            return(undef)   
         }
      }until(!defined($rec));
   }
   return(1);
}

sub DeleteAllFilteredRecords
{
   my $self=shift;
   my $method=shift;
   my $idobj=$self->IdField();
   my $ncount;
   if (defined($idobj)){
      my $idname=$idobj->Name();
      $self->SetCurrentView(qw(ALL));
      my ($rec,$msg)=$self->getFirst();
      if (defined($rec)){
         do{
            if ($method eq "SecureValidatedDeleteRecord"){
               $self->SecureValidatedDeleteRecord($rec);
               $ncount++;
            }
            if ($method eq "ValidatedDeleteRecord"){
               $self->ValidatedDeleteRecord($rec);
               $ncount++;
            }
            if ($method eq "DeleteRecord"){
               $self->DeleteRecord($rec);
               $ncount++;
            }
            ($rec,$msg)=$self->getNext();
            return($ncount) if (!defined($rec));
         }until(!defined($rec));
      }
   }
   return($ncount);
}

sub CountRecords
{
   my $self=shift;
   return($self->SoftCountRecords());
}

sub SoftCountRecords
{
   my $self=shift;
   my $n=0;
   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         $n++;
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   return($n);
}

sub SecureValidatedDeleteRecord
{
   my $self=shift;
   my $oldrec=shift;
   $self->isDataInputFromUserFrontend(1);
   $self->doInitialize();
   if ($self->isDeleteValid($oldrec)){
      return($self->ValidatedDeleteRecord($oldrec));
   }
   else{
      $self->LastMsg(ERROR,"you are not autorized to delete the requested ".
                           "record");
   }
   return(undef);
}

sub ValidatedDeleteRecord
{
   my $self=shift;
   my $oldrec=shift;

   my $bk;
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
      $self->LastMsg(ERROR,"W5BaseOperationMode=readonly");
      return(undef);
   }
   if ($self->StartTransaction("delete",$oldrec,undef)){
      $bk=$self->ValidatedDeleteRecordTransactionless($oldrec);
   }
   else{
      $self->LastMsg(ERROR,"can not start delete transaction");
   }
   if ($self->LastMsg()){
      $self->RoolbackTransaction("delete",$oldrec,undef);
   }
   $self->FinishTransaction("delete",$oldrec,undef);

   return($bk);
}

sub ValidatedDeleteRecordTransactionless
{
   my $self=shift;
   my $oldrec=shift;
   $self->doInitialize();
   my $bak=undef;
   if ($self->ValidateDelete($oldrec)){
      $bak=$self->DeleteRecord($oldrec);
      $self->SendRemoteEvent("del",$oldrec,undef) if ($bak);
      $self->FinishDelete($oldrec) if ($bak); 
      $self->StoreUpdateDelta("delete",$oldrec,undef) if ($bak);
   }

   return($bak);
}

sub FinishView    # called on finsh view of one record (f.e. to reset caches)
{
   my $self=shift;
   my $rec=shift;

}

sub findNearestTargetDataObj
{
   my $self=shift;
   my $to=shift;
   my $requestedfor=shift;

   my $s=$self->Self();
   my ($m1,$m2,$dataobj);
   if (($m1,$dataobj)=$to=~m/^([^:]+)::(.*)$/){
      if (($m2)=$s=~m/^([^:]+)::/){
         if ($m1 eq $m2){
            return($to);
         }
      }
   }
   if ($dataobj ne "" && $m2 ne ""){
      if ( -f "$W5V2::INSTDIR/mod/$m2/$dataobj.pm"){
         my $nto="${m2}::${dataobj}";
         eval("use $nto;"); # ensure all super objects are used
         my @tree=Class::ISA::super_path($nto); 
         #msg(INFO,"check from $to to $nto in $requestedfor");
         if (in_array(\@tree,$to)){
            #msg(INFO,"rewrite for target of $requestedfor from $to to $nto");
            return($nto);
         }
         else{
            if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
               msg(WARN,"unable findNearestTargetDataObj in '$s' ".
                        "from '$to' to '$nto' ".
                        "requested for ".$requestedfor." needs SCALAR ref ".
                        "because not unique dataobject names");
            }
         }
      }
   }
   return(\$to);
}

sub SendRemoteEvent
{
   my $self=shift;
   my $mode=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $insertid=shift;


   $self->LoadSubObjs("ObjectEventHandler","ObjectEventHandler");
   foreach my $eh (values(%{$self->{ObjectEventHandler}})){
      $eh->HandleEvent($mode,$self->Self,$oldrec,$newrec);
   }
   my @updkeys;
   if (defined($newrec)){
      @updkeys=keys(%$newrec);
      @updkeys=grep(!/^(lastqenrich|lastqcheck|mdate)$/,@updkeys);
   }
   
   if (($#updkeys!=-1 || $mode eq "del") && !$self->{dontSendRemoteEvent}){
      my $idobj=$self->IdField();
      my $userid=$self->getCurrentUserId();
      my ($id,$sub);
      if (defined($idobj)){
         if (defined($oldrec)){
            $id=$oldrec->{$idobj->Name};
         }
         else{
            $id=$insertid;
         }
      }
      if ($self->Self() eq "base::workflow"){
         $sub=effVal($oldrec,$newrec,"class");
      }
      my $source=$self->Self;
      my $altsource=effVal($oldrec,$newrec,"alteventsource");
      if ($altsource ne ""){
         $source=$altsource;
      }
      $userid=0 if (!defined($userid));
      Time::HiRes::sleep(0.2);
      $self->W5ServerCall("rpcSendRemoteEvent",
                          $userid,$self->Self,$mode,$id,$sub);
   }
}


sub getDeleteRecordFilter
{
   my $self=shift;
   my $oldrec=shift;

   my $idname=$self->IdField->Name();
   my $dropid=$oldrec->{$idname};
   if (!defined($dropid)){
      $self->LastMsg(ERROR,"can't delete record without unique id in $idname");
      printf STDERR ("getDeleteRecordFilter:%s\n",Dumper($oldrec));
      Stacktrace(1);
      return;
   }
   my @flt=({$self->IdField->Name()=>$dropid});
   return(@flt);
}




sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;
   $self->doInitialize();
   msg(ERROR,"DeleteRecord not implemented in DataObj '$self'");
   return(0);
}
sub BulkDeleteRecord    # this function should be only used, if the
{                       # developer exactly knows the consequeses!!!
   my $self=shift;
   my @filter=@_;
   $self->doInitialize();
   msg(ERROR,"BulkDeleteRecord not implemented in DataObj '$self'");
   return(0);
}
########################################################################


sub getHtmlSelect
{
   my $self=shift;
   my $name=shift;
   my $uniquekey;
   my $fld;
   my $static;
   if (ref($_[0]) eq "ARRAY"){
      $static=shift;
   }
   else{
      $uniquekey=shift;
      $fld=shift;
   }

   my %opt=@_;
   my $d;
   my $width="100%";
   my $onchange="";
   my $multiple="";
   my $size="";
   my $keylist=[];
   my $vallist=[];
   my @selected=();
   my @style;

   $width=$opt{htmlwidth}     if (exists($opt{htmlwidth}));
   $multiple=" multiple"      if (exists($opt{multiple}) && $opt{multiple}==1);
   if (exists($opt{size})){
      if ($opt{size}=~m/\%$/){
         push(@style,"height:".$opt{size});
         $size=" size=2";
      }
      else{
         $size=" size=".$opt{size};
      }
   }
   if (exists($opt{autosubmit}) && $opt{autosubmit}==1){
      $onchange=" onchange=window.document.forms[0].submit()";
   }
   if (exists($opt{onchange}) && $opt{onchange} ne ""){
      $onchange=" onchange=\"$opt{onchange}\" ";
   }
   if (exists($opt{selected}) && ref($opt{selected}) eq "ARRAY"){
      push(@selected,@{$opt{selected}});
   }
   else{
      if (exists($opt{selected})){
         push(@selected,$opt{selected});
      }
      else{
        push(@selected,Query->Param($name));
      }
   }
   push(@style,"width:$width");
   my $style=join(";",@style);
   $d="<select name=$name style=\"$style\"$onchange$multiple$size>";
   my @l;
   my @list;

    
   my @data;
   my %data;
   if (!defined($static)){
      my @selectfields=(@{$fld},$uniquekey);
      if (defined($opt{fields})){
         push(@selectfields,@{$opt{fields}});
      }
      @data=$self->getHashList(@selectfields);
   }
   else{
      if (ref($static) eq "ARRAY"){
         $uniquekey="k";
         $fld=["v"];
         while(my $k=shift(@$static)){
            my $v=shift(@$static);
            push(@l,{k=>$k,v=>$v});
         }
      }
   }
   if (defined($opt{selectindex})){
      $opt{selectindex}=sprintf("%d",$opt{selectindex});
      @data=reverse(@data) if ($opt{selectindex}<0);
   }
      
   if ($uniquekey ne ""){
      my @sdata=@data;
      @data=();
      foreach my $chkrec (@sdata){
         push(@data,$chkrec) if (!exists($data{$chkrec->{$uniquekey}}));
         $data{$chkrec->{$uniquekey}}++;
      }
   }
   if (defined($opt{selectindex})){
      $opt{selectindex}=sprintf("%d",$opt{selectindex});
      if ($opt{selectindex}<0){
         (@selected)=$data[($opt{selectindex}*-1)]->{$uniquekey};
      }
      else{
         (@selected)=$data[$opt{selectindex}]->{$uniquekey};
      }
   }

   if (!defined($static)){
      foreach my $rec (@data){
         my %lrec;
         foreach my $k (keys(%$rec)){
            $lrec{$k}=$rec->{$k};
         }
         push(@list,\%lrec);
         my %frec;
         foreach my $k (keys(%$rec)){
            if (grep(/^$k$/,@{$fld})){
               my $fo=$self->getField($k,$rec);
               $frec{$k}=$fo->RawValue($rec);
            }
            else{
               $frec{$k}=$rec->{$k};
            }
         }
         push(@l,\%frec);
      }
   }

   my %len=();
   foreach my $rec (@l){
      foreach my $f (@{$fld}){
         $len{$f}=length($rec->{$f}) if ($len{$f}<length($rec->{$f}));
      }
   }
   my $format="%s";
   if ($#{$fld}>0){
      $format="";
      foreach my $f (@{$fld}){
         $format.=" " if ($format ne "");
         $format.='%-'.$len{$f}.'s';
      }
   }
   foreach my $rec (@l){
      push(@{$keylist},$rec->{$uniquekey});
      my @d=();
      foreach my $f (@{$fld}){
         push(@d,$rec->{$f});
      }
      push(@{$vallist},sprintf($format,@d));
   }

   if (exists($opt{AllowEmpty}) && $opt{AllowEmpty}==1){
      $d.="<option value=\"\"";
      if (grep(/^$/,@selected)){
         $d.=" selected";
      }
      $d.="></option>";
   }
   if (exists($opt{Add}) && ref($opt{Add}) eq "ARRAY"){
      foreach my $rec (@{$opt{Add}}){
         my $qkey1=quotemeta($rec->{key});
         if (!grep(/^$qkey1$/,@{$keylist})){
            $d.="<option value=\"$rec->{key}\"";
            my $qkey=quotemeta($rec->{key});
            if (grep(/^$qkey$/,@selected)){
               $d.=" selected";
            }
            my $va=$rec->{val};
            $va=~s/ /&nbsp;/g;
            $d.=">$va</option>";
         }
      }
   }
   for(my $c=0;$c<=$#{$keylist};$c++){
      $d.="<option";
      my $k=$keylist->[$c];
      $k=~s/</&lt;/g;
      $k=~s/>/&gt;/g;
      $k=~s/"/&quot;/g;
      $d.=" value=\"$k\"";
      my $qkey=quotemeta($keylist->[$c]);
      if (grep(/^$qkey$/,@selected)){
         $d.=" selected";
      }
      my $va=$vallist->[$c];
      $va=~s/ /&nbsp;/g;
      $d.=">$va</option>";
   }
   $d.="</select>"; 



#printf STDERR ("keylist=%s\n",Dumper($keylist));
#printf STDERR ("vallist=%s\n",Dumper($vallist));

   return($d,$keylist,$vallist,\@list);
}

sub getHtmlTextDrop
{
   my $self=shift;
   my $name=shift;
   my $newval=shift;
   my %p=@_;
   my %param;
   my $disp=$p{vjoindisp};
   if (ref($disp) ne "ARRAY"){
      $disp=[$disp];
   }
   my $filter={$disp->[0]=>'"'.$newval.'"'};

   my $txtinput="<input style=\"width:100%\" ".
                "type=text name=Formated_$name value=\"$newval\">";
   if ($newval=~m/^\s*$/){
      return(undef,undef,$txtinput,undef,undef);
   }


   $self->ResetFilter();
   if (defined($p{vjoinbase})){
      $self->SetNamedFilter("BASE",$p{vjoinbase});
   }
   if (defined($p{vjoineditbase})){
      $self->SetNamedFilter("EDITBASE",$p{vjoineditbase});
   }
   $self->SetFilter($filter);
   my $fromquery=Query->Param("Formated_$name");
   if (defined($fromquery)){
      $param{Add}=[{key=>$fromquery,val=>$fromquery},
                   {key=>'',val=>''}];
      $param{selected}=$fromquery;
   }
   if (defined($p{fields})){
      $param{fields}=$p{fields};
   }
   my $key=$disp;
#=$disp;
#   if (defined($p{vjoinkey})){
#      $key=$p{vjoinkey};
#   }
   if (ref($key) eq "ARRAY"){
      $key=$key->[0];
   }
   my ($dropbox,$keylist,$vallist,$list)=$self->getHtmlSelect(
                                                  "Formated_$name",
                                                  $key,$disp,%param);
   if ($#{$keylist}<0 && $fromquery ne ""){
      $filter={$disp->[0]=>'"*'.$fromquery.'*"'};
      $self->ResetFilter();
      if (defined($self->{vjoineditbase})){
         $self->SetNamedFilter("EDITBASE",$self->{vjoineditbase});
      }
      if (defined($p{vjoineditbase})){
         $self->SetNamedFilter("EDITBASE",$p{vjoineditbase});
      }
      $self->SetFilter($filter);
      ($dropbox,$keylist,$vallist,$list)=$self->getHtmlSelect(
                                                  "Formated_$name",
                                                  $key,$disp,%param);
   }
   if ($#{$keylist}>0){
      $self->LastMsg(ERROR,"value '%s' is not unique",$newval);
      return($#{$keylist}+1,$newval,$dropbox,$keylist,$vallist,$list);
   }
   if ($#{$keylist}<0 && ((defined($fromquery) && $fromquery ne ""))){
      if ($p{AllowEmpty}){
         return(0,undef,$txtinput,undef,undef);
      }
      $self->LastMsg(ERROR,"value '%s' not found",$newval);
      return(undef,undef,$txtinput,undef,undef);
   }
   my $txtinput="<input style=\"width:100%\" ".
                "type=text name=Formated_$name value=\"$vallist->[0]\">";

   return(1,$vallist->[0],$txtinput,$keylist,$vallist,$list);
   # (resultcount,resultval,htmleditfield,rawkeylist,rawvallist)
}

sub IdField
{
   my $self=shift;
   foreach my $fname (@{$self->{'FieldOrder'}}){
      my $fobj=$self->{'Field'}->{$fname};
      return($fobj) if ($fobj->Type() eq "Id");
   }
   return(undef);
}

sub AddOperator
{
   my $self=shift;
   my $name=shift;
   $self->{Operator}={} if (!defined($self->{Operator}));
   foreach my $obj (@_){
      $obj->Name($name);
      my $name=$obj->Name;
      $obj->setParent($self);
      $self->{Operator}->{$name}=$obj;
      $self->{Operator}->{$name}->{Config}=$self->Config;
   }
}

sub getOperator
{
   my $self=shift;
   $self->{Operator}={} if (!defined($self->{Operator}));
   return(values(%{$self->{Operator}}));
}


sub InitFields
{
   my $self=shift;
   my @finelist;
   $self->{'_vjoinRewrite'}={} if (!exists($self->{'_vjoinRewrite'}));
   foreach my $obj (@_){
      next if (!defined($obj));
      my $name=$obj->Name;
      $obj->{group}="default" if (!exists($obj->{group}));
      $obj->setParent($self);
      if (exists($self->{'Field'}->{$name})){
         #msg(INFO,"${self}:AddFields: '%s' already exists - ignored",$name);
         next;
      }
      if (!defined($obj->{translation})){
         my ($package,$filename, $line, $subroutine)=caller(1);
         if ($subroutine=~m/^kernel/){
            ($package,$filename, $line, $subroutine)=caller(2);
         }
         $subroutine=~s/::[^:]*$//;
         #msg(INFO,"caller=$package sub=$subroutine"); 
         $obj->{translation}=$subroutine;
      }
      $obj->{transprefix}=""    if (!defined($obj->{transprefix}));
      if (!defined($obj->{uivisible})){
         $obj->{uivisible}=1;
         my $t=$obj->Type();
         $obj->{uivisible}=0 if ($t eq "Linenumber" ||
                                 $t eq "Container"  ||
                                 $t eq "Link"); 
      }
      push(@finelist,$obj);
   }
   return(@finelist);
}

sub AddFields
{
   my $self=shift;
   my @fobjlist;
   my %param;

   while(ref($_[0])){
      push(@fobjlist,shift);
   }
   %param=@_;

   foreach my $obj ($self->InitFields(@fobjlist)){
      my $name=$obj->Name;
      next if (defined($self->{'Field'}->{$name}));
      $self->{'Field'}->{$name}=$obj;
      if (exists($obj->{dataobjattr}) && $name ne $obj->{dataobjattr}){
         $self->{InternExternRemapping}++;
      }
      my $inserted=0;
      if (defined($param{'insertafter'})){
         my @match=($param{'insertafter'});
         if (ref($param{'insertafter'}) eq "ARRAY"){
            @match=@{$param{'insertafter'}};
         }
         for(my $c=0;$c<=$#{$self->{'FieldOrder'}};$c++){
            if (grep(/^$self->{'FieldOrder'}->[$c]$/,@match)){
               splice(@{$self->{'FieldOrder'}},$c+1,0,$name);
               $inserted++;
               last;
            }
         }
      }
      elsif (defined($param{'insertbefore'})){
         my @match=($param{'insertbefore'});
         if (ref($param{'insertbefore'}) eq "ARRAY"){
            @match=@{$param{'insertbefore'}};
         }
         for(my $c=0;$c<=$#{$self->{'FieldOrder'}};$c++){
            if (grep(/^$self->{'FieldOrder'}->[$c]$/,@match)){
               splice(@{$self->{'FieldOrder'}},$c,0,$name);
               $inserted++;
               last;
            }
         }
      }

      if (!$inserted){
         push(@{$self->{'FieldOrder'}},$name);
      }
      if (defined($obj->{group}) &&
          !defined($self->{Group}->{$obj->{group}})){
         $self->AddGroup($obj->{group},translation=>$obj->{translation});
      }
   }
   return(1);
}

sub DelFields
{
   my $self=shift;
   my @fobjlist=@_;

   foreach my $fld (@fobjlist){
      my $fldname=$fld;
      delete($self->{'Field'}->{$fldname});
      @{$self->{'FieldOrder'}}=grep(!/^$fldname$/,@{$self->{'FieldOrder'}});
   }
}

sub ResetFields
{
   my $self=shift;

   $self->{'FieldOrder'}=[];
   $self->{'Field'}={};
   $self->{'Group'}={};
   return(1);
}

sub AddFrontendFields
{
   my $self=shift;

   foreach my $obj ($self->kernel::DataObj::InitFields(@_)){
      my $name=$obj->Name;
      next if (defined($self->{'Field'}->{$name}));
      next if (defined($self->{'FrontendField'}->{$name}));
      $self->{'FrontendField'}->{$name}=$obj;
      push(@{$self->{'FrontendFieldOrder'}},$name);
   }
   return(1);
}

sub AddGroup                 # parameter fields und translation
{
   my $self=shift;
   my $name=shift;
   my %param=@_;
   my @field;

   @field=@{$param{fields}} if (defined($param{fields}));
   if (!defined($param{translation})){
      $param{translation}=(caller(1))[3];
      if ($param{translation}=~m/^kernel/){
         $param{translation}=(caller(2))[3]; 
      }
      $param{translation}=~s/::[^:]*$//;
   }
   $self->{Group}={}                    if (!defined($self->{Group}));
   if (!defined($self->{Group}->{$name})){
      $self->{Group}->{$name}={FieldOrder=>[],Field=>{},translation=>[]};
   }
   my $grp=$self->{Group}->{$name};
   unshift(@{$grp->{translation}},$param{translation});
   foreach my $field (@field){
      if (!exists($grp->{Field}->{$field})){
         push(@{$grp->{FieldOrder}},$field);
         $grp->{Field}->{$field}=1;
      }
   }
   return(1);
}

sub AddVJoinReferenceRewrite
{
   my $self=shift;
   my %addtab=@_;

   $self->{'_vjoinRewrite'}={} if (!exists($self->{'_vjoinRewrite'}));

   foreach my $k (keys(%addtab)){
      $self->{'_vjoinRewrite'}->{$k}=$addtab{$k};
   }
   #
   #  ToDo - hier müßten alle Felder auf vjointo reference hin
   #         überprüft und korrigiert werden
   #
   return(%{$self->{'_vjoinRewrite'}});
}

sub getGroup
{
   my $self=shift;
   my $name=shift;
   my %param=@_;
   return(keys(%{$self->{Group}})) if (!defined($name));
   if (!defined($self->{Group}->{$name})){
      return(undef);
   }
   return($self->{Group}->{$name});
}




sub generateIndiviualAttributes
{
   my $self=shift;

   if ( defined($self->{individualAttr}) && 
        $W5V2::OperationContext eq "WebFrontend"){
      my $context=$self->Context;
      if (!defined($self->{individualAttr}->{Worktable})){
         my $o=getModuleObject($self->Config,$self->{individualAttr}->{dataobj});
         my ($worktable,$workdb)=$o->getWorktable();
         $self->{individualAttr}->{Worktable}=$worktable; 
      }
      if (!exists($context->{individualAttrCache})){
         $context->{individualAttrCache}={};
         if ($W5V2::OperationContext eq "WebFrontend"){
            #msg(INFO,"genereat Indiv Attr");
            my $o=getModuleObject($self->Config,"base::grpindivfld");
            my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','up');
            my @ids=keys(%groups);
            @ids=(-99) if ($#ids==-1);
            my @dids=map({$_->{grpid}}
                              grep({$_->{distance} eq "0"}
                              values(%groups)));
            @dids=(-99) if ($#dids==-1);

            my $dataobj=$self->SelfAsParentObject();
            $o->SetFilter([{
                              directonly=>\'0',
                              grpidview=>\@ids,
                              dataobj=>\$dataobj
                           },
                           {
                              directonly=>\'1',
                              grpidview=>\@dids,
                              dataobj=>\$dataobj
                           },
            ]);
            my $worktable=$self->{individualAttr}->{Worktable};
            my $idfield=$self->IdField();
            my $idattr=$idfield->{dataobjattr};
            foreach my $ifld ($o->getHashList(qw(id name readonly behavior 
                                                 extra))){
               my $indicolid=$ifld->{id};
               my $ifldname=$ifld->{name};
               $ifld=ObjectRecordCodeResolver($ifld);
               my %fldparam=(
                  name          =>"individualattribute_$indicolid",
                  label         =>$ifldname,
                  grpindivfldid =>$indicolid,
                  htmlwidth     =>'200',
                  htmlfixedfont =>1,
                  group         =>'individualAttr',
                  dataobjattr   =>"(select ${worktable}.fldval ".
                                  "from ${worktable} where ".
                                  "${worktable}.grpindivfld='$indicolid' ".
                                  " and ".
                                  "${idattr}=${worktable}.dataobjid)"
               );
               if (!$ifld->{readonly}){
                  my $extra=$ifld->{extra};
                  $extra=~s/'//g;
                  $fldparam{onClick}="inlineEdit(event,this,".
                                     "'$ifld->{behavior}','$extra');";
               }
               else{
                  $fldparam{onClick}='return(false);';
                  $fldparam{readonly}='1';
               }
               if ($ifld->{behavior} eq "hugemulti"){
                  $fldparam{htmlwidth}="300";
               }
               $fldparam{behavior}=$ifld->{behavior};
               $fldparam{extra}=$ifld->{extra};
               my $f=new kernel::Field::IndividualAttr(%fldparam);
               $self->InitFields($f);
               $context->{individualAttrCache}->{$f->Name()}=$f;
            }
         }
         else{
         }
      }
      return($context->{individualAttrCache});
   }
   else{
      return;
   }
}





sub getFieldList
{
   my $self=shift;
   my $context=shift;

   return() if (!defined($self->{'FieldOrder'}));
   my @fl=(@{$self->{'FieldOrder'}});
   if (defined($self->{SubDataObj})){
      my %subfld=();
      foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
         my $o=$self->{SubDataObj}->{$SubDataObj};
         next if (!defined($o));
         foreach my $f ($o->getFieldList()){
            push(@fl,$f) if (!defined($subfld{$f}));
            $subfld{$f}=1;
         }
      }
   }
   if ($context ne "collectively"){
      my $indivAttr=$self->generateIndiviualAttributes();
      push(@fl,sort(keys(%$indivAttr)));
   }

   return(@fl);
}

sub getFieldObjsByView
{
   my $self=shift;
   my $view=shift;
   my %param=@_;
   my @fobjs=();
   my @subl=();
   my @view;

   my $onlysync=0;
   if ($view->[0] eq "ALL" && $#{$view}==0){
      @view=$self->getFieldList();
      @view=grep(!/^(qctext|qcstate|qcok|interview|interviewst|itemsummary)$/,@view); # remove qc data
   }
   #elsif ($view->[0] eq "MAINSET" && $#{$view}==0){  # u.U. for further aliases
   #   @view=@{$self->{'FieldOrder'}} if (defined($self->{'FieldOrder'}));
   #   @view=grep(!/^(qctext|qcstate|qcok|interview|interviewst)$/,@view); # remove qc data
   #   $onlysync=1;
   #}
   else{
      @view=@{$view};
   }
   foreach my $fullfieldname (@view){
      $fullfieldname=trim($fullfieldname);
      $fullfieldname=~s/^[+-]//;  # remove posible order
      my ($container,$fieldname)=(undef,$fullfieldname);
      if ($fullfieldname=~m/\./){
         ($container,$fieldname)=$fullfieldname=~m/^(\S+?)\.(\S+)/;
      }
      my $fobj;
      if (!defined($container)){
         if (exists($self->{'Field'}) &&
             exists($self->{'Field'}->{$fieldname})){
            $fobj=$self->{'Field'}->{$fieldname};
         } 
         if ((caller(1))[3] ne "base::workflow::getSubDataObjFieldObjsByView" &&
             !defined($fobj)){  # maybe a dynamic user specific field
            $fobj=$self->getField($fieldname);  # this is needed to allow
                                                # user specific fields
           # This getField is not allowed in an getSubDataObjFieldObjsByView
         }
    
         
         if (defined($fobj)){
            if ($fobj->Type() eq "Dynamic"){
               my @dlist=$fobj->fields(%param);
               foreach my $f (@dlist){
                  $f->{namepref}=$fobj->Name().".";
               }
               push(@subl,@dlist);
            }
            else{
               push(@fobjs,$fobj);
            }
         }
      }
      else{   # handle dot notation for container fields
         if (exists($self->{'Field'}->{$container})){
            $fobj=$self->{'Field'}->{$container};
         } 
         my @sublreq;
         if (defined($fobj)){
            if ($fobj->Type() eq "Dynamic"){
               my @dlist=$fobj->fields(%param);
               foreach my $f (@dlist){
                  $f->{namepref}=$fobj->Name().".";
               }
               push(@sublreq,@dlist);
            }
            if ($fobj->Type() eq "Container"){
               push(@sublreq,$fobj->fields(%param));
            }
            foreach my $fo (@sublreq){
               push(@fobjs,$fo) if ($fo->Name() eq $fieldname);
            }
         }
      }
   }
   my @SubDataObjFields=$self->getSubDataObjFieldObjsByView($view,%param);
#   if ($self->Self()=~m/^base::workflow/){
      #printf STDERR ("fifi1: %s\n",join(",",map({$_->Name()."-".$_->getParent()} @fobjs)));
      #printf STDERR ("fifi2: %s\n",join(",",map({$_->Name()."-".$_->getParent()} @SubDataObjFields)));
#      printf STDERR ("fifi1: %s\n",join(",",map({$_->Name()} @fobjs)));
#      printf STDERR ("fifi2: %s\n",join(",",map({$_->Name()} @SubDataObjFields)));
#   }
#
#   my @full=();  # now remove doublicates - not beautyfull
#   foreach my $f (@fobjs,@SubDataObjFields,@subl){ # remove dups
#      if (!in_array(\@full,$f)){
#         push (@full,$f);
#      }
#   }
   my @full=(@fobjs,@SubDataObjFields,@subl);
   return(@full);
}

sub getSubDataObjFieldObjsByView
{
   my $self=shift;
   my $view=shift;
   my %param=@_;
   my @fobjs;

   foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
      my $sobj=$self->{SubDataObj}->{$SubDataObj};
      if (defined($sobj) && $sobj->can("getFieldObjsByView")){
         push(@fobjs,$sobj->getFieldObjsByView($view,%param));
      }
   }
   return(@fobjs);
}



sub getFieldHash
{
   my $self=shift;
   my %param=@_;
   my %fh;
   if (ref($self->{'Field'}) eq "HASH"){
      if (ref($self->{'FrontendField'}) eq "HASH"){
         %fh=(%{$self->{'Field'}},%{$self->{'FrontendField'}});
      }
      else{
         %fh=(%{$self->{'Field'}});
      }
   }
   if (defined($self->{SubDataObj})){
      foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
         my $so=$self->{SubDataObj}->{$SubDataObj};
         if (defined($so)){
            foreach my $fieldname (sort(keys(%{$so->{Field}}))){
               $fh{$fieldname}=$so->{Field}->{$fieldname};
            }
         }
      }
   }
   return(\%fh);
}


sub getFieldRawValue
{
   my $self=shift;
   my $fieldname=shift;
   my $current=shift;
   my $mode=shift;

   my $fld=$self->getField($fieldname,$current);
   if (defined($fld)){
      return($fld->RawValue($current,$mode));
   }
   msg(ERROR,"invalid field access at $self getFieldRawValue($fieldname)");
   Stacktrace();
}




sub getField
{
   my $self=shift;
   my $fullfieldname=shift;
   my $deprec=shift;
   my ($container,$name)=(undef,$fullfieldname);
   if ($fullfieldname=~m/\./){
      ($container,$name)=$fullfieldname=~m/^([^.]+)\.(\S+)/;
   }
   if (my ($indicolid)=$fullfieldname=~m/^individualattribute_([0-9]{5,15})$/){
      my $indivAttr=$self->generateIndiviualAttributes();
      if (exists($indivAttr->{$fullfieldname})){
         return($indivAttr->{$fullfieldname});
      }
   }
   if (defined($container)){
      if (!defined($deprec)){
         return(undef);
      }
      my $fobj;
      if (exists($self->{'Field'}->{$container})){
         $fobj=$self->{'Field'}->{$container};
      } 
      my @sublreq;
      if (defined($fobj)){
         if ($fobj->Type() eq "Dynamic"){
            push(@sublreq,$fobj->fields(current=>$deprec));
         }
         foreach my $fo (@sublreq){
            return($fo) if ($fo->Name() eq $name);
         }
      }
      return(undef);
   }
   if (defined($container) && !defined($deprec)){
      return
   }
   if (exists($self->{'Field'}->{$name})){
      return($self->{'Field'}->{$name});
   } 
   if (defined($self->{SubDataObj})){
      foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
         my $so=$self->{SubDataObj}->{$SubDataObj};
         if (defined($so)){
            if (exists($so->{'Field'}->{$name})){ 
               return($so->{'Field'}->{$name});
            }
         }
      }
   }
   return(undef);
}

sub getFieldIfExists
{
   my $self=shift;
   my $fullfieldname=shift;
   my $deprec=shift;
   my $f=$self->getField($fullfieldname,$deprec);
   $f={} if (!defined($f)); # das muß irgendwann mal in ein "univeral" objekt
                            # geändert werden
   return($f);
}

sub getFieldParam
{
   my $self=shift;
   my $name=shift;
   my $param=shift;

   my $fobj=$self->getField($name);
   if (defined($fobj) && ref($fobj) eq "HASH"){
      return($fobj->{$param});
   }

   return(undef);
}

sub setFieldParam
{
   my $self=shift;
   my $name=shift;
   my %param=@_;


   if (ref($name) eq "Regexp"){
      $param{NEGMATCH}=0 if (!exists($param{NEGMATCH}));
      my $n;
      foreach my $fo ($self->getFieldObjsByView([qw(ALL)])){
         if ($param{NEGMATCH}){
            if (!($fo->Name()=~$name)){
               $n+=$self->setFieldParam($fo,%param);
            }
         }
         else{
            if ($fo->Name()=~$name){
               $n+=$self->setFieldParam($fo,%param);
            }
         }
      }
      return($n);
   }
   elsif (ref($name)){
      my $c=0;
      foreach my $k (keys(%param)){
         next if ($k eq "NEGMATCH");
         $name->{$k}=$param{$k};
         $c++;
      }
      return($c);
   }
   else{
      my $fobj=$self->getField($name);
      if (defined($fobj)){
         return($self->setFieldParam($fobj,%param));
      }
   }

   return(undef);
}

sub RawValue
{
   my $self=shift;
   my $key=shift;
   my $current=shift;
   my $field=shift;
   my $mode=shift;

   if (!defined($field)){
      #msg(ERROR,"access to unknown field '$key' in $self");
      return(undef);
   }
   return($field->RawValue($current,$mode));
}

sub getSubList
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my %param=@_;
   my %opt=();

   my $pmode=$mode;
   $param{parentcurrent}=$current;
   if (defined($param{ParentMode})){
      $pmode=$param{ParentMode};
   }
   $opt{SubListEdit}=1 if ($mode eq "HtmlSubListEdit");
   return("...")       if ($mode=~m/^Multi.*/);   # on FormaterMultiOperation s
   if ($mode ne "HtmlExplore" && ($mode=~m/^.{0,1}Html.*$/)){
      $mode="HtmlSubList";
   }
   if ($mode eq "HtmlExplore"){
      $mode="HtmlSubListExplore";
   }
   $mode="SubXMLV01"   if ($mode=~m/XML/);
   if ($mode=~m/^OneLine$/){
      my @view=$self->GetCurrentView();
      if ($view[0] eq "VDISTINCT"){ # for VDISTINCT Querys use second field
         return([$self->getVal($view[1])]);
      }
      return([$self->getVal($view[0])]);
   }
   if ($mode eq "RAW" || $mode eq "JSON" || $mode eq "ContactMail"){
      my @view=$self->GetCurrentView();
      return($self->getHashList(@view));
   }
   if ($mode eq "FIRSTTEXT"){ # create a array structure with first text field
                              # in view (for non multidimension outputs)
      my @view=$self->GetCurrentView();
      my @fl=$self->getFieldObjsByView(\@view);
      my $fo;
      foreach my $chkfo (@fl){
         my $type=$chkfo->Type();
         if (in_array([$type],[qw(TextDrop Text)])){
            $fo=$chkfo;
            last;
         }
      }
      if (defined($fo)){
         my @l=$self->getHashList(@view);
         my @result;
         foreach my $rec (@l){
            my $d=$fo->FormatedResult($rec,"OneLine");
            push(@result,$d);
         }
         return(\@result);
      }
      return();
   }
   my $output=new kernel::Output($self);
   if (!($output->setFormat($mode,%opt,%param))){
      msg(ERROR,"can't set output format '$mode'");
      return("ERROR: Data-Source '$mode' not available - Format problem");
   }
   return($output->WriteToScalar(HttpHeader=>0,ParentMode=>$pmode));
}



sub setDefaultView
{
   my $self=shift;
   $self->{'DefaultView'}=[@_];
}

sub getDefaultView
{
   my $self=shift;
   return() if (!defined($self->{'DefaultView'}) || 
                  ref($self->{'DefaultView'}) ne "ARRAY");
   return(@{$self->{'DefaultView'}});
}

sub getCurrentViewName
{
   my $self=shift;

   return(Query->Param("CurrentView"));
}

sub getCurrentView
{
   my $self=shift;
   my $raw=shift;    # if raw=1 no +- is striped
   if (!defined($self->Context->{'CurrentView'})){
      if (ref($self->{DefaultView}) eq "ARRAY"){
         return(@{$self->{DefaultView}});
      }
      else{
         return();
      }
   }
   my @view=@{$self->Context->{'CurrentView'}};
   if (!$raw){
      map({$_=~s/^[+-]//;$_} @view);
   }

   return(@view);
}

sub SetCurrentOrder
{
   my $self=shift;

   #  prefix + on field creates "ascending" (asc) order
   #  prefix - on field creates "descending" (desc) order
   #  (but only if sqlorder is not set to "none")
   #

   if ($#_==-1){
      delete($self->Context->{'CurrentOrder'});
   }
   else{
     $self->Context->{'CurrentOrder'}=[@_];
   }
}

sub GetCurrentOrder
{
   my $self=shift;
   if (defined($self->Context->{'CurrentOrder'})){
      return(@{$self->Context->{'CurrentOrder'}});
   }
   return(undef);
}


sub SetCurrentView
{
   my $self=shift;

   $self->doInitialize();
   if ($_[0] eq "ALL" && $#_==0){
      my $fh=$self->getFieldHash();
      $self->Context->{'CurrentView'}=[];
      foreach my $f ($self->getFieldList()){
         if (defined($fh->{$f})){
            if ($fh->{$f}->selectable()){
               push(@{$self->Context->{'CurrentView'}},$f);
            }
         }
      }
      @{$self->Context->{'CurrentView'}}=
         grep(!/^(qctext|qcstate|qcok|itemsummary)$/,
         @{$self->Context->{'CurrentView'}}); 
         # remove qc data
   }
   else{
      $self->Context->{'CurrentView'}=[@_];
   }
   return(@{$self->Context->{'CurrentView'}});
}

sub GetCurrentView
{
   my $self=shift;
   return(@{$self->Context->{'CurrentView'}});
}

sub getFieldListFromUserview
{
   my $self=shift;
   my $currentview=shift;
   my @showfieldlist;

   if (my ($fl)=$currentview=~m/^\((.*)\)$/){  # direct view from client
      @showfieldlist=split(/,/,$fl);
   }
   else{
      if (defined($self->{userview})){
         $self->{userview}->ResetFilter();
         my $curruserid=$self->getCurrentUserId();
         $self->{userview}->SetFilter([
                                 #     {editor=>[$ENV{REMOTE_USER}],
                                 #      module=>[$self->ViewEditorModuleName()],
                                 #      name=>[$currentview]},
                                      {userid=>[$curruserid,0],
                                       module=>[$self->ViewEditorModuleName()],
                                       name=>[$currentview]}]);
         my @l=$self->{userview}->getHashList("data","viewrevision");
         if ($currentview eq "default" && $#l!=0){
            @showfieldlist=$self->getDefaultView();
         }
         else{
            if ($l[0]->{viewrevision}==1){
               @showfieldlist=split(/,\s*/,$l[0]->{data});
            }
         }
      }
      else{
         @showfieldlist=$self->getDefaultView();
      }
   }
   return(@showfieldlist);
}



sub ViewEditorModuleName
{
   my $self=shift;

   my $f=join(".",$self->getObjectTree());
   my $My=Query->Param("MyW5BaseSUBMOD");
   $f="$f($My)" if ($My ne "");
   return($f);
}

sub DetailX
{
   my $self=shift;

   $self->{DetailX}=$_[0] if (defined($_[0]));
   $self->{DetailX}=640 if (!defined($self->{DetailX}));
   return($self->{DetailX});

}

sub DetailY
{
   my $self=shift;

   $self->{DetailY}=$_[0] if (defined($_[0]));
   $self->{DetailY}=480 if (!defined($self->{DetailY}));
   return($self->{DetailY});
}

sub getRecordHtmlIndex
{
   my $self=shift;
   my $rec=shift;
   my $id=shift;
   my $viewgroups=shift;
   my $grouplist=shift;
   my $grouplabel=shift;
   my @indexlist;
   return() if (!defined($rec));
   $viewgroups=[$viewgroups] if (ref($viewgroups) ne "ARRAY");

   foreach my $group (@$grouplist){
      if ($group ne "header" && $group ne "HEADER" &&
          (grep(/^$group$/,@$viewgroups) || grep(/^ALL$/,@$viewgroups))){
        push(@indexlist,
             $self->makeHtmlIndexRecord($id,$group,$grouplabel->{$group}));
      }
   }
   if ($#indexlist<=1){
      return;
   }
   return(@indexlist);
}

sub makeHtmlIndexRecord
{
   my $self=shift;
   my $id=shift;
   my $group=shift;
   my $label=shift;
   return({label=>$label,
           href=>"#I.$id.$group",
           group=>"$group",
          });
}


sub getHtmlPagingLine
{
   my $self=shift;
   my $mode=shift;
   my $app=$self;
   my $pagelimit=shift;
   my $currentlimit=shift;
   my $records=shift;
   my $limitreached=shift;
   my $limitstart=shift;
   my $d="";

   my $LimitBackend=$self->LimitBackend();
   if (defined($records) && $pagelimit>0){
      my $totalpages=0;
      if ($pagelimit>0){
         $totalpages=$records/$pagelimit;
      }
      $totalpages=int($totalpages)+1 if (int($totalpages)!=$totalpages);
      my $currentpage=0;
      if ($pagelimit>0){
         $currentpage=int($limitstart/$pagelimit);
      }


      $d.="<div class=pagingline>";
      my $nextpagestart=$pagelimit*($currentpage+1);
      if ($nextpagestart>$totalpages*$pagelimit){
         $nextpagestart=$totalpages*$pagelimit;
      }
      my $prevpagestart=($currentpage-1)*$pagelimit;
      $prevpagestart=0 if ($prevpagestart<0);
      

      my $nexttext="&nbsp;";
      if ($currentpage<$totalpages-1 && $currentlimit>0){
         $nexttext="<a class=pageswitch ".
                   "href=JavaScript:setLimitStart($nextpagestart)>".
                   $app->T("next page")."</a>";
      }
      my $prevtext="&nbsp;";
      if ($currentpage>0 && $currentlimit>0){
         $prevtext="<a class=pageswitch ".
                   "href=JavaScript:setLimitStart($prevpagestart)>".
                   $app->T("previous page")."</a>";
      }
      my $recordstext="<b>".
                      sprintf($app->T("Total: %d records"),$records).
                      "</b>";
      if ($LimitBackend>0 && $records>$LimitBackend-1){
         $recordstext="<b>".
                      sprintf($app->T("Total: &gt;%d records"),$LimitBackend-1).
                      "</b>";

      }

      if (($records<500 || $app->IsMemberOf("admin")) && 
          $app->allowHtmlFullList() &&
          $currentlimit>0 && $records>$currentlimit){
         $recordstext="<a class=pageswitch ".
                      "href=Javascript:showall()>$recordstext</a>";
      }
      my $maxpages=14;
      $maxpages=$totalpages-1 if ($maxpages>$totalpages-1);
      my @pages=();
      my $disppagestart=$currentpage-($maxpages/2);
      $disppagestart=1 if ($disppagestart<1);
      if ($disppagestart>$totalpages-$maxpages-1){
         $disppagestart=$totalpages-$maxpages;
      }
      for(my $c=0;$c<=$maxpages;$c++){
         $pages[$c]=$disppagestart+$c;
      }

      $pages[0]=1 if ($pages[0]!=1);
      $pages[$maxpages]=$totalpages if ($totalpages>$pages[$maxpages]);

      my $pagelist="";
      if ($totalpages>1 && $currentlimit>0){
         $pagelist.="<table border=0><tr>";
         for(my $p=0;$p<=$#pages;$p++){
            ###################################################################
            # do not show last page, if BackendLimit is reached
            if ($LimitBackend>0 && $records>$LimitBackend-1){
               next if ($#pages==$p);
            }
            ###################################################################
            $pagelist.="<td>...</td>" if ($p==1 && $pages[$p]-1!=$pages[$p-1]);
            my $disppagesstr=$pages[$p];
            if ($currentpage+1==$pages[$p]){
               $disppagesstr="<u><b>$pages[$p]</b></u>";
            }
            my $ps=($pages[$p]-1)*$pagelimit;
            $disppagesstr="<a class=pageswitch ".
                          "href=JavaScript:setLimitStart($ps)>".
                          "$disppagesstr</a>";
            $pagelist.="<td width=20 align=center>$disppagesstr</td>";
            $pagelist.="<td>...</td>" if ($p==$#pages-1 && 
                                          $pages[$p]+1!=$pages[$#pages]);
         }
         $pagelist.="</tr></table>";
      }
      
      $d.="<center><table width=600 border=0><tr>";
      $d.="<tr>";
      $d.="<td width=90 align=center>$prevtext</td>";
      $d.="<td align=center>$recordstext</td>";
      $d.="<td width=90 align=center>$nexttext</td></tr>";
      $d.="</tr>";
      $d.="<tr>";
      $d.="<td></td>";
      $d.="<td align=center>$pagelist</td>";
      $d.="<td></td></tr>";
      $d.="</tr>";
      $d.="</table></center></div>";
      if ($mode eq "SUBFRAME"){
         $d.=<<EOF;
   <script language="JavaScript">
   function setLimitStart(n)
   {
      parent.document.forms[0].elements['UseLimitStart'].value=n;
      parent.document.forms[0].submit();
   }
   function showall()
   {
      parent.document.forms[0].elements['UseLimit'].value="0";
      parent.document.forms[0].elements['UseLimitStart'].value="0";
      parent.DoRemoteSearch(undefined,undefined,undefined,undefined,1);
   }
   </script>
EOF
      }
      if ($mode eq "FORM"){
         $d.=<<EOF;
   <script language="JavaScript">
   function setLimitStart(n)
   {
      document.forms[0].elements['UseLimitStart'].value=n;
      document.forms[0].submit();
   }
   function showall()
   {
      document.forms[0].elements['UseLimit'].value="0";
      document.forms[0].elements['UseLimitStart'].value="0";
      document.forms[0].submit();
   }
   </script>
EOF

      }
   }
   return($d);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/world.jpg?".$cgi->query_string());
}

sub getRecordWatermarkUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return(undef);
   return("../../../public/base/load/world.jpg?".$cgi->query_string());
}

sub getRecordHeaderField
{
   my $self=shift;
   my $rec=shift; 

   if (my $f=$self->getField("fullname")){
      return($f);
   }
   elsif (my $f=$self->getField("name")){
      return($f);
   }
   elsif (my $f=$self->getField("id")){
      return($f);
   }
   return(undef);
}

sub getRecordHeader
{
   my $self=shift;
   my $rec=shift;
   my $headerval;

   if (my $f=$self->getRecordHeaderField($rec)){
      $headerval=quoteHtml($f->RawValue($rec));
   }
   else{
      $headerval="not labeld";
   }
   return($headerval);
}

sub getRecordSubHeader
{
   my $self=shift;
   my $current=shift;
   if (my $fld=$self->getField("dataissuestate")){
      return($fld->FormatedDetail($current,"HtmlDetail"));
   }
   return("");
}


#
# setting the limit on selects -
# Limit()       returns the current limit
# Limit(0)      sets the limit to unlimited
# Limit(10)     sets the limit to 10
# Limit(10,5)   sets the limit to 10 starting with record 5
# Limit(10,5,0) sets the limit to 10 starting with record 5 use hard limit
# Limit(10,5,1) sets the limit to 10 starting with record 5 use soft limit
#
sub Limit
{
   my $self=shift;

   if (!defined($_[0])){
      return($self->{_Limit});
   }
   else{
      if ($_[0]==0){
         delete($self->{_Limit});
         delete($self->{_LimitStart});
         delete($self->{_UseSoftLimit});
         delete($self->Context->{CurrentLimit});
      }
      $self->{_Limit}=$_[0];
      $self->{_LimitStart}=$_[1];
      $self->{_LimitStart}=0 if (!defined($self->{_LimitStart}));
      if ($_[2]){
         $self->{_UseSoftLimit}=1;
      }
      else{
         $self->{_UseSoftLimit}=0;
      }
   }
   return($self->{_Limit});
}


sub LimitBackend
{
   my $self=shift;

   if (!exists($self->{_LimitBackend})){
      $self->{_LimitBackend}=undef;
   }
   if (!defined($_[0])){
      return($self->{_LimitBackend});
   }
   else{
      if ($_[0]==0){
         $self->{_LimitBackend}=undef;
      }
      else{
         $self->{_LimitBackend}=$_[0];
      }
   }
   return($self->{_LimitBackend});
}



sub DataObj_findtemplvar
{
   my $self=shift;
   my ($opt,$var,@param)=@_;
   my $fieldbase;


   if (defined($opt->{fieldbase})){
      $fieldbase=$opt->{fieldbase};
   }
   else{
      $fieldbase=$self->getFieldHash(); 
   }

   my $fieldobj;
   if (exists($fieldbase->{$var})){
      $fieldobj=$fieldbase->{$var};
   }
   else{
      $fieldobj=$self->getField($var);
   }

   if (defined($fieldobj)){
      my $current=$opt->{current};
      my $defmode=Query->Param("FormatAs");
      my %FOpt=(WindowMode=>$opt->{WindowMode});
      $defmode="HtmlDetail" if ($defmode eq "");
      my $mode=$defmode;
      $mode=$opt->{mode} if (defined($opt->{mode}));
      if (!defined($param[0])){
         return($fieldobj->RawValue($current,$mode));
      }
      if ($param[0] eq "formated" || $param[0] eq "detail" || 
          $param[0] eq "sublistedit" || $param[0] eq "forceedit"){
         if (exists($opt->{viewgroups})){
            my @fieldgrouplist=($fieldobj->{group});
            if (ref($fieldbase->{$var}->{group}) eq "ARRAY"){
               @fieldgrouplist=@{$fieldobj->{group}};
            }
            my $viewok=0;
            foreach my $fieldgroup (@fieldgrouplist){
               if (grep(/^$fieldgroup$/,@{$opt->{viewgroups}})){
                  $viewok=1;last;
               }
            }
            if (!$viewok && !grep(/^ALL$/,@{$opt->{viewgroups}})){
               return(undef) if ($mode eq "JSON" || $mode eq "XML");
               return("-");
            }
         }
         if ($param[0] eq "formated"){
            my $d=$fieldobj->FormatedResult($current,$mode,%FOpt);
            return($d);
         }
         elsif ($param[0] eq "detail"){
            if (defined($opt->{currentfieldgroup})){
               if (($opt->{currentfieldgroup} eq $opt->{fieldgroup} &&
                    $opt->{currentid} eq $opt->{id}) ||
                   !defined($current) ||# in New mode all fields are in edit
                   $opt->{WindowEnviroment} eq "modal"){  
                  $mode="edit";          # mode
               }
            }
            if (exists($opt->{editgroups})){
               my @fieldgrouplist=($fieldobj->{group});
               if (ref($fieldobj->{group}) eq "ARRAY"){
                  @fieldgrouplist=@{$fieldobj->{group}};
               }
               my $editok=0;
               foreach my $fieldgroup (@fieldgrouplist){
                  if (grep(/^$fieldgroup$/,@{$opt->{editgroups}})||
                      grep(/^$fieldgroup\.$var$/,@{$opt->{editgroups}})){
                     $editok=1;last;
                  }
               }
               foreach my $fieldgroup (@fieldgrouplist){
                  if (grep(/^!$fieldgroup$/,@{$opt->{editgroups}})||
                      grep(/^!$fieldgroup\.$var$/,@{$opt->{editgroups}})){
                     $editok=0;last;
                  }
               }
               if (!$editok && 
                   !grep(/^ALL$/,@{$opt->{editgroups}}) &&
                   !grep(/^1$/,@{$opt->{editgroups}})){
                  $mode=$defmode;
               }
            }
            my $d=$fieldobj->FormatedDetail($current,$mode,%FOpt);
            if ($mode eq "HtmlDetail"){
               my $add=$fieldobj->detailadd($current,%FOpt);
               $d.=$add if (defined($add));
            }
            return($d);
         }
         elsif ($param[0] eq "sublistedit" || $param[0] eq "forceedit"){
            return($fieldobj->FormatedDetail($current,"edit",%FOpt));
         }
      }
      if ($param[0] eq "jsonlatin" || $param[0] eq "json"){
         eval('use JSON;$self->{JSON}=new JSON;');
         if ($@ ne ""){
            return(undef);
         }
         if ($param[0] eq "jsonlatin"){
            $self->{JSON}->utf8(0);
            $self->{JSON}->property(latin1=>1);
         }
         if ($param[0] eq "json"){
            $self->{JSON}->utf8(1);
            $self->{JSON}->property(utf8=>1);
         }
         my $d=$self->{JSON}->encode([$current->{$var}]);
         $d=~s/</&lt;/g;  # prevent html sequences in JSON Data. This
         $d=~s/>/&gt;/g;  # could be used for X-SiteScripting
         return($d);
      }
      if ($param[0] eq "storedworkspace"){
         return($fieldobj->FormatedStoredWorkspace());
      }
      elsif ($param[0] eq "search"){
         return($fieldobj->FormatedSearch());
      }
      elsif ($param[0] eq "label"){
         return($fieldobj->Label($mode));
      }
      elsif ($param[0] eq "searchlabel"){
         return(TextShorter($fieldobj->Label($mode),35,"INDICATED"));
      }
      elsif ($param[0] eq "detailunit"){
         if ($opt->{WindowMode} ne "HtmlDetailEdit"){
            my $unit=$fieldobj->unit;
            if (defined($unit)){
               return(" ".$self->T($unit,$self->Self));
            } 
         }
         return("");
      }
   }
   elsif ($var eq "VIEWSELECT"){
   #   if (defined($self->{userview})){
   #      return($self->getUserviewDropDownBox($ENV{REMOTE_USER}));
   #   }
      return("<input type=hidden name=CurrentView value=\"default\">");
   }

   return(undef);
}

sub getUserviewList
{
   my $self=shift;
   my $user=shift;
   $user=$ENV{REMOTE_USER} if ($user eq "");

   if (defined($self->{userview})){
      $self->{userview}->ResetFilter();
      my $curruserid=$self->getCurrentUserId();
      $self->{userview}->SetFilter({userid=>[$curruserid,0],
                                    module=>[$self->ViewEditorModuleName()]});
      my @l=$self->{userview}->getHashList("name");
      my @userviewlist=map({$_->{name}} @l);
      push(@userviewlist,"default") if (!grep(/^default$/,@userviewlist));
      @userviewlist=sort({
                           my $bk=$a cmp $b;
                           $bk=-1 if ($a eq "default");
                           $bk=1  if ($b eq "default");
                           $bk;
                         } @userviewlist);
      return(@userviewlist);
   }
   return("default");
}

sub getDetailBlockPriority                # posibility to change the block order
{
   return(qw(header default contacts control misc source));
}

sub getSpecPaths
{
   my $self=shift;
   my $rec=shift;
   my $mod=$self->Module();
   my $selfname=$self->Self();
   $selfname=~s/::/./g;
   my @libs=("$mod/spec/$selfname");
   my $selfasparent=$self->SelfAsParentObject();
   if ($selfasparent ne $selfname){
      my ($mod)=$selfasparent=~m/^(.*?)::/;
      if ($mod ne ""){
         $selfasparent=~s/::/./g;
         push(@libs,"$mod/spec/$selfasparent");
      }
   }
   return(@libs);
}

sub LoadSpec
{
   my $self=shift;
   my $rec=shift;
   my @libs=$self->getSpecPaths($rec);
   my %spec;
   my $lang=$self->Lang();

   sub processSpecfile
   {
      my $filename=shift;
      my $specrec=shift;
      my $lang=shift;

      my $speccode="";
      if (open(F,"<$filename")){
         $speccode=join("",<F>);
         close(F);
      }
      my $s={};
      eval("\$s={$speccode};");
      if ($@ ne ""){
         my $e=$@;
         msg(ERROR,"error while reading '%s'",$filename);
         msg(ERROR,$e);
      }
      else{
         foreach my $k (keys(%$s)){
            if (defined($s->{$k}->{$lang}) && trim($s->{$k}->{$lang}) ne ""){
               $specrec->{$k}=$s->{$k}->{$lang};
            }
         }
      }
   }
   my %filedone;
   foreach my $lib (reverse(@libs)){ # use the local spec as last (highest prio)
      my $filename=$self->getSkinFile($lib,addskin=>'default');
      if ($filename ne "" && !$filedone{$filename}){
         processSpecfile($filename,\%spec,$lang);
         $filedone{$filename}++;
      }
   }
   foreach my $lib (reverse(@libs)){ # use the local spec as last (highest prio)
      my $filename=$self->getSkinFile($lib);
      if ($filename ne "" && !$filedone{$filename}){
         processSpecfile($filename,\%spec,$lang);
         $filedone{$filename}++;
      }
   }
   return(\%spec);
}





sub sortDetailBlocks
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   my @grp=@{$grp};
   my @prio=$self->getDetailBlockPriority($grp,%param);
   push(@prio,"source") if (!grep(/^source$/,@prio));
   push(@prio,"qc") if (!grep(/^qc$/,@prio));

   my @newlist=();
   map({
         my $blk=$_;
         my $q='^'.quotemeta($blk).'$';
         if (grep(/$q/,@grp)){
            push(@newlist,$blk);
            @grp=grep(!/$q/,@grp);
         }
       } @prio);
   @grp=sort(@grp);
   unshift(@grp,@newlist);
   return(@grp);
}

sub getLinenumber
{  
   my $self=shift;
   return($self->Context->{Linenumber}+$self->{_LimitStart});
}  


sub getUserviewDropDownBox
{
   my $self=shift;
   my $user=shift;
   my $d="";
   my $oldval=Query->Param("CurrentView");
   $d.="<select class=viewselect name=CurrentView>";
   foreach my $view ($self->getUserviewList($user)){
      $d.="<option value=\"$view\" ";
      $d.="selected" if ($view eq $oldval);
      $d.=">$view</option>";
   }
   $d.="</select>";
   return($d);
}


#######################################################################
# 
#  addmode=>'OR' | 'AND'       default AND
#  datatype=>'DATE'|'STRING'   default STRING
#  conjunction=>'AND' | 'OR'   default OR
#  listmode=>1|0               default 1 on strings else 0
#  negation=>1|0               default 1 on strings else 0
#  wildcards=>1|0              default 1 on strings else 0
#  containermode=>NameOfField  
#  sqldbh=>DBI Handle  
#
#  true|false = Data2SQLwhere($$where,$sqldatafield,$data,%param);
#

sub Data2SQLwhere
{
   my $self=shift;
   my $where=shift;
   my $sqlfieldname=shift;
   my $filter=shift;
   my %sqlparam=@_;


   $sqlparam{addmode}="and"     if (!defined($sqlparam{addmode}));
   $sqlparam{conjunction}="or"  if (!defined($sqlparam{conjunction}));
   $sqlparam{datatype}="STRING" if (!defined($sqlparam{datatype}));
   $sqlparam{allow_sql_in}=0    if (!defined($sqlparam{allow_sql_in}));
   my @filter;
   if (!ref($filter)){
      $sqlparam{negation}=1  if (!defined($sqlparam{negation}));
      $sqlparam{listmode}=1  if (!defined($sqlparam{listmode}));
      $sqlparam{wildcards}=1 if (!defined($sqlparam{wildcards}));
      $sqlparam{logicalop}=1 if (!defined($sqlparam{logicalop}));
      @filter=($filter);
   }
   else{
      $sqlparam{negation}=0  if (!defined($sqlparam{negation}));
      $sqlparam{listmode}=0  if (!defined($sqlparam{listmode}));
      $sqlparam{wildcards}=0 if (!defined($sqlparam{wildcards}));
      $sqlparam{logicalop}=0 if (!defined($sqlparam{logicalop}));
      if (ref($filter) eq "ARRAY"){
         $sqlparam{allow_sql_in}=1;
         @filter=@{$filter};
      }
      @filter=(${$filter}) if (ref($filter) eq "SCALAR");
   }
   if (ref($filter) eq "ARRAY" && $#{$filter}==-1){
      $$where.=" ".$sqlparam{addmode}." " if ($$where ne "");
      $$where.="(0=1)";
      return(1);
   }
   if ($sqlparam{listmode}){
      my @newfilter=();
      foreach my $f (@filter){
         if ($sqlparam{datatype} eq "DATE"){
            $f=$self->PreParseTimeExpression($f,$sqlparam{timezone});
         }
         $f=~s/\\\*/[|*|]/g;
         $f=~s/\\/\\\\/g;
         my @words=parse_line('[,;]{0,1}\s+',0,$f);
         if ($f ne "" && $#words==-1){
            $self->LastMsg(ERROR,"parse error '$f'");
            return(undef);
         }
         #my @words=parse_line('[,;]{0,1}\s+',"delimiters",$f);
         if (!($f=~m/^\s*$/) && $#words==-1){  # maybe an invalid " struct
            push(@newfilter,undef);
         }
         else{
            push(@newfilter,@words);
         }
      }
      @filter=@newfilter;
   }
   my @negfilter;
   my @posfilter;
   if ($sqlparam{negation}){
      @negfilter=map({my $v=$_;$v=~s/^!//;$v;} grep(/^!/,@filter));
      @posfilter=grep(!/^!/,@filter);
   }
   else{
      @posfilter=@filter;
   }
   #printf STDERR ("posfilter on $sqlfieldname=%s\n",Dumper(\@posfilter));
   #printf STDERR ("negfilter on $sqlfieldname=%s\n",Dumper(\@negfilter));
   my $negexp;
   if ($#negfilter!=-1){
      $negexp=$self->FilterPart2SQLexp($sqlfieldname,\@negfilter,%sqlparam);
      return(undef) if (!defined($negexp));
   }
   my $posexp;
   if ($#posfilter!=-1){
      $posexp=$self->FilterPart2SQLexp($sqlfieldname,\@posfilter,%sqlparam);
      return(undef) if (!defined($posexp));
   }
   if ($negexp ne ""){
      $$where.=" ".$sqlparam{addmode}." " if ($$where ne "");
      $$where.=" NOT ".$negexp;
   }
   if ($posexp ne ""){
      $$where.=" ".$sqlparam{addmode}." " if ($$where ne "");
      $$where.=$posexp;
   }
   return(1);
}

sub dbQuote
{
   my $str=shift;
   my %sqlparam=@_;
   return("NULL") if (!defined($str));
   my $dbtyp;
   if (defined($sqlparam{sqldbh})){
      $dbtyp=$sqlparam{sqldbh}->DriverName();
   }
   if ($sqlparam{wildcards}){ 
      $str=~s/\\/\\\\/g;
      $str=~s/%/\\%/g;
      if ($dbtyp ne "odbc"){
         $str=~s/_/\\_/g;
      }
      $str=~s/\*/%/g;
      $str=~s/\?/_/g;
      $str=~s/\[\|%\|\]/*/g;  # to allow \* searchs (see parse_line above)
   }
   if (defined($sqlparam{sqldbh})){
      my $str=$sqlparam{sqldbh}->quotemeta($str);
      return($str);
   }
   return("'".$str."'");

}

sub FilterPart2SQLexp
{
   my $self=shift;
   my $sqlfieldname=shift;
   my $filter=shift;
   my %sqlparam=@_;
   my $exp="";

   my @workfilter=(@$filter);
      my $conjunction=$sqlparam{conjunction};
      if ($sqlparam{allow_sql_in}){  # NULL check not works with "in" statement!
         if ($#workfilter>10 && !in_array(\@workfilter,undef)){
            my @subexp=();
            my $FinalUseSqlFieldName=$sqlfieldname;
            if (defined($sqlparam{containermode})){
               $FinalUseSqlFieldName=$sqlparam{containermode};
            }
            while(my @subflt=splice(@workfilter,0,999)){
               push(@subexp,"$FinalUseSqlFieldName in (".
                 join(",",map({my $qv="'".$_."'";
                               $qv="NULL" if (!defined($_)); 
                               $qv;} @subflt)).")");
            }
            $exp="(".join(" or ",@subexp).")";

            @workfilter=();
         }
      }
      my $sqlfieldnameislowered=0;
      for(my $fltpos=0;$fltpos<=$#workfilter;$fltpos++){
         my $val=$workfilter[$fltpos];
         if ($val eq "AND" && $sqlparam{logicalop} && $fltpos>0){
            $conjunction="AND";
            next;
         }
         if ($val eq "OR" && $sqlparam{logicalop} && $fltpos>0){
            $conjunction="OR";
            next;
         }
         my $sqldriver=$sqlparam{sqldbh}->DriverName();
         if (($val eq "[LEER]" || $val eq "[EMPTY]") && 
              ($sqlparam{wildcards} || $sqlparam{datatype} eq "DATE")){
            $exp.=" ".$conjunction." " if ($exp ne "");
            if ($sqlparam{containermode}){
               my $container=$sqlparam{containermode};
               $exp.="(($container not like '".'%'.
                       "$sqlfieldname=%=$sqlfieldname".'%'."') or ".
                      "($container is NULL) or ".
                      "($container like '".'%'.
                       "$sqlfieldname=\'\'=$sqlfieldname".'%'."'))";
            }
            else{
               if (defined($sqlparam{sqldbh}) &&
                   ($sqldriver eq "oracle" || $sqldriver eq "db2")){
                  $exp.="($sqlfieldname is NULL)"; # in oracle is ''=NULL and
               }                                   # a compare on '' produces a
               else{                               # wrong result
                  $exp.="($sqlfieldname is NULL or $sqlfieldname='')";
               }
            }
            next;
         }
         my $compop=" like ";
         if ($sqldriver eq "pg"){
            $compop=" ilike ";
         }
         $compop="=" if (!$sqlparam{wildcards}); 
         $compop=" is " if (!defined($val));
         if ($sqlparam{datatype} eq "DATE" && defined($val) &&
             !($val=~m/\*/ || $val=~m/\?/)){
            $compop="=";
         }
         my $compopcount=0;
         while($val=~m/^[<>]/){
            if ($compopcount>0){
               $self->LastMsg(ERROR,"illegal usage of comparison operator");
               return(undef);
            }
            if ($val=~m/^<=/){
               $val=~s/^<=//;
               $compop="<=";
            }
            elsif ($val=~m/^</){
               $val=~s/^<//;
               $compop="<";
            }
            elsif ($val=~m/^>=/){
               $val=~s/^>=//;
               $compop=">=";
            }
            if ($val=~m/^>/){
               $val=~s/^>//;
               $compop=">";
            }
            $compopcount++;
         }
         if ($sqlparam{datatype} eq "FULLTEXT"){
            $sqlfieldname="match($sqlfieldname)";
            $compop=" ";
            $val=dbQuote($val,%sqlparam);
            $val="against($val)";
         }
         if ($sqlparam{datatype} eq "STRING"){
            if (($val eq '' || $val=~m/^\d+$/) && $compop eq " like "){
               $compop="=";
            }
            if ($sqlparam{uppersearch} && defined($val)){
               $val=uc($val);
            }
            if ($sqlparam{lowersearch} && defined($val)){
               $val=lc($val);
            }
            $val=dbQuote($val,%sqlparam);
         }
         if (defined($sqlparam{containermode})){
            $compop=" like ";
            $val=~s/^'/\\'/;
            $val=~s/'$/\\'/;
            #fifi $val="'".'%'."$sqlfieldname=$val=$sqlfieldname".'%'."'";
            $val="'".'%'."$sqlfieldname=$val=$sqlfieldname".'%'."'";
         }
         my $setescape="";
         if (defined($sqlparam{sqldbh}) &&
             ($sqlparam{sqldbh}->DriverName() eq "oracle" ||
              $sqlparam{sqldbh}->DriverName() eq "db2") &&
             $compop eq " like "){
            $setescape=" ESCAPE '\\' ";
         }
         if ($sqlparam{datatype} eq "DATE"){
            my $qval;
            if (!defined($val)){
               $val="NULL";
            }
            else{
               $qval=$self->ExpandTimeExpression($val,"en",
                                                 undef,
                                                 $sqlparam{timezone});
               if (!defined($qval)){
                  if ($self->LastMsg()==0){
                     $self->LastMsg(ERROR,"unknown time expression '%s'",
                                    $val);
                  }
                  return(undef);
               }
               if (defined($sqlparam{sqldbh}) &&
                   lc($sqlparam{sqldbh}->DriverName()) eq "oracle"){
                  $val="to_date(".dbQuote($qval,%sqlparam).
                       ",'YYYY-MM-DD HH24:MI:SS')";
               }
               else{
                  $val=dbQuote($qval,%sqlparam);
               }
            }
         }
         if ((lc($sqlparam{sqldbh}->DriverName()) eq "oracle" ||
              $sqlparam{sqldbh}->DriverName() eq "db2") &&
             $sqlparam{ignorecase}==1){
            if ($val ne "NULL"){
               if (!$sqlfieldnameislowered){
                  $sqlfieldnameislowered++;
                  $sqlfieldname="lower($sqlfieldname)";
               }
               $val="lower($val)";
            }
         }
         my $FinalUseSqlFieldName=$sqlfieldname;
         if (defined($sqlparam{containermode})){
            $FinalUseSqlFieldName=$sqlparam{containermode};
         }
         $exp.=" ".$conjunction." " if ($exp ne "");
         $exp.="(".$FinalUseSqlFieldName.$compop.$val.$setescape.")"
      }
      $exp="($exp)" if ($exp ne "");
#   }
#   else{
#     # $self->LastMsg(ERROR,
#     #                "container search not implemented at now - ".
#     #                "contatct the developer");
#     # return(undef);
#      $sqlfieldname=$sqlparam{containermode};
#   }
   return($exp);
}
#######################################################################



########################################################################
# REST Extensions to handle REST Calls as Static (Cached) Data structes#
########################################################################

sub GetRESTCredentials
{
   my $self=shift;
   my $dbname=shift;
   my %p;

   $p{dbconnect}=$self->Config->Param('DATAOBJCONNECT');
   $p{dbpass}=$self->Config->Param('DATAOBJPASS');
   $p{dbuser}=$self->Config->Param('DATAOBJUSER');  # user is optional
   $p{dbbase}=$self->Config->Param('DATAOBJBASE');  # base is optional

   foreach my $v (qw(dbconnect dbpass dbuser dbbase)){
      if ((ref($p{$v}) ne "HASH" || !defined($p{$v}->{$dbname})) &&
          $v ne "dbuser" && $v ne "dbbase"){
         my $msg=sprintf("Connect(%s): essential information '%s' missing",
                    $dbname,$v);
         $self->LastMsg(ERROR,$msg);
         return();
      }
      if (defined($p{$v}->{$dbname}) && $p{$v}->{$dbname} ne ""){
         $p{$v}=$p{$v}->{$dbname};
      }
   }
   foreach my $v (keys(%p)){
      if (ref($p{$v})){
         delete($p{$v});
      }
   }
   return($p{dbconnect},$p{dbpass},$p{dbuser},$p{dbbase});
}


sub getQueryToken
{
   my $self=shift;
   my $token="";

   my %h=Query->MultiVars();

   my $idobj=$self->IdField();
   if (defined($idobj)){
      my $idname=$idobj->Name();
      if (defined($h{$idname})){
         return("$idname:$h{$idname}");
      }
   }
   foreach my $v (sort(keys(%h))){
      if ($v=~m/^search_/ && $h{$v} ne ""){
         $token.="&$v=$h{$v}";
      }
   }
   return($token);
}


sub DoRESTcall
{
   my $self=shift;
   my %p=@_;

   my $retry_count=$p{retry_count};
   my $retry_interval=$p{retry_interval};
   $retry_count=0     if ($retry_count eq "");
   $retry_interval=10 if ($retry_interval eq "");
   my $sseconds=Time::HiRes::time();


   if (!exists($p{useproxy}) && exists($self->{useproxy})){
      $p{useproxy}=$self->{useproxy};
   }

   my $reqtrace="DoRESTcall: --- $self ---\n";
   RETRYLOOP: for(my $retry=0;$retry<=$retry_count;$retry++){

      my $RESTcallURL=$p{method}." ".$p{url};
      $reqtrace.="DoRESTcall: ".$RESTcallURL."\n";

      my $ua;
      if (!exists($p{verify_hostname})){
         $p{verify_hostname}="1";
      }
      eval('
         use JSON;
         use LWP::UserAgent;
         $ua=new LWP::UserAgent(env_proxy=>0,
                                ssl_opts =>{
                                   verify_hostname=>'.$p{verify_hostname}.'
                                });
      ');
      $reqtrace.="DoRESTcall: ua=$ua\n";
      if ($@ ne ""){
         $reqtrace.="DoRESTcall: ua error=$@\n";
         $self->LastMsg(ERROR,"fail to create UserAgent for DoRESTcall");
         return(undef);
      }

      $ua->protocols_allowed( ['https','http','connect'] );
      if ($p{useproxy}){
         my $probeipproxy=$self->Config->Param("http_proxy");
         if ($probeipproxy ne ""){
            $probeipproxy=~s/^http:/connect:/;
            $ua->proxy(['https'],$probeipproxy);
         }
      }
      $reqtrace.="DoRESTcall: ua timeout=$p{timeout}\n";
      $reqtrace.="DoRESTcall: ua retry_count=$retry_count\n";
      $reqtrace.="DoRESTcall: ua retry_interval=$retry_interval\n";
      if (defined($p{timeout}) && $p{timeout}>0){
         $ua->timeout($p{timeout});
      }
      else{
         if ($retry_count>0){
            $ua->timeout(30); # if retry is enabled, the timeout for one
         }                    # request can be reduced to 30sec
         else{
            $ua->timeout(180); # default UserAgent timeout
         }
      }
      my $req;
      if ($p{method} eq "GET"){
         if (exists($p{data}) && defined($p{data})){
            $req=HTTP::Request->new($p{method},$p{url},$p{headers},$p{data});
         }
         else{
            $req=HTTP::Request->new($p{method},$p{url},$p{headers});
         }
      }
      if ($p{method} eq "POST"){
         $req=HTTP::Request->new($p{method},$p{url},$p{headers},$p{data});
      }
      if ($p{method} eq "PUT"){
         if (exists($p{data}) && defined($p{data})){
            $req=HTTP::Request->new($p{method},$p{url},$p{headers},$p{data});
         }
         else{
            $req=HTTP::Request->new($p{method},$p{url},$p{headers});
         }
      }
      if ($p{method} eq "PATCH"){
         $req=HTTP::Request->new($p{method},$p{url},$p{headers});
      }
      if ($p{method} eq "DELETE"){
         $req=HTTP::Request->new($p{method},$p{url},$p{headers});
      }
      if (ref($p{headers}) eq "ARRAY"){
         my @p=@{$p{headers}};
         while(my $var=shift(@p)){
            my $val=shift(@p);
            if (($var=~m/token/i) || 
                ($var=~m/auth/i) || 
                ($var=~m/passw/i) || 
                ($var=~m/access/i)){
               if (length($val)>22){
                  $val=substr($val,0,8)."...".substr($val,-8);
               }
               elsif (length($val)>18){
                  $val=substr($val,0,6)."...".substr($val,-6);
               }
               elsif (length($val)>10){
                  $val=substr($val,0,2)."...".substr($val,-2);
               }
               else{
                  $val=~s/[a-z0-9]/?/ig;
               }
            }
            $reqtrace.=$var.": ".$val."\n";
         }

      }
      if (defined($p{content})){
         $req->content($p{content});
         if (length($p{content})<1000){
            $reqtrace.=$p{content};
         }
         else{
            $reqtrace.="[CLOB more then 1000 char]\n";
         }
      }
      
      $self->Log(INFO,"restcall",$self->Self()." ".$p{method}." ".$p{url}.
                      " REMOTE_USER=$ENV{REMOTE_USER}");


      my $response=$ua->request($req);
      my $code=$response->code();
      my $message=$response->message();
      if ($response->is_success) {
         my $eseconds=Time::HiRes::time();
         # printf STDERR ("Debug1: code=$code ".
         #                "message=$message ".
         #                "result=%s\n",$response->decoded_content);
         my $sec=sprintf("%.2lf",$eseconds-$sseconds);
         $self->Log(INFO,"restcall",$self->Self()." SUCCESS ${sec}sec ".
                         $p{method}." ".$p{url}.
                         " REMOTE_USER=$ENV{REMOTE_USER}");
         my $respcontent=$response->decoded_content;
         if ($p{preprocess}){
            $respcontent=&{$p{preprocess}}($self,$respcontent,$code,$message,
                                           $response);
         }
         my $ContentType=$response->header('content-type');
         $ContentType="text/json" if ($ContentType eq "");

         my $d;
         if ($ContentType eq "application/xml"){
            eval("use XML::Smart;");
            return(undef) if ($@ ne "");
            my $xmltree;
            eval('$xmltree=new XML::Smart($respcontent);');
            return(undef) if ($@ ne "");
            $d=$xmltree;
         }
         else{
            eval('$d=from_json($respcontent,{utf8=>1});');
            if ($@=~m/Wide character in subroutine entry/){    # if response is 
               eval('$d=from_json($respcontent,{utf8=>0});');  # wrong coded
            }
            if ($@ ne ""){
               my $jsonParseError=$@;
               if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
                  msg(ERROR,"JSON parse error: $jsonParseError");
                  $respcontent=TextShorter($respcontent,80,["INDICATED"]);
                  msg(ERROR,"can not parse JSON content:\n".$respcontent);
               }
               return(undef);
            }
         }
         #print STDERR ("Debug2: result=%s\n",Dumper($d));
         if (ref($d) eq "HASH" || ref($d) eq "ARRAY" || ref($d) eq "XML::Smart"){
            if ($p{success}){
               my $dd=&{$p{success}}($self,$d,$code,$message);
               if (defined($dd)){
                  if (wantarray()){
                     return($dd,$code,$message);
                  }
                  return($dd);
               }
            }
            if (wantarray()){
               return($d,$code,$message);
            }
            return($d);
         }
         else{
            msg(ERROR,"unexpected data in REST response - d=$d");
            msg(ERROR,$reqtrace);
            $self->LastMsg(ERROR,
                           "unexpected data structure returend from REST call");
         }
      }
      else{
         my $statusline=$response->status_line;
         if (($retry<$retry_count) && 
             ($code eq "500" || $code eq "502" || 
              $code eq "503" || $code eq "504")){
            $self->Log(INFO,"restcall",$self->Self()." RETRY $code($retry) ".
                            $p{method}." ".$p{url}.
                            " REMOTE_USER=$ENV{REMOTE_USER}");
            sleep($retry_interval);
         }
         else{
            $reqtrace.=
                 "Response (".NowStamp("en")." UTC):\n$code $statusline\n";
            if ($response->decoded_content ne ""){
               $reqtrace.=$response->decoded_content."\n";
            }
            if ($p{onfail}){
               return(
                  &{$p{onfail}}($self,$code,$statusline,
                                $response->decoded_content,
                                $reqtrace)
               );
            }
            else{
               msg(ERROR,$reqtrace."\nstatusline=".$statusline);
               $self->LastMsg(ERROR,"unexpected result from REST call: ".
                                    $statusline);
            }
            last RETRYLOOP;
         }
      }
   }
   return(undef);
}


sub CollectREST
{
   my $self=shift;
   my %p=@_;

   my $cachetime;
   if (!exists($p{cachetime})){
      if ($W5V2::OperationContext eq "W5Server"){
         $cachetime=0;
      }
      else{
         $cachetime=30;
      }
   }
   else{
      $cachetime=int($p{cachetime});
   }
   $cachetime=0 if (!defined($cachetime));


   if (!exists($p{retry_count})){ 
      $p{retry_count}=0; 
   }
   if (!exists($p{retry_interval})){ 
      $p{retry_interval}=10; 
   }

   my $dbname=$p{dbname};
   my ($baseurl,$apikey,$apiuser,$base);
   if ($dbname ne ""){
      ($baseurl,$apikey,$apiuser,$base)=$self->GetRESTCredentials($dbname);
      if (!defined($baseurl) || !defined($apikey)){
         return(undef);
      }
   }
   my $dataobjurl=$p{url};
   if (ref($p{url}) eq "CODE"){
      $dataobjurl=&{$p{url}}($self,$baseurl,$apikey,$apiuser,$base);
   }
   if (!defined($dataobjurl)){
      $self->LastMsg(ERROR,"no REST URL can be created");
      return(undef);
   }

   my $token="REQUEST:".$dataobjurl.":".time();
   $p{method}="GET" if (!exists($p{method}));
   if ($p{method} eq "GET"){
      $token=$dataobjurl;
   }
   $token=$p{requesttoken} if (defined($p{requesttoken}));
   # requesttoken is needed, to identify query in query-cache
   
   my $c=$self->Context();
   if (1){  # better Caching process
      $W5V2::RESTCache={} if (!defined($W5V2::RESTCache));
      my $globalCache=$W5V2::RESTCache;
      my $globalKey=$self->Self().".Cache";
      $globalCache->{$globalKey}={} if (!defined($globalCache->{$globalKey}));
      $c=$globalCache->{$globalKey};
   }
   foreach my $k (keys(%{$c})){ # cleanup cache
      if ($c->{$k}->{t}<time()-$cachetime){
         delete($c->{$k});
      }
   }
   
   #msg(INFO,"CollectREST: Cache address=$c - token='$token'");

   if (($cachetime<2 || !exists($c->{"RESTCallResult.$token"})) || 
       $c->{"RESTCallResult.$token"}->{t}<time()-$cachetime ||
       $p{method} eq "POST"){  # no Caching for posts

      my $Headers=[];
      if ($p{headers}){
         $Headers=&{$p{headers}}($self,$baseurl,$apikey,$apiuser,$base);
      }
      if ($cachetime<2){  # cachetime = 1 | 0 disables caching
         my %h=@$Headers;
         if (!exists($h{'Cache-Control'})){
            push(@{$Headers},
               "Cache-Control",
               "no-cache, no-store, must-revalidate"
            );
         }
         if (!exists($h{'Pragma'})){
            push(@{$Headers},
               "Pragma","no-cache"
            );
         }
         if (!exists($h{'Expires'})){
            push(@{$Headers},
               "Expires","0"
            );
         }
      }
      my $Content;
      if ($p{content}){
         $Content=&{$p{content}}($self,$baseurl,$apikey,$apiuser,$base)
      }
      $p{format}="JSON" if (!exists($p{format}));
      $p{verify_hostname}="1" if (!exists($p{verify_hostname}));

      my @data=$self->DoRESTcall(
         method=>$p{method},    url=>$dataobjurl,
         content=>$Content,     headers=>$Headers,
         useproxy=>$p{useproxy},
         retry_count=>$p{retry_count},
         retry_interval=>$p{retry_interval},
         verify_hostname=>$p{verify_hostname},
         data=>$p{data},
         BasicAuthUser=>undef, BasicAuthPass=>undef,
         format=>$p{format},
         timeout=>$p{timeout},
         success=>$p{success},
         onfail=>$p{onfail},
         preprocess=>$p{preprocess}
      );
      $c->{"RESTCallResult.$token"}={
         DATA=>\@data,
         t=>time()
      };
   }
   if (exists($c->{"RESTCallResult.$token"})){
      if (wantarray()){
         return(@{$c->{"RESTCallResult.$token"}->{DATA}});
      }
      return($c->{"RESTCallResult.$token"}->{DATA}->[0]);
   }
   return(undef);
}
#######################################################################







1;
