package base::usermask;
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
use kernel::App::Web;
use CGI;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main));
}

sub isSubstValid
{
   my $self=shift;
   my $realuser=shift;
   my $substuser=shift;

   my @userrecview=qw(userid);
   if (!$self->IsMemberOf("admin") &&
       $self->IsMemberOf("support")){
      push(@userrecview,"groups");  # for support members, the group membership
   }                                # of target user is relevant

   my $user=getModuleObject($self->Config,"base::user");  # this operation
   $user->SetFilter({accounts=>\$substuser});             # is only done, if
   my ($userrec,$msg)=$user->getOnlyFirst(@userrecview);  # the current user
   return() if (!defined($userrec));                      # is in mask mode

   my $isadmin=0;
   if ($ENV{REAL_REMOTE_USER} eq $substuser || 
       $self->IsMemberOf("admin")){
      $isadmin=1;
   }
   if (!$isadmin){
      if ($ENV{REAL_REMOTE_USER} eq $substuser || 
          $self->IsMemberOf("support")){
         $isadmin=1;
         my $groups=[];
         if (ref($userrec->{groups}) eq "ARRAY"){
            $groups=$userrec->{groups};
         }
         $groups=[map({$_->{group}} @$groups)]; 
         # mask on target Users from support to admin, testadmin or support
         # ist not allowed
         if (in_array($groups,[qw(admin testadmin support)])){
            msg(WARN,"ilegal try usermask request ".
                     "from $realuser to $substuser");
            $isadmin=0;
         }
      }
   }
   if ($isadmin){
      return({usersubstid=>'admin',srcaccount=>$substuser});
   }


   my $usersubst=getModuleObject($self->Config,"base::usersubst");
   $usersubst->SetFilter({dstaccount=>\$realuser,
                          srcaccount=>\$substuser,
                          active=>\"1"});
   
   my ($substrec,$msg)=$usersubst->getOnlyFirst(qw(usersubstid srcaccount));
   if (defined($substrec)){
      return({srcaccount=>$substuser,usersubstid=>'admin'});
   }
   return();
   
#printf STDERR ("fifi 02 %s\n",Dumper(\@l));
#   return(@l);
}


