package kernel::CIStatusTools;
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
use kernel;


sub ProtectObject
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $admingroups=shift;

   my $effcistatus=effVal($oldrec,$newrec,"cistatusid");
   if (!defined($effcistatus)){
      $self->LastMsg(ERROR,"no cistatus specified");
      return(0);
   }
   my $effowner=effVal($oldrec,$newrec,"owner");
   my $curruserid=$self->getCurrentUserId();
   if ($effcistatus<2 && defined($effowner) && $curruserid!=$effowner){
      $self->LastMsg(ERROR,"you are only authorized to edit this record");
      return(0);
   }
   if (effChanged($oldrec,$newrec,"cistatusid") && 
       $effcistatus>2 && 
       !($self->IsMemberOf($admingroups) || 
         effVal($oldrec,$newrec,"databossid") eq $curruserid ||
         effVal($oldrec,$newrec,"databoss2id") eq $curruserid )){
      $self->LastMsg(ERROR,"you are only authorized to add in 'order' ".
                           "or 'reserved' state");
      return(0);
   }

   return(1);
}

# process if the cistatus turns from <=4 to >4 - if it is, the primary
# key must be renamed to xxx[n]
sub HandleCIStatusModification
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @primarykey=@_;
   my @altname;
   if (ref($_[0]) eq "ARRAY"){
      my $primarykey=shift;
      @primarykey=@$primarykey;
      if (ref($_[0]) eq "ARRAY"){
         my $altname=shift;
         @altname=@$altname;
      }
      else{
         @altname=@_;
      }
   }
   else{
      @primarykey=@_;
   }

   my $idfield=$self->IdField->Name();

   if (!defined($oldrec) && defined($newrec) && $newrec->{cistatusid}==6){
      # special case to insert/create an "disposed of waste" record
      # - solution is to create a "virtual" oldrec entry
      my %n=%{$newrec};
      $n{$idfield}="[NULL]";
      $oldrec=\%n;
   }
   if (!defined($oldrec) && defined($newrec) && 
       (!defined($newrec->{cistatusid}) || $newrec->{cistatusid} eq "")){
      msg(INFO,"no cistatus specified - using cistatusid 1 as default");
      $newrec->{cistatusid}="1";
   }

   my $id=effVal($oldrec,$newrec,$idfield);
   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
   if (!defined($id) && defined($newrec) && $newrec->{cistatusid}==6){
      $self->LastMsg(ERROR,"can't idenfify target record id in ".$self->Self);
      return(0);
   }
   my $adduniq=0;
   my $deluniq=0;

   if (defined($oldrec) && defined($newrec) &&
       $oldrec->{cistatusid}==6 && $cistatusid==6){
      foreach my $primarykey (@primarykey){
         if (exists($newrec->{$primarykey}) &&
             !($newrec->{$primarykey}=~m/\[\d+\]$/)){
            if (my ($olduniq)=$oldrec->{$primarykey}=~m/(\[\d+\])$/){
               $newrec->{$primarykey}.=$olduniq;
            }
            else{
               $adduniq=1;
            }
         }
      }
   }

   if (((defined($oldrec) && $oldrec->{cistatusid}<=5) || !defined($oldrec)) && 
         (defined($newrec->{cistatusid}) && $newrec->{cistatusid}>5)){ 
      $adduniq=1;
   }
   if (defined($newrec->{cistatusid}) && $newrec->{cistatusid}<6){
      $deluniq=1;
   }
   if ($adduniq || $deluniq){
      foreach my $primarykey (@primarykey){
         if (!defined($newrec->{$primarykey})){
            $newrec->{$primarykey}=$oldrec->{$primarykey};
         }
         $newrec->{$primarykey}=trim($newrec->{$primarykey});
      }
   }
   if ($adduniq){
      my $altnamechanged=0;
      foreach my $primarykey (@primarykey){
         if (defined($newrec->{$primarykey})){
            my $found=0;
            my $basechkname=$newrec->{$primarykey};
            $basechkname=~s/\[\d+\]$//;
            my $mdatefield=$self->getField("mdate"); 
            FINDLOOP: for(my $dropLoop=0;$dropLoop<=1;$dropLoop++){
               for(my $c=0;$c<=999;$c++){
                  my $chkname=$basechkname;
                  $chkname.="[$c]";
                  $self->ResetFilter();
                  $self->SetFilter($primarykey=>\$chkname);
                  my $chkid=$self->getVal($idfield);
                  if (!defined($chkid)){
                     $newrec->{$primarykey}=$chkname;
                     $found++;
                     if (!$altnamechanged){
                        foreach my $altname (@altname){
                           next if ($altname eq "");
                           my $altval=effVal($oldrec,$newrec,$altname);
                           $altval=~s/\[\d*?\]$//;
                           $newrec->{$altname}=$altval."[$c]"; 
                        }
                        $altnamechanged++;
                     }
                     last FINDLOOP;
                  }
               }
               if (!$found){
                  if (!defined($mdatefield)){ # no mdate - so 
                     last FINDLOOP;           # we can' select drops candidates
                  }
                  else{
                     my $dropchkname=$basechkname."[*";
                     $self->ResetFilter();
                     $self->SetFilter({$primarykey=>$dropchkname});
                     $self->SetCurrentOrder("+mdate");
                     my ($droprec,$msg)=$self->getOnlyFirst($idfield,
                                                            $primarykey);
                     if (defined($droprec) && !defined($msg)){
                        msg(WARN,"drop record ".
                            "$droprec->{$idfield}($droprec->{$primarykey}) in ".
                            $self->Self()." to get free ".
                            "name($primarykey) [999]");
                        $self->BulkDeleteRecord({
                           $idfield=>\$droprec->{$idfield}
                        });
                     }
                  }
               }
            }
            if (!$found){
               $self->LastMsg(ERROR,
                              "can't find a unique name for key '%s' ".
                              "with value '%s' in '%s'",
                              $primarykey,$basechkname,$self->Self());
               return(0);
            }
         }
      }
      return(1);
   }
   if ($deluniq){
      foreach my $primarykey (@primarykey){
         $newrec->{$primarykey}=~s/\[\d*?\]$//;
      }
      foreach my $altname (@altname){
         next if ($altname eq "");
         my $altval=effVal($oldrec,$newrec,$altname);
         $altval=~s/\[\d*?\]$//;
         $newrec->{$altname}=$altval; 
      }
   }
   if ($cistatusid<6){  # namecheck is needed, if cistatusid=6 or 7
      foreach my $primarykey (@primarykey){
         my $primkeyval=effVal($oldrec,$newrec,$primarykey);
         if ($primkeyval=~m/\[.*\]\s*$/){
            $self->LastMsg(ERROR,
                           "invalid character in key field ".
                           "'\%s'=>'\%s'",$primarykey,$primkeyval);
            return(0);
         }
      }
   }

   return(1);   # all ok - now break error
}

