package base::MyW5Base::DataIssueQC;
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
use kernel::MyW5Base;
@ISA=qw(kernel::MyW5Base);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;
   return(1);
}


sub getDefaultStdButtonBar
{
   my $self=shift;
   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                         ["RQManager"],"down");
   my @grpids=keys(%grp);
   if ($#grpids<50){
      return('%StdButtonBar(teamviewcontrol,print,search)%');
   }
   return($self->SUPER::getDefaultStdButtonBar());
}


sub getQueryTemplate
{
   my $self=shift;
   my $bb=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
<td class=fname width=10%>\%fwdtargetname(label)\%:</td>
<td class=finput width=40%>\%fwdtargetname(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>\%createdate(label)\%:</td>
<td class=finput width=40% >\%createdate(search)\%</td>
<td class=fname colspan=2>&nbsp;</td>
</tr>
</table>
</div>
<script language="JavaScript">
setEnterSubmit(document.forms[0],document.DoSearch);
</script>
   
EOF
   
   $bb.=$self->getDefaultStdButtonBar();
   return($bb);
}



sub Result
{
   my $self=shift;
   my $dc=Query->Param("EXVIEWCONTROL");
   my $dataobj=$self->getDataObj();
   my %q=$dataobj->getSearchHash();


   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);
   my %q1=%q;

   my $searchuser=[$userid];
   if ($dc eq "TEAM"){
      my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["RQManager"],
                                            "down");
      my @grpids=keys(%grp);
      if ($#grpids<50){
         @grpids=(qw(-1)) if ($#grpids==-1);
         my $lnk=getModuleObject($self->getParent->Config,"base::lnkgrpuser");
         $lnk->SetFilter({grpid=>\@grpids});
         my @l=$lnk->getHashList(qw(userid));
         if ($#l!=-1){
            $searchuser=[map({$_->{userid}} @l)];
         }
      }
   }
   $q1{fwdtarget}=\'base::user';
   $q1{fwdtargetid}=$searchuser;


   if ($q1{stateid} eq ""){
      $q1{stateid}="<20";
   }
   else{
      $q1{stateid}=$q1{stateid}." AND <20"
   }
   $q1{class}=\'base::workflow::DataIssue';

   $dataobj->ResetFilter();
   $dataobj->SecureSetFilter([\%q1]);
   $dataobj->setDefaultView(qw(linenumber createdate fwdtargetname responsiblegrp 
                       name detaildescription));
   
   return($dataobj->Result(ExternalFilter=>1));
}

sub getDataObj
{
   my $self=shift;
   if (!defined($self->{DataObj})){
      $self->{DataObj}=getModuleObject($self->getParent->Config,
                                       "base::workflow");
   }
   return($self->{DataObj});
}






1;
