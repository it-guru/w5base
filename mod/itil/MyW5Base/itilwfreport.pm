package itil::MyW5Base::itilwfreport;
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

   $self->{Val}->{wfclass}=["",qw(problem change incident 
                                  opmeasure)];

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
 
   my $u=$param{user};
   if (ref($u->{groups}) eq "ARRAY"){  
      foreach my $grprec (@{$u->{groups}}){ 
         if (ref($grprec->{roles}) eq "ARRAY"){
            return(1) if (in_array($grprec->{roles}, 
                          [qw(
                              RINManager 
                              RINManager2 
                              RINOperator
                              RCHManager 
                              RCHManager2 
                              RCHOperator
                              RPRManager 
                              RPRManager2 
                              RPROperator
                              RAuditor 
                              RMonitor)],
                          @{$grprec->{roles}}));
         }
      }
   }
   my $dataobj=$self->getDataObj();
   return(1) if ($dataobj->IsMemberOf("admin"));
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
<td class=fname width=10%>$reptypl:</td>
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
<td class=fname width=10%>\%affectedapplication(label)\%:</td>
<td class=finput width=40%>\%affectedapplication(search)\%</td>
<td class=fname width=10%>\%involvedbusinessteam(label)\%:</td>
<td class=finput width=40%>\%involvedbusinessteam(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>\%mandator(label)\%:</td>
<td class=finput width=40%>\%mandator(search)\%</td>
<td class=fname width=10%>\%involvedcustomer(label)\%:</td>
<td class=finput width=40%>\%involvedcustomer(search)\%</td>
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
<td class=fname width=10%>\%srcid(label)\%:</td>
<td class=finput width=40%>\%srcid(search)\%</td>
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
   $flt->{duration}=CalcDateDuration($flt->{from},$flt->{to},"GMT");
   if ($flt->{duration}->{totalseconds}<0){
      $self->LastMsg(ERROR,"from is later then to");
      return(undef);
   }
   if ($flt->{duration}->{totalseconds}>31622400){
      $self->LastMsg(ERROR,"range is larger then the allowed limit of 366d");
      return(undef);
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
   if ($flt->{wfclass} eq "" || $flt->{to} eq "" || $flt->{from} eq ""){
      $self->LastMsg(ERROR,"missing query param to prozess this request");
      return(undef);
   }
   #######################################################################
   #
   # make filter related to dataobj
   #
   my $dataobj=$self->getDataObj();
   $flt->{class}=[grep(/^.*::$flt->{wfclass}$/,
                       keys(%{$dataobj->{SubDataObj}}))];
   delete($flt->{wfclass});

   $flt->{$flt->{refto}}=">\"$flt->{from} GMT\" AND <\"$flt->{to} GMT\"";
   delete ($flt->{refto});
   
   delete ($flt->{duration});
   delete ($flt->{to});
   delete ($flt->{from});

   msg(INFO,"MyW5Base Dataobj Filter=%s",Dumper($flt));
   $dataobj->ResetFilter();
   $dataobj->SetFilter($flt);
   #######################################################################


   return(1);
}




sub Result
{
   my $self=shift;
   my %q=$self->getDataObj()->getSearchHash();

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
