package itil::MyW5Base::efforts;
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
use kernel::date;
@ISA=qw(kernel::MyW5Base);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub isSelectable
{
   my $self=shift;

#   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
#                          "base::MyW5Base",
#                          func=>'Main',
#                          param=>'MyW5BaseSUBMOD=base::MyW5Base::wfmyjobs');
#   if (defined($acl)){
#      return(1) if (grep(/^read$/,@$acl));
#   }
   return(1);
}



sub Init
{
   my $self=shift;
   $self->{DataObj}=getModuleObject($self->getParent->Config,"itil::appl");
   return(0) if (!defined($self->{DataObj}));
   $self->{DataObj}->AddFields(
      new kernel::Field::Number(
                name          =>'efforts_treal',
                label         =>'Effort real',
                searchable    =>0,
                group         =>'efforts',
                unit          =>'min',
                depend        =>['id'],
                onRawValue    =>sub {
                   my $fieldself=shift;
                   my $current=shift;
                   my $id=$current->{id};

                   return($self->Context->{treal}->{$id});
                }),
   #   new kernel::Field::Number(
   #             name          =>'efforts_tprojection',
   #             label         =>'Effort projection',
   #             searchable    =>0,
   #             depend        =>['id'],
   #             onRawValue    =>sub {
   #                my $fieldself=shift;
   #                my $current=shift;
   #                my $id=$current->{id};
   #
   #                   return($self->{treal}->{$id}+2);
   #                }),

      new kernel::Field::Number(
                name          =>'efforts_employecount',
                label         =>'Effort employecount',
                searchable    =>0,
                group         =>'efforts',
                depend        =>['id'],
                onRawValue    =>sub {
                   my $fieldself=shift;
                   my $current=shift;
                   return($self->{usercount});
                })
   );
   $self->{DataObj}->AddGroup("efforts",translation=>'itil::MyW5Base::efforts');


   return(1);
}


sub addSpecialSearchMask
{
   my $self=shift;
   my $Applicationname=$self->getParent->T("Applicationname");
   my $d=<<EOF;
<tr>
<td class=fname width=10%>$Applicationname:</td>
<td class=finput colspan=3 >\%name(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>\%customer(label)\%:</td>
<td class=finput colspan=3 >\%customer(search)\%</td>
</tr>
EOF
}


sub getQueryTemplate
{
   my $self=shift;

   my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                            ["REmployee","RFreelancer","RBoss",
                                             "RBoss2","RAuditor"],
                                            "down");

   my $orgsel="<select name=search_grpid style=\"width:100%\">";
   my $oldorg=Query->Param("search_grpid");
   foreach my $rec (values(%grp)){
      next if ($rec->{grpid}<=0);
      $orgsel.="<option value=\"$rec->{grpid}\"";
      $orgsel.=" selected" if ($oldorg eq $rec->{grpid});
      $orgsel.=">$rec->{fullname}</option>";
   }
   $orgsel.="<option value=\"0\">only mine</option>";
   $orgsel.="</select>";

   my $msel=$self->getTimeRangeDrop("search_mon",$self->getParent,
                                    "fixmonth","rangeChangedEvent",
                                    "shorthist","lastmonth");
   my $ivday=$self->getParent->T("Invoice Day");
   my $Month=$self->getParent->T("Timerange");
   my $Orgunit=$self->getParent->T("Orgunit");
   my $efftr=$self->getParent->T("effective timerange");
   my $InvoiceInfo=$self->getParent->T("all calculations based on GMT");
   my $invoiceday="<select name=search_invoiceday onchange=\"recalcEffTime()\">";
   my $oldivday=Query->Param("search_invoiceday");
   for(my $c=1;$c<=25;$c++){
      $invoiceday.="<option value=\"$c\"";
      $invoiceday.=" selected" if ($oldivday==$c);
      $invoiceday.=">$c.</option>";
   }
   $invoiceday.="</select>";

   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>$Month:</td>
<td class=finput width=40% >$msel</td>
<td class=fname width=10%>$ivday:</td>
<td class=finput width=40% >$invoiceday ($InvoiceInfo)</td>
</tr>
<tr>
<td class=fname width=10%>$Orgunit:</td>
<td class=finput colspan=3>$orgsel</td>
</tr>
<tr>
<td class=fname width=10%>$efftr:</td>
<td class=finput colspan=3><div id=efftime></div></td>
</tr>
EOF
   $d.=$self->addSpecialSearchMask();
   $d.=<<EOF;
</table>
</div>
%StdButtonBar(bookmark,print,search)%

<script language=JavaScript>

function rangeChangedEvent()
{
   recalcEffTime();
}

function recalcEffTime()
{
   var e=document.getElementById("efftime");
   var m=document.forms[0].elements["search_mon"];
   var d=document.forms[0].elements["search_invoiceday"];
   var Ausdruck = /(\\d.+)\\/(\\d.+)/;
   if (Ausdruck.exec(m.value)){
      var mon=RegExp.\$1;
      var year=RegExp.\$2;
     
      var mon2=parseInt(mon)+1;
      var year2=parseInt(year);
      if (mon2>12){
         mon2=1;
         year2=parseInt(year)+1;
      }
       
      e.innerHTML=d.value+"."+mon+"."+year+" 00:00:00  -  "+
                  d.value+"."+mon2+"."+year2+" 00:00:00";
   }
   else{
      e.innerHTML="???";
   }
}
addEvent(window,"load",recalcEffTime);

</script>
EOF
   return($d);
}

sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();
   delete($q{mon});
   delete($q{grpid});
   delete($q{invoiceday});

   my $invoiceday=Query->Param("search_invoiceday");
   $invoiceday=1 if ($invoiceday eq "");
   my $mon=Query->Param("search_mon");
   my $grpid=Query->Param("search_grpid");
   if ($mon eq "lastmonth" || $mon eq ""){
      my ($year,$month,$day)=Today_and_Now($self->getParent->UserTimezone());
      ($year,$month)=Add_Delta_YM($self->getParent->UserTimezone(),
                                  $year,$month,$day,0,-1);
      $mon="$month/$year";
   }
   my ($mon,$year)=$mon=~m/^(\d+)\/(\d+)$/;
   

   #
   # find user
   #
   my %user=();
   if ($grpid!=0){
      my $grp=getModuleObject($self->getParent->Config,"base::grp");
      $grp->SetFilter({grpid=>\$grpid});
      my @d=$grp->getHashList(qw(users));
      foreach my $rec (@d){
         next if (!defined($rec->{users}) || ref($rec->{users}) ne "ARRAY");
         foreach my $urec (@{$rec->{users}}){
            my @r=$urec->{roles};
            @r=@{$urec->{roles}} if (ref($urec->{roles}) eq "ARRAY");
            if (grep(/^(REmployee|RBoss|RFreelancer)$/,@r)){
           #    printf STDERR ("fifi urec=%s\n",Dumper($urec));
               $user{$urec->{userid}}++;
            }
         }
      }
      $self->{usercount}=keys(%user);
   }
   else{
      my $userid=$self->getParent->getCurrentUserId();
      $user{$userid}=1;
      $self->{usercount}=1;
   }
   msg(INFO,"user=%s\n",Dumper(\%user));
 
   #
   # find users actions
   #
   my ($Y1,$M1,$D1);
   eval('($Y1,$M1,$D1)=Add_Delta_YM("GMT",$year,$mon,$invoiceday,0,1);');
   if ($@ ne ""){
      $self->getParent->LastMsg(ERROR,$@);
      return(undef);
   }
   my %fineQuery;
   $self->{DataObj}->ResetFilter();
   my $result=$self->calculateEfforts($year,$mon,$invoiceday,
                                      $Y1,$M1,$invoiceday,\%user,
                                      $grpid,\%fineQuery);

   #print STDERR Dumper($self->Context->{treal});

   $self->{DataObj}->SecureSetFilter([\%fineQuery]);
   my %param=(ExternalFilter=>1);
   return($self->{DataObj}->Result(%param));
}

sub calculateEfforts
{
   my $self=shift;
   my ($year,$mon,$invoiceday,$Y1,$M1,$invoiceday1,$user,$grpid,$fineQuery)=@_;

   $self->{DataObj}->setDefaultView(qw(linenumber name customer conumber
                                       efforts_treal
                                       efforts_employecount
                                       efforts_tprojection
                                       ));

   my $wfact=getModuleObject($self->getParent->Config,"base::workflowaction");
   $wfact->SetFilter({creatorid=>[keys(%{$user})],
                      cdate=>">$year-$mon-${invoiceday} AND ".
                             "<=$Y1-$M1-${invoiceday1}"
                     }
                    );
   my %wfheadid=();
   foreach my $rec ($wfact->getHashList(qw(wfheadid effort creator))){
      if (defined($rec->{effort}) && $rec->{effort}!=0){
         $wfheadid{$rec->{wfheadid}}+=$rec->{effort};
      }
   }
   return(undef) if ($wfact->LastMsg());
   #print STDERR Dumper(\%wfheadid);

   #
   # find affectedapplicationid
   #
   if (keys(%wfheadid)){
      my $wfkey=getModuleObject($self->getParent->Config,"base::workflowkey");
      $wfkey->SetFilter({wfheadid=>[keys(%wfheadid)],
                         name=>\'affectedapplicationid'});
      foreach my $rec ($wfkey->getHashList(qw(wfheadid value))){
         my $applid=$rec->{value};
         my $wfheadid=$rec->{wfheadid};
         my $effort=$wfheadid{$wfheadid};
         $self->Context->{treal}->{$applid}+=$effort;
      }
      $fineQuery->{id}=[keys(%{$self->Context->{treal}})];
   }
   else{
      $fineQuery->{id}=["NONE"];
   }
   return(1);
}



1;