sub _validateCIStatusHistoryActivity
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1) if ($self->IsMemberOf("admin"));

   my $idfield=$self->IdField();
   my $dataobj=$self->SelfAsParentObject();
   if (defined($idfield) && $dataobj ne ""){
      my $id=effVal($oldrec,$newrec,$idfield->Name);
      my $h=$self->ModuleObject("base::history");
      $h->SetFilter({
         name=>\'cistatusid',
         dataobject=>\$dataobj,
         dataobjectid=>\$id,
         cdate=>'>now-12M'
      });
      my @l=$h->getHashList(qw(cdate name oldstate newstate));

      my $inactcount=0;
      my $tinactcount=0;
      my $actcount=0;
      my $sameop=0;
      my $wasactive=0;
      my $actdate;
      foreach my $hrec (reverse(@l)){
         if ($hrec->{newstate} eq "4"){
            $actcount++;
            $actdate=$hrec->{cdate};
         }
         if ($hrec->{oldstate} eq "4" && $hrec->{newstate} ne "4"){
            $actdate=undef;
         }
         if ($hrec->{oldstate} eq "4" && $hrec->{newstate}>4){
            $tinactcount++;  # temp inactive
         }
         if ($hrec->{oldstate} eq "4" && $hrec->{newstate} ne "4"){
            $inactcount++;
         }
         if ($hrec->{oldstate} eq $oldrec->{cistatusid} &&
             $hrec->{newstate} eq $newrec->{cistatusid}){
            $sameop++;
         }
      }
      if (0){
         printf STDERR ("History:%s\n",Dumper(\@l));
         printf STDERR ("Stat: actcount=$actcount ".
                        "inactcount=$inactcount ".
                        "tinactcount=$tinactcount ".
                        "sameop=$sameop ".
                        "actdate=$actdate\n");
      }
      if (defined($actdate)){
         my $d=CalcDateDuration($actdate,NowStamp("en"));
         if ($oldrec->{cistatusid} eq "4" && $newrec->{cistatusid}<4){
            if ($d->{days}>28){
               $self->LastMsg(ERROR,
                       "CI-State downgrade not allowed on long ".
                       "lasting active CI - create admin request to ".
                       "approve this operation");
               return(0);
            }
         }
      }
      if ($oldrec->{mdate} ne "" && $oldrec->{cistatusid}>5 &&
          defined($newrec) && $newrec->{cistatusid}<6 ){
         my $d=CalcDateDuration($oldrec->{mdate},NowStamp("en"));
         if (defined($d) && $d->{totaldays}>90){
            $self->LastMsg(ERROR,
                    "CI-State reactivation not allowed after ".
                    "90 days in disposed of wasted state - ".
                    "create admin request to ".
                    "approve this operation");
            return(0);
         }
      }
      if ($sameop>2 && $oldrec->{cistatusid}<4){
         $self->LastMsg(ERROR,"flipping cistatus makes detect - ".
                           "create admin request to approve this operation");
         return(0),
      }
      if ($oldrec->{cistatusid} eq "4" && 
          ($newrec->{cistatusid}<4  || $newrec->{cistatusid}>4)){
         if ($inactcount>3 || $sameop>2 || $tinactcount>1){
            $self->LastMsg(ERROR,"too many inactivations - ".
                              "create admin request to approve this operation");
            return(0),
         }
      }
      if (($oldrec->{cistatusid}>2 || $actcount>1) && 
          $newrec->{cistatusid} eq "1"){
         $self->LastMsg(ERROR,"switch back to reserved makes no sense - ".
                           "create admin request to approve this operation");
         return(0),
      }
   }

   return(1);
}

