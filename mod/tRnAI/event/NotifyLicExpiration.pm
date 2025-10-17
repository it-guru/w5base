package tRnAI::event::NotifyLicExpiration;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
@ISA=qw(kernel::Event);



# Modul to detect expiered SSL Certs based on Qualys scan data
sub NotifyLicExpiration
{
   my $self=shift;
   my $queryparam=shift;


   my $firstDayRange=14;
   my $maxDeltaDayRange="15";

   my $StreamDataobj="tRnAI::license";
   my $jobid;
   my $exitmsg="done";

   my $datastream=getModuleObject($self->Config,$StreamDataobj);
   my $wfa=getModuleObject($self->Config,"base::workflowaction");
   my $user=getModuleObject($self->Config,"base::user");
   my $grp=getModuleObject($self->Config,"base::grp");


   $grp->SetFilter({fullname=>\"w5base.RnAI.inventory",cistatusid=>'4'});

   my @g=$grp->getHashList(qw(grpid name));

    
   return({exitcode=>0,exitmsg=>'ok - no group'}) if ($#g!=0);


   my @nuser=$datastream->getMembersOf($g[0]->{grpid},
      "RMember",
      "direct"
   );
   return({exitcode=>0,exitmsg=>'ok - no user'}) if ($#nuser==-1);

   $datastream->SetFilter({
      expdate=>"<now+28d",
      expnotify1=>"[EMPTY]"
   });

   foreach my $rec ($datastream->getHashList(qw(ALL))){
      $self->analyseRecord($datastream,$wfa,$user,\@nuser,$rec);
   }
   return({exitcode=>0,exitmsg=>'ok'});
}


sub analyseRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $wfa=shift;
   my $user=shift;
   my $nuser=shift;
   my $rec=shift;

#   my $d=CalcDateDuration(NowStamp("en"),$validtill);

#   if (!defined($d)){
#      msg(ERROR,"can no handle sslparsedvalidtill '$validtill'");
#      return();
#   }

   msg(INFO,"PROCESS: $rec->{id} exp:$rec->{expdate}");

   if ($self->doNotify($dataobj,$wfa,$user,$nuser,$rec)){
      my $op=$dataobj->Clone();
      if ($op->ValidatedUpdateRecord($rec,{
            mdate=>$rec->{mdate},
            owner=>$rec->{owner},
            editor=>$rec->{editor},
            expnotify1=>NowStamp("en") 
          },{id=>$rec->{id}})){
         return(1);
      }
   }
   return(0);
}


sub doNotify
{
   my $self=shift;
   my $datastream=shift;
   my $wfa=shift;
   my $user=shift;
   my $nuser=shift;
   my $rec=shift;
   my $debug="";

   my @targetuids=@$nuser;

   my %nrec;

   $user->ResetFilter(); 
   $user->SetFilter({userid=>\@targetuids});
   foreach my $urec ($user->getHashList(qw(fullname userid lastlang lang))){
      my $lang=$urec->{lastlang};
      $lang=$urec->{lang} if ($lang eq "");
      $lang="en" if ($lang eq "");
      $nrec{$lang}->{$urec->{userid}}++;
   }
   my $lastlang;
   if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
      $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
   }
   foreach my $lang (keys(%nrec)){
      $ENV{HTTP_FORCE_LANGUAGE}=$lang;
      my @emailto=keys(%{$nrec{$lang}});
      my $subject=$datastream->T(
         "License expiration detected",
         'tRnAI::event::NotifyLicExpiration').": ".$rec->{name};

      my $tmpl=$datastream->getParsedTemplate("tmpl/LicExpiration_MailNotify",{
         static=>{
            LICURL=>$rec->{urlofcurrentrec},
            DEBUG=>$debug
         }
      });
      $wfa->Notify( "WARN",$subject,$tmpl, 
         emailto=>\@emailto, 
#         emailbcc=>[
#            11634953080001,   # HV
#         ],
         emailcategory =>['RnAI',
                          'tRnAI::event::NotifyLicExpiration',
                          'LicExpiration']
      );
   }
   if ($lastlang ne ""){
      $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
   }
   else{
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
   return(1);
}


1;
