package base::MyW5Base::wfmyjobs;
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
   return(1) if (defined($self->{DataObj}));
   $self->SUPER::Init();
   $self->{DataObj}=getModuleObject($self->getParent->Config,"base::workflow");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

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

   $$XMLtypes.="<xsd:simpleType name=\"viewstate\">";
   $$XMLtypes.="<xsd:restriction base=\"xsd:string\">";
   $$XMLtypes.="<xsd:enumeration value=\"\" />";
   $$XMLtypes.="<xsd:enumeration value=\"HIDEUNNECESSARY\" />";
   $$XMLtypes.="<xsd:enumeration value=\"ONLYDEFFERED\" />";
   $$XMLtypes.="</xsd:restriction>";
   $$XMLtypes.="</xsd:simpleType>";

   $self->getDataObj()->WSDLWorkflowFieldTypes($uri,$ns,$fp,$module,
                           $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);


 
   return($self->SUPER::WSDLcommon($uri,$ns,$fp,$module,
                              $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes));
}


sub WSDLaddNativFieldList
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $class=shift;
   my $mode=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   if ($mode eq "filter"){
      $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
                  "name=\"viewstate\" type=\"$ns:viewstate\" />";
   }

   return($self->getDataObj()->WSDLaddNativFieldList($uri,$ns,$fp,$class,$mode,
                              $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes));
}




sub getDefaultStdButtonBar
{
   my $self=shift;
   return('%StdButtonBar(bookmark,deputycontrol,personalview,wfstatecontrol,teamviewcontrol,print,search)%');
}

sub getQueryTemplate
{
   my $self=shift;
   my $prio=Query->Param("search_prioid");
   Query->Param("search_prioid"=>'<10') if (!defined($prio));
   my $viewstate=Query->Param("VIEWSTATE");
   $viewstate="HIDEUNNECESSARY" if (!defined($viewstate));
   my $VS="<select name=VIEWSTATE style=\"width:100%\">";

   $VS.="<option value=\"HIDEUNNECESSARY\"";
   $VS.=" selected" if ($viewstate eq "HIDEUNNECESSARY");
   $VS.=">";
   $VS.=$self->getParent->T("hide defered, pending");
   $VS.="</option>";

   $VS.="<option value=\"ONLYDEFFERED\"";
   $VS.=" selected" if ($viewstate eq "ONLYDEFFERED");
   $VS.=">";
   $VS.=$self->getParent->T("only defered workflows");
   $VS.="</option>";

   $VS.="<option value=\"\"";
   $VS.=" selected" if ($viewstate eq "");
   $VS.=">";
   $VS.=$self->getParent->T("show all");
   $VS.="</option>";
   $VS.="</select>";
   my $wffilter=$self->getParent->T("Workflow Filter");

   my $bb=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=50% >\%name(search)\%</td>
<td class=fname width=10%>\%prio(label)\%:</td>
<td class=finput width=30%>\%prioid(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>\%class(label)\%:</td>
<td class=finput width=50% >\%class(search)\%</td>
<td class=fname width=10%>\%stateid(label)\%:</td>
<td class=finput width=30%>\%stateid(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>$wffilter:</td>
<td class=finput width=50% >$VS</td>
<td class=fname width=10%>&nbsp;</td>
<td class=finput width=30%>&nbsp;</td>
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


sub isSelectable
{
   my $self=shift;

   return(1);
}

sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();

   $q{exviewcontrol}=Query->Param("EXVIEWCONTROL");
   $q{viewstate}=Query->Param("VIEWSTATE");

   if (!$self->SetFilter(\%q)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"can not SetFilter on DataObj - unknown problem");
      }
      return(undef);
   }


   $self->{DataObj}->setDefaultView(qw(prio mdate state class name editor));
   
   return($self->{DataObj}->Result(ExternalFilter=>1));
}