sub HandleCIStatus
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my %param=@_;

   $param{activator}="valid_user" if (!defined($param{activator}));
   $param{activator}=[$param{activator}] if (ref($param{activator}) ne "ARRAY");
   if (!defined($param{mode})){
      my ($package,$filename, $line, $subroutine)=caller(1);
      $subroutine=~s/^.*:://;
      $param{mode}=$subroutine;
   }
   if ($param{mode} eq "SecureValidate"){
      if (defined($oldrec) && defined($newrec)){ # classic true update operation
         if (exists($newrec->{cistatusid})){
            if (!($newrec->{cistatusid}==4 && $oldrec->{cistatusid}==4)){
               if (!$self->_validateCIStatusHistoryActivity($oldrec,$newrec)){
                  return(0);
               }
            }
         }
      }

      if (!defined($oldrec)){
         if ($newrec->{cistatusid}>2 || $newrec->{cistatusid}==0){
            if (!$self->isActivator($oldrec,$newrec,%param)){
               $self->LastMsg(ERROR,"you are not authorized to create ".
                                    "items with this state - ".
                                    "please try to use \"on order\"");
               return(0);
            }
         }
      }
      else{
         if (exists($newrec->{cistatusid}) && $newrec->{cistatusid}==0){
            if (!$self->isActivator($oldrec,$newrec,%param)){
               $self->LastMsg(ERROR,"you are not authorized to set ".
                                    "this state - ".
                                    "please try to use 'on order'");
               return(0);
            }
         }
         elsif ($oldrec->{cistatusid}==1 && $newrec->{cistatusid}>2){
            if (!$self->isActivator($oldrec,$newrec,%param)){
               $self->LastMsg(ERROR,"you are not authorized to set ".
                                    "this state, please set state ".
                                    "to \"on order\"");
               return(0);
            }
         }
         elsif (effChanged($oldrec,$newrec,"cistatusid") && 
                ($newrec->{cistatusid}>2 && $newrec->{cistatusid}<6)){
            if ($oldrec->{cistatusid}<4){
               if (!$self->isActivator($oldrec,$newrec,%param)){
                  $self->LastMsg(ERROR,"you are not authorized to set ".
                                       "this state, please wait for ".
                                       "activation");
                  return(0);
               }
            }
         }
      }
   }
   if ($param{mode} eq "Validate"){
      return($self->HandleCIStatusModification($oldrec,$newrec,
                                               [$param{uniquename}],
                                               $param{altname}));
   }
   if ($param{mode} eq "FinishWrite"){
      if ($self->Config->Param("W5BaseOperationMode") eq "test"){
        # printf STDERR ("fifi oldrec=%s\n",Dumper($oldrec));
        # printf STDERR ("fifi newrec=%s\n",Dumper($newrec));
         my $idname=$self->IdField->Name();
         my $id=effVal($oldrec,$newrec,$idname);
         if ($id ne ""){
            my $dataobj=$self->Clone();
            $dataobj->SetFilter({$idname=>\$id});
            my ($oldrec,$msg)=$dataobj->getOnlyFirst(qw(ALL));
            if ($oldrec->{cistatusid}==2){
               $dataobj->ValidatedUpdateRecord($oldrec,{cistatusid=>4},
                                               {$idname=>\$id});
            }
         }
      }
      else{
         if (!defined($oldrec)){
            if ($newrec->{cistatusid}==2){
               $self->NotifyAdmin("request",$oldrec,$newrec,%param);
               # notify admin about the request (owner in cc)
            }
            if ($newrec->{cistatusid}==1){
               $self->NotifyAdmin("reservation",$oldrec,$newrec,%param);
               # notify notify owner about the reservation and
               # about the unuseable state of this entry
            }
         }
         else{
            if ($oldrec->{cistatusid}<2 && $newrec->{cistatusid}==2){
               $self->NotifyAdmin("request",$oldrec,$newrec,%param);
            }
            if ($newrec->{cistatusid}==4 && $oldrec->{cistatusid}<3){
               $self->NotifyAdmin("activate",$oldrec,$newrec,%param);
            }
            if ($newrec->{cistatusid}==6 && $oldrec->{cistatusid}<3){
               $self->NotifyAdmin("reject",$oldrec,$newrec,%param);
            }
         }
      }
   }
   if ($param{mode} eq "FinishDelete"){
      if ($oldrec->{cistatusid}==2){
         $self->NotifyAdmin("drop",$oldrec,$newrec,%param);
      }
   }
   #printf STDERR ("ciparam=%s\n",Dumper(\%param));


   return(1);
}


