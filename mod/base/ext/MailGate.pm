package base::ext::MailGate;
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

   my $mailtext;
   my $isdelerror=0;
   my $email;
   my $mailbody=$app->FindFirstMimePartWithType($parsedMail,"text/plain");
   #printf STDERR ("found from:%s in $self\n",$from);
   #printf STDERR ("found to:%s in $self\n",$to);
   if ($from=~m/^MAILER-DAEMON\@/){
      if (defined($mailbody)){
         if (my $io=$mailbody->bodyhandle->open("r")){
            while(my $l=$io->getline()){
               $mailtext.=$l;
               if ($l=~m/Delivery to the following recipients failed./){
                  $isdelerror++;
               }
               if ($l=~m/Unknown Mailaddress/){
                  $isdelerror++;
               }
               if ($isdelerror){
                  if (my ($e)=$l=~m/(\S+\@\S+)/){
                     $email=lc($e);
                     $email=~s/://g;
                  }
               }
            }
            $io->close();
         }
      }
      if ($from ne "" && $name ne "" && $mailtext ne ""){
         my $reqid=$ms->ValidatedInsertRecord({
                                     fromemail=>$from,
                                     state=>'6',
                                     account=>$ENV{REMOTE_USER},
                                     name=>$name,
                                     textdata=>$mailtext,
                                     mailmode=>"MAILER-DAEMON"});

      }
   #   printf STDERR ("from:%s\n",$from);
   #   printf STDERR ("name:%s\n",$name);
   #   printf STDERR ("isdelerror:%s\n",$isdelerror);
   #   printf STDERR ("email:%s\n",$email);
   #   printf STDERR ("mailtext:\n%s\n",$mailtext);
   }



   #printf STDERR ("mailtext from FindFirstMimePartWithType:%s\n",$mailtext);


#   if ($rec->{mailmode} eq "postmaster"){
#      if (my ($email)=$rec->{textdata}=~m/(\S+\@\S+)/m){
#         my $user=getModuleObject($app->Config,"base::user");
#         $email=lc($email);
#         $user->SetFilter({email=>\$email,cistatusid=>"<6"});
#         my ($urec,$msg)=$user->getOnlyFirst(qw(userid fullname));
#         if (defined($urec)){
#            msg(INFO,"delivery error on $urec->{fullname}");
#            my $wf=getModuleObject($app->Config,"base::workflow");
#            my $srcsys="MailgateDeliveryError";
#            $wf->SetFilter({srcid=>\$urec->{userid},srcsys=>\$srcsys});
#            my ($wrec,$msg)=$wf->getOnlyFirst(qw(ALL));
#            if (defined($wrec) && $wrec->{stateid}>=17){
#               $wf->ValidatedDeleteRecord($wrec);
#               $wrec=undef;
#            }
#            if (!defined($wrec)){
#               my $newrec={name=>"DataIssue: delivery error on $email",
#                            detaildescription=>$rec->{textdata},
#                            class=>"base::workflow::DataIssue",
#                            step=>"base::workflow::DataIssue::dataload",
#                            affectedobject=>"base::user",
#                            affectedobjectid=>$urec->{userid},
#                            altaffectedobjectname=>$urec->{fullname},
#                            directlnkmode=>"DataIssueMsg",
#                            eventend=>undef,
#                            eventstart=>NowStamp("en"),
#                            srcload=>NowStamp("en"),
#                            srcsys=>$srcsys,
#                            srcid=>$urec->{userid},
#                            DATAISSUEOPERATIONSRC=>"DataIssueMsg"};
#                my $bk=$wf->Store(undef,$newrec);
#            }
#         }
#      }
#
#      
#      msg(INFO,"ok delerror");
#      return(1);
#
#
#
#   }elsif ($rec->{mailmode} eq "adminrequest"){
#      my $name=$rec->{name};
#      my $desc=$rec->{textdata};
#      my $wf=getModuleObject($app->Config,"base::workflow");
#      my $h={name=>$rec->{name},
#             class=>'base::workflow::adminrequest',
#             step=>'base::workflow::adminrequest::dataload',
#             detaildescription=>$rec->{textdata}}; 
#      if ($wf->nativProcess("NextStep",$h,undef)){
#         my $id=$h->{id};
#         $$answer="Admin-Request ID: ".$id."\r".
#                  "direct link:      ".
#                 $app->Config->Param("EventJobBaseUrl").
#                 "/auth/base/workflow/ById/$id";
#      }
#      else{
#         return(0);
#      }
#      return(1);
#   }
#   return(undef);

   return(0);
}



1;
