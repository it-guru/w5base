package base::MyW5Base::myeffortsraw;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
   $self->{DataObj}=getModuleObject($self->getParent->Config,
                                    "base::workflowaction");
   return(0) if (!defined($self->{DataObj}));
   $self->{DataObj}->setDefaultView(qw(bookingdate creatorposix effortrelation 
                                       effortcomments effort));

   $self->{DataObj}->AddFields(

     new kernel::Field::Text(
                name          =>'effortrelation',      # label for effort lists
                depend        =>['comments','wfheadid'],
                htmldetail    =>0,
                searchable    =>0,
                translation   =>'base::MyW5Base::myeffortsraw',
                label         =>'effort relation',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;

                   my $wf=getModuleObject($self->getParent->Config,
                                          "base::workflow");
                   $wf->SetFilter({id=>\$current->{wfheadid}});
                   my ($wfrec,$msg)=$wf->getOnlyFirst(qw(ALL));
                   my $personaltag;

                   if ($wfrec->{class} eq "base::workflow::adminrequest"){
                      $personaltag="AdminRequest";
                   }
                   elsif (exists($wfrec->{affectedapplicationid}) && 
                       $wfrec->{affectedapplicationid} ne ""){
                      my $app=getModuleObject($self->getParent->Config,
                                              "itil::appl");
                      $app->SetFilter({id=>$wfrec->{affectedapplicationid}});
                      my ($arec,$msg)=$app->getOnlyFirst(qw(id conumber));
                      if (defined($arec)){
                         $personaltag="CostNode:".$arec->{conumber};
                      }
                   }
                   elsif (exists($wfrec->{involvedcostcenter}) && 
                       $wfrec->{involvedcostcenter} ne ""){
                      $personaltag="CostNode:".$wfrec->{involvedcostcenter};
                   }
                 #  elsif (exists($wfrec->{affectedproject}) && 
                 #      $wfrec->{affectedproject} ne ""){
                 #     $personaltag=$wfrec->{affectedproject};
                 #  }
                   if (!defined($personaltag) &&
                       exists($wfrec->{affectedapplication}) && 
                       $wfrec->{affectedapplication} ne ""){
                      $personaltag="APPL:".$wfrec->{affectedapplication};
                   }
                   if (exists($wfrec->{affectedproject})){
                      my $p=$wfrec->{affectedproject};
                      if (ref($p) eq "ARRAY"){
                         $p=join(",",@{$p});
                      }
                      if ($p ne ""){
                         $personaltag.='@'.$p;
                      }
                   }


                   return($personaltag);
                })

   );

   return(1);
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

   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>$Month:</td>
<td class=finput width=40% >$msel</td>
</tr>
EOF
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

   my $mon=Query->Param("search_mon");
   if ($mon eq "lastmonth" || $mon eq ""){
      my ($year,$month,$day)=Today_and_Now($self->getParent->UserTimezone());
      ($year,$month)=Add_Delta_YM($self->getParent->UserTimezone(),
                                  $year,$month,$day,0,-1);
      $mon="$month/$year";
   }
   my ($mon,$year)=$mon=~m/^(\d+)\/(\d+)$/;
   
   my $userid=$self->getParent->getCurrentUserId();

   my ($Y1,$M1,$D1);
   eval('($Y1,$M1,$D1)=Add_Delta_YM("GMT",$year,$mon,1,0,1);');
   if ($@ ne ""){
      $self->getParent->LastMsg(ERROR,$@);
      return(undef);
   }
   my %fineQuery;
   %fineQuery=%q;

   $fineQuery{creatorid}=\$userid;
   $fineQuery{effort}=">0";
   $fineQuery{bookingdate}=">$year-$mon-01 AND <=$Y1-$M1-01";

   printf STDERR ("fineQuery=%s\n",Dumper(\%fineQuery));




   $self->{DataObj}->ResetFilter();
#   my $result=$self->calculateEfforts($year,$mon,$invoiceday,
#                                      $Y1,$M1,$invoiceday,\%user,
#                                      $grpid,\%fineQuery);
#
   #print STDERR Dumper($self->Context->{treal});

   $self->{DataObj}->SecureSetFilter([\%fineQuery]);
   my %param=(ExternalFilter=>1);
   return($self->{DataObj}->Result(%param));
}




1;
