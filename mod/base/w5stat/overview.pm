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

   foreach my $p (sort({$P->{$a}->{prio} <=> $P->{$b}->{prio}} keys(%{$P}))){
      my $prec=$P->{$p};
      if (defined($prec) && defined($prec->{overview})){
         if (my @ov=&{$prec->{overview}}($prec->{obj},$primrec,$hist)){
            push(@{$ovdata},@ov);
         }
      }
   }
}

sub displayOverview
{
   my $self=shift;
   my ($primrec,$hist)=@_;
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
   $self->processOverviewRecords(\@ovdata,$P,$primrec,$hist);
   if (defined($primrec->{nameid}) && $primrec->{nameid} ne "" 
       && $primrec->{sgroup} eq "Group"){
      my $month=$primrec->{dstrange};
      my $grp=getModuleObject($app->Config,"base::grp");
      $grp->SetFilter({parentid=>\$primrec->{nameid}});
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
      my $text=$rec->[0];
      if ($#{$rec}!=0){
         my $color="black";
         if (!defined($rec->[1])){
            $text="<u>".$text."</u>";
            if ($subloopcnt>1){
               $text="<br>".$text;
            }
         }
         else{
            $text="&nbsp;".$text;
         }
         if (defined($rec->[2])){
            $color=$rec->[2];
         }
         $d.="\n<tr height=1%>";
         $d.="<td><div class=\"$class\">".$text."</div></td>";
         $d.="<td align=right width=50><font color=\"$color\"><b>".
             $rec->[1]."</b></font></td>";
         $d.="<td align=right width=50>".$rec->[3]."</td>";
         $d.="</tr>";
      }
      else{
         $subloopcnt=0;
         if ($class eq "unitdata"){
            $d.="\n<tr height=1%><td colspan=3>&nbsp;</td></tr>";
            $class="subunitdata";
         }
         $d.="\n<tr height=1%>";
         $d.="<td colspan=3><div class=subunit>".$app->T("Subunit").": ".
              $text."</div></td>";
         $d.="</tr>";
      }
   }
   $d.="\n<tr><td colspan=3></td></tr>";
   $d.="</table>";
   $d.="</div>\n";
   return($d,\@ovdata);
}


1;
