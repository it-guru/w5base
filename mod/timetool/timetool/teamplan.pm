package timetool::timetool::teamplan;
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
use timetool::timetool::myplan;

@ISA=qw(timetool::timetool::myplan);

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

   return("timetool::timetool::teamplan",0,"Teamplan")

}

sub AddLineLabels
{
   my $self=shift;
   my $vbar=shift;
   my $id=shift;
   my $myuserid=$self->getParent->getCurrentUserId();

   my $grpid=Query->Param("search_grpid");
   my %user;
   my $con=$self->Context();
   $con->{uid}=[];
   if ($grpid!=0){
      my $grp=$self->getParent->getPersistentModuleObject("base::grp");
      $grp->SetFilter({grpid=>\$grpid});
      my @d=$grp->getHashList(qw(users));
      foreach my $rec (@d){
         next if (!defined($rec->{users}) || ref($rec->{users}) ne "ARRAY");
         foreach my $urec (@{$rec->{users}}){
            $user{$urec->{userid}}={userid=>$urec->{userid},
                                    fullname=>$urec->{userid}};
         }
      }
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


sub getAdditionalSearchMask
{
   my $self=shift;

   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["REmployee","RBoss",
                                             "RBoss2","RTimeManager"],
                                            "down");

   my $orgsel="<select name=search_grpid style=\"width:100%\">";
   my $oldorg=Query->Param("search_grpid");
   my $oldorgfound=0;
   my $first=undef;
   foreach my $rec (values(%grp)){
      next if ($rec->{grpid}<=0);
      $first=$rec->{grpid} if (!defined($first));
      $orgsel.="<option value=\"$rec->{grpid}\"";
      if ($oldorg eq $rec->{grpid}){
         $orgsel.=" selected";
         $oldorgfound=1;
      }
      $orgsel.=">$rec->{fullname}</option>";
   }
   $orgsel.="</select>";
   if (!$oldorgfound){
      Query->Param("search_grpid"=>$first);
   }
   return($orgsel);
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

   if ($rec->{useridref}!=0){
      my $line=2;
      my $color="yellow";
      my @et=@{$self->getParent->{subsys}->{'timetool::timetool::myplan'}->
               {EntryTypes}};
      my %ec=%{$self->getParent->{subsys}->{'timetool::timetool::myplan'}->
               {EntryColors}};

      for(my $c=0;$c<=$#et;$c++){
         $line=$c if ($et[$c] eq $rec->{entrytyp});
      }
      $color=$ec{$rec->{entrytyp}} if (defined($ec{$rec->{entrytyp}}));


      $vbar->AddSpan($line,$rec->{useridref},$t1,$t2,
              color=>$color,
              onclick=>"parent.AddOrModify('$calendar','TSpanID=$rec->{id}');",
              id=>$TSpanID);
   }
}

sub SetFilter
{
   my $self=shift;
   my $tspan=shift;
   my $start=shift;
   my $end=shift;
   my $userid=$self->getParent->getCurrentUserId();
   my $con=$self->Context();

   $self->SUPER::SetFilter($tspan,$start,$end);
   $tspan->SetNamedFilter("uid",{useridref=>$con->{uid}});
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $userid=$self->getParent->getCurrentUserId();
   my $useridref=effVal($oldrec,$newrec,"useridref");
   if (!defined($oldrec)){
      $useridref=Query->Param("Formated_useridref");
   }
   printf STDERR ("fifi my userid=$userid useridref=$useridref\n");
   return(1) if ($userid==$useridref);  # edit my own records
   if ($self->isTimeManagerOfUser($useridref)){
      return(1);
   }
   return(0);
}

sub isTimeManagerOfUser
{
   my $self=shift;
   my $destuserid=shift;
   my $userid=$self->getParent->getCurrentUserId();

   return(1) if ($self->getParent->IsMemberOf("admin"));
   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                        ["RTimeManager","RBoss","RBoss2"],"down");
   print STDERR Dumper(\%grp);
   if ($destuserid>0){
      my $user=$self->getParent->getPersistentModuleObject("base::user");
      $user->SetFilter({userid=>\$destuserid});
      my ($urec,$msg)=$user->getOnlyFirst(qw(groups));
      if (defined($urec) && ref($urec->{groups}) eq "ARRAY"){
         my @g=keys(%grp);
         foreach my $grec (@{$urec->{groups}}){
            my $grpid=$grec->{grpid};
            return(1) if (grep(/^$grpid$/,@g));
         }
      }
   }
   return(0);
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
   return($self->SUPER::InitNewRecordQuery($tz));
}

sub Bottom
{
   my $self=shift;

   my @et=@{$self->getParent->{subsys}->{'timetool::timetool::myplan'}->
            {EntryTypes}};
   my %ec=%{$self->getParent->{subsys}->{'timetool::timetool::myplan'}->
            {EntryColors}};

   my $d="<div style=\"margin:5px\"><center><table border=0>";
   $d.="<tr>";
   for(my $c=0;$c<=$#et;$c++){
      my $et=$et[$c];
      $d.="</tr><tr>" if ($c % 2 ==0);
      $d.="<td align=left width=100>".
          $self->T($et,"timetool::timetool::myplan")."</td>";   
      $d.="<td width=150><div style=\"height:5px;width:40px;background:$ec{$et};".
          "overflow:hidden\"><font size=1>&nbsp;</font></div></td>";   
   }
   
   $d.="</tr>";
   $d.="</table></center></div>";
   $d="<center><div class=noteframe>$d</div></center>";
   return($d);
}











1;
