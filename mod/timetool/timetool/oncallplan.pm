package timetool::timetool::oncallplan;
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
use kernel::date;
use kernel::Timetool;

@ISA=qw(kernel::Timetool);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


sub getCalendars
{
   my $self=shift;
   my @l;
   my $timeplan=$self->getParent->getPersistentModuleObject(
                                                    "timetool::timeplan");
   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
   $timeplan->SetFilter({mandatorid=>\@mandators,rawtmode=>$self->Self.";*",
                         cistatusid=>[3,4]});
   my @tl=$timeplan->getHashList(qw(name id));
print STDERR Dumper(\@tl);
   foreach my $tp (@tl){
      push(@l,$self->Self().";".$tp->{id},10,$tp->{name});
   }
   return(@l);
}

sub getCalendarModes
{
   my $self=shift;
   my $s=$self->Self;

   return($s.";oncall"=>'Rufbereitschaft',
          $s.";oncallnotiyfy"=>'Rufbereitschaft mit Benachrichtigung');
}


sub LoadTimeplanRec
{
   my $self=shift;
   my $id=shift;

   if (defined($id) && $id ne ""){
      my $tp=$self->getParent->getPersistentModuleObject("timetool::timeplan");
      $tp->SetFilter({id=>\$id});
      my ($tprec,$msg)=$tp->getOnlyFirst(qw(ALL));
      if (defined($tprec)){
         return($tprec);
      }
   }
   return(undef);
}



sub AddLineLabels
{
   my $self=shift;
   my $vbar=shift;
   my $id=shift;
   my $myuserid=$self->getParent->getCurrentUserId();

   my %user;
   my $con=$self->Context();
   $con->{uid}=[];
   $con->{timeplan}=$self->LoadTimeplanRec($id);


   if (defined($con->{timeplan})){
      my $con=$self->getParent->getPersistentModuleObject("base::lnkcontact");
      $con->SetFilter({parentobj=>\'timetool::timeplan',
                       refid=>\$id,
                       croles=>"*roles=?member?=roles*"});
      my @l=$con->getHashList(qw(targetid));
      foreach my $conrec (@l){
         $user{$conrec->{targetid}}={userid=>$conrec->{targetid},
                                     fullname=>$conrec->{targetid}};
      }
      print STDERR Dumper(\@l);
   }

   my $user=$self->getParent->getPersistentModuleObject("base::user");
   foreach my $userid (keys(%user)){
      $user->ResetFilter();
      $user->SetFilter({userid=>\$userid});
      push(@{$con->{uid}},$userid);
      my ($rec,$msg)=$user->getOnlyFirst(qw(fullname surname givenname));
      if (defined($rec)){
         my $name=$rec->{surname};
         $name.=", " if ($name ne "" && $rec->{givenname} ne "");
         $name.=$rec->{givenname} if ($rec->{givenname} ne "");
         $name=$rec->{fullname} if ($name eq "");
         $user{$userid}->{fullname}=$name;
      }
   }
   my $c=0;
   foreach my $userid (sort({$user{$a}->{fullname} cmp $user{$b}->{fullname}} 
                            keys(%user))){
      my $fullname=$user{$userid}->{fullname};
      if ($userid==$myuserid){
         $fullname="<b>".$fullname."</b>";
      }
      $vbar->SetLabel($userid,$fullname,{order=>$c});
      $c++;
   }
}


sub AddSpan
{
   my $self=shift;
   my $vbar=shift;
   my $start=shift;
   my $end=shift;
   my $dsttimezone=shift;
   my $rec=shift;
   my $TSpanID=shift;
   my $id=shift;
   
   my $calendar=Query->Param("Calendar");
   my $t1=Date_to_Time("GMT",$rec->{tfrom});
   my $t2=Date_to_Time("GMT",$rec->{tto});
   my $con=$self->Context();
   
   if ($rec->{useridref}!=0){
      my $line=2;
      my $color=$con->{timeplan}->{vbarcolor};
      $vbar->AddSpan($line,$rec->{useridref},$t1,$t2,
              color=>$color,
              onclick=>"parent.AddOrModify('$calendar','TSpanID=$rec->{id}');",
              id=>$TSpanID);
   }
}


sub getDefaultMarkHour
{
   my $self=shift;
   my $h=0;

   my $TimeplanID=Query->Param("Formated_timeplanrefid");
   if ($TimeplanID ne ""){
      my $tp=$self->getParent->getPersistentModuleObject("timetool::timeplan");
      $tp->SetFilter({id=>\$TimeplanID});
      my ($tprec,$msg)=$tp->getOnlyFirst(qw(defstarthour));
      if (defined($tprec)){
         $h=$tprec->{defstarthour};
      }
   }

   return($h);
}


sub InitNewRecordQuery
{
   my $self=shift;
   my $tz=shift;

   my $name=Query->Param("name");
   if ($name ne ""){
      Query->Param("Formated_useridref"=>$name);
      Query->Delete("name");
   }
   my $TimeplanID=Query->Param("TimeplanID");
   if ($TimeplanID ne ""){
      Query->Param("Formated_timeplanrefid"=>$TimeplanID);
      Query->Delete("TimeplanID");
   }

   return($self->SUPER::InitNewRecordQuery($tz));
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $userid=$self->getParent->getCurrentUserId();
   my $useridref=effVal($oldrec,$newrec,"useridref");
   my $timeplanrefid=effVal($oldrec,$newrec,"timeplanrefid");
printf STDERR ("fifi timeplanrefid=$timeplanrefid userid=$useridref oldrec=$oldrec\n");
   if (!defined($oldrec)){
      $useridref=Query->Param("Formated_useridref");
      $timeplanrefid=Query->Param("Formated_timeplanrefid");
   }
   return(0) if ($timeplanrefid eq "");
   return(1) if ($self->isEntryWriteable($timeplanrefid,$useridref));
   #$self->LastMsg(ERROR,"no write access in isEntryWriteable");
   return(0);
}


