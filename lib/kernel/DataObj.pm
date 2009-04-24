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
use kernel;
use kernel::App;
use Text::ParseWords;

@ISA    = qw(kernel::App);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   $self->{isInitalized}=0;
   $self->{use_distinct}=1 if (!exists($self->{use_distinct}));
   
   return($self);
}


sub Clone
{
   my $self=shift;
   my $name=$self->Self;
   my $config=$self->Config;
   return(getModuleObject($config,$name));
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

sub SetFilterForQualityCheck    # prepaire dataobject for automatic 
{                               # quality check (nightly)
   my $self=shift;
   my @view=@_;                 # predefinition for request view
   my @flt;
   if (my $cistatusid=$self->getField("cistatusid")){
      $flt[0]->{cistatusid}=[3,4,5];
      if (my $mdate=$self->getField("mdate")){
         $flt[1]->{cistatusid}=[1,2,6];
         $flt[1]->{mdate}=">now-14d";
      }
   }
   $self->SetFilter(\@flt);
   $self->SetCurrentView(@view);
   return(1);
}

sub SecureSetFilter
{
   my $self=shift;
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
   do{
      if (ref($list[0]) eq "ARRAY"){
         my @l=@{$list[0]};
         for(my $c=0;$c<=$#l;$c++){
            $l[$c]=$self->_preProcessFilter($l[$c]);
         }
         push(@{$self->{FilterSet}->{$filtername}},\@l);
      }
      elsif (ref($list[0]) eq "HASH"){
         my $h=$self->_preProcessFilter($list[0]);
         push(@{$self->{FilterSet}->{$filtername}},$h);
      }
      shift(@list); 
   } until(!defined($list[0]));

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
   msg(INFO,"StringToFilter words=%s\n",Dumper(\@words));
   for(my $c=0;$c<=$#words;$c++){
      msg(INFO,"parse word '\%s'",$words[$c]);
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
      while ($words[$c]=~m/\]$/){
         $words[$c]=~s/\]$//;
         if (!$inrawmode){
            $self->LastMsg(ERROR,"structure error while closeing []");
            return;
         }
         $closerawmode++;
      }
      if ($words[$c]=~m/\)$/){
         $words[$c]=~s/\)$//;
         $andclose++;
      }
      #msg(INFO,"parse inrawmode=$inrawmode closerawmode=$closerawmode");
      if (lc($words[$c]) eq "and"){
         return if ($andopen!=1);
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
   if ($self->can("AddDatabase")){
      my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
      return(@result) if (defined($result[0]) eq "InitERROR");
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

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
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
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   if (defined($rec)){
      my @pa=('StandardDetail'=>$self->T("Standard-Detail"));
      if (defined($self->{history})){
         push(@pa,'HtmlHistory'=>$self->T("History"));
      }
      if (defined($self->{workflowlink})){
         push(@pa,'HtmlWorkflowLink'=>$self->T("Workflows"));
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

sub TryToHandleTransactionSafe
{
   my $self=shift;  
   if ($self->Config->Param("W5BaseTransactionSave") eq "yes"){
      return(1);
   }
   return(0);
}


sub TransactionStart                  # hook to handle commits 
{
   my $self=shift;
   msg(INFO,"=====> TransactionStart");
   return(1);
}

sub TransactionEnd                    # hook to handle commits in 
{                                     # transaction save database engines
   my $self=shift;
   my $docommit=shift;
   msg(INFO,"=====> DBTransactionEnd docommit=$docommit");
   return(1);
}

sub getHashIndexed
{
   my $self=shift;
   my @key=@_;
   my $res={};

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   @key=($self->{'fields'}->[0]) if ($#key==-1);
   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         foreach my $key (@key){
            my $v=$rec->{$key};
            next if (!defined($v));
            $res->{$key}->{$v}=$rec;
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
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
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
   msg(INFO,"getHashList: msg=$msg") if ($msg ne "");
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
   $self->SetCurrentView(qw(ALL));
   my @fieldlist=$self->getFieldObjsByView([$self->getCurrentView()],
                                           oldrec=>$oldrec,
                                           opmode=>'getWriteRequestHash');

   foreach my $fobj (@fieldlist){
      my $field=$fobj->Name();
      if ($mode eq "web"){
         my @val=Query->Param($field);
         if ($#val==-1){
            @val=Query->Param("Formated_".$field);
            if ($#val!=-1){
               my $rawWrRequest=$fobj->Unformat(\@val,$rec);
               #msg(INFO,"getWriteRequestHash: var=$field $rawWrRequest");
               if (!defined($rawWrRequest)){
                  return(undef) if ($self->LastMsg()!=0);
        
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
   return($newrec) if ($mode eq "upload");
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
      $fo->finishWriteRequestHash($oldrec,$newrec);
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
   msg(INFO,"preValidate in $self");
   return(1);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;
   #msg(INFO,"SecureValidate in $self");
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
          foreach my $group (@fieldgrouplist){
             if (grep(/^$group$/,@$wrgroups)){
                $writeok=1;last;
             }
          }
          if ($fo->Type() eq "SubList" ||
              (!grep(/^ALL$/,@$wrgroups) && !$writeok &&
               !($fo->Type() eq "Id"))){
             my $msg=sprintf($self->T("write request to field '\%s' rejected"),
                             $wrfield);
             $self->LastMsg(ERROR,$msg);
             return(0);
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
   return($self->isWriteValid($rec));
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

   return(undef);   # ALL means all groups - else return list of fieldgroups
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef);  # ALL means all groups - else return list of fieldgroups
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
  my $idfieldname=$self->IdField->Name();
  if ($#flt==0){
     if (ref($flt[0]) eq "HASH"){
        if (defined($flt[0]->{$idfieldname}) &&
            ref($flt[0]->{$idfieldname}) eq "ARRAY" &&
            $#{$flt[0]->{$idfieldname}}==0){
           if ($flt[0]->{$idfieldname}->[0]=~m/[\*\?]/){
              return(0);
           }
           return(1);
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
   my $pid=Query->Param("RefFromId");
   my $p=$self->getParent();
   if (defined($p) && defined($pid) && $p->can("FinishSubDelete")){
      $p->FinishSubDelete($pid);
   }
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $selfname=$self->SelfAsParentObject();
   my $idfield=$self->IdField();
   if (defined($idfield)){
      my $id=$idfield->RawValue($oldrec);
      if ($id ne ""){
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

sub FinishSubDelete                  # called, if a record in 
{                                    # SubList has been deleted
   my $self=shift;
   my $id=shift;
   return($self->FinishSubWrite($id));
}

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
   my $pid=Query->Param("RefFromId");
   my $p=$self->getParent();
   if (defined($p) && defined($pid) && $p->can("FinishSubWrite")){
      $p->FinishSubWrite($pid);
   }
}

sub FinishSubWrite
{
   my $self=shift;
   my $id=shift;
   my %rec=();
   msg(INFO,"default FinishSubWrite in $self on $id"); 
   my $idname=$self->IdField->Name();

   $self->SetFilter($idname=>\$id);
   $self->SetCurrentView(qw(ALL));
   $self->ForeachFilteredRecord(sub{
         my $rec=$_;
         $self->ValidatedUpdateRecord($rec,{},{$idname=>\$rec->{$idname}});
   });
   return(undef);
}

sub StoreUpdateDelta
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (defined($self->{history})){
      $self->SetCurrentView(qw(ALL));
      my @fieldlist=$self->getFieldObjsByView([$self->getCurrentView()],
                                              oldrec=>$oldrec,
                                              current=>$newrec,
                                              opmode=>'StoreUpdateDelta');
      my %delta=();
      foreach my $fobj (@fieldlist){
         if ($fobj->history){
            my $field=$fobj->Name;
            next if ($field eq "srcload" || $field eq "mdate");
            if (exists($newrec->{$field})){
               next if (ref($oldrec->{$field}) eq "HASH" ||
                        ref($newrec->{$field}) eq "HASH");
               my $old=$oldrec->{$field};
               my $new=$newrec->{$field};
               $old=[$old] if (ref($old) ne "ARRAY");
               $new=[$new] if (ref($new) ne "ARRAY");
               $old=join(", ",sort(@{$old}));
               $new=join(", ",sort(@{$new}));
               if ($new ne $old){
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
                  $self->HandleHistory($oldrec,$newrec,$field,$old,$new);
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
   my $oldrec=shift;
   my $newrec=shift;
   my $field=shift;
   my $oldval=shift;
   my $newval=shift;

   if (ref($self->{history}) ne "ARRAY"){
      $self->{history}=[$self->{history}]
   }
   my $h=$self->getPersistentModuleObject("History","base::history");
   if (defined($h)){
      my $dataobject=$self->SelfAsParentObject();
      my $idname=$self->IdField->Name();
      my $id=effVal($oldrec,$newrec,$idname);
      my $histrec={name=>$field,
                   dataobject=>$dataobject,
                   dataobjectid=>$id,
                   oldstate=>$oldval,
                   newstate=>$newval,
                   operation=>"modify"};
      my $comments;
      if ($ENV{REMOTE_ADDR} ne ""){
         $comments.="REMOTE_ADDR = $ENV{REMOTE_ADDR} \n";
      }
      if ($W5V2::OperationContext ne "WebFrontend" &&
          $W5V2::OperationContext ne ""){
         $comments.="CONTEXT = $W5V2::OperationContext \n";
      }
      if (defined($comments)){
         $histrec->{comments}=$comments;
      }

      $h->ValidatedInsertRecord($histrec);
   }
   #msg(INFO,"DELTAWRITE: %-10s : old=%s new=%s",$field,$oldval,$newval);
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
   $self->ForeachFilteredRecord(sub{
         my $rec=$_;
         my $changed=0;
         foreach my $k (keys(%$newrec)){
            if ($k ne $idfname){
               if ($newrec->{$k} ne $rec->{$k}){
                  $changed=1;
                  last;
               }
            }
            else{
               if (exists($newrec->{$k})){
                  delete($newrec->{$k});
               }
            }
         }
         if ($changed){
            my $opobj=$self->Clone();
            $opobj->ValidatedUpdateRecord($rec,$newrec,
                                         {$idfname=>$rec->{$idfname}});
         }
         push(@idlist,$rec->{$idfname});
         $found++;
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
   if (my @groups=$self->isWriteValid(undef)){
      if ($self->SecureValidate(undef,$newrec,\@groups)){
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

sub ValidatedInsertRecord
{
   my $self=shift;
   my $newrec=shift;

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   $self->TransactionStart();
   if (!$self->preValidate(undef,$newrec)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"ValidatedInsertRecord: ".
                              "unknown error in ${self}::preValidate()");
      }
   }
   else{
      if ($newrec=$self->validateFields(undef,$newrec)){
         if ($self->Validate(undef,$newrec)){
            $self->finishWriteRequestHash(undef,$newrec);
            my $bak=$self->InsertRecord($newrec);
            $self->LoadSubObjs("ObjectEventHandler","ObjectEventHandler");
            foreach my $eh (values(%{$self->{ObjectEventHandler}})){
               $eh->HandleEvent("InsertRecord",$self->Self,undef,$newrec);
            }
            $self->FinishWrite(undef,$newrec) if ($bak);
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
   if (my @groups=$self->isWriteValid($oldrec)){
      if ($self->SecureValidate($oldrec,$newrec,\@groups)){
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
sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my %comprec=%{$newrec};
   $self->TransactionStart();
   if (!$self->preValidate($oldrec,$newrec,\%comprec)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"ValidatedUpdateRecord: ".
                              "unknown error in ${self}::preValidate()");
      }
   }
   else{
      if (my $validatednewrec=$self->validateFields($oldrec,$newrec,\%comprec)){
         if ($self->Validate($oldrec,$validatednewrec,\%comprec)){
            $self->finishWriteRequestHash($oldrec,$validatednewrec);
            my $bak=$self->UpdateRecord($validatednewrec,@filter);
            if ($bak){
               $self->LoadSubObjs("ObjectEventHandler","ObjectEventHandler");
               foreach my $eh (values(%{$self->{ObjectEventHandler}})){
                  $eh->HandleEvent("UpdateRecord",$self->Self,$oldrec,$newrec);
               }
               $self->FinishWrite($oldrec,$validatednewrec,\%comprec);
               $self->StoreUpdateDelta($oldrec,\%comprec) if ($bak);
               foreach my $v (keys(%$newrec)){
                  $oldrec->{$v}=$newrec->{$v};
               }
            }
            return($bak);
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

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
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
       #  if (!&$method$self->SecureValidatedDeleteRecord($rec)){
       #     printf STDERR ("fifi ERROR in HandleDelete\n");
       #  }
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
      $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
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
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
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

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my $bak=undef;
   if ($self->ValidateDelete($oldrec)){
      $bak=$self->DeleteRecord($oldrec);
      $self->LoadSubObjs("ObjectEventHandler","ObjectEventHandler");
      foreach my $eh (values(%{$self->{ObjectEventHandler}})){
         $eh->HandleEvent("DeleteRecord",$self->Self,$oldrec,undef);
      }
      $self->FinishDelete($oldrec) if ($bak); 
   }

   return($bak);
}
sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   msg(ERROR,"deleteRecord not implemented in DataObj '$self'");
   return(0);
}
########################################################################


sub getHtmlSelect
{
   my $self=shift;
   my $name=shift;
   my $uniquekey=shift;
   my $fld=shift;
   my %opt=@_;
   my $d;
   my $width="100%";
   my $autosubmit="";
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
      $autosubmit=" onchange=window.document.forms[0].submit()";
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
   $d="<select name=$name style=\"$style\"$autosubmit$multiple$size>";
   my @l;
   my @list;
   my @selectfields=(@{$fld},$uniquekey);
   if (defined($opt{fields})){
      push(@selectfields,@{$opt{fields}});
   }
    
   foreach my $rec ($self->getHashList(@selectfields)){
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
      $d.=" value=\"$keylist->[$c]\"";
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
      $self->SetFilter($filter);
      ($dropbox,$keylist,$vallist,$list)=$self->getHtmlSelect(
                                                  "Formated_$name",
                                                  $key,$disp,%param);
   }
#printf STDERR ("fifi keylist=%s filter=%s\n",Dumper($keylist),Dumper($filter));
#printf STDERR ("fifi disp=%s\n",Dumper($disp));
#printf STDERR ("fifi vallist=%s\n",Dumper($vallist));
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
   foreach my $obj (@_){
      next if (!defined($obj));
      my $name=$obj->Name;
      #msg(INFO,"fifi AddField:%s",$obj->name);
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
   my @fobjlist=shift;
   my %param;
   if (ref($_[0])){
      push(@fobjlist,@_);
   }
   else{
      %param=@_;
   }

   foreach my $obj ($self->InitFields(@fobjlist)){
      my $name=$obj->Name;
      next if (defined($self->{'Field'}->{$name}));
      $self->{'Field'}->{$name}=$obj;
      my $inserted=0;
      if (defined($param{insertafter})){
         my @match=($param{insertafter});
         @match=@{$param{insertafter}} if (ref($param{insertafter}) eq "ARRAY");
         for(my $c=0;$c<=$#{$self->{'FieldOrder'}};$c++){
            if (grep(/^$self->{'FieldOrder'}->[$c]$/,@match)){
               splice(@{$self->{'FieldOrder'}},$c+1,
                      $#{$self->{'FieldOrder'}}-$c+1,
                 ($name,
                 @{$self->{'FieldOrder'}}[($c+1)..($#{$self->{'FieldOrder'}})]));
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






sub getFieldList
{
   my $self=shift;
   my %param=@_;

   return() if (!defined($self->{'FieldOrder'}));
   my @fl=(@{$self->{'FieldOrder'}});
   if (defined($self->{SubDataObj})){
      my %subfld=();
      foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
         foreach my $f ($self->{SubDataObj}->{$SubDataObj}->getFieldList()){
            push(@fl,$f) if (!defined($subfld{$f}));
            $subfld{$f}=1;
         }
      }
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

   if ($view->[0] eq "ALL" && $#{$view}==0){
      @view=@{$self->{'FieldOrder'}} if (defined($self->{'FieldOrder'}));
      @view=grep(!/^(qctext|qcstate|qcok)$/,@view); # remove qc data
   }
   else{
      @view=@{$view};
   }
   foreach my $fullfieldname (@view){
      $fullfieldname=trim($fullfieldname);
      my ($container,$fieldname)=(undef,$fullfieldname);
      if ($fullfieldname=~m/\./){
         ($container,$fieldname)=$fullfieldname=~m/^(\S+?)\.(\S+)/;
      }
      my $fobj;
      if (!defined($container)){
         if (exists($self->{'Field'}->{$fieldname})){
            $fobj=$self->{'Field'}->{$fieldname};
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

   return(@fobjs,$self->getSubDataObjFieldObjsByView($view,%param),@subl);
}

sub getSubDataObjFieldObjsByView
{
   my $self=shift;
   my $view=shift;
   my %param=@_;
   my @fobjs;

   foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
      my $sobj=$self->{SubDataObj}->{$SubDataObj};
      if ($sobj->can("getFieldObjsByView")){
         push(@fobjs,$sobj->getFieldObjsByView($view,%param));
      }
   }
   return(@fobjs);
}



sub getFieldHash
{
   my $self=shift;
   my %param=@_;
   my %fh=(%{$self->{'Field'}});

   if (defined($self->{SubDataObj})){
      foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
         my $so=$self->{SubDataObj}->{$SubDataObj};
         foreach my $fieldname (sort(keys(%{$so->{Field}}))){
            $fh{$fieldname}=$so->{Field}->{$fieldname};
         }
      }
   }
   return(\%fh);
}

sub getField
{
   my $self=shift;
   my $fullfieldname=shift;
   my $deprec=shift;
   my ($container,$name)=(undef,$fullfieldname);
   if ($fullfieldname=~m/\./){
      ($container,$name)=$fullfieldname=~m/^(\S+)\.(\S+)/;
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
         if (exists($self->{SubDataObj}->{$SubDataObj}->{'Field'}->{$name})){ 
            return($self->{SubDataObj}->{$SubDataObj}->{'Field'}->{$name});
         }
      }
   }
   return(undef);
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

   my $fobj=$self->getField($name);
   if (defined($fobj) && ref($fobj)){
      my $c=0;
      foreach my $k (keys(%param)){
         $fobj->{$k}=$param{$k};
         $c++;
      }
      return($c);
   }

   return(undef);
}

sub RawValue
{
   my $self=shift;
   my $key=shift;
   my $current=shift;
   my $field=shift;
   if (!defined($field)){
      #msg(ERROR,"access to unknown field '$key' in $self");
      return(undef);
   }
   return($field->RawValue($current));
}

sub getSubList
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my %param=@_;
   my %opt=();

   my $pmode=$mode;
   if (defined($param{ParentMode})){
      $pmode=$param{ParentMode};
   }
   $opt{SubListEdit}=1 if ($mode eq "HtmlSubListEdit");
   $mode="HtmlSubList" if ($mode=~m/^.{0,1}Html.*$/);
   $mode="SubXMLV01"   if ($mode=~m/XML/);
   $param{parentcurrent}=$current;
   if ($mode eq "RAW"){
      my @view=$self->GetCurrentView();
      return($self->getHashList(@view));
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
   if (!defined($self->Context->{'CurrentView'})){
      if (ref($self->{DefaultView}) eq "ARRAY"){
         return(@{$self->{DefaultView}});
      }
      else{
         return();
      }
   }
   return(@{$self->Context->{'CurrentView'}});
}

sub SetCurrentOrder
{
   my $self=shift;
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
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   if ($_[0] eq "ALL" && $#_==0){
      my $fh=$self->getFieldHash();
      $self->Context->{'CurrentView'}=[];
      foreach my $f ($self->getFieldList()){
         if ($fh->{$f}->selectable()){
            push(@{$self->Context->{'CurrentView'}},$f);
         }
      }
      @{$self->Context->{'CurrentView'}}=
         grep(!/^(qctext|qcstate|qcok)$/,@{$self->Context->{'CurrentView'}}); 
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
      if ($group ne "header" && 
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
           href=>"#$id.$group",
           group=>"$group",
          });
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

sub getRecordHeader
{
   my $self=shift;
   my $rec=shift;
   my $headerval;

   if (my $f=$self->getField("fullname")){
      $headerval=quoteHtml($f->RawValue($rec));
   }
   elsif (my $f=$self->getField("name")){
      $headerval=quoteHtml($f->RawValue($rec));
   }
   elsif (my $f=$self->getField("id")){
      $headerval=quoteHtml($f->RawValue($rec));
   }
   else{
      $headerval="not labeld";
   }
   return($headerval);
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

   if (exists($fieldbase->{$var})){
      my $current=$opt->{current};
      my $defmode=Query->Param("FormatAs");
      my %FOpt=(WindowMode=>$opt->{WindowMode});
      $defmode="HtmlDetail" if ($defmode eq "");
      my $mode=$defmode;
      $mode=$opt->{mode} if (defined($opt->{mode}));
      if (!defined($param[0])){
         return($fieldbase->{$var}->RawValue($current));
      }
      if ($param[0] eq "formated" || $param[0] eq "detail" || 
          $param[0] eq "sublistedit" || $param[0] eq "forceedit"){
         if (exists($opt->{viewgroups})){
            my @fieldgrouplist=($fieldbase->{$var}->{group});
            if (ref($fieldbase->{$var}->{group}) eq "ARRAY"){
               @fieldgrouplist=@{$fieldbase->{$var}->{group}};
            }
            my $viewok=0;
            foreach my $fieldgroup (@fieldgrouplist){
               if (grep(/^$fieldgroup$/,@{$opt->{viewgroups}})){
                  $viewok=1;last;
               }
            }
            if (!$viewok && !grep(/^ALL$/,@{$opt->{viewgroups}})){
               return("-");
            }
         }
         if ($param[0] eq "formated"){
            my $d=$fieldbase->{$var}->FormatedResult($current,$mode,%FOpt);
            return($d);
         }
         if ($param[0] eq "detail"){
            if (defined($opt->{currentfieldgroup})){
               if ($opt->{currentfieldgroup} eq $opt->{fieldgroup} &&
                   $opt->{currentid} eq $opt->{id}){
                  $mode="edit";
               }
            }
            if (exists($opt->{editgroups})){
               my @fieldgrouplist=($fieldbase->{$var}->{group});
               if (ref($fieldbase->{$var}->{group}) eq "ARRAY"){
                  @fieldgrouplist=@{$fieldbase->{$var}->{group}};
               }
               my $editok=0;
               foreach my $fieldgroup (@fieldgrouplist){
                  if (grep(/^$fieldgroup$/,@{$opt->{editgroups}})){
                     $editok=1;last;
                  }
               }
               if (!$editok && 
                   !grep(/^ALL$/,@{$opt->{editgroups}}) &&
                   !grep(/^1$/,@{$opt->{editgroups}})){
                  $mode=$defmode;
               }
            }
            my $d=$fieldbase->{$var}->FormatedDetail($current,$mode,%FOpt);
            return($d);
         }
         if ($param[0] eq "sublistedit" || $param[0] eq "forceedit"){
            return($fieldbase->{$var}->FormatedDetail($current,"edit",%FOpt));
         }
      }
      if ($param[0] eq "storedworkspace"){
         return($fieldbase->{$var}->FormatedStoredWorkspace());
      }
      if ($param[0] eq "search"){
         return($fieldbase->{$var}->FormatedSearch());
      }
      if ($param[0] eq "label"){
         return($fieldbase->{$var}->Label($mode));
      }
      if ($param[0] eq "searchlabel"){
         my $l=$fieldbase->{$var}->Label($mode);
         if (length($l)>35){
            $l=substr($l,0,23)."...".substr($l,length($l)-8,8);
         }
         return($l);
      }
      if ($param[0] eq "detailunit"){
         if ($opt->{WindowMode} ne "HtmlDetailEdit"){
            my $unit=$fieldbase->{$var}->unit;
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
   return(qw(header default contacts misc source));
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
      my $spec=shift;

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
            if (defined($s->{$k}->{$lang})){
               $spec->{$k}=$s->{$k}->{$lang};
            }
         }
      }
   }
   my %filedone;
   foreach my $lib (@libs){
      my $filename=$self->getSkinFile($lib,addskin=>'default');
      if ($filename ne "" && !$filedone{$filename}){
         processSpecfile($filename,\%spec);
         $filedone{$filename}++;
      }
   }
   foreach my $lib (@libs){
      my $filename=$self->getSkinFile($lib);
      if ($filename ne "" && !$filedone{$filename}){
         processSpecfile($filename,\%spec);
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
         my @words=parse_line('[,;]{0,1}\s+',0,$f);
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
   if ($sqlparam{wildcards}){ 
      $str=~s/\\/\\\\/g;
      $str=~s/%/\\%/g;
      $str=~s/_/\\_/g;
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
#   if (!defined($sqlparam{containermode})){
      my $conjunction=$sqlparam{conjunction};
      if ($sqlparam{allow_sql_in}){
         if ($#workfilter>10){
            my @subexp=();
            while(my @subflt=splice(@workfilter,0,999)){
               push(@subexp,"$sqlfieldname in (".
                 join(",",map({"'".$_."'";} @subflt)).")");
            }
            $exp="(".join(" or ",@subexp).")";

            @workfilter=();
         }
      }
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
         if (($val eq "[LEER]" || $val eq "[EMPTY]") && 
              ($sqlparam{wildcards} || $sqlparam{datatype} eq "DATE")){
            $exp.=" ".$conjunction." " if ($exp ne "");
            $exp.="($sqlfieldname is NULL or $sqlfieldname='')";
            next;
         }
         my $compop=" like ";
         $compop="=" if (!$sqlparam{wildcards}); 
         $compop=" is " if (!defined($val));
         if ($sqlparam{datatype} eq "DATE" && defined($val) &&
             !($val=~m/\*/ || $val=~m/\?/)){
            $compop="=";
         }
         while($val=~m/^[<>]/){
            if ($val=~m/^<=/){
               $val=~s/^<=//;
               $compop="<=";
            }
            if ($val=~m/^</){
               $val=~s/^<//;
               $compop="<";
            }
            if ($val=~m/^>=/){
               $val=~s/^>=//;
               $compop=">=";
            }
            if ($val=~m/^>/){
               $val=~s/^>//;
               $compop=">";
            }
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
            if ($sqlparam{uppersearch}){
               $val=uc($val);
            }
            if ($sqlparam{lowersearch}){
               $val=lc($val);
            }
            $val=dbQuote($val,%sqlparam);
         }
         if (defined($sqlparam{containermode})){
            $compop=" like ";
            $val=~s/^'/\\'/;
            $val=~s/'$/\\'/;
            $val="'".'%'."$sqlfieldname=$val=$sqlfieldname".'%'."'";
         }
         my $setescape="";
         if (defined($sqlparam{sqldbh}) &&
             lc($sqlparam{sqldbh}->DriverName()) eq "oracle" &&
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
         if (lc($sqlparam{sqldbh}->DriverName()) eq "oracle" &&
             $sqlparam{ignorecase}==1){
            $sqlfieldname="lower($sqlfieldname)";
            $val="lower($val)";
         }
         if (defined($sqlparam{containermode})){
            $sqlfieldname=$sqlparam{containermode};
         }
         $exp.=" ".$conjunction." " if ($exp ne "");
         $exp.="(".$sqlfieldname.$compop.$val.$setescape.")"
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



#######################################################################
# WSDL integration
#######################################################################
sub WSDLcommon
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLtypes.="<xsd:complexType name=\"ArrayOfString\">";
   $$XMLtypes.="<xsd:complexContent>";
   $$XMLtypes.="<xsd:restriction base=\"soapenc:Array\">";
   $$XMLtypes.="<xsd:attribute ".
               "ref=\"soapenc:arrayType\" arrayType=\"xsd:string[]\"/>";
   $$XMLtypes.="</xsd:restriction>";
   $$XMLtypes.="</xsd:complexContent>";
   $$XMLtypes.="</xsd:complexType>";

   $self->WSDLdoPing($uri,$ns,$fp,$module,
                     $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLshowFields($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLfindRecord($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLstoreRecord($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
}

sub WSDLsimple
{
   my $self=shift;
   my $fp=shift;
   my $ns=shift;
   my $func=shift;
   my $soapaction=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;
   my %param=@_;

   $$XMLbinding.="<operation name=\"$func\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#$soapaction\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"$func\">";
   $$XMLportType.="<input message=\"${ns}:${func}InpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:${func}OutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"${func}InpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:${func}\" />";
   $$XMLmessage.="</message>";
   $$XMLmessage.="<message name=\"${func}OutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:${func}Response\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"${func}\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:${func}Input\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:element name=\"${func}Response\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:${func}Output\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"${func}Output\">";
   $$XMLtypes.="<xsd:sequence>";
   my @l=@{$param{'out'}};
   while(my $varname=shift(@l)){
      my $p=shift(@l);
      if (ref($p) eq "HASH"){
         $$XMLtypes.="<xsd:element name=\"$varname\"";
         foreach my $k (keys(%$p)){
            $$XMLtypes.=" $k=\"$p->{$k}\"";
         }
         $$XMLtypes.=" />";
      }
   }
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"${func}Input\">";
   $$XMLtypes.="<xsd:sequence>";
   my $subbuffer;
   my @l=@{$param{'in'}};
   while(my $varname=shift(@l)){
      my $p=shift(@l);
      if (ref($p) eq "HASH"){
         if (exists($p->{default})){
            $varname="___STORE_TAG_AT_${varname}_$p->{default}_PARAM___";
            delete($p->{default});
         }
         $$XMLtypes.="<xsd:element name=\"$varname\"";
         foreach my $k (keys(%$p)){
            $$XMLtypes.=" $k=\"$p->{$k}\"";
         }
         $$XMLtypes.=" />";
      }
      if (ref($p) eq "ARRAY"){
         my $usevarname=$varname;
         $usevarname=~s/(^[a-z])/uc($1)/e;
         $$XMLtypes.="<xsd:element name=\"${varname}\" ".
                    "type=\"${ns}:${func}${usevarname}\" />";
                    "minOccurs=\"1\" maxOccurs=\"1\" />";
         $subbuffer.="<xsd:complexType name=\"${func}${usevarname}\">";
         $subbuffer.="<xsd:sequence>";
         my @subl=@$p;
         while(my $subvarname=shift(@subl)){
            my $subp=shift(@subl);
            if (exists($subp->{default})){
               $varname="___STORE_TAG_AT_${varname}_$subp->{default}_PARAM___";
               delete($subp->{default});
            }
            $subbuffer.="<xsd:element name=\"$subvarname\"";
            foreach my $subk (keys(%$subp)){
               $subbuffer.=" $subk=\"$subp->{$subk}\"";
            }
            $subbuffer.=" />";
         }
         $subbuffer.="</xsd:sequence>";
         $subbuffer.="</xsd:complexType>";
      }
   }
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>".$subbuffer;
}

sub WSDLdoPing
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLbinding.="<!-- doPing() checks the connection to the w5base object ".
                 " --> ";
   $self->WSDLsimple($fp,$ns,"doPing","doPing",
                     $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes,
                     in =>[
                            lang            =>{type=>'xsd:string',
                                               minOccurs=>'1',
                                               maxOccurs=>'1',
                                               nillable=>'true'},
                            action          =>{type=>'xsd:string',
                                               minOccurs=>'1',
                                               maxOccurs=>'1',
                                               default=>'ActionCheck',
                                               nillable=>'true'}
                          ],
                     out=>[
                            exitcode        =>{type=>'xsd:int',
                                               minOccurs=>'1',
                                               maxOccurs=>'1' },
                            result          =>{type=>'xsd:int',
                                               minOccurs=>'1',
                                               maxOccurs=>'1' }
                     ]);
}

sub WSDLshowFields
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLbinding.="<!-- showFields() gives you access to the field definitions ".
                 "of the dataobject -->";
   $$XMLbinding.="<operation name=\"showFields\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#showFields\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"showFields\">";
   $$XMLportType.="<input message=\"${ns}:showFieldsInpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:showFieldsOutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"showFieldsInpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:showFields\" />";
   $$XMLmessage.="</message>";
   $$XMLmessage.="<message name=\"showFieldsOutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:showFieldsResponse\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"showFields\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:showFieldsInp\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:element name=\"showFieldsResponse\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:showFieldsOut\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"showFieldsOut\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"1\" maxOccurs=\"1\" ".
              "name=\"exitcode\" type=\"xsd:int\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"lastmsg\" type=\"${ns}:ArrayOfString\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"records\" type=\"${ns}:FieldList\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"FieldList\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"item\" type=\"${ns}:Field\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"Field\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"type\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"longtype\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"name\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"group\" type=\"${ns}:ArrayOfString\" />";
   $$XMLtypes.="<xsd:element name=\"primarykey\" ".
               "minOccurs=\"0\" maxOccurs=\"1\" type=\"xsd:int\"  />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"showFieldsInp\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"lang\" ".
              "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
}




sub WSDLstoreRecord
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;
   my @flist;

   my $recordname="StoreableRec";
   if ($o->Self() eq "base::workflow"){
      $recordname="WfRec";
   }

   $$XMLbinding.="<!-- the storeRecord() method allows to access all data -->";
   $$XMLbinding.="<operation name=\"storeRecord\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#storeRecord\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"storeRecord\">";
   $$XMLportType.="<input message=\"${ns}:storeRecordInpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:storeRecordOutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"storeRecordInpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:storeRecord\" />";
   $$XMLmessage.="</message>";

   $$XMLmessage.="<message name=\"storeRecordOutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:storeRecordResponse\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"storeRecord\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:storeRecInp\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"storeRecInp\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"lang\" ".
              "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"data\" ".
              "type=\"${ns}:$recordname\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:element name=\"storeRecordResponse\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:storeRecOut\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"storeRecOut\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"1\" maxOccurs=\"1\" ".
              "name=\"exitcode\" type=\"xsd:int\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"IdentifiedBy\" type=\"xsd:integer\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"lastmsg\" type=\"${ns}:ArrayOfString\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"$recordname\">";
   $$XMLtypes.="<xsd:sequence>";
   $self->WSDLfieldList($uri,$ns,$fp,$module,"store",
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
}

sub WSDLfieldList
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $mode=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;
   my @flist;
   if ($o->can("getFieldObjsByView")){
      @flist=$o->getFieldObjsByView(["ALL"]);
   }
   if ($mode eq "store"){
      foreach my $fobj (@flist){
         my $type="xsd:string";
         my $minOccurs="0";
         if ($fobj->Type() eq "Id"){
            $type="xsd:integer";
         }
     
         my $name=$fobj->Name();
         $$XMLtypes.="<xsd:element minOccurs=\"$minOccurs\" ".
                     "maxOccurs=\"1\" name=\"$name\" type=\"$type\" />";
      }
   }
   if ($mode eq "result"){
      foreach my $fobj (@flist){
         my $type="xsd:string";
         my $minOccurs="0";
         if ($fobj->Type() eq "Id"){
            $type="xsd:integer";
            $minOccurs="1";
         }
     
         my $name=$fobj->Name();
         $$XMLtypes.="<xsd:element minOccurs=\"$minOccurs\" ".
                     "maxOccurs=\"1\" name=\"$name\" type=\"$type\" />";
      }
   }
   if ($mode eq "filter"){
      foreach my $fobj (@flist){
         next if ($fobj->Type() eq "Linenumber");
         my $type="xsd:string";
         my $name=$fobj->Name();
         $$XMLtypes.="<xsd:element minOccurs=\"0\" ".
                     "maxOccurs=\"1\" name=\"$name\" type=\"$type\" />";
      }
   }
}


sub WSDLfindRecord
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;
   my @flist;
   if ($o->can("getFieldObjsByView")){
      @flist=$o->getFieldObjsByView(["ALL"]);
   }

   $$XMLbinding.="<!-- the findRecord() method allows to access all data -->";
   $$XMLbinding.="<operation name=\"findRecord\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#findRecord\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"findRecord\">";
   $$XMLportType.="<input message=\"${ns}:findRecordInpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:findRecordOutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"findRecordInpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:findRecord\" />";
   $$XMLmessage.="</message>";
   $$XMLmessage.="<message name=\"findRecordOutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:findRecordResponse\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"findRecord\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:findRecordInp\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:element name=\"findRecordResponse\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:findRecordOut\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"findRecordOut\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"1\" maxOccurs=\"1\" ".
              "name=\"exitcode\" type=\"xsd:int\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"lastmsg\" type=\"${ns}:ArrayOfString\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"records\" type=\"${ns}:RecordList\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"RecordList\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"item\" type=\"${ns}:Record\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"Record\">";
   $$XMLtypes.="<xsd:sequence>";
   $self->WSDLfieldList($uri,$ns,$fp,$module,"result",
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"findRecordInp\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"lang\" ".
              "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"view\" ".
              "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"filter\" ".
              "type=\"${ns}:Filter\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"Filter\">";
   $$XMLtypes.="<xsd:sequence>";
   $self->WSDLfieldList($uri,$ns,$fp,$module,"filter",
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

}







1;
