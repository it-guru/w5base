package base::workflow::DataIssue;
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
use kernel::WfClass;
@ISA=qw(kernel::WfClass);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{history}=[qw(insert modify delete)];

   $self->LoadSubObjs("ext/DataIssue","DI");
   foreach my $objname (keys(%{$self->{DI}})){
      my $obj=$self->{DI}->{$objname};
      foreach my $entry (@{$obj->getControlRecord()}){
         $self->{da}->{$entry->{dataobj}}=$entry;
         $self->{da}->{$entry->{dataobj}}->{DI}=$objname;
      }
   }

   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;


   printf STDERR ("param in getDynamicFields=%s\n",Dumper(\%param));
   printf STDERR ("Query in getDynamicFields=%s\n",
                  Dumper(scalar(Query->MultiVars())));
   my $affectedobject;
   if (defined($param{current})){
      $affectedobject=$param{current}->{affectedobject};
   }
   else{
      Query->Param("Formated_affectedobject");
   }
   my ($DataIssueName,$dataobjname)=split(/;/,$affectedobject);
   printf STDERR ("fifi DataIssueName=$DataIssueName\n");
   printf STDERR ("fifi dataobjname  =$dataobjname\n");
   my @dynfields=$self->InitFields(
                   new kernel::Field::Select(  
                             name               =>'affectedobject',
                             selectwidth        =>'350px',
                             translation        =>'base::workflow::DataIssue',
                             getPostibleValues  =>\&getObjectList,
                             label              =>'affected Dataobject',
                             container          =>'additional'),
                   new kernel::Field::Text(  
                             name               =>'targetname',
                             translation        =>'base::workflow::DataIssue',
                             label              =>'affected Dataelement',
                             container          =>'additional'),
                 );
#   if (defined($self->getParent->


   return(@dynfields);
}

sub getObjectList
{
   my $self=shift;
   my $app=$self->getParent->getParent();

   my @l;
   foreach my $k (sort({$app->T($a,$a) cmp $app->T($b,$b)} 
                       keys(%{$self->getParent->{da}}))){
      push(@l,$self->getParent->{da}->{$k}->{DI}.";".$k,$app->T($k,$k));
   }
   return(@l);

}


sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=base::workflow::DataIssue');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","state","flow","header","relations","init","history");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   my @l;
#   push(@l,"default") if ($rec->{state}<=20 &&
#                         ($self->isCurrentForward() ||
#                          $self->getParent->IsMemberOf("admin")));
#   if (grep(/^default$/,@l) &&
#       ($self->getParent->getCurrentUserId() != $rec->{initiatorid} ||
#        $self->getParent->IsMemberOf("admin"))){
#      push(@l,"init");
#   }
   return(@l);
}




sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   return("base::workflow::DataIssue::".$shortname);
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if($currentstep eq ""){
      return($self->getStepByShortname("dataload",$WfRec)); 
   }
   elsif($currentstep=~m/::dataload$/){
      return($self->getStepByShortname("main",$WfRec)); 
   }
   return(undef);
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "prio");
   return(1) if ($name eq "name");
   return(1) if ($name eq "shortactionlog");
   return(1) if ($name eq "detaildescription");
   return(0);
}



sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my $isadmin=$self->getParent->IsMemberOf("admin");
   my $stateid=$WfRec->{stateid};
   my $lastworker=$WfRec->{owner};
   my $creator=$WfRec->{openuser};
   my $initiatorid=$WfRec->{initiatorid};
   my @l=();
   my $iscurrent=$self->isCurrentForward($WfRec);


   return(@l);
}


sub NotifyUsers
{
   my $self=shift;

}



#######################################################################
package base::workflow::DataIssue::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%affectedobject(label)%:</td>
<td class=finput>%affectedobject(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%targetname(label)%:</td>
<td class=finput>%targetname(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>detailierte Beschreibung<br>des Datenproblems:</td>
<td class=finput>%detaildescription(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   $newrec->{name}="Bla Bla";
   $newrec->{detaildescription}="xxo";
   foreach my $v (qw(name detaildescription)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   $newrec->{stateid}=2; # zugewiesen
  # $self->LastMsg(ERROR,"no op");
  # return(0);
   $newrec->{step}=$self->getNextStep();

   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $h=$self->getWriteRequestHash("web");
      if (my $id=$self->StoreRecord($WfRec,$h)){
         $h->{id}=$id;
      }
      else{
         return(0);
      }
      return(1);
   }

   return($self->SUPER::Process($action,$WfRec));
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("100%");
}


#######################################################################
package base::workflow::DataIssue::main;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr>
<td class=fname width=20%>%affectedobject(label)%:</td>
<td class=finput> Jo Main</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(0);
   return(1);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

#   if ($action eq "NextStep"){
#      my $h=$self->getWriteRequestHash("web");
#      if (my $id=$self->StoreRecord($WfRec,$h)){
#         $h->{id}=$id;
#      }
#      else{
#         return(0);
#      }
#      return(1);
#   }

   return($self->SUPER::Process($action,$WfRec));
}



sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("100");
}


1;