sub Main
{
   my ($self)=@_;
   my $lastmsg="";
   my $setaccount;
   my $uainput="<input type=text name=setnewuser value=\"$ENV{REMOTE_USER}\" ".
               "id=setnewuser style=\"width:100%\">";
   if (Query->Param("setnewuser") ne ""){
      my $setnewuser=trim(Query->Param("setnewuser"));
      $uainput="<input type=text id=setnewuser name=setnewuser ".
               "value=\"$setnewuser\" ".
               "style=\"width:100%\">";
      my $ua=getModuleObject($self->Config,"base::useraccount");
      $ua->SetFilter({account=>\$setnewuser});
      my @l=$ua->getHashList(qw(account));
      if ($#l==-1){
         my $altsetnewuser="\"*$setnewuser*\"";
         $ua->SetFilter({account=>$altsetnewuser});
         @l=$ua->getHashList(qw(account));
         if ($#l==-1){
            $lastmsg="ERROR "."account not found";
         }
      }
      if ($#l==0){
         # setzen
         my @l=$self->isSubstValid($ENV{REAL_REMOTE_USER},$l[0]->{account});
         if ($#l==0){
            $setaccount=$l[0]->{srcaccount};
            $lastmsg="OK ".
                     sprintf(
                        $self->T("account set by substitution id %s to '%s'"),
                             $l[0]->{usersubstid},$setaccount);
         }
         else{ 
            $lastmsg="ERROR "."account not allowed";
         }
      }
      if ($#l>0){
         $lastmsg="ERROR "."account not unique";
         my $d="<select name=setnewuser style=\"width:100%\">";
         $d.="<option value=\"$setnewuser\">$setnewuser</option>";
         foreach my $rec (@l){
            $d.="<option value=\"$rec->{account}\">$rec->{account}</option>";
         }
         $d.="<option value=\"\"></option>";
         $d.="</select>";
         $uainput=$d;
      }
   }
 
   my $mycontactid;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{userid})){
      $mycontactid=$UserCache->{userid};
   }
   if (!defined($mycontactid)){
      print $self->HttpHeader("text/plain");
      print msg(ERROR,"unknown contact id for user $ENV{REMOTE_USER}");
      return(undef); 
   }
   my $uau=getModuleObject($self->Config,"base::usersubstusage");
   $uau->SetFilter({userid=>$mycontactid});
   my @uaulist=$uau->getHashList(qw(usersubstusageid account));
   my @lastused=map({$_->{account}} @uaulist);;
   push(@lastused,$ENV{REAL_REMOTE_USER});
   my $lastused="<select size=5 name=lastuse ".
                "onchange=\"SetNewAcc(this);\" ".
                "style=\"width:100%;height:100%\">";
   foreach my $acc (reverse(@lastused)){
      $lastused.="<option value=\"$acc\">$acc</option>";
   }
   $lastused.="</select>";
   my %h=();
   if (defined($setaccount)){
      my $cookie;
      if ($setaccount eq $ENV{REAL_REMOTE_USER}){
         $cookie=Query->Cookie(
                       -path=>'/',
                       -name=>"remote_user",
                       -value=>'',
                       -expires=>'-1s');
      }
      else{
         $cookie=Query->Cookie(
                       -path=>'/',
                       -name=>"remote_user",
                       -value=>$setaccount);
         my @cleanup;
         for(my $c=0;$c<=$#uaulist;$c++){
            if ($uaulist[$c]->{account} eq $setaccount){
               push(@cleanup,$uaulist[$c]);
            }
            if ($c+($#cleanup+1)>10){
               push(@cleanup,$uaulist[$c]);
            }
         }
         foreach my $rec (@cleanup){
            $uau->ValidatedDeleteRecord($rec);
         }
         $uau->ValidatedInsertRecord({userid=>$mycontactid,
                                      account=>$setaccount});
      }
      $h{'-cookie'}=$cookie;
   }
   print(Query->Header(%h)); 
   print $self->HtmlHeader(style=>'default.css',
                           js=>['toolbox.js'],
                           title=>$self->T($self->Self()),
                           onload=>'initOnLoad();');
   print $self->HtmlBottom(body=>1,form=>1);
   print <<EOF;
<script language="JavaScript">
function initOnLoad()
{
   var o=document.getElementById("setnewuser");
   if (o){
      o.select();
      o.focus();
   }
   var o=document.getElementById("ResetBotton");
   if (o){  // falls ResetButton da ist
      o.focus();
   }
   addFunctionKeyHandler(document.forms[0],
      function(e){
         if (e.keyCode == 27) {
            parent.hidePopWin(false);
            return(false);
         }
         return(true);
      }
   );
}
function SetNewAcc(o)
{
   var dst=document.getElementById("setnewuser");
   for(i=0;i<o.options.length;i++){
      if (o.options[i].selected){
         dst.value=o.options[i].value;
      }
      o.options[i].selected=false;
   }
}
</script>
EOF
   if ($lastmsg=~m/^OK /){
      print <<EOF;
<script language="JavaScript">
function fineclose()
{
   parent.hidePopWin(true);
}
window.setTimeout("fineclose();",1000);
</script>
EOF
   }
   if ($lastmsg=~m/^OK /){
      $lastmsg="<font style=\"color:darkgreen\">$lastmsg</font>";
   }
   if ($lastmsg=~m/^ERROR /){
      $lastmsg="<font style=\"color:red\">$lastmsg</font>";
   }
   my $currentuserlabel=$self->T("Current logged in useraccount");
   my $effectuserlabel=$self->T("Effective useraccount");
   my $lastlabel=$self->T("List of last used substitution accounts");
   my $resetlabel=$self->T("reset to user");
   if ($ENV{REAL_REMOTE_USER} eq $ENV{REMOTE_USER}){
      print <<EOF;
<form method=post><center>
<table border=0 cellspacing=2 cellpadding=1 width=98% height=180>
<tr height=1%>
<td width=1% nowrap>$currentuserlabel:</td>
<td>
<input style="width:100%;background:silver;" type=text value="$ENV{REAL_REMOTE_USER}" disabled>
</td>
<td>&nbsp;</td>
</tr>
<tr height=1%>
<td width=1% nowrap>$effectuserlabel:</td>
<td>$uainput</td>
<td width=1%><input type=submit value="setzen"></td>
</tr>
<tr height=1%>
<td colspan=3>$lastmsg&nbsp;</td>
</tr>
<tr height=1%>
<td colspan=3>$lastlabel:</td>
</tr>
<tr>
<td colspan=3>$lastused</td>
</tr>
</table>
EOF
   }
   else{
      print <<EOF;
<form method=post><center>
<table border=0 cellspacing=2 cellpadding=1 width=98% height=180>
<tr height=1%>
<td nowrap align=center><h3><b>$effectuserlabel $ENV{REMOTE_USER}</b></h3></td>
<td>
</tr>
<tr >
<td nowrap align=center valign=center><input type=button 
                  id=ResetBotton
                  onclick=doResetAccount()
                  value="$resetlabel $ENV{REAL_REMOTE_USER}"
                  style="width:80%;height:40px"></td>
<td>
</tr>
</table>
<input type="hidden" value="" name=setnewuser id=setnewuser>
<script language="JavaScript">
function doResetAccount()
{
   var dst=document.getElementById("setnewuser");
   dst.value="$ENV{REAL_REMOTE_USER}";
   document.forms[0].submit();
}
</script>
EOF
   }
      
   print $self->HtmlBottom(body=>1,form=>1);
}


1;
