package base::qrule::checkInfoAboRef;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This qulaity rule checks the CI-Status of the groups, references in
businessteam, serviceteam and customer. It is technical not posible,
to realize realtions to config-items per foreign keys - so the only
posible solution is to check in cycle if the target exists still.

=cut

#######################################################################
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
   return(["base::infoabo"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $wfrequest={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   if ($rec->{active}==1){
      my $exp=$rec->{expiration};
      if ($exp ne ""){  # check if expiration is arrived. If it is, set
                        # infoabo as active=0
         my $d=CalcDateDuration(NowStamp("en"),$exp,"GMT");
         if ($d->{totalminutes}<0){
            my $o=$dataobj->Clone();
            $o->ValidatedUpdateRecord($rec,{active=>0},{id=>\$rec->{id}});
            push(@qmsg,"set infoabo inactive due expiration");
         }
      }
   } 
   my $valid=0;
   if ($rec->{parentobj} eq "base::staticinfoabo"){
      # static InfoAbos haben keine gültige Datensatz Referenz - man könnte
      # höchstens noch überprüfen, ob der InfoAboMode noch perl T eine
      # Übersetzung liefert - das sollte aber noch Zeit haben.
      my $o=getModuleObject($self->getParent->Config,"base::user");
      if (defined($o) && $rec->{userid} ne ""){
         $o->SetFilter({userid=>\$rec->{userid},cistatusid=>"!6"});
         my ($rec,$msg)=$o->getOnlyFirst("userid");
         if (defined($rec)){
            $valid=1;
         }
      }
   }elsif ($rec->{parentobj} ne ""){
      my $o=getModuleObject($self->getParent->Config,$rec->{parentobj});
      if (defined($o)){
         my $idfield=$o->IdField();
         if (defined($idfield) && $rec->{refid} ne ""){
            my $flt={$idfield->Name()=>\$rec->{refid}};
            if ($o->getField("cistatusid")){
               $flt->{cistatusid}="!6";
            }
            $o->SetFilter($flt);
            my ($datarec,$msg)=$o->getOnlyFirst($idfield->Name());
            if (defined($datarec)){
               # now check the User
               my $o=getModuleObject($self->getParent->Config,"base::user");
               if (defined($o) && $rec->{userid} ne ""){
                  $o->SetFilter({userid=>\$rec->{userid},cistatusid=>"!6"});
                  my ($rec,$msg)=$o->getOnlyFirst("userid");
                  if (defined($rec)){
                     $valid=1;
                  }
               }
            }
         }
      }
   }
   if (!$valid && $rec->{invalidsince} eq ""){
      my $o=$dataobj->Clone();
      $o->ValidatedUpdateRecord($rec,{invalidsince=>NowStamp("en")},
                                {id=>\$rec->{id}});
      push(@qmsg,"note target of invalid is invalid");
      #printf STDERR ("DEBUG from QRule: ungültiges Ziel in ".
      #               "InfoAbo $rec->{id}\n");
   }
   my $invalidsince=$rec->{invalidsince};
   if ($valid && $invalidsince ne ""){
      my $o=$dataobj->Clone();
      $o->ValidatedUpdateRecord($rec,{invalidsince=>undef},
                                {id=>\$rec->{id}});
      push(@qmsg,"remove invalid note of target");
      $invalidsince=undef;
   }

   if ($invalidsince ne ""){
      my $d=CalcDateDuration(NowStamp("en"),$invalidsince,"GMT");
      #if ($d->{totalminutes}<-30320){
      #   printf STDERR ("DEBUG from QRule: demnaechst Delete of ".
      #                  "InfoAbo $rec->{id}\n");
      #}
      if ($d->{totalminutes}<-40320){
         my $o=$dataobj->Clone();
         $o->ValidatedDeleteRecord($rec,{id=>\$rec->{id}});
         push(@qmsg,"remove infoabo due long invalidity");
      #   printf STDERR ("DEBUG from QRule: Delete of ".
      #                  "InfoAbo $rec->{id}\n");
      }

   }

   return(0,{qmsg=>\@qmsg});
}



1;
