package itil::MyW5Base::riskreport;
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
use kernel::Field;
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
   $self->{DataObj}=getModuleObject($self->getParent->Config,"base::workflow");
   $self->{appl}=getModuleObject($self->getParent->Config,"itil::appl");

   $self->{Field}->{from}=new kernel::Field::Date(
                Parent        =>$self,
                name          =>'from',
                label         =>'From');
   $self->{Field}->{from}->setParent($self);

   $self->{Field}->{to}=new kernel::Field::Date(
                Parent        =>$self, 
                name          =>'to',
                label         =>'To');
   $self->{Field}->{to}->setParent($self);

   $self->{Val}->{wfclass}=[qw(riskmgmt opmeasure both)]; 

   $self->{Val}->{refto}=[qw(eventend eventstart createdate mdate closedate)];

   return(0) if (!defined($self->{DataObj}));
   return($self->SUPER::Init(@_));
}

sub doAutoSearch
{
   my $self=shift;

   return(0);
}


sub isSelectable
{
   my $self=shift;
   my %param=@_;

   #my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
   #                                     'itil::MyW5Base::riskreport$');
   #if (defined($acl)){
   #   return(0) if (!grep(/^read$/,@$acl));
   #}
   #else{
   #   return(0);
   #}

   my $u=$param{user};
   if (ref($u->{groups}) eq "ARRAY"){  
      foreach my $grprec (@{$u->{groups}}){ 
         if (ref($grprec->{roles}) eq "ARRAY"){
            return(1) if (in_array($grprec->{roles}, 
                          [qw(
                              RSKManager 
                              RSKCoord 
                              RSKPManager RSKPManager2
                              RPRManager RPRManager2 RPROperator
                              )],
                          @{$grprec->{roles}}));
         }
      }
   }
   my $dataobj=$self->getDataObj();
#   return(1) if ($dataobj->IsMemberOf("admin"));
   return(0);
}



