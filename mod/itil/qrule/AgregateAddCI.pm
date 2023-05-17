package itil::qrule::AgregateAddCI;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Agregate Addtional CIs from associated CIs to Application CI

=head3 IMPORTS

NONE

=head3 HINTS

Aggregate additional CIs from associated CIs to Application CI

[de:]

Aggregieren der zusätzlich verwendeten CIs aus dem zugehörigen 
CIs ins Anwendungs CI.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
use itil::lib::Listedit;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};


   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   my @ipl;

   my $applid=$rec->{id};

   my %soll;


   my $acis=getModuleObject($dataobj->Config,"itil::lnkadditionalci");
   my $aurl=getModuleObject($dataobj->Config,"itil::lnkapplurl");

   $aurl->SetFilter({applid=>\$applid});
   foreach my $aurl ($aurl->getHashList(qw(name addcis))){
      #print STDERR ("aurl=".Dumper($aurl));
      if (exists($aurl->{addcis}) && ref($aurl->{addcis}) eq "ARRAY"){
         foreach my $acirec (@{$aurl->{addcis}}){
            my $k=$acirec->{name}.".".$acirec->{ciusage};
            $soll{$k}={
               name=>$acirec->{name},
               ciusage=>$acirec->{ciusage}
            };
         }
      }
   }
   my @sid;
   foreach my $sysrec (@{$rec->{systems}}){
      if ($sysrec->{systemid} ne ""){
         push(@sid,$sysrec->{systemid});
      }
   }
   if ($#sid!=-1){
      $acis->ResetFilter();
      $acis->SetFilter({systemid=>\@sid});
      my @sysacis=$acis->getHashList(qw(ALL));
      foreach my $r (@sysacis){
         my $k=$r->{name}.".".$r->{ciusage};
         $soll{$k}={
            name=>$r->{name},
            ciusage=>$r->{ciusage}
         };
      }
   }


   #
   # Hier müssen irgendwann mal die addcis aller an der Anwendung "hängenden"
   # logischen Systeme hinzugeladen werden.
   #

   $acis->ResetFilter();
   $acis->SetFilter({applid=>\$rec->{id}});
   my @acis=$acis->getHashList(qw(ALL));

   #print STDERR ("soll=".Dumper(\%soll));
   #print STDERR ("acis=".Dumper(\@acis));

   my $srcsys=$self->Self();
   my @opList;
   my $res=OpAnalyse(
      sub{  # comperator 
         my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
         my $eq;
         if (!($b->{mapped}) &&
             $a->{name} eq $b->{name} &&
             $a->{ciusage} eq $b->{ciusage}){
            $eq=1;
            if ($b->{srcsys} ne $srcsys){
               $eq=0;
            }
            $b->{mapped}=1;
         }
         return($eq);
      },
      sub{  # oprec generator
         my ($mode,$oldrec,$newrec,%p)=@_;
         if ($mode eq "insert" || $mode eq "update"){
            my $oprec={
               OP=>$mode,
               MSG=>"$mode  $newrec->{name} ".
                    "in W5Base",
               DATAOBJ=>'itil::lnkadditionalci',
               DATA=>{
                  name   =>$newrec->{name},
                  ciusage=>$newrec->{ciusage},
                  srcid     =>undef,
                  applid    =>$rec->{id}
               }
            };
            if ($mode eq "update"){
               $oprec->{IDENTIFYBY}=$oldrec->{id};
            }
            if ($mode eq "insert"){
               $checksession->{EssentialsChangedCnt}++;
               $oprec->{DATA}->{srcsys}=$srcsys;
               push(@{$desc->{qmsg}},"add: ".$oprec->{DATA}->{name});
            }
            return($oprec);
         }
         elsif ($mode eq "delete"){
            my $id=$oldrec->{id};
            return() if ($id eq "");
            push(@{$desc->{qmsg}},"remove: ".$oldrec->{name});
            $checksession->{EssentialsChangedCnt}++;
            return({OP=>$mode,
                    MSG=>"delete ip $oldrec->{name} ".
                         "from W5Base",
                    DATAOBJ=>'itil::lnkadditionalci',
                    IDENTIFYBY=>$oldrec->{id},
                    });
         }
         return(undef);
      },
      \@acis,[values(%soll)],\@opList,
      refid=>$rec->{id}
   );
   if (!$res){
      my $opres=ProcessOpList($self->getParent,\@opList);
   }

   return($exitcode,$desc);
}




1;