sub HandleRunDownRequests
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;
   my %param=@_;

   $param{activator}="admin" if (!defined($param{activator}));
   $param{activator}=[$param{activator}] if (ref($param{activator}) ne "ARRAY");
   if (!defined($param{mode})){
      my ($package,$filename, $line, $subroutine)=caller(1);
      $subroutine=~s/^.*:://;
      $param{mode}=$subroutine;
   }
   if ($param{mode} eq "Validate"){
      #######################################################################
      # ci "rundown" request handling
      #######################################################################
      if (exists($newrec->{rundownreqcomment})){
         if (defined($newrec->{rundownreqcomment}) &&
             $newrec->{rundownreqcomment} eq ""){
            $newrec->{rundownreqcomment}=undef;
            $comprec->{rundownreqcomment}=undef;
            $newrec->{rundownreqdate}=undef;
            if ($self->getField("rundownrequestorid")){
               $newrec->{rundownrequestorid}=undef;
            }
         }
         else{
            $newrec->{rundownreqdate}=NowStamp("en");
            if ($self->getField("rundownrequestorid")){
               my $userid=$self->getCurrentUserId();
               $newrec->{rundownrequestorid}=$userid;
            }
         }
      }
      if (!defined($oldrec) ||
          (exists($newrec->{cistatusid}) &&
           defined($oldrec->{rundownreqdate}) &&
           ($newrec->{cistatusid} eq "4" ||
            $newrec->{cistatusid} eq "3"))){
         if ($self->getField("rundownreqdate")){
            $newrec->{rundownreqdate}=undef;
            $newrec->{rundownreqcomment}=undef;
            $comprec->{rundownreqcomment}=undef;
         }
      }
      #######################################################################
   }
   if ($param{mode} eq "FinishWrite"){
      #######################################################################
      # ci "rundown" request handling
      #######################################################################
      if (defined($oldrec) &&
          exists($newrec->{rundownreqcomment}) &&
          $newrec->{rundownreqcomment} ne "" &&
          $newrec->{rundownreqcomment} ne $oldrec->{rundownreqcomment}){
         $self->NotifyAdmin("rundown",$oldrec,$newrec,%param);
         printf STDERR ("fifi now i should send a MAIL with='$newrec->{rundownreqcomment}'\n");
      }
      #######################################################################
   }
   return(1);
}