sub getQueryTemplate
{
   my $self=shift;
   my $dataobj=$self->getDataObj();

   #######################################################################
   my @wfclass=@{$self->{Val}->{wfclass}};

   my $reptyp="<select name=search_wfclass style=\"width:100%\">";
   my $oldval=Query->Param("search_wfclass");
   foreach my $wfclass (@wfclass){
      $reptyp.="<option value=\"$wfclass\"";
      $reptyp.=" selected" if ($wfclass eq $oldval);
      $reptyp.=">".$self->T($wfclass)."</option>";
   }
   $reptyp.="</select>";
   my $reptypl=$self->T("workflow class");


   if (!defined(Query->Param("search_state"))){
      Query->Param("search_state"=>"1 2 4 17");
   }


   #######################################################################
   my @refto=@{$self->{Val}->{refto}};

   my $refsel="<select name=search_refto style=\"width:100%\">";
   my $oldval=Query->Param("search_refto");
   foreach my $refto (@refto){
      $refsel.="<option value=\"$refto\"";
      $refsel.=" selected" if ($refto eq $oldval);
      $refsel.=">".$self->T($refto)."</option>";
   }
   $refsel.="</select>";
   my $refsell=$self->T("reference to");
   #######################################################################

   my $m1=$self->getParent->T("enclose all not finshed eventnotifications");
   my $showallsel;
   $showallsel="checked" if (Query->Param("SHOWALL"));

   
   my $froml=$self->{Field}->{from}->Label;
   my $froms=$self->{Field}->{from}->FormatedSearch();

   my $tol=$self->{Field}->{to}->Label;
   my $tos=$self->{Field}->{to}->FormatedSearch();


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>$reptypl</td>
<td class=finput width=40%>$reptyp</td>
<td class=fname width=10%>$refsell:</td>
<td class=finput width=40%>$refsel</td>
</tr>
<tr>
<td class=fname width=10%>$froml:</td>
<td class=finput width=40%>$froms</td>
<td class=fname width=10%>$tol:</td>
<td class=finput width=40%>$tos</td>
</tr>
<tr>
<td class=fname width=10%>\%mandator(label)\%:</td>
<td class=finput width=40%>\%mandator(search)\%</td>
<td class=fname width=10%>\%affectedapplication(label)\%:</td>
<td class=finput width=40%>\%affectedapplication(search)\%</td>
</tr>
<tr>
</tr>
<tr>
<td class=fname width=10%>\%state(label)\%:</td>
<td class=finput width=40%>\%state(search)\%</td>
<td class=fname width=10%>\%prio(label)\%:</td>
<td class=finput width=40%>\%prio(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40%>\%name(search)\%</td>
<td class=fname width=10%>\%detaildescription(label)\%:</td>
<td class=finput width=40%>\%detaildescription(search)\%</td>
</tr>
</table>
</div>
%StdButtonBar(bookmark,search)%
EOF
   return($d);
}


#sub SetFilter
#{
#   my $self=shift;
#   my $dataobj=$self->getDataObj();
#
#
#
#}

sub SetFilter
{
   my $self=shift;
   my $flt=shift;

   #######################################################################
   #
   # verify allowed data for current MyW5Base module
   #
   if ($flt->{from} ne "" && $flt->{to} ne ""){
      $flt->{duration}=CalcDateDuration($flt->{from},$flt->{to},"GMT");
      if ($flt->{duration}->{totalseconds}<0){
         $self->LastMsg(ERROR,"from is later then to");
         return(undef);
      }
      if ($flt->{duration}->{totalseconds}>31622400){
         $self->LastMsg(ERROR,"range is larger then the allowed limit of 366d");
         return(undef);
      }
   }
   if (defined($flt->{affectedapplication}) &&
       $flt->{affectedapplication} eq "*"){
      $self->LastMsg(ERROR,"invalid application filter");
      return(undef);
   }
   if (defined($flt->{mandator}) &&
       $flt->{mandator} eq "*"){
      $self->LastMsg(ERROR,"invalid mandator filter");
      return(undef);
   }
   if (defined($flt->{srcid}) &&
       $flt->{srcid}=~m/^\*/){
      $self->LastMsg(ERROR,"invalid srcid filter");
      return(undef);
   }
   if (!grep(/^$flt->{refto}$/,@{$self->{Val}->{refto}}) ||
       !grep(/^$flt->{wfclass}$/,@{$self->{Val}->{wfclass}})){
      $self->LastMsg(ERROR,"invalid request for this module");
      return(undef);
   }
   #######################################################################
   # make filter related to dataobj
   #




   #######################################################################
   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
             [qw(RSKManager RSKCoord
                 RPRManager RPRManager2 RPROperator
                 RSKPManager RSKPManager2)], "down");
   my @grpids=keys(%grp);
   @grpids=(qw(-1)) if ($#grpids==-1);
   $flt->{mandatorid}=\@grpids;
   #######################################################################

   

   if ($flt->{from} ne "" && $flt->{to} ne ""){
      $flt->{$flt->{refto}}=">\"$flt->{from} GMT\" AND <\"$flt->{to} GMT\"";
   }
   if ($flt->{from} eq "" && $flt->{to} ne ""){
      $flt->{$flt->{refto}}="<\"$flt->{to} GMT\"";
   }
   if ($flt->{from} ne "" && $flt->{to} eq ""){
      $flt->{$flt->{refto}}=">\"$flt->{from} GMT\"";
   }
   delete ($flt->{refto});
   
   delete ($flt->{duration});
   delete ($flt->{to});
   delete ($flt->{from});


   my $dataobj=$self->getDataObj();
   if ($flt->{wfclass} eq "riskmgmt"){
      $flt->{class}=[grep(/^.*::riskmgmt$/,
                          keys(%{$dataobj->{SubDataObj}}))];
   }
   elsif ($flt->{wfclass} eq "opmeasure"){
      delete($flt->{wfclass});
      $flt->{class}=[grep(/^.*::riskmgmt$/,
                          keys(%{$dataobj->{SubDataObj}}))];
      my %subflt=%{$flt};
      delete($subflt{state});
      delete($subflt{wfclass});
      my $o=$dataobj->Clone();
      $o->SetFilter(\%subflt);
      my @l=$o->getHashList(qw(id relations));
      my %wfheadid=();
      foreach my $wfrec (@l){
         foreach my $relrec (@{$wfrec->{relations}}){
            if ($relrec->{name} eq "riskmesure"){
               $wfheadid{$relrec->{dstwfid}}++;
            }
         }
      }
      my @wfheadid=keys(%wfheadid);
      push(@wfheadid,"-99") if ($#wfheadid==-1);
      $flt->{id}=\@wfheadid;
      $flt->{class}=[grep(/^.*::opmeasure$/,
                          keys(%{$dataobj->{SubDataObj}}))];
   }
   elsif ($flt->{wfclass} eq "both"){
      $flt->{class}=[grep(/^.*::riskmgmt$/,
                          keys(%{$dataobj->{SubDataObj}}))];
      my %subflt=%{$flt};
      delete($subflt{state});
      delete($subflt{wfclass});
      my $o=$dataobj->Clone();
      $o->SetFilter(\%subflt);
      my @l=$o->getHashList(qw(id relations));
      my %wfheadid=();
      foreach my $wfrec (@l){
         $wfheadid{$wfrec->{id}}++;
         foreach my $relrec (@{$wfrec->{relations}}){
            if ($relrec->{name} eq "riskmesure"){
               $wfheadid{$relrec->{dstwfid}}++;
            }
         }
      }
      my @wfheadid=keys(%wfheadid);
      push(@wfheadid,"-99") if ($#wfheadid==-1);
      $flt->{id}=\@wfheadid;
      $flt->{class}=[grep(/^.*::(opmeasure|riskmgmt)$/,
                          keys(%{$dataobj->{SubDataObj}}))];
   }
   else{
      $flt->{class}="undefined";
   }
   delete($flt->{wfclass});


   $flt->{isdeleted}=\'0';


   #msg(INFO,"MyW5Base Dataobj Filter=%s",Dumper($flt));
   $dataobj->ResetFilter();
   $dataobj->SetFilter($flt);
   #######################################################################


   return(1);
}




sub Result
{
   my $self=shift;
   my %q=$self->getDataObj()->getSearchHash();

   $self->getDataObj()->setDefaultView(qw(eventstart 
            state name 
            affectedapplication 
            nature 
            wffields.riskmgmtestimation
            wffields.riskmgmtcondition
            wffields.solutionopt
            wffields.riskbasetype
            wffields.riskmgmtcalclog
            wffields.riskmgmtpoints));

   return(undef) if (!(my $f=$self->{Field}->{from}->Unformat($q{from})));
   $q{from}=$f->{from};

   return(undef) if (!(my $f=$self->{Field}->{to}->Unformat($q{to})));
   $q{to}=$f->{to};

   #msg(INFO,"MyW5Base Filter=%s",Dumper(\%q));
   if (!$self->SetFilter(\%q)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"can not SetFilter on DataObj - unknown problem");
      }
      return(undef);
   }

#printf STDERR ("fifi parent of DataObj=%s\n",$self->getDataObj()->getParent());
#printf STDERR ("fifi parent of meine=%s\n",$self->getParent());
#printf STDERR ("fifi search=%s\n",Dumper(\%q));
   
   my %param=(ExternalFilter=>1,
              Limit=>50);
   return($self->{DataObj}->Result(%param));
}



1;
