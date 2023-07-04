package base::w5stat::overview;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub getPresenter
{
   my $self=shift;

   my @l=(
          'overview'=>{
                         opcode=>\&displayOverview,
                         prio=>1,
                      },
         );

}


sub processOverviewRecords
{
   my $self=shift;
   my $ovdata=shift;
   my $P=shift;
   my $primrec=shift;
   my $hist=shift;
   my $p=shift;

   foreach my $p (sort({$P->{$a}->{prio} <=> $P->{$b}->{prio}} keys(%{$P}))){
      my $prec=$P->{$p};
      if (defined($prec) && defined($prec->{overview})){
         if (my @ov=&{$prec->{overview}}($prec->{obj},$primrec,$hist,$p)){
            push(@{$ovdata},@ov);
         }
      }
   }
}

sub displayOverview
{
   my $self=shift;
   my ($primrec,$hist,$p)=@_;
   my $app=$self->getParent();
   my $d="";

   my @ovdata;


   my @Presenter;
   foreach my $obj (values(%{$app->{w5stat}})){
      if ($obj->can("getPresenter")){
         my %P=$obj->getPresenter();
         foreach my $p (values(%P)){
            $p->{module}=$obj->Self();
            $p->{obj}=$obj;
         }
         push(@Presenter,%P);
      }
   }
   my $P={@Presenter};
   $self->processOverviewRecords(\@ovdata,$P,$primrec,$hist,$p);
   my $grp=getModuleObject($app->Config,"base::grp");
   if (defined($primrec->{nameid}) && $primrec->{nameid} ne "" 
       && $primrec->{sgroup} eq "Group"){
      my $month=$primrec->{dstrange};

      $grp->SetFilter([
         {
            parentid=>\$primrec->{nameid},is_orggrp=>\'1'
         },
         {
            parentid=>\$primrec->{nameid},is_projectgrp=>\'1'
         },
      ]);
      my @l=$grp->getHashList(qw(fullname grpid));
      if ($#l!=-1){
         foreach my $grprec (@l){
            my ($primrec,$hist)=$app->LoadStatSet(grpid=>$grprec->{grpid},
                                                   $month);

            if (defined($primrec)){
               push(@ovdata,[$primrec->{fullname}]);
               $self->processOverviewRecords(\@ovdata,$P,$primrec,$hist);

            }
         }
      }
   }
   $d.="\n<div class=overview>";
   $d.="<table border=0 width=\"98%\" height=\"70%\">";
   my $class="unitdata";
   my $subloopcnt=0;
   foreach my $rec (@ovdata){
      $subloopcnt++;
      my $ctrlrec={};
      if (ref($rec->[0]) eq "HASH"){
         $ctrlrec=shift(@$rec);
      }
      my $text=$rec->[0];

      my $extfullname;
      my $extdesc;
      my $fullname;
      my $desc;
      if ($primrec->{sgroup} eq "Group"){
         $grp->ResetFilter();
         $grp->SetFilter({fullname=>\$text,cistatusid=>"<6"});
         my ($grprec,$msg)=$grp->getOnlyFirst(qw(description));
         $fullname=$text;
         $extfullname=$text;
         if (defined($grprec)){
            $extdesc=$grprec->{description};
            if (($extdesc=~m/http[s]{0,1}:/i)){
               $extdesc=undef;
            }
         }
         $desc=$extdesc;
         if ((length($extfullname)+
              length($extdesc))>65){
            if (length($extfullname)>35){
               $extfullname=TextShorter($extfullname,35,"DOTHIER");
            }
            if ((length($extfullname)+
                 length($extdesc))>55){
               $extdesc=TextShorter($extdesc,32,"INDICATED");
            }
         }
         if ($extdesc ne ""){
            $extdesc="($extdesc)";
         }
      }


      if ($#{$rec}!=0){
         my $color="black";
         if (!defined($rec->[1])){
            $text="<div style=\"margin-top:4px\"><u>".$text."</u></div>";
            if ($subloopcnt>1){
               #$text="<div style='width:1px;height:2px'></div>".$text;
            }
         }
         else{
            $text="&nbsp;".$text;
         }
         if (defined($rec->[2])){
            $color=$rec->[2];
         }
         my $preVal="";
         my $pstVal="";

         if ($ENV{HTTP_USER_AGENT} ne "" &&   # only in Web-Context
             $rec->[1] ne "" && $ctrlrec->{detail} ne ""){
            $preVal=
               "<span style=\"cursor:pointer\" ".
               "onclick=\"if (parent.setTag){".
               "parent.setTag(".$ctrlrec->{id}.",'".$ctrlrec->{detail}."');".
               "}\" >";
            $pstVal="</span>";
         }
         $d.="\n<tr height=1%>";
         $d.="<td><div class=\"$class\">".$text."</div>";
         if ($desc ne ""){
            $d.="<div class=unitdesc>".$desc."</div>";
         }
         $d.="</td>";
         $d.="<td align=right width=50><font color=\"$color\"><b>".
             $preVal.$rec->[1].$pstVal."</b></font></td>";

         $d.="<td align=right width=50>".$preVal.$rec->[3].$pstVal."</td>";
         $d.="</tr>";
      }
      else{
         $subloopcnt=0;
         if ($class eq "unitdata"){
            $d.="\n<tr style='height:5px'><td colspan=3></td></tr>";
            $class="subunitdata";
         }
         $d.="\n<tr height=1%>";
  
         $d.="<td colspan=3><div class=subunit>".$app->T("Subunit").": ".
              $fullname."</div>\n";
         if ($desc ne ""){
            $d.="<div class=unitdesc>".$desc."</div>";
         }
         $d.="</td>";
         $d.="</tr>";
      }
   }
   $d.="\n<tr><td colspan=3></td></tr>";
   $d.="</table>";
   $d.="</div>\n";
   return($d,\@ovdata);
}


1;
