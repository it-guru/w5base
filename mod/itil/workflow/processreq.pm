package itil::workflow::processreq;
#  W5Base Framework
#  Copyright (C) 2018  Markus Zeis (w5base@zeis.email)
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
use base::workflow::request;
use itil::workflow::base;
@ISA=qw(base::workflow::request itil::workflow::base);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      new kernel::Field::Select(
                name          =>'process',
                label         =>'IT business process',
                htmleditwidth =>'60%',
                getPostibleValues=>\&getPossibleProcess,
                container     =>'headref'),
   ),$self->SUPER::getDynamicFields(%param));
}


sub getPossibleProcess
{
   my $self=shift;

   my $allgroups=$self->getParent->getGroupHierarchy();
   my %directgroups=$self->getParent->getPosibleInitiatorGroups();
   
   my $bpobj=getModuleObject($self->Config,'itil::businessprocess');

   $bpobj->SetFilter([
              {nature=>\'PROCESS',nativprocessmgrrole=>'R*',cistatusid=>\4},
              {nature=>\'PROCESS',nativprocessmgr2role=>'R*',cistatusid=>\4},
   ]);

   my @proclist=$bpobj->getHashList(qw(id name customerid
                                       nativprocessmgrrole
                                       nativprocessmgr2role));

   # calc relevant processmanager groups (@relprocs) sorted by distance
   my @customerids=map {$_->{customerid}} @proclist;
   my @relgrpids=grep {in_array(\@customerids,$_)} keys(%$allgroups);

   my @relprocs=();
   foreach my $p (@proclist) {
      if (in_array(\@relgrpids,$p->{customerid})) {
         $p->{distance}=$allgroups->{$p->{customerid}}->{distance};
         push(@relprocs,$p);
      }
   }
   @relprocs=sort {$a->{distance} <=> $b->{distance}} @relprocs;

   # IT businessprocess list nearest by user group distance
   my @possibleproc=('','');
   my %procfound;

   foreach my $proc (@relprocs) {
      my @mgrroles=($proc->{nativprocessmgrrole},
                    $proc->{nativprocessmgr2role});
      @mgrroles=grep(!/^\s*$/,@mgrroles);

   USERGROUP:
      foreach my $usergrpid (keys(%directgroups)) {
         my $resp=$self->getParent->getResponsibleTarget(
                                       $usergrpid,
                                       $proc->{customerid},
                                       @mgrroles);
         if (defined($resp)) {
            foreach my $role (@mgrroles) {
               if (in_array($procfound{$usergrpid},$role)) {
                 next USERGROUP;
               }
               if (!exists($procfound{$usergrpid})) {
                  $procfound{$usergrpid}=[$role];
               }
               else {
                  push(@{$procfound{$usergrpid}},$role);
               }
            }

            my $optname=join('#',($proc->{id},$resp->{groupid},
                                  @{$resp->{targetid}}));
            my $optval=$proc->{name};
            $optval.=' ('.$resp->{group}.')';

            push(@possibleproc,($optname,$optval));
         }
      }
   }

   return (@possibleproc);
}


sub getGroupHierarchy
{
   my $self=shift;

   return($self->{allgroups}) if (exists($self->{allgroups}));

   my $userid=$self->getParent->getCurrentUserId();
   my %allgroups=$self->getParent->getGroupsOf($userid,
                           [qw(REmployee RBoss RBackoffice RBoss2)],
                           'up');
   $self->{allgroups}=\%allgroups;
   
   return(\%allgroups);
}


sub getResponsibleTarget
{
   my $self=shift;
   my $grpid=shift;
   my $mgrgrpid=shift;
   my @roles=grep(!/^\s*$/,@_);
   my %res;
   $res{targetid}=[];

   my %procgrps=$self->getParent->getGroupsByRoles($grpid,\@roles);

   foreach my $role (@roles) {
      next if (!exists($procgrps{$mgrgrpid}->{roles}->{$role}));

      my @mgr=@{$procgrps{$mgrgrpid}->{roles}->{$role}};
      push(@{$res{targetid}},map {$_->{userid}} @mgr);
   }

   return(undef) if ($#{$res{targetid}}==-1);

   $res{groupid}=$mgrgrpid;
   $res{group}=$procgrps{$mgrgrpid}->{description};

   return(\%res);
}


sub isWorkflowManager
{
   my $self=shift;
   my $WfRec=shift;

   if (defined($WfRec->{id}) &&   # only if a workflow exists, a workflow
       $WfRec->{stateid}<16){     # manager can be calculated
      my $userid=$self->getParent->getCurrentUserId();

      my @devcon=grep {defined($_)} $self->getDefaultContractor($WfRec);

      while(my $target=shift(@devcon)){
         my $targetid=shift(@devcon);
         if ($target eq "base::user" && $targetid eq $userid){
            return(1);
         }
      }
   }
   return(0);
}


sub getDefaultContractor
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my ($procid,$grpid,@targets)=split('#',$WfRec->{process});

   if ($#targets==-1) {
      $self->LastMsg(ERROR,"Could not find a responsible contact");
      return(undef);
   }
   my $fwdtargetid=shift(@targets);
   my @wsref=map {('base::user',$_)} @targets;

   return(undef,'base::user',$fwdtargetid,undef,undef,@wsref);
}


sub getStepByShortname
{
   my $self=shift;
   my $shortname=shift;
   my $WfRec=shift;

   if ($shortname eq 'dataload') {
      return("itil::workflow::processreq::".$shortname);
   }
   return($self->SUPER::getStepByShortname($shortname,$WfRec));
}


sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("itil::workflow::processreq"=>'relinfo');
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/workflow_proc.jpg?".$cgi->query_string());
}


#######################################################################
package itil::workflow::processreq::dataload;
use vars qw(@ISA);
use kernel;
use base::workflow::request;
@ISA=qw(base::workflow::request::dataload);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   my $oldval=Query->Param("Formated_prio");
   $oldval="5" if (!defined($oldval));
   my $d="<select name=Formated_prio>";
   my @l=("high"=>3,"normal"=>5,"low"=>8);
   while(my $n=shift(@l)){
      my $i=shift(@l);
      $d.="<option value=\"$i\"";
      $d.=" selected" if ($i==$oldval);
      $d.=">".$self->T($n,"base::workflow")."</option>";
   }
   $d.="</select>";

   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=\"100%\">
<tr>
<td class=fname width=20%>%process(label)%:</td>
<td class=finput>%process(detail)%</td>
</tr>
<tr>
<td class=fname width=20%>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%detaildescription(label)%:</td>
<td class=finput>%detaildescription(detail)%</td>
</tr>
<tr>
<td class=fname valign=top width=20%>%prio(label)%:</td>
<td class=finput>$d</td>
</tr>
</table>
EOF
   return($templ);
}


sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($h->{process} eq '') {
      $self->LastMsg(ERROR,"No IT Business process selected");
      return(undef);
   }

   my ($businessprocessid)=split('#',$h->{process},2);
   $h->{affectedbusinessprocessid}=$businessprocessid;

   return($self->SUPER::nativProcess($action,$h,$WfRec,$actions));
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return("300");
}


1;