sub getAddOrModifySubsysForm
{
   my $self=shift;
   my $tz=shift;
   my $TSpanRec=shift;
   my $writeok=shift;
   my $tspan=$self->getParent->getPersistentModuleObject("timetool::tspan");

   my $Calendar=Query->Param("Calendar");
   my $Formated_timeplanrefid=Query->Param("Formated_timeplanrefid");
   if (defined($TSpanRec)){
      $Formated_timeplanrefid=$TSpanRec->{timeplanrefid};
      Query->Param("Formated_timeplanrefid"=>$Formated_timeplanrefid);
   }
   if (!defined($TSpanRec)){
      my $uid=Query->Param("Formated_useridref");
      if ($uid ne ""){
         my $u=$self->getParent->getPersistentModuleObject("base::user");
         $u->SetFilter({userid=>\$uid});
         my ($ur,$msg)=$u->getOnlyFirst(qw(fullname));
         if (defined($ur)){
            Query->Param("Formated_user"=>$ur->{fullname});
         }
      }
   }
   my $mode="edit";
   $mode="HtmlDetail" if (!$writeok);


   my $Formated_userref=$tspan->getField("user")->FormatedDetail($TSpanRec,
                                                                      $mode);
   my $Formated_comments=$tspan->getField("comments")->FormatedDetail($TSpanRec,
                                                                      $mode);
   my $d=<<EOF;
<table width=100% border=1>
<tr>
<td width=1% valign=top>User:</td>
<td>$Formated_userref</td>
</tr>
<tr>
<td width=1% valign=top>Bemerkung:</td>
<td>$Formated_comments</td>
</tr>
</table>
EOF
#<input type=hidden value="$Formated_useridref" name=Formated_useridref>

   return($d);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $tspan=$self->getParent->getPersistentModuleObject("timetool::tspan");
   my $user=$tspan->getField("user");
   if (my $userchk=$user->Validate($oldrec,$newrec)){
      $newrec->{useridref}=$userchk->{useridref};
   }
   else{
      return(0);
   }
   my $userid=effVal($oldrec,$newrec,"useridref");
   $newrec->{cistatusid}=4;
   my $timeplanrefid=effVal($oldrec,$newrec,"timeplanrefid");
   if (!defined($timeplanrefid)){
      $timeplanrefid=Query->Param("Formated_timeplanrefid");
   }
   if ($timeplanrefid eq ""){
      $self->LastMsg(ERROR,"invalid timeplanrefid '$timeplanrefid'");
      return(undef);
   }
   if ($userid eq ""){
      $self->LastMsg(ERROR,"no user specified");
      return(undef);
   }
   $newrec->{timeplanrefid}=$timeplanrefid;

   if (!$self->isEntryWriteable($timeplanrefid,$userid)){
      $self->LastMsg(ERROR,"no write access on this entry");
      return(undef);
   }
   return(1);
}


sub isEntryWriteable
{
   my $self=shift;
   my $timeplanrefid=shift;
   my $userid=shift;
   my $myuserid=$self->getParent->getCurrentUserId();

   my $tp=$self->getParent->getPersistentModuleObject("timetool::timeplan");
   $tp->SetFilter({id=>\$timeplanrefid});
   my ($tprec,$msg)=$tp->getOnlyFirst(qw(ALL));
printf STDERR ("myuserid=$myuserid userid=$userid tplan=%s\n",Dumper($tprec));
   if (($tprec->{admid}!=0 && $tprec->{admid}==$myuserid) ||
       ($tprec->{adm2id}!=0 && $tprec->{adm2id}==$myuserid)){
printf STDERR ("fifi rights ok\n");
      return(1);
   }


   return(1) if ($self->getParent->IsMemberOf("admin"));



   return(0);
}








sub Header
{
   my $self=shift;
   my $con=$self->Context();
   my $d;

   if (defined($con->{timeplan}) && $con->{timeplan}->{name} ne ""){
      $d.="<center><div class=header>";
      $d.=$con->{timeplan}->{name};
      $d.="</div></center>";
   }
   return($d.$self->SUPER::Header(@_));
}



sub Bottom
{
   my $self=shift;
   my $con=$self->Context();
   my $d="";

   if (defined($con->{timeplan}) && $con->{timeplan}->{comments} ne ""){
      $d.="<center><div class=noteframe>";
      $d.=$con->{timeplan}->{comments};
      $d.="</div></center>";
   }
   if (defined($con->{timeplan}) && $con->{timeplan}->{prnapprovedline} ne ""){
      $d.="<div class=approvedbar>";
      foreach my $name (reverse(
                        split(/\s*;\s*/,$con->{timeplan}->{prnapprovedline}))){
         $d.="<div class=approvedblock>$name</div>";
      }
      my $lang=$self->getParent->Lang();
      my @now=Today_and_Now($lang);
      my $da=Date_to_String($lang,@now);
      $d.="<br><br><br><div class=approveddate>$da</div>";
      $d.="</div>";
   }
   return($d);
}






1;
