package base::W5Server::DailyProcess;
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

# debug cleanup run:
#
#  sudo kill -USR2 $(ps -ef | grep 'W5Sserver-base::W5Server::DailyProcess' | \
#  grep -v grep| awk '{print $2}')
#
#

sub process
{
   my $self=shift;
   my $CleanupTime=$self->getParent->Config->Param("DailyProcessTime");
   my ($h,$m)=$CleanupTime=~m/^(\d+):(\d+)/;


   $h=0  if ($h<0);
   $h=23 if ($h>23);
   $m=0  if ($m<0);
   $m=59 if ($m>59);

   my $nextrun;
   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   my $ro=0;
   if ($opmode eq "readonly"){
      $ro=1;
   }

   while(1){
      if ((defined($nextrun) && $nextrun<=time()) || $self->{doForceCleanup}){
         $self->{doForceCleanup}=0;
         if (!$ro){
            my $joblog=getModuleObject($self->getParent->Config,"base::joblog");
            my %jobrec=(name=>"base::W5Server::DailyProcess.pm",
                        event=>"DailyProcess.pm W5Server",
                        pid=>$$);
            my $jobid;
            if ($joblog->Ping()){
               $jobid=$joblog->ValidatedInsertRecord(\%jobrec);
            }

            my @objlist=$self->getParent->globalObjectList();
            foreach my $obj (@objlist){
               my $o;
               eval('$o=getModuleObject($self->getParent->Config,$obj);');
               #if (!defined($o)){
               #   die("ERROR: can not create object $obj");
               #}
               if (defined($o) && $o->can("DailyProcess")){
                  msg(DEBUG,"run for DailyProcess $obj as '$o' instance");
                  my $n=$o->DailyProcess();
               }
            }
            $joblog->ValidatedUpdateRecord({id=>$jobid},
                                          {exitcode=>"0",
                                           exitmsg=>'ok',
                                           exitstate=>"ok"},
                                          {id=>\$jobid});
         }
         sleep(1);
      }
      my $current=time();
      my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date("GMT",$current);
      if (Date_to_Time("GMT",$year,$month,$day,$h,$m,0)<=time()){
         ($year,$month,$day)=Add_Delta_YMD("GMT",$year,$month,$day,0,0,1);
      }
      $nextrun=Date_to_Time("GMT",$year,$month,$day,$h,$m,0);
      msg(DEBUG,"(%s) next cleanup at %04d-%02d-%02d %02d:%02d:%02d",
                 $self->Self,$year,$month,$day,$h,$m,0);
      my $sleep=$nextrun-$current;
      msg(DEBUG,"(%s) sleeping %d seconds",$self->Self,$sleep);
      $self->FullContextReset();
      $sleep=60 if ($sleep>60);
      die('lost my parent W5Server process - not good') if (getppid()==1);
      my $targettime=time()+$sleep;
      do{
        msg(DEBUG,"sleep ".time()." target=$targettime ".
                  "doForceCleanup $self->{doForceCleanup}");
        sleep(1);
      }while((time()<$targettime) && !$self->{doForceCleanup});
   }
}

sub reload
{
   my $self=shift;
   msg(DEBUG," got reload");
   $self->{doForceCleanup}++;
}










1;


