package AL_TCom::MyW5Base::myP800rawdata;
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
use kernel::MyW5Base;
use AL_TCom::lib::tool;
@ISA=qw(kernel::MyW5Base AL_TCom::lib::tool);

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
   return(0) if (!defined($self->{DataObj}));


   $self->DataObj->AddFields(

      new kernel::Field::DynWebIcon(
                name          =>'p800chk',
                searchable    =>0,
                htmlwidth     =>'5px',
                htmldetail    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;
                   my $fobjrelevant=$app->getField("wffields.tcomcodrelevant",
                                                   $current);
                   my $tcomcodrelevant="yes";
                   if (defined($fobjrelevant)){
                      $tcomcodrelevant=$fobjrelevant->RawValue($current);
                   }
                   my $ok=0;
                   if ($tcomcodrelevant eq "no"){
                      $ok=1;
                   }
                   else{
                      my $fobjcause=$app->getField("wffields.tcomcodcause",
                                                   $current);
                      my $fobjtime=$app->getField("wffields.tcomworktime",
                                                   $current);
                      my $fobjcomm=$app->getField("wffields.tcomcodcomments",
                                                   $current);
                      if (defined($fobjcause) && 
                          defined($fobjtime) &&
                          defined($fobjcomm)){
                         $ok=1;
                         my $tcomcodcause=$fobjcause->RawValue($current);
                         my $tcomcodcomments=$fobjcomm->RawValue($current);
                         my $tcomworktime=$fobjtime->RawValue($current);
                        
                         $ok=0 if ($tcomcodcause eq "" || 
                                   $tcomcodcause eq "undef");
                         if ($tcomworktime>1200 && 
                             length($tcomcodcomments)<20){
                            $ok=0;
                         }
                      }
                   }
                   if ($ok){
                      return("ok");
                   }
                   else{
                      return("fail");
                   }
                   return("?");
                },
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $d=$self->RawValue($current);
                   my $app=$self->getParent;
                           
                   my $img="<img ";
                   if ($d=~m/ok/){
                      $img.="src=\"../../base/load/ok.gif\" ";
                   }
                   else{
                      $img.="src=\"../../base/load/fail.gif\" ";
                   }
                   $img.="title=\"\" border=0>";
                   if ($mode=~m/html/i){
                      return("$img");
                   }

                   return($d);
                })
   );

   return(1);
}

sub isSelectable
{
   my $self=shift;

   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                                        'base::MyW5Base::myP800$');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}

sub getTimeRanges
{
   my $self=shift;
   my ($year,$month,$day, $hour,$min,$sec) = Today_and_Now("GMT");

   my @l;
   my $first;
   for(my $d=0;$d<=60;$d++){
      my ($y,$m,$d)=
          Add_Delta_YMD("GMT",$year,$month,$day,0,0,$d*-1);
      if ($d==20){
         my ($y1,$m1,$d1)=Add_Delta_YMD("GMT",$y,$m,$d,0,1,0);
         my @e=(sprintf("\">%02d.%02d.%04d 00:00:00\" AND ".
                         "\"<%02d.%02d.%04d 00:00:00\"",$d,$m,$y,$d1,$m1,$y1),
                 sprintf("%02d.%02d.%04d - ".
                         "%02d.%02d.%04d S",$d,$m,$y,$d1-1,$m1,$y1));
         if (!defined($first)){
            $first=$e[0];
         }
         push(@l,@e);
      }
      if ($d==1){
         my ($y1,$m1,$d1)=Add_Delta_YMD("GMT",$y,$m,$d,0,1,0);
         my ($y2,$m2,$d2)=Add_Delta_YMD("GMT",$y,$m,$d,0,1,-1);
         push(@l,sprintf("\">%02d.%02d.%04d 00:00:00\" AND ".
                         "\"<%02d.%02d.%04d 00:00:00\"",$d,$m,$y,$d1,$m1,$y1),
                 sprintf("%02d.%02d.%04d - ".
                         "%02d.%02d.%04d",$d,$m,$y,$d2,$m2,$y2));
      }
   }  
   return($first,\@l);
}




sub getQueryTemplate
{
   my $self=shift;
   my $timelabel=$self->getParent->T("P800 reporting month");;
   my ($first,$tl)=$self->getTimeRanges();
   my ($timedrop)=$self->{DataObj}->getHtmlSelect("P800_TimeRange",$tl,
                                                  selected=>$first);

   my $l1=$self->getParent->T("show all data");;

   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=40% >\%name(search)\%</td>
<td class=fname width=10%>\%affectedcontract(label)\%:</td>
<td class=finput width=40%>\%affectedcontract(search)\%</td>
<td colspan=2></td>
</tr><tr>
<td class=fname>$timelabel:</td>
<td class=finput>$timedrop</td>
<td class=fname>\%affectedapplication(label)\%:</td>
<td class=finput>\%affectedapplication(search)\%</td>
</tr><tr>
<td class=fname colspan=4>$l1:<input type=checkbox name=SHOWALL></td>
</tr>
</table>
</div>
%StdButtonBar(teamusercontrol,teamviewcontrol,bookmark,deputycontrol,print,search)%
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my %q=$self->DataObj->getSearchHash();

   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);
   my $showall=Query->Param("SHOWALL");
   my $dc=Query->Param("EXVIEWCONTROL");
   my @q=();
   my %mainq1=%q;

   my @appl=("none");
   if ($dc eq "ADDDEP"){
      @appl=$self->getRequestedApplicationIds($userid,user=>1,dep=>1);
   }
   elsif ($dc eq "DEPONLY"){
      @appl=$self->getRequestedApplicationIds($userid,dep=>1);
   }
   elsif ($dc eq "TEAM"){
      @appl=$self->getRequestedApplicationIds($userid,team=>1);
   }
   elsif ((my ($uid)=$dc=~m/^COLLEGE:(\d+)$/)){
      @appl=$self->getRequestedApplicationIds($userid,college=>$uid);
   }
   else{
      @appl=$self->getRequestedApplicationIds($userid,user=>1);
   }
   $mainq1{affectedapplicationid}=\@appl;
   my $p800m=Query->Param("P800_TimeRange");
   $p800m="now" if (!defined($p800m) || $p800m eq ""); 
   $mainq1{eventend}="$p800m";

   my @valids=grep(/^.*::(diary|change|incident|businesreq)$/,
                    keys(%{$self->{DataObj}->{SubDataObj}}));
   if ($mainq1{class} ne ""){
      my $q=quotemeta($mainq1{class});
      if (!grep(/^$q$/i,@valids)){
         delete($mainq1{class});
      }
   }
   if ($mainq1{class} eq ""){
      $mainq1{class}=\@valids;
   }
   $self->DataObj->{'SoftFilter'}=sub{
       my $self=shift;
       my $rec=shift;
       return(1) if ($showall);
       my $fobj=$self->getField("p800chk",$rec);
       if (defined($fobj)){
          my $d=$fobj->RawValue($rec);
          return(0) if ($d eq "ok");
       }
       return(1);
   };


   $self->DataObj->ResetFilter();
   $self->DataObj->SecureSetFilter([\%mainq1]);
   $self->DataObj->setDefaultView(qw(linenumber p800chk dataissuestate
                     name srcid wffields.tcomcodcause 
                     wffields.tcomworktime wffields.tcomcodcomments));
   my %param=(ExternalFilter=>1);
   return($self->DataObj->Result(%param));
}



1;
