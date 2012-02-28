package itil::event::invalidateDataboss;
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

sub Init
{
   my $self=shift;


   $self->RegisterEvent("invalidateDataboss","invalidateDataboss");
   return(1);
}

sub invalidateDataboss
{
   my $self=shift;
   my $contact=shift;
   my $reqdataobj=shift;
   my @dataobj=split(/[;,\s]/,$reqdataobj);

   my %notify;

   foreach my $dataobj (@dataobj){
      if ($dataobj ne "itil::system" &&
          $dataobj ne "itil::asset"){
         return({exitcode=>1,msg=>'invalid object specified'});
      }
   }
   foreach my $dataobj (@dataobj){
      my $obj=getModuleObject($self->Config,$dataobj);
      $obj->SetFilter({databoss=>\$contact,cistatusid=>"<6"});
      $obj->SetCurrentView(qw(name id contacts applications));
      #$sys->SetNamedFilter("X",{name=>'!ab1*'});
      #$obj->Limit(5,0,0);
      my ($rec,$msg)=$obj->getFirst();
      if (defined($rec)){
         do{
            msg(INFO,"process object ".$obj->Self." : $rec->{name}");
            my @appl=$self->addAdditionalWrites($obj,$rec);
            foreach my $a (@appl){
               if (!defined($notify{$a})){
                  $notify{$a}={};
               }
               if (!defined($notify{$a}->{$dataobj})){
                  $notify{$a}->{$dataobj}=[];
               }
               push(@{$notify{$a}->{$dataobj}},$rec);
            }
            ($rec,$msg)=$obj->getNext();
         } until(!defined($rec));
      }
   }
   $self->doNotify($contact,\%notify);

   return({exitcode=>0});
}


sub doNotify
{
   my $self=shift;
   my $contact=shift;
   my $notify=shift;
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $wfa=getModuleObject($self->Config,"base::workflowaction");

   my $user=getModuleObject($self->Config,"base::user");

   $user->SetFilter({fullname=>\$contact});
   my ($urec,$msg)=$user->getOnlyFirst(qw(userid));
   my $EventJobBaseUrl=$self->Config->Param("EventJobBaseUrl");

   foreach my $applid (keys(%$notify)){
      $appl->SetFilter({id=>\$applid,cistatusid=>'<6'});
      my ($applrec,$msg)=$appl->getOnlyFirst(qw(name mandatorid 
                                                databossid tsmid tsm2id));

      my $msg=
      "Sehr geehrter Datenverantwortlicher,\n".
      "\n".
      "in Ihrer Anwendung '$applrec->{name}' exitieren Config-Items, bei ".
      "denen als Datenverantwortlicher '$contact' eingetragen ist. Dieser ".
      "Kontakt darf die Funktion des Datenverantwortlichen <b>nicht</b> ".
      "mehr ausfüllen! Das \"normale\" Verfahren zur Übergabe der ".
      "Datenverantwortung konnte in diesem Fall nicht angewandt werden, ".
      "da eine automatisierte Ermittlung der neuen Datenverantworlichen ".
      "nicht möglich war.\n".
      "Sie als Datenverantwortlicher der Anwendung '$applrec->{name}' ".
      "müssen nun sicherstellen das ein neuer Datenverantwortlicher für ".
      "die betreffenden Config-Items ".
      "gefunden wird. In der Regel sollte der TSM oder der OPM der ".
      "Anwendung '$applrec->{name}' die Datenverantwortung für die ".
      "unten aufgeführten Items übernehmen.\n".
      "<b>Sollte binnen 4 Wochen kein neuer Datenverantwortlicher eingetragen ".
      "sein, so werden die W5Base-Admins die Config-Items als ".
      "\"veraltet/gelöscht\" markieren!</b> Daraus würde resultieren, dass ".
      "für eine vollständige Dokumentation Ihrer Anwendung, u.U. Systeme ".
      "und Assets neu erfasst werden müßten.\n";
      if (exists($notify->{$applid}->{'itil::system'})){
         $msg.="\n<b>Betroffene Systeme:</b>\n".
               join("\n",
               map({$_->{name}." ".
                    $EventJobBaseUrl."/auth/itil/system/ById/".$_->{id}
                   } @{$notify->{$applid}->{'itil::system'}}));
      }
      if (exists($notify->{$applid}->{'itil::asset'})){
         $msg.="\n<b>Betroffene Assets:</b>\n".
               join("\n",
               map({$_->{name}." ".
                    $EventJobBaseUrl."/auth/itil/asset/ById/".$_->{id}
                   } @{$notify->{$applid}->{'itil::asset'}}));
      }
      $msg.="\n\nDie betreffenden TSMs und OPMs wurden bereits bei ".
            "den aufgeführten Config-Items als Kontakt mit der Rolle ".
            "\"schreiben\" eingetragen. Es ist also nur noch notwendig, ".
            "das sich einer der beiden als Datenverantwortlicher einträgt.\n".
            "\nsiehe dazu auch (Änderung eines Datenverantwortlichen):\n".
            "$EventJobBaseUrl/auth/faq/article/ById/12229485550002\n".
            "\nDiese Maßnahme ist mit dem Config-Manager abgestimmt. ".
            "Sollten Sie noch offene Fragen haben, so wenden Sie sich bitte ".
            "an den Config-Manager.";
      my @cc;
      push(@cc,$applrec->{tsmid});
      push(@cc,$applrec->{opmid});
      push(@cc,$applrec->{tsm2id});
      push(@cc,$applrec->{opm2id});
      if ($applrec->{mandatorid} ne ""){
         my @l=$appl->getMembersOf($applrec->{mandatorid},
                                   ["RCFManager","RCFManager2"],"up");
         push(@cc,@l);
      }
      {
         my @l=$appl->getMembersOf("1","RMember","direct");
         push(@cc,@l);
      }
      if (defined($urec)){
         push(@cc,$urec->{userid});
      }


      $wfa->Notify("",
                   $applrec->{name}.
                   " - Übernahme der Datenverantwortung notwendig!",$msg,
                   emailfrom=>"\"Config-Management\" <no_reply\@w5base.net>",
                   emailto=>$applrec->{databossid},
                   emailcc=>\@cc);
   }
}

sub addAdditionalWrites
{
   my $self=shift;
   my $parent=shift;
   my $rec=shift;
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $lnk=getModuleObject($self->Config,"base::lnkcontact");
   my $tsmcount=0;
   my @applid=();

   my $refid=$rec->{id};
   my $parentobj=$parent;

   my @writers=qw(tsmid tsm2id opmid opm2id databossid);

   foreach my $arec (@{$rec->{applications}}){
      $appl->ResetFilter();
      $appl->SetFilter({id=>\$arec->{applid},cistatusid=>'<6'});
      foreach my $arec ($appl->getHashList(qw(id name),@writers)){
         push(@applid,$arec->{id});
         foreach my $contact (@writers){
            my $target="base::user";
            my $targetid=$arec->{$contact};
            if ($targetid ne ""){
               $tsmcount++ if ($contact ne "databossid");
               $lnk->ValidatedInsertOrUpdateRecord({
                     refid=>$refid,
                     parentobj=>$parentobj->SelfAsParentObject(),
                     target=>'base::user',
                     targetid=>$targetid,
                     roles=>['write'],
                     comments=>'write right by invalidateDataboss'},
                     {
                     refid=>$refid,
                     parentobj=>$parentobj->SelfAsParentObject(),
                     target=>'base::user',
                     targetid=>$targetid,
               });
            }
         }
      
      }
   }
   return(@applid);
}

1;
