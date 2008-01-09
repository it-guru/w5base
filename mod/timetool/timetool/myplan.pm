package timetool::timetool::myplan;
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
   $self->{EntryTypes}=[qw(00vacation 10timeclear 
                           20businesstrip 30illness 40education
                           50svacation)];
   $self->{EntryColors}={'00vacation'=>'green',
                         '20businesstrip'=>'blue',
                         '30illness'=>'red',
                         '40education'=>'#FDFD88',
                         '50svacation'=>'#FD0088',
                         'unknown'=>'yellow',
                         '10timeclear'=>'#E6AF2D'};
   return($self);
}

sub getEntryTypes
{
   my $self=shift;
   return(@{$self->{EntryTypes}});
}

sub getSubsysName
{
   my $self=shift;

   return("timetool::timetool::myplan");
}

sub getCalendars
{
   my $self=shift;

   return("timetool::timetool::myplan",0,"MyPlan")

}

sub SetFilter
{
   my $self=shift;
   my $tspan=shift;
   my $start=shift;
   my $end=shift;
   my $userid=$self->getParent->getCurrentUserId();

   $self->SUPER::SetFilter($tspan,$start,$end);
   $tspan->SetNamedFilter("uid",{useridref=>\$userid});
}

sub AddLineLabels
{
   my $self=shift;
   my $vbar=shift;
   my $id=shift;

   foreach my $entry ($self->getEntryTypes()){
      $vbar->SetLabel($entry,$self->getParent->T($entry,$self->Self()));
   }
}


sub InitNewRecordQuery
{
   my $self=shift;
   my $tz=shift;

   my $name=Query->Param("name");
   if ($name ne ""){
      Query->Delete("name");
      Query->Param("Formated_entrytyp"=>$name);
   }
   if (Query->Param("Formated_useridref") eq ""){
      my $userid=$self->getParent->getCurrentUserId();
      Query->Param("Formated_useridref"=>$userid);
   }

   return($self->SUPER::InitNewRecordQuery($tz));
}



sub getAddOrModifySubsysForm
{
   my $self=shift;
   my $tz=shift;
   my $TSpanRec=shift;
   my $writeok=shift;
   my $tspan=$self->getParent->getPersistentModuleObject("timetool::tspan");

   my $Calendar=Query->Param("Calendar");
   my $entrytyp=Query->Param("Formated_entrytyp");
   if (!defined($entrytyp)){
      if (defined($TSpanRec)){
         $entrytyp=$TSpanRec->{entrytyp};
      }
   }
   my $e="<select name=Formated_entrytyp style=\"width:100%\" ";
   $e.="disabled" if (!$writeok);
   $e.=">";
   my $mode="edit";
   $mode="HtmlDetail" if (!$writeok);
   foreach my $entry ($self->getEntryTypes()){
      $e.="<option value=\"$entry\" ";
      $e.="selected" if ($entry eq $entrytyp);
      $e.=">".$self->getParent->T($entry,'timetool::timetool::myplan')."</option>";
   }

   my $Formated_comments=$tspan->getField("comments")->FormatedDetail($TSpanRec,
                                                                      $mode);
   my $Formated_useridref=Query->Param("Formated_useridref");
   if (defined($TSpanRec)){
      $Formated_useridref=$TSpanRec->{useridref};
   }
   $e.="</select>";
   my $d=<<EOF;
<table width=100% border=1>
<!--
<tr>
<td width=1%>User:</td>
<td><input type=text></td>
</tr>
-->
<tr>
<td width=1%>Eintrag:</td>
<td>$e</td>
</tr>
<!--
<tr>
<td width=1%>Status:</td>
<td><input type=text></td>
</tr>
-->
<tr>
<td width=1% valign=top>Bemerkung:</td>
<td>$Formated_comments</td>
</tr>
</table>
<input type=hidden value="$Formated_useridref" name=Formated_useridref>
EOF

   return($d);
}

sub AddSpan
{
   my $self=shift;
   my $vbar=shift;
   my $start=shift;
   my $end=shift;
   my $dsttimezone=shift;
   my $rec=shift;
   my $id=shift;
  
   my $calendar=Query->Param("Calendar"); 
   my $t1=Date_to_Time("GMT",$rec->{tfrom});
   my $t2=Date_to_Time("GMT",$rec->{tto});
   my $entrytype=$rec->{entrytyp};
   $entrytype="unknown" if (!defined($self->{EntryColors}->{$entrytype}));
   $vbar->AddSpan(2,$entrytype,$t1,$t2,
              color=>$self->{EntryColors}->{$entrytype},
              onclick=>"parent.AddOrModify('$calendar','TSpanID=$rec->{id}');");
   
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $userid=$self->getParent->getCurrentUserId();

   if (!defined($oldrec) && (!defined($newrec->{useridref}) ||
                             $newrec->{useridref} eq "")){
      $newrec->{useridref}=$userid;
   }
   my $useridref=effVal($oldrec,$newrec,"useridref");
   my $istm=$self->isTimeManagerOfUser($useridref);
   if ($useridref!=$userid && !$istm){
      $self->LastMsg(ERROR,"insuficient rights");
      return(0);
   }
   my $wg=$self->getParent->getPersistentModuleObject("timetool::workgroup");
   $wg->SetFilter({contactids=>\$useridref});
   my @rulesets=$wg->getHashList(qw(name contactids mincomposition restrictive));
  
   my $chkid=effVal($oldrec,$newrec,"id");
   my $chkfrom=effVal($oldrec,$newrec,"tfrom");
   my $chkto=effVal($oldrec,$newrec,"tto");
   if (!$self->checkRulesets(\@rulesets,$istm,$chkfrom,$chkto,$chkid)){
      return(0);
   }
 
#   printf STDERR ("fifi from=$chkfrom to=$chkto id=$chkid\n");
#   print STDERR Dumper(\@rulesets);
   
   return(1);
}