sub SetFilter
{
   my $self=shift;
   my $flt=shift;

   my $dataobj=$self->getDataObj();
   $dataobj->ResetFilter() if (defined($dataobj));

   if (!exists($flt->{userid})){
      $flt->{userid}=$self->getParent->getCurrentUserId();
   }

   my $dc=$flt->{exviewcontrol};
   delete($flt->{exviewcontrol});
   my $vs=$flt->{viewstate};
   delete($flt->{viewstate});
   my $userid=$flt->{userid};
   delete($flt->{userid});
   
   my %grp;
   if ($dc eq "TEAM"){  
      %grp=$self->getParent->getGroupsOf($userid,"RMember","both");
   }
   else{
      %grp=$self->getParent->getGroupsOf($userid,"RMember","direct");
   }
   my @grpids=keys(%grp);
   @grpids=(qw(NONE)) if ($#grpids==-1);

   $userid=-1 if (!defined($userid) || $userid==0);

   my %q=%{$flt};
   $q{isdeleted}=\'0';
   my $origstatequery=$q{stateid};
   delete($q{stateid});
   my @q=();
   if ($dc eq "ADDDEP" || $dc eq "DEPONLY"){
      my %q1=%q;
      my %q2=%q;
      $q1{fwddebtargetid}=\$userid;
      $q1{fwddebtarget}=\'base::user';
      $q1{stateid}.=" AND " if ($q1{stateid} ne "");
      $q1{stateid}.="<20";
      if ($vs eq "HIDEUNNECESSARY"){
         $q1{stateid}.=" AND " if ($q1{stateid} ne "");
         $q1{stateid}.=" !6 AND !5";  # hide defered pending
      }
      if ($vs eq "ONLYDEFFERED"){
         $q1{stateid}.=" AND " if ($q1{stateid} ne "");
         $q1{stateid}.="5";
      }
      $q2{fwddebtargetid}=\@grpids;
      $q2{fwddebtarget}=\'base::grp';
      $q2{stateid}.=" AND " if ($q2{stateid} ne "");
      $q2{stateid}.="<20";
      if ($vs eq "HIDEUNNECESSARY"){
         $q2{stateid}.=" AND " if ($q2{stateid} ne "");
         $q2{stateid}.=" !6 AND !5";  # hide defered pending
      }
      if ($vs eq "ONLYDEFFERED"){
         $q2{stateid}.=" AND " if ($q2{stateid} ne "");
         $q2{stateid}.="5";
      }
      $dataobj->ResetFilter();
      $dataobj->SetFilter([\%q1,\%q2]);
      $dataobj->SetCurrentOrder(qw(NONE));
      my @ids=$dataobj->getVal("id");
      if ($#ids!=-1){
         push(@q,{id=>\@ids,stateid=>$origstatequery});
      }
      else{
         push(@q,{id=>[-1]});
      }
   }
   if ($dc ne "DEPONLY"){
      my %q1=%q;
      my %q2=%q;
      my %q3=%q;
      $q1{fwdtargetid}=\$userid;
      $q1{fwdtarget}=\'base::user';
      $q1{stateid}.=" AND " if ($q1{stateid} ne "");
      $q1{stateid}.="<20";
      if ($vs eq "HIDEUNNECESSARY"){
         $q1{stateid}.=" AND " if ($q1{stateid} ne "");
         $q1{stateid}.=" !6 AND !5";  # hide defered pending
      }
      if ($vs eq "ONLYDEFFERED"){
         $q1{stateid}.=" AND " if ($q1{stateid} ne "");
         $q1{stateid}.="5";
      }
      if ($dc ne "PERSONAL"){
         $q2{fwdtargetid}=\@grpids;
         $q2{fwdtarget}=\'base::grp';
         $q2{stateid}.=" AND " if ($q2{stateid} ne "");
         $q2{stateid}.="<20";
         if ($vs eq "HIDEUNNECESSARY"){
            $q2{stateid}.=" AND " if ($q2{stateid} ne "");
            $q2{stateid}.=" !6 AND !5";  # hide defered pending
         }
         if ($vs eq "ONLYDEFFERED"){
            $q2{stateid}.=" AND " if ($q2{stateid} ne "");
            $q2{stateid}.="5";
         }
      }
      my %id=();  # this hack prevents searches over two keys (this is bad)
      $dataobj->ResetFilter();
      if ($dc ne "PERSONAL"){
         $dataobj->SetFilter([\%q1,\%q2]);
      }
      else{
         $dataobj->SetFilter([\%q1]);
      }
      my @l=$dataobj->getHashList(qw(id));
      map({$id{$_->{id}}=1} @l);

      $q3{owner}=\$userid;
      $q3{stateid}.=" AND " if ($q3{stateid} ne "");
      if ($vs eq "HIDEUNNECESSARY"){
         $q3{stateid}.="<=4";
      }
      elsif ($vs eq "ONLYDEFFERED"){
         $q3{stateid}.="5";
      }
      else{
         $q3{stateid}.="<=6";
      }

      $dataobj->ResetFilter();
      $dataobj->SetFilter([\%q3]);
      my @l=$dataobj->getHashList(qw(id));
      map({$id{$_->{id}}=1} @l);

  #    my $ws=$self->getParent->getPersistentModuleObject("base::workflow");
  #    $ws->SetFilter([{fwdtargetid=>\$userid,fwdtarget=>\'base::user'},
  #                    {fwdtargetid=>\@grpids,fwdtarget=>\'base::grp'}]); 
  #    map({$id{$_->{wfheadid}}=1;} $ws->getHashList(qw(wfheadid)));

      # workspace must ALWAYS be added
      my $wspace=$self->getParent->getPersistentModuleObject(
                                        "base::workflowws");
      if (defined($wspace)){   # Links of the workspace table add
         $wspace->SetFilter([{fwdtargetid=>\$userid,fwdtarget=>\'base::user'},
                             {fwdtargetid=>\@grpids,fwdtarget=>\'base::grp'}]); 
         map({$id{$_->{wfheadid}}=1;} $wspace->getHashList(qw(wfheadid)));
      }
      if ($dc ne "TEAM"){  # filter out records, witch are forwared to a
                           # group and already in process by one other person
         $dataobj->SetFilter({id=>[keys(%id)]});
         $dataobj->SetCurrentOrder(qw(NONE));
         %id=();
         foreach my $rec ($dataobj->getHashList(qw(stateid  owner
                                                   fwdtarget 
                                                   fwdtargetid id))){
            if ($dc eq "PERSONAL"){
               if (($rec->{stateid}==4 || $rec->{stateid}==1)  && 
                   $rec->{fwdtarget} eq "base::grp" &&
                   $rec->{owner}!=$userid){
                  next;
               }
            }
            if ($vs eq "HIDEUNNECESSARY"){
               if (($rec->{stateid}==2)  && 
                   $rec->{fwdtarget} eq "base::user" &&
                   $rec->{owner}==$userid &&
                   $rec->{fwdtargetid}!=$userid){
                  next;
               }
               if (($rec->{stateid}==2)  && 
                   $rec->{fwdtarget} eq "base::grp" &&
                   $rec->{owner}==$userid &&
                   !($self->getParent->IsMemberOf($rec->{fwdtargetid}))){
                  next;
               }

            }
            $id{$rec->{id}}++;
         }
      }
      else{
         # filter out records, witch are assigned to me personaly
         $dataobj->ResetFilter();
         $dataobj->SetFilter({id=>[keys(%id)]});
         $dataobj->SetCurrentOrder(qw(NONE));
         %id=();
         foreach my $rec ($dataobj->getHashList(qw(stateid 
                                                   fwdtarget 
                                                   fwdtargetid 
                                                   owner
                                                   id))){
            if ($rec->{fwdtarget} eq "base::user" &&
                $rec->{fwdtargetid}==$userid){
               next;
            }
            if ($rec->{owner}==$userid){
               next;
            }
            $id{$rec->{id}}++;
         }
      }
      my %finalq=%q;
      $finalq{id}=[keys(%id)];
      $finalq{stateid}=$origstatequery;
      push(@q,\%finalq);
   }
   $dataobj->ResetFilter();
   $dataobj->SecureSetFilter(\@q);
}





1;
