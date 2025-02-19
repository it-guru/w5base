package itil::W5Server::FastQualityChecker;
use strict;
use kernel;
use kernel::date;
use kernel::W5Server;
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

   my $insleep=1;
   $self->{'itil::system'}->{'SPOOL'}=[];

   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   my $ro=0;
   if ($opmode eq "readonly"){
      $ro=1;
   }
   my $spoolRefresh=time()-290;

   while(1){
      if (!$ro){
         my $current=time();
         my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date("GMT",$current);
         if ($hour>=7 and $hour<=18){
            $insleep=0;
         }
         else{
            # nightly check, if a QualityCheck process is running. If not,
            # FastQualityChecks can also be done at night.
            my $joblog=getModuleObject($self->Config,"base::joblog");
            $joblog->SetFilter({
               'name'=>'base::event::QualityCheck::QualityCheck',
               'event'=>'QualityCheck',
               'cdate'=>'>now-12h',
               'exitcode'=>'[EMPTY]'
            });
            my @l=$joblog->getHashList(qw(id));
            if ($#l==-1){
               $insleep=0;    # no nightly QualityCheck is currently running
            }
            else{
               $insleep=1;
               sleep(300);   # if Job is running, we check it at first in
            }                # 5 min again
         }
         if (time()-$spoolRefresh>300){
            $spoolRefresh=time();
            my $o=getModuleObject($self->Config,"itil::system");
            ###################################################################
            msg(INFO,"FastQualityChecker: doSpoolRefresh for shortly inst");
            $o->SetFilter({
                cistatusid=>\'4',
                instdate=>'<now-1h AND >now-2h',
                itcloudareaid=>"![EMPTY]",
                lastqcheck=>'<now-1h AND >now-2h'
            });
            my @l=$o->getHashList(qw(instdate lastqcheck id  mdate));
            foreach my $rec (@l){
               if (!in_array($self->{'itil::system'}->{'SPOOL'},$rec->{id})){
                  push(@{$self->{'itil::system'}->{'SPOOL'}},$rec->{id});
               }
            }
            ###################################################################
            msg(INFO,"FastQualityChecker: doSpoolRefresh for last 25h inst");
            $o->SetFilter({
                cistatusid=>\'4',
                instdate=>'<now-25h AND >now-26h',
                itcloudareaid=>"![EMPTY]",
                lastqcheck=>'<now-12h AND >now-26h'
            });
            my @l=$o->getHashList(qw(instdate lastqcheck id mdate));
            foreach my $rec (@l){
               if (!in_array($self->{'itil::system'}->{'SPOOL'},$rec->{id})){
                  push(@{$self->{'itil::system'}->{'SPOOL'}},$rec->{id});
               }
            }
            ###################################################################
         }
         my $nent=$#{$self->{'itil::system'}->{'SPOOL'}}+1;
         msg(INFO,"FastQualityChecker: $nent in spool");
         if ($#{$self->{'itil::system'}->{'SPOOL'}}!=-1){
            sleep(2);
         }
         if ((!$insleep) &&
             ($#{$self->{'itil::system'}->{'SPOOL'}}!=-1)){
            my $o=getModuleObject($self->Config,"itil::system");
            my $st=time();
            PLOOP: while(my $id=shift(@{$self->{'itil::system'}->{'SPOOL'}})){
               msg(INFO,"FastQualityChecker: start process id $id from spool");
               $o->SetFilter({
                  id=>\$id,
                  lastqcheck=>'<now-55m',
                  cistatusid=>\'4',
                  itcloudareaid=>"![EMPTY]"
               });
               my @l=$o->getHashList(qw(id lastqcheck 
                                        qcstate mdate cistatusid));
               if ($#l==-1){
                  msg(INFO,"FastQualityChecker: id $id hast lost need ".
                           "to qcheck since is in spool");
                  
               }
               else{
                  foreach my $rec (@l){
                     msg(INFO,"FastQualityChecker: qcheck result for id $id : ".
                              $rec->{qcstate});
                  }
               }
               sleep(1);
               if ($st-time()>60){
                  last PLOOP;
               }
            }
            sleep(3);
         }
      }
      sleep(5);
      #msg(INFO,"FastQualityChecker: fifi01");
   }
}




sub reload
{
   my $self=shift;
   $self->{doForceCleanup}++;
}










1;


