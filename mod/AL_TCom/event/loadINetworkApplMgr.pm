package AL_TCom::event::loadINetworkApplMgr;
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

sub loadINetworkApplMgr
{
   my $self=shift;
   my $wiw=getModuleObject($self->Config,"tswiw::user");
   my $o=getModuleObject($self->Config,"TS::appl");
   my $oop=$o->Clone();
   my $i=getModuleObject($self->Config,"inetwork::aeg");
   my $user=getModuleObject($self->Config,"base::user");
   my @elog;

   $o->SetFilter({cistatusid=>\'4'});
   $o->SetCurrentView(qw(name id applmgr applmgrid ictono databossid));
   my ($rec,$msg)=$o->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{id}: $rec->{name}");
         $i->ResetFilter();
         $i->SetFilter({w5baseid=>\$rec->{id}});
         my ($irec)=$i->getOnlyFirst(qw(ictoid w5baseid smemail));
         if ($irec->{ictoid} ne "" &&
             $irec->{ictoid} ne $rec->{ictono}){
            push(@elog,msg(ERROR,"Bei '$rec->{name}' -->".
                            " IN:$irec->{ictoid} ne W5B:$rec->{ictono}"));
         }
         if ($irec->{smemail} ne "" &&
             $rec->{applmgr} eq ""){
            my $w5bid=$wiw->GetW5BaseUserID($irec->{smemail});
            if ($w5bid ne ""){
               my $m="Sehr geehrter Datenverantwortlicher,\n\n".
                     "über den Datenbestand aus I-Network wurde bei\nder ".
                     "Anwendung '<b>$rec->{name}</b>' in einer einmaligen ".
                     "Lade-Aktion der Application-Manager '$irec->{smemail}' ".
                     "nach W5Base/Darwin übertragen.\n\n".
                     "Dies war ein einmaliger Initial-Load. ".
                     "Ab sofort sind Sie als Datenverantwortlich dafür ".
                     "zuständig, sicherzustellen das bei den von Ihnen ".
                     "verantworteten Anwendung immer der korrekte ".
                     "Application-Manager erfasst ist (wie dies auch ".
                     "für alle anderen anwendungsbezogenen Daten gilt).\n\n".
                     "Bei Rückfragen dazu wenden Sie sich bitte an ".
                     "das Config-Management (Hr. Merx bzw. Fr. Gräb) oder ".
                     "den W5Base/Darwin 1st Level Support (+49 951 1336 4312)".
                     "\n\nDieser Datenload wurde durch das Config-Management ".
                     "über den Request ...\n".
                     "https://darwin.telekom.de/".
                     "darwin/auth/base/workflow/ById/13655012180002\n".
                     "... beauftragt.";
               $user->ResetFilter();
               $user->SetFilter({userid=>\$rec->{databossid}});
               my ($urec)=$user->getOnlyFirst(qw(email));
               if (defined($urec)){
                  $user->ResetFilter();
                  $user->SetFilter({userid=>\$w5bid});
                  my ($w5brec)=$user->getOnlyFirst(qw(fullname));

                  if ($oop->ValidatedUpdateRecord($rec,
                                                 {applmgr=>$w5brec->{fullname}},
                                                 {id=>\$rec->{id}})){
                     my $wa=getModuleObject($self->Config,
                            "base::workflowaction");
                     $wa->Notify("INFO",
                                 "W5Base/Darwin Datenimport aus I-Network ".
                                 "für $rec->{name}",
                                 $m,adminbcc=>1,
                                   emailfrom=>'W5SUPPORT',
                                   emailcc=>[qw(11634955470001 12762475160001)],
                                   emailto=>$urec->{email});
                  }
               }
            }
         }
         ($rec,$msg)=$o->getNext();
      } until(!defined($rec));
   }
   if ($#elog!=-1){
      my $wa=getModuleObject($self->Config,"base::workflowaction");
      $wa->Notify("INFO",
                  "W5Base/Darwin Datenimport aus I-Network ".
                  "ICTO-ID Probleme",
                  "Hallo Kollegen,\n\n".
                  "beim Load der Application-Manager nach Darwin ".
                  "hab ich in diesem Zuge auch gleich die ICTOIDs ".
                  "mit verglichen. Dabei sind mir folgende Probleme ".
                  "aufgefallen:\n\n".join("",@elog)
                    ,adminbcc=>1,
                     emailcc=>[qw(12762475160001)],
                     emailto=>[qw(13401048580000 11634955470001)]);
   }
   return({exitcode=>0});
}

1;
