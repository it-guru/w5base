package base::W5Server::MailProc;
use strict;
use kernel;
use kernel::date;
use kernel::W5Server;
use MIME::Entity;
use MIME::Parser;

use vars (qw(@ISA));
@ISA=qw(kernel::W5Server);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub process
{
   my $self=shift;

   #
   # setup "normal" signal handling to ensure correct 
   # working of system() or qx calls.
   #
   chdir("/tmp");
      $SIG{INT}='DEFAULT';
      $SIG{HUP}='DEFAULT';
      $SIG{CHLD}='DEFAULT';
      $SIG{ALRM}='DEFAULT';
      $SIG{USR1}='DEFAULT';
      $SIG{TERM}='DEFAULT';
      $SIG{PIPE}='DEFAULT';
      $SIG{WARN}='DEFAULT';




   my $nextrun;
   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   my $ro=0;
   if ($opmode eq "readonly"){
      $ro=1;
   }

   while(1){
      if ((defined($nextrun) && $nextrun<=time()) || $self->{doForceMailSpool}){
         $self->{doForceCleanup}=0;
         $self->processMailSpool($ro);
         sleep(1);
      }
      my $current=time();

      $nextrun=$current+10;   # check time

      my $sleep=$nextrun-$current;
      msg(DEBUG,"(%s) sleeping %d seconds",$self->Self,$sleep);
      $self->FullContextReset();
      $sleep=60 if ($sleep>60);
      die('lost my parent W5Server process - not good') if (getppid()==1);
      my $targettime=time()+$sleep;
      do{
        msg(DEBUG,"sleep ".time()." target=$targettime ".
                  "doForceMailSpool $self->{doForceMailSpool}");
        sleep(1);
      }while((time()<$targettime) && !$self->{doForceMailSpool});
   }
}

sub FindFirstMimePartWithType
{
   my $self=shift;
   my $part=shift;
   my $type=shift;

   if ($part->mime_type() eq $type){
      return($part);
   }
   foreach my $mpart ($part->parts()){
      #printf STDERR ("fifi check %s\n",$mpart->mime_type());
      if ($mpart->mime_type() eq "multipart/alternative"){
         my $f=$self->FindFirstMimePartWithType($mpart,$type);
         return($f) if (defined($f));
      }
      if ($mpart->mime_type() eq $type){
         return($mpart);
         last;
      }
   }
   return(undef);
}

sub FindAttachmentByName
{
   my $self=shift;
   my $part=shift;
   my $filename=shift;

   #printf STDERR ("fifi FindAttachmentByName part=$part\n");
   #    $part->dump_skeleton(\*STDERR);
   
   if (my $head=$part->head()){
      my $name=$head->recommended_filename;
      if (my $disposition=$head->get('Content-Disposition')){
         if ($disposition =~ /attachment/i) {
             if ($name && $name eq $filename) {
      #           print STDERR ("Gefunden: $name\n");
                 return($part);
             }
         }
      }
   }
   foreach my $mpart ($part->parts()){
      my $f=$self->FindAttachmentByName($mpart,$filename);
      return($f) if (defined($f));
   }
   return();
}


sub processMailSpool
{
   my $self=shift;
   my $ro=shift;
   if (!$ro){
      msg(DEBUG,"======== processMailSpool ============");
      my $W5MailSpoolDir=$self->getParent->Config->Param("W5MailSpoolDir");
      return() if ($W5MailSpoolDir eq "");
      $W5MailSpoolDir=~s/\/$//;
      if (! -d $W5MailSpoolDir ){
         msg(ERROR,"W5MailSpoolDir '$W5MailSpoolDir' does not exists");
         return();
      }
      if (! -w $W5MailSpoolDir ){
         msg(ERROR,"no write access to W5MailSpoolDir '$W5MailSpoolDir'");
         return();
      }
      my $ms=getModuleObject($self->getParent->Config(),"base::mailreqspool");
      if (opendir(my $dh,$W5MailSpoolDir)){
         while(my $mailfile=readdir($dh)){
            next unless($mailfile=~m/\.eml$/);
            $mailfile=$W5MailSpoolDir."/".$mailfile;
            msg(INFO,"start processing $mailfile");
            next unless(-w $mailfile);
            msg(INFO,"file processing $mailfile allowed");
            my $mp=new MIME::Parser();
            my $tmpdir="/tmp";
            if ($ENV{TMP} ne ""){
               $tmpdir=$ENV{TMP};
            }
            if ($ENV{tmp} ne ""){
               $tmpdir=$ENV{tmp};
            }
            $mp->output_under($tmpdir);
            $mp->decode_headers(1);
            $mp->extract_uuencode(1);
            if (open(MAILFH,"<$mailfile")){
               msg(INFO,"pre parse $mailfile");
               my $parsedMail=$mp->parse(\*MAILFH);
               my $mailHead=$parsedMail->head();
               my $name=$mailHead->get("Subject");
               my $from=$mailHead->get("From");
               my $processed=0;
               foreach my $obj (values(%{$ms->{MailGate}})){
                  msg(INFO,"distribute mail to $obj");
                  my $res=$obj->Process($self,$ms,$parsedMail);
                  $processed++ if ($res);
               }
               close(MAILFH);
            }
            else{
               msg(ERROR,"fail to open '$mailfile'- $!");
            }
            unlink($mailfile);
            $mp->filer->purge();
         }
      }
      else{
         msg(ERROR,"fail to open dir W5MailSpoolDir '$W5MailSpoolDir'- $!");
         return();
      }
   }


#            my $joblog=getModuleObject($self->getParent->Config,"base::joblog");
#            my %jobrec=(name=>"base::W5Server::Cleanup.pm",
#                        event=>"Cleanup.pm W5Server",
#                        pid=>$$);
#            my $jobid;
#            if ($joblog->Ping()){
#               $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
#            }
#
#            $self->CleanupWasted();
#            $self->doCleanup();
#            $self->CleanupWorkflows();
#            $self->CleanupHistory();
#            msg(DEBUG,"Call CleanupLnkContactExp");
#            my $bk=$joblog->W5ServerCall("rpcCallEvent","CleanupLnkContactExp");
#            if ($jobid ne ""){
#               if ($joblog->Ping()){
#                  $joblog->ValidatedUpdateRecord({id=>$jobid},
#                                                {exitcode=>"0",
#                                                 exitmsg=>"done",
#                                                 exitstate=>"ok"},
#                                                {id=>\$jobid});
#
#             }
}


sub reload
{
   my $self=shift;
   msg(DEBUG," got reload");
   $self->{doForceMailSpool}++;
}










1;