sub checkRulesets
{
   my $self=shift;
   my $rules=shift;
   my $istm=shift;
   my $tfrom=shift;
   my $tto=shift;
   my $id=shift;

   my $subsys=$self->getSubsysName();
   my $ts=$self->getParent->getPersistentModuleObject("timetool::tspan");

   my $dfrom=$self->getParent->ExpandTimeExpression($tfrom,"DateTime",
                               "GMT","GMT");
   my $dto=$self->getParent->ExpandTimeExpression($tto,"DateTime","GMT","GMT");

#printf STDERR ("fifi 01 dfrom=%s\n",$dfrom);
#printf STDERR ("fifi 02 dto  =%s\n",$dto);

   my $basespan;
   eval('$basespan=DateTime::Span->from_datetimes(start=>$dfrom,end=>$dto);');
   if (!defined($basespan)){
      $self->LastMsg(ERROR,"can't create DateTime::Span->from_datetimes");
      return(0);
   }
   foreach my $rule (@$rules){
      printf STDERR ("fifi basespan=$basespan\n");

      printf STDERR ("fifi check rule '%s'\n",$rule->{name});
      my $ruleerror=ERROR;
      my $ruleexit=0;
      if ($self->getParent->IsMemberOf("admin") || !($rule->{restrictive})){
         $ruleerror=WARN;
         $ruleexit=1;
      }
      if (ref($rule->{contactids}) eq "ARRAY"){
         my @ruleusers=map({$_->{targetid}} @{$rule->{contactids}});
         my @spaces;
         my $spacecount=$#ruleusers-$rule->{mincomposition};
         for(my $r=0;$r<=$spacecount;$r++){
            my $spset=DateTime::SpanSet->from_spans(spans=>[$basespan]);
            push(@spaces,$spset);
         }
#printf STDERR ("fifi spaces=%s\n",Dumper(\@spaces));



         if ($#ruleusers>-1){
#printf STDERR ("fifi rulsetupser=%s\n",Dumper(\@ruleusers));
            $ts->ResetFilter();
            my %globflt=(useridref=>\@ruleusers,subsys=>\$subsys);
            if ($id ne ""){
               $globflt{id}="!$id";
            }
            my $flt=[{%globflt,tfrom=>">=\"$tfrom GMT\" AND <=\"$tto GMT\""},
                     {%globflt,tto=>">=\"$tto GMT\"",
                               tfrom=>"<=\"$tfrom GMT\""},
                     {%globflt,tto=>">=\"$tfrom GMT\" AND <=\"$tto GMT\""}];
            $ts->SetFilter($flt);
            my @aff=$ts->getHashList(qw(tfrom tto useridref));
#printf STDERR ("fifi aff=%s\n",Dumper(\@aff));
            foreach my $aff (@aff){
               my $stored=0;
               my $afrom=$self->getParent->ExpandTimeExpression(
                                      $aff->{tfrom},"DateTime","GMT","GMT");
               my $ato=$self->getParent->ExpandTimeExpression(
                                      $aff->{tto},"DateTime","GMT","GMT");
               my $span;
               eval('$span=DateTime::Span->from_datetimes(start=>$afrom,'.
                    'end=>$ato);');
               my $set=DateTime::SpanSet->from_spans(spans=>[$span]);
               for(my $s=0;$s<=$#spaces;$s++){
                  $set=$set->intersection($basespan);
                  if ($spaces[$s]->contains($set)){
                     $spaces[$s]=$spaces[$s]->complement($set);
                     $stored=1;
#                     printf STDERR ("fifi stored in $s\n");
                     last;
                  }
               }
               if (!$stored){
                  $self->LastMsg($ruleerror,
                                 "ruleset '$rule->{name}' error level0");
                  return($ruleexit);
               }
            }
         }
         my $stored=0;
         for(my $s=0;$s<=$#spaces;$s++){
            if ($spaces[$s]->contains($basespan)){
               $spaces[$s]=$spaces[$s]->complement($basespan);
#               printf STDERR ("fifi fine stored in $s\n");
               $stored=1;
               last;
            }
         }
         if (!$stored){
            my $msg=sprintf($self->getParent->T('entry violates ruleset %s'),
                            $rule->{name});
            $self->LastMsg($ruleerror,$msg);
            return($ruleexit);
         }
      }
   }
   return(1);
}

sub isTimeManagerOfUser
{
   my $self=shift;
   my $userid=shift;

   return(0);
}

sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $userid=$self->getParent->getCurrentUserId();
   if (!defined($oldrec)){
      my $useridref=Query->Param("Formated_useridref");
      return(1) if ($userid==$useridref);

   }
   my $useridref=effVal($oldrec,$newrec,"useridref");
   return(1) if ($useridref==$userid);

   return(0);
}





1;
