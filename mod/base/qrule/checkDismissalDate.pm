package base::qrule::checkDismissalDate;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

checks a posible dismissal date and send notifications

=head3 IMPORTS

NONE

=head3 HINTS

Check of dismissal date and send notifications to the
last known bosses.

[de:]

Prüft das geplante Aussacheidungsdatum und sendet
Benachrichtigung an die letzten bekannten Vorgesetzten.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
   return(["base::user"]);
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

   return(undef) if ($rec->{cistatusid}!=4);

   return(undef) if ($rec->{planneddismissaldate} eq "");


   #printf STDERR ("fifi: planneddismissaldate=%s\n",
   #               $rec->{planneddismissaldate});
   #printf STDERR ("fifi: notifieddismissaldate=%s\n",
   #               $rec->{notifieddismissaldate});

   if ($rec->{notifieddismissaldate} eq ""){
      my $off=CalcDateDuration(NowStamp("en"),$rec->{planneddismissaldate});
      #print STDERR Dumper($off);
      if ($off->{totaldays}>7 && $off->{totaldays}<(7*12)){ # zwischen 1-12W
         #printf STDERR ("check if notification is needed\n");
         my $lastknownbossid=$rec->{lastknownbossid};
         my @lastknownbossid=split(/[,\s]+/,$lastknownbossid);
         my $lastknownpbossid=$rec->{lastknownpbossid};
         my @lastknownpbossid=split(/[,\s]+/,$lastknownpbossid);
         my %boss;
         foreach my $userid (@lastknownbossid,@lastknownpbossid){
            $boss{$userid}++;
         }
         my @boss=sort(grep(!/^\s*$/,keys(%boss)));
         #printf STDERR ("check boss=@boss\n");

         my @o=$dataobj->getCheckObjects();
         @o=grep({($_->{ctrlrec}->{idfield} eq "databossid" &&
                   $_->{ctrlrec}->{replaceoptype} eq "base::user");} @o);
         my $foundRefs=0;
         #printf STDERR ("check objs=%s\n",Dumper(\@o));
         my $id=$rec->{userid};
         foreach my $chk (@o){
            my $obj=getModuleObject($dataobj->Config,$chk->{dataobj});
            my %flt;
            if (exists($chk->{ctrlrec}->{baseflt}) &&
                ref($chk->{ctrlrec}->{baseflt}) eq "HASH"){
               %flt=%{$chk->{ctrlrec}->{baseflt}};
            }
          
            $flt{$chk->{ctrlrec}->{idfield}}=\$id;
            if (defined($obj->getField("cistatusid"))){
               if (!exists($flt{cistatusid})){
                  $flt{cistatusid}="<6";
               }
            }
            $obj->SetFilter(\%flt);
            my $idfield=$obj->IdField();
            $obj->SetCurrentView($idfield->Name());
            my $n=$obj->SoftCountRecords();
            $foundRefs+=$n;
            #printf STDERR ("fifi %s = n=%s\n",$chk->{dataobj},$n); 
         }
         if ($foundRefs==0){
            #nothing found - and no notification needed
            $forcedupd->{notifieddismissaldate}=NowStamp("en");
         }
         else{
            # f.e. 14436098220000
            #printf STDERR ("NNEEEDD NOTIFY: $id = $foundRefs\n");
            if ($#boss!=-1){ 
               my $wfa=getModuleObject($dataobj->Config,"base::workflowaction");
               my %talklang;
               my $resbuf;
               my $user=getModuleObject($dataobj->Config,"base::user");
               $user->SetFilter({userid=>\@boss,cistatusid=>\'4'});
               foreach my $urec ($user->getHashList(qw(fullname talklang 
                                                       email))){
                  $resbuf->{$urec->{userid}}->{fullname}=$urec->{fullname};
                  $resbuf->{$urec->{userid}}->{talklang}=$urec->{talklang};
                  $resbuf->{$urec->{userid}}->{email}=$urec->{email};
                  $talklang{$urec->{talklang}}++;
               }
               my $lastlang;
               if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
                  $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
               }
               foreach my $lang (keys(%talklang)){
                  $ENV{HTTP_FORCE_LANGUAGE}=$lang;
                  my @cleanemailto;
                  my @cleanemailcc=($rec->{email});
                  foreach my $bossrec (values(%{$resbuf})){
                     if ($bossrec->{talklang} eq $lang){
                        push(@cleanemailto,$bossrec->{email});
                     }
                  }
                  my %notifyparam;
                  $notifyparam{emailto}=\@cleanemailto;
                  $notifyparam{emailcc}=\@cleanemailcc;
                  $notifyparam{emailbcc}=[11634953080001];
                  $notifyparam{emailcategory}=['DataRespClarification'];
        
                  #printf STDERR ("sending Notification in $lang\n");
                  #printf STDERR ("sending To:@cleanemailto\n");
                  #printf STDERR ("sending Cc:@cleanemailcc\n");
                  my $subject=$dataobj->T(
                     "Request for clarification of data responsibility").": ".
                     $rec->{fullname};
                  my $tmpl="tmpl/bossnotify.checkDismissalDate";
                  my $ddate=$rec->{planneddismissaldate};
                  $ddate=~s/\s.*$//;
                  my $txt=$dataobj->getParsedTemplate($tmpl,{
                     static=>{
                        USERNAME=>$rec->{fullname},
                        DISMISSALDATE=>$ddate
        
                     }
                  });
                  $wfa->Notify("WARN",$subject,$txt,%notifyparam);
               }
               if (defined($lastlang)){
                  $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
               }
               else{
                  delete($ENV{HTTP_FORCE_LANGUAGE});
               }
               $forcedupd->{notifieddismissaldate}=NowStamp("en");
               $checksession->{EssentialsChangedCnt}=0;
            }
         }
      }
      elsif ($off->{totaldays}<28){ # Notication Window is ended
         $forcedupd->{notifieddismissaldate}=NowStamp("en");
         $checksession->{EssentialsChangedCnt}=0;
      }
   }



   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}



1;