sub NotifyAdmin
{
   my $self=shift;
   my $mode=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my %param=@_;

   my $idname=$self->IdField->Name();
   my $creator=effVal($oldrec,$newrec,"creator");
   my $userid=$self->getCurrentUserId();
   my $name=effVal($oldrec,$newrec,$param{uniquename});
   my $id=effVal($oldrec,$newrec,$idname);
   my $modulename=$self->T($self->Self,$self->Self);
   my $wf=getModuleObject($self->Config,"base::workflow");

   my $user=getModuleObject($self->Config,"base::user");
   $user->Initialize();
   #delete($user->{DB});
   return() if ($creator==0);
   $user->SetFilter({userid=>\$creator});
   my ($creatorrec,$msg)=$user->getOnlyFirst(qw(givenname surname
                                                email lastlang));
   return() if (!defined($creatorrec));

   my $oldlang;
   if (defined($ENV{HTTP_FORCE_LANGUAGE})) {
      $oldlang=$ENV{HTTP_FORCE_LANGUAGE};
   }
   $ENV{HTTP_FORCE_LANGUAGE}=$creatorrec->{lastlang};

   my $fromname=$creatorrec->{surname};
   $fromname.=", " if ($creatorrec->{givenname} ne "" && $fromname ne "");
   $fromname.=$creatorrec->{givenname} if ($creatorrec->{givenname});
   $fromname=$creatorrec->{email} if ($fromname eq "");

   my $url=$ENV{SCRIPT_URI};
   $url=~s#/(auth|public).*$##g;
   if ($url eq ""){
      my $baseurl=$self->Config->Param("EventJobBaseUrl");
      $url=$baseurl;
   }

   if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
      $url=~s/^http:/https:/i;
   }

   my $spath=$self->Self();
   $spath=~s/::/\//g;
   my $publicurl=$url."/public/".$spath."/";
   my $listurl=$url."/auth/".$spath."/";
   my $cistatuspath=$url."/public/base/cistatus/show/".$spath;

   my $itemname=$self->T($self->Self,$self->Self);;
   $url=$listurl."Detail?$idname=$id";
   $listurl=$listurl."Main";
   $cistatuspath.="/$id";
   $cistatuspath.="?HTTP_ACCEPT_LANGUAGE=".$self->Lang();

   my $wfname;
   my %notiy;
   my $msg;

   my $activator;
   my @admin=();
   if ($mode eq "request" || $mode eq "rundown") {
      if (ref($param{activator}) eq 'ARRAY' &&
          in_array($param{activator},'admin')) {
         my @admgrps=grep(!/^admin$/,@{$param{activator}});
         $user->SetFilter({groups=>\@admgrps});
         @admin=$user->getHashList(qw(email givenname surname));
      }

      if ($#admin==-1) {
         $user->ResetFilter();
         $user->SetFilter({groups=>$param{activator}});
         @admin=$user->getHashList(qw(email givenname surname));
      }
   }

   if ($mode eq "request"){
      $notiy{emailto}=[map({$_->{email}} @admin)];
      $notiy{emailcc}=[$creatorrec->{email}];
      $wfname=$self->T("Request to activate '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG001");
      $msg=sprintf($msg,$fromname,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "reservation"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Reservation confirmation for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG002");
      $msg=sprintf($msg,$fromname,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "activate"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Activation notification for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG003");
      $msg=sprintf($msg,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "drop"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Drop notification for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG004");
      $msg=sprintf($msg,$name);
      return() if ($creator==$userid);
   }
   if ($mode eq "reject"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Reject notification for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG011");
      my $comments="";
      if ($W5V2::HistoryComments ne ""){
         $comments.="\n<b>".$self->T("argumentation").":</b>\n";
         $comments.=$W5V2::HistoryComments;
         $comments.="\n\n";
      }
      $msg=sprintf($msg,$name,$name,$comments);
   }
   if ($mode eq "rundown"){
      $notiy{emailto}=[map({$_->{email}} @admin)];
      $notiy{emailcc}=[$creatorrec->{email}];
      $wfname=$self->T("Request to rundown '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG009");
      my $comments=$W5V2::HistoryComments;
      if ($comments ne ""){
         $comments="\n".$comments."\n";
      }
      $msg=sprintf($msg,$name,$fromname,$name,$url,$comments);
   }
   my $sitename=$self->Config->Param("SITENAME");
   my $subject=$wfname;
   if ($sitename ne ""){
      $subject=$sitename.": ".$subject;
   }

   my $imgtitle=$self->T("current state of the requested CI");


#   $notiy{emailfrom}=$creatorrec->{email};  # testweise entfernt
   $notiy{name}=$subject;
   if ($mode ne "drop"){
      $notiy{emailpostfix}=<<EOF;
<br>
<br>
<br>
<img title="$imgtitle" src="${cistatuspath}">
EOF
   }
   $notiy{emailtext}=$msg;
   $notiy{class}='base::workflow::mailsend';
   $notiy{step}='base::workflow::mailsend::dataload';
   if (my $id=$wf->Store(undef,\%notiy)){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      my $r=$wf->Store($id,%d);
   }

   if (defined($oldlang)) {
      $ENV{HTTP_FORCE_LANGUAGE}=$oldlang;
   }
   else {
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }

   return(0);
}





sub isActivator
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my %param=@_;

   if ($self->IsMemberOf($param{activator})){
      return(1);
   }
   return(0);
}

sub NotifyOnCIStatusChange
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) && !$self->IsMemberOf("admin")){
      msg(DEBUG,"now we can notify the admins about the request");
      # notify admin
   }
   if (defined($oldrec)){
      if ($newrec->{cistatus}>2 && $oldrec->{cistatus}<=2){
         msg(DEBUG,"now we can notify the createor about the activation");
         # notify creator
      }
   }


   return();
}

