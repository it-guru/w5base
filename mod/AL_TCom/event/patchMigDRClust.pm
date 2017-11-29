package AL_TCom::event::patchMigDRClust;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
use kernel::database;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub patchMigDRClust
{
   my $self=shift;
   my $intv=getModuleObject($self->Config,"base::interview");
   my $appl=getModuleObject($self->Config,"itil::appl");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
   $self->{ia}=getModuleObject($self->Config,"base::interanswer");

   $intv->SetFilter({cistatusid=>"<6"});
   $intv->SetCurrentView(qw(id cistatusid qtag));
   $self->{intv}=$intv->getHashIndexed("qtag");

   #
   # System operation
   #
   $appl->SetFilter({cistatusid=>"<6"});
  # $appl->SetFilter({name=>"W5*"});
   $appl->SetCurrentView(qw(name id olastdrtestwf solastdrdate socomments
                            solastclusttestwf solastclustswdate));
   #$sys->SetNamedFilter("X",{name=>'!ab1*'});
  # $appl->Limit(10,0,0);
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process system: $rec->{name}");
         $self->patchRecord("itil::appl",$rec);
         ($rec,$msg)=$appl->getNext();
      } until(!defined($rec));
   }


   return({exitcode=>0});
}

sub patchRecord
{
   my $self=shift;
   my $parent=shift;
   my $rec=shift;

   if ($rec->{olastdrtestwf} ne ""){   # handle last dr Test change number
      $self->{wf}->ResetFilter();
      $self->{wf}->SetFilter({id=>\$rec->{olastdrtestwf}});
      my ($wfrec,$msg)=$self->{wf}->getOnlyFirst(qw(id srcid srcload srcsys 
                                                    eventend));
      if (defined($wfrec) && $wfrec->{srcsys}=~m/change$/){
         my $qtag="SOB_003";
         $self->{ia}->ResetFilter();
         $self->{ia}->SetFilter({qtag=>\$qtag,
                                 parentid=>\$rec->{id},
                                 parentobj=>\'itil::appl'});
         my ($iarec,$msg)=$self->{ia}->getOnlyFirst(qw(ALL));
         if (defined($iarec)){
            if ($iarec->{answer} ne $wfrec->{srcid} ||
                $iarec->{relevant} eq "0"){
               # update old answer rec
               $self->{ia}->ValidatedUpdateRecord(
                  $iarec,
                  {
                      relevant=>1,
                      answer=>$wfrec->{srcid}
                  },{id=>$iarec->{id}});
            }
         }
         else{
            $self->{ia}->ValidatedInsertRecord(
               {
                   parentid=>$rec->{id},
                   parentobj=>'itil::appl',
                   interviewid=>$self->{intv}->{qtag}->{$qtag}->{id},
                   relevant=>1,
                   answer=>$wfrec->{srcid}
               },{id=>$iarec->{id}});
         }
      }
   }
   if ($rec->{socomments} ne ""){
      my $qtag="SOB_004";
      $self->{ia}->ResetFilter();
      $self->{ia}->SetFilter({qtag=>\$qtag,
                              parentid=>\$rec->{id},
                              parentobj=>\'itil::appl'});
      my ($iarec,$msg)=$self->{ia}->getOnlyFirst(qw(ALL));
      if (defined($iarec)){
         if ($iarec->{comments} ne $rec->{socomments} ||
             $iarec->{relevant} eq "0"){
            # update old answer rec
            $self->{ia}->ValidatedUpdateRecord(
               $iarec,
               {
                   relevant=>1,
                   comments=>$rec->{socomments}
               },{id=>$iarec->{id}});
         }
      }
      else{
         $self->{ia}->ValidatedInsertRecord(
            {
                parentid=>$rec->{id},
                parentobj=>'itil::appl',
                interviewid=>$self->{intv}->{qtag}->{$qtag}->{id},
                relevant=>1,
                comments=>$rec->{socomments}
            },{id=>$iarec->{id}});
      }

   }

 


   if ($rec->{solastclusttestwf} ne ""){   # handle last Cluster Switch test
      $self->{wf}->ResetFilter();
      $self->{wf}->SetFilter({id=>\$rec->{solastclusttestwf}});
      my ($wfrec,$msg)=$self->{wf}->getOnlyFirst(qw(id srcid srcload srcsys 
                                                    eventend));
      if (defined($wfrec) && $wfrec->{srcsys}=~m/change$/){
         my $qtag="SOB_009";
         $self->{ia}->ResetFilter();
         $self->{ia}->SetFilter({qtag=>\$qtag,
                                 parentid=>\$rec->{id},
                                 parentobj=>\'itil::appl'});
         my ($iarec,$msg)=$self->{ia}->getOnlyFirst(qw(ALL));
         if (defined($iarec)){
            if ($iarec->{answer} ne $wfrec->{srcid} ||
                $iarec->{relevant} eq "0"){
               print STDERR Dumper($iarec);
               # update old answer rec
               $self->{ia}->ValidatedUpdateRecord(
                  $iarec,
                  {
                      relevant=>1,
                      answer=>$wfrec->{srcid}
                  },{id=>$iarec->{id}});
            }
         }
         else{
            $self->{ia}->ValidatedInsertRecord(
               {
                   parentid=>$rec->{id},
                   parentobj=>'itil::appl',
                   interviewid=>$self->{intv}->{qtag}->{$qtag}->{id},
                   relevant=>1,
                   answer=>$wfrec->{srcid}
               },{id=>$iarec->{id}});
         }
      }
   }



   return(undef);
}

1;
