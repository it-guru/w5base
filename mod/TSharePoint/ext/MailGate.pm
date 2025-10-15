package TSharePoint::ext::MailGate;
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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

use File::Temp qw(tempfile);
use Fcntl qw(SEEK_SET);

@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub Process
{
   my $self=shift;
   my $app=shift;
   my $ms=shift;
   my $parsedMail=shift;

   my $mailHead=$parsedMail->head();
   my $name=$mailHead->get("Subject");
   my $from=$mailHead->get("From");
   my $to=$mailHead->get("To");

   $to=~s/[\n\r]/ /g;

print STDERR "to0:".$to;

   my @to=split(/\s*[;,]\s*/,$to);

   @to=map { s/^.*<(.+)>\s*$/$1/gsr } @to;
   @to=map { s/\s+//gsr } @to;
   @to=map { s/\@.*$//gsr } @to;


   my $fromemail=lc($from);
   $fromemail=~s/^.*<(\S+)>$/$1/s;
   $fromemail=~s/\s*//gs;

   my $toemail=$to;
   $toemail=~s/^.*<(\S+)>$/$1/s;
   $toemail=~s/\s*//gs;
   my $touser=$toemail;
   $touser=~s/\@.*$//;


   my $mailtext;
   my $email;
   my $mailbody=$app->FindFirstMimePartWithType($parsedMail,"text/plain");
   if (in_array(\@to,"SharePointHubMaster") ){
      my $exitcode=0;
      my $recordcount="?";
      msg(INFO,$self->Self().": Mailprocessing start");
      my $joblog=getModuleObject($app->Config(),"base::joblog");
      my %jobrec=(name=>"MailProc::SharePointHubMaster",
                  event=>"base::W5Server::MailProc ".$self->Self(),
                  pid=>$$);
      my $jobid;
      if ($joblog->Ping()){
         $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
      }
      my $mailbody=$app->FindAttachmentByName($parsedMail,
                                              "HubMasterlist.FullLoad.json");
      if (defined($mailbody)){
         #printf STDERR ("found Attachment $mailbody in $self\n");
         if (my $io=$mailbody->bodyhandle->open("r")){
            while(my $l=$io->getline()){
               $mailtext.=$l;
            }
            $io->close();
         }
      }
      msg(INFO,$self->Self().": mailtext readed l=".length($mailtext));
      if ($fromemail ne ""){
         my $user=getModuleObject($app->Config(),"base::user");
         $user->SetFilter({cistatusid=>4,emails=>$fromemail});
         my ($urec,$msg)=$user->getOnlyFirst(qw(accounts cistatusid fullname));
         if (defined($urec) && $#{$urec->{accounts}}>=0){
            $ENV{REMOTE_USER}=$urec->{accounts}->[0]->{account};
            msg(INFO,$self->Self().": from user userid=$urec->{userid}");
            my ($tfh,$tfname)=tempfile();
            if (defined($tfh)){
               msg(INFO,$self->Self().": tempfile $tfname created");
               print $tfh $mailtext;
               seek($tfh,0,SEEK_SET);
               my $o=getModuleObject(
                  $app->Config(),"TSharePoint::SharePointHubMaster"
               );
               msg(INFO,$self->Self().": start processing $tfname");
               $recordcount=$o->JsonObjectLoad_FullLoad(
                  $tfname,"HubMasterlist.FullLoad.json"
               );
               close($tfh);
               unlink($tfname);
            }
            else{
               msg(ERROR,$self->Self().": fail to create tempfile - $!");
            }
         }
      }
      my $exitmsg="length:".length($mailtext)." reccount:".$recordcount;
      sleep(5);
      if ($jobid ne ""){
         if ($joblog->Ping()){
            $joblog->ValidatedUpdateRecord(
               {id=>$jobid},
               {exitcode=>$exitmsg,
                exitmsg=>$exitmsg,
                exitstate=>"ok"},
               {id=>\$jobid}
            );
        }
      }
   }

   return(0);
}



1;