sub NotifyAddOrRemoveObject
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $labelname=shift;
   my $infoaboname=shift;
   my $infoaboid=shift;
   my $idname=$self->IdField->Name();
   my $id=effVal($oldrec,$newrec,$idname);
   my $modulelabel=$self->T($self->Self,$self->Self);
   my $mandatorid=effVal($oldrec,$newrec,"mandatorid");
   my $name=effVal($oldrec,$newrec,$labelname);
   my $fullname="???";
   my $oldname="???";

   if (defined($oldrec) && exists($oldrec->{$labelname})){
      $oldname=$oldrec->{$labelname};
   }

   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      if ($UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname} ne ""){
         $fullname=$UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname};
      }
   }
   else{
      $fullname=$W5V2::OperationContext;
      if ($W5V2::EventContext ne ""){
         $fullname.=" (".$W5V2::EventContext.")";
      }
   }

   my $url=$ENV{SCRIPT_URI};
   $url=~s#/(auth|public).*$##g;
   if ($url eq ""){
      my $baseurl=$self->Config->Param("EventJobBaseUrl");
      $url=$baseurl;
   }
   if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
      $url=~s/^http:/https:/i;
   }
   my $spath=$self->Self();
   $spath=~s/::/\//g;
   my $publicurl=$url."/public/".$spath."/";
   my $listurl=$url."/auth/".$spath."/";
   my $cistatuspath=$url."/public/base/cistatus/show/".$spath;

   my $itemname=$self->T($self->Self,$self->Self);;
   $url=$listurl."Detail?$idname=$id";
   $listurl=$listurl."Main";
   $cistatuspath.="/$id";
   $cistatuspath.="?HTTP_ACCEPT_LANGUAGE=".$self->Lang();

   my $op;
   if (defined($oldrec) && !defined($newrec)){
      $op="delete";
   }
   if (!defined($oldrec) && defined($newrec)){
      $op="insert";
   }
   if (defined($oldrec) && defined($newrec)){
      if (exists($oldrec->{$labelname}) && exists($newrec->{$labelname})){
         my $old=$oldrec->{$labelname};
         my $new=$newrec->{$labelname};
         $old=~s/\[\d+\]$//;
         $new=~s/\[\d+\]$//;
         if ($old ne $new){
            $op="rename";
         }
      }


      if (exists($newrec->{cistatusid})){
         if ($newrec->{cistatusid}==4 && $oldrec->{cistatusid}!=4){
            $op="activate";
         }
         if ($newrec->{cistatusid}!=4 && $oldrec->{cistatusid}==4){
            $op="deactivate";
         }
      }
   }
   if (defined($op)){
      my $mandator;
      if ($mandatorid ne ""){
         my $ma=getModuleObject($self->Config,"base::mandator");
         $ma->SetFilter({grpid=>\$mandatorid});
         my ($marec,$msg)=$ma->getOnlyFirst(qw(name));
         if (defined($marec)){ 
            $mandator=$marec->{name};
         }
      }
      my $msg;
      my $mandatorstr="";
      if ($mandator ne ""){
         $mandatorstr=$self->T("MSG010");
         $mandatorstr=sprintf($mandatorstr,$mandator);
      }
      if ($op eq "insert"){
         $msg=$self->T("MSG005");
         $msg=sprintf($msg,$modulelabel,$name,$mandatorstr,$fullname);
         $msg.="\n\nDirectLink:\n$url";
      }
      if ($op eq "delete"){
         $msg=$self->T("MSG006");
         $msg=sprintf($msg,$modulelabel,$name,$mandatorstr,$fullname);
      }
      if ($op eq "activate"){
         $msg=$self->T("MSG007");
         $msg=sprintf($msg,$modulelabel,$name,$mandatorstr,$fullname);
         $msg.="\n\nDirectLink:\n$url";
      }
      if ($op eq "deactivate"){
         $msg=$self->T("MSG008");
         $msg=sprintf($msg,$modulelabel,$name,$mandatorstr,$fullname);
         $msg.="\n\nDirectLink:\n$url";
      }
      if ($op eq "rename"){
         $msg=$self->T("MSG012");
         $msg=sprintf($msg,$modulelabel,$oldname,$mandatorstr,$name,$fullname);
         $msg.="\n\nDirectLink:\n$url";
      }
      my $sitename=$self->Config->Param("SITENAME");
      my $subject="Config-Change: ";
      if ($mandator ne ""){
         $subject.=" $mandator: ";
      }

      $subject.=effVal($oldrec,$newrec,$labelname);
      if ($sitename ne ""){
         $subject=$sitename.": ".$subject;
      }
      my $ia=getModuleObject($self->Config,"base::infoabo");
      my @emailto;
      my $emailto={};
      $ia->LoadTargets($emailto,'base::staticinfoabo',\$infoaboname,
                                 $infoaboid,undef);

      if ($op eq "delete" || $op eq "deactivate"){
         my $databossobj=$self->getField("databossid");
         if (defined($databossobj)){
            my $databossid=effVal($oldrec,$newrec,"databossid");
            my $userid=$self->getCurrentUserId();
            if ($databossid!=$userid && $databossid ne ""){
               my $user=getModuleObject($self->Config,"base::user");
               $user->SetFilter({userid=>\$databossid});
               my ($urec,$msg)=$user->getOnlyFirst(qw(email));
               if (defined($urec) && $urec->{email} ne ""){
                  $emailto->{$urec->{email}}=1;         
               }
            }
         }
      }




      @emailto=keys(%$emailto);
      if ($#emailto!=-1){
         my %notiy;
         $notiy{name}=$subject;
         $notiy{emailtext}=$msg;
         $notiy{emailto}=\@emailto;
         $notiy{class}='base::workflow::mailsend';
         $notiy{step}='base::workflow::mailsend::dataload';
         if ($op ne "delete"){
            $notiy{emailpostfix}=<<EOF;
<img src="${cistatuspath}">
EOF
         }
         my $wf=getModuleObject($self->Config,"base::workflow");
         if (my $id=$wf->Store(undef,\%notiy)){
            my %d=(step=>'base::workflow::mailsend::waitforspool');
            my $r=$wf->Store($id,%d);
         }
      }
   }
}


1;

