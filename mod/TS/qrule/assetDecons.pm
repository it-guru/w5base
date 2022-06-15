package TS::qrule::assetDecons;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Monitor Hardware deconstruction.


=head3 HINTS

[en:]

For assets it is mandatory that at least 3 months before 
end of the hardware support, a planned deconstruction date 
(in W5Base/Darwin) is/will be documented. 
This is necessary because there are agreements at our concern,
there has to be a deconstruction planning for such assets.

[de:]

Bei Assets ist es zwingend, dass spätestens 3 Monate vor
Ende des Hardware-Supports, ein geplanter Rückbauzeitpunkt (in W5Base/Darwin)
erfasst ist/wird. Dies ist notwendig da es Vereinbarungen im Konzern gibt, dass 
für derartige Assets eine Rückbauplanung geben muß.


=cut

#######################################################################
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
   return(["itil::asset"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   return(0,undef) if ($rec->{cistatusid}!=4);

   ################################################################
   # handling for plandecons, notifyplandecons1, notifyplandecons2
   #$rec->{eohs}="2022-01-31 22:00:00";
   if ($rec->{eohs} ne ""){
      my $deohs=CalcDateDuration(NowStamp("en"),$rec->{eohs});
      msg(INFO,"delta days eohs: ".$deohs->{totaldays});
      if ($deohs->{totaldays}<0){
         my $plandeconsok=0;
         if ($rec->{plandecons} ne ""){
            my $dplandecons=CalcDateDuration(NowStamp("en"),$rec->{plandecons});
            if ($dplandecons->{totaldays}<0){
               my $msg="overwriten planned deconstruction date";
               push(@qmsg,$msg);
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
            else{
               if (!isDetailed(undef,$rec,"eohscomments",20,5)){
                  my $msg="justification for overwriten planned ".
                          "deconstruction date not detailed enough";
                  push(@qmsg,$msg);
                  push(@dataissue,$msg);
                  $errorlevel=3 if ($errorlevel<3);
               }
               else{
                  $plandeconsok++;
               }
            }
         }
         if (!$plandeconsok){
            my $msg="overwriten end of hardware support ".
                    "without valid deconstruction planning";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
      if ($rec->{plandecons} eq ""){
         if ($deohs->{totaldays}<90){
            my $msg="missing planned deconstruction date";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
         else{
            if ($deohs->{totaldays}<180 && 
                $rec->{notifyplandecons2} eq ""){
               $self->doDeConNotify($dataobj,$rec,$deohs,
                                    "notifyplandecons2");
            }
            elsif ($deohs->{totaldays}<365 && 
                   $deohs->{totaldays}>250 &&
                $rec->{notifyplandecons1} eq ""){
               $self->doDeConNotify($dataobj,$rec,$deohs,
                                    "notifyplandecons1");
            }
         }
      }
   }
   ################################################################

   if (keys(%$forcedupd)){
      #printf STDERR ("fifi request a forceupd=%s\n",Dumper($forcedupd));
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         my @fld=grep(!/^srcload$/,keys(%$forcedupd));
         if ($#fld!=-1){
            push(@qmsg,"all desired fields has been updated: ".join(", ",@fld));
         }
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
   if (keys(%$wfrequest)){
      my $msg="different values stored in Extern: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}


sub doDeConNotify
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $deohs=shift;
   my $mode=shift;

   my $op=$dataobj->Clone();

   msg(INFO,"doDeConNotify $mode :".$rec->{name});

   my %notifyparam=(emailbcc=>['11634953080001']);
   my %notifycontrol=();

   if ($mode eq "notifyplandecons2"){
      $notifycontrol{mode}="WARN";
   }

   $op->NotifyWriteAuthorizedContacts($rec,undef,
                                      \%notifyparam,\%notifycontrol,sub{
      my ($subject,$ntext);
      my $subject=$dataobj->T("hint for deconstruction planning")." : ".
                                 $rec->{name};
      if ($mode eq "notifyplandecons2"){
         $subject=$dataobj->T("request for deconstruction date")." : ".
                                 $rec->{name};
      }
      my $tmpl=$dataobj->getParsedTemplate("tmpl/deconsNotify_".$mode,{
         skinbase=>'tsacinv',
         static=>{
            URL=>$rec->{urlofcurrentrec},
            ASSETNAME=>$rec->{name}
         }
      });
      return($subject,$tmpl);
   });
   $op->ValidatedUpdateRecord($rec,{
      $mode=>NowStamp("en"),
      mdate=>$rec->{mdate},
   },{id=>\$rec->{id}});
            
   #printf STDERR ("fifi: deohs=%s\n",Dumper($deohs));
   #printf STDERR ("fifi: ishousing: %s\n",$parrec->{ishousing});
   #printf STDERR ("fifi: eohs: %s\n",$rec->{eohs});
   #printf STDERR ("fifi: plandecons: %s\n",$rec->{plandecons});
   #printf STDERR ("fifi: notifyplandecons1: %s\n",$rec->{notifyplandecons1});
   #printf STDERR ("fifi: notifyplandecons2: %s\n",$rec->{notifyplandecons2});
}


1;
