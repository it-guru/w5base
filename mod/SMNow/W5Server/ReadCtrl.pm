package SMNow::W5Server::ReadCtrl;
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

   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   my $deepsleep=0;
   if ($opmode eq "readonly"){
      $deepsleep++;
   }
   my $dbconnect=$self->getParent->Config->Param('DATAOBJCONNECT');
   if (ref($dbconnect) ne "HASH" ||
       $dbconnect->{tssm} eq ""){
      $deepsleep++;
   }

   if ($deepsleep){
      while(1){
         sleep(3600);
      }
   }


   my %ctrl=(
              'sngroup'=>{
                           laststart=>undef,
                           lastend=>undef,
                           suspend=>30,   # dont start in first 15 minutes
                           AsyncID=>undef,
                          }
             );
   my $evrt=getModuleObject($self->Config,"base::eventrouter");
   #my $bk=$evrt->W5ServerCall("rpcCallEvent","LongRunner");

   my $looptimer=30;
   while(!$self->ServerGoesDown()){
      my $evrt=getModuleObject($self->Config,"base::eventrouter");
      #
      # Job Starter
      #
      if (1){
         msg(DEBUG,"from %s now i check to start new events\n",
                        $self->Self());
         EVST: foreach my $eventname (keys(%ctrl)){
            if ($ctrl{$eventname}->{'suspend'}>0){
               $ctrl{$eventname}->{'suspend'}--;
            }
            if (currentRunnings(\%ctrl)<keys(%ctrl)){
               if (!defined($ctrl{$eventname}->{'AsyncID'}) &&
                   $ctrl{$eventname}->{'suspend'}<=0 &&
                   ((defined($ctrl{$eventname}->{'lastend'}) &&
                     $ctrl{$eventname}->{'lastend'}<(time()-300)) ||
                    (!defined($ctrl{$eventname}->{'laststart'})) ||
                    ($ctrl{$eventname}->{'laststart'}<(time()-1500)))){
                  my $bk=$evrt->W5ServerCall("rpcCallEvent",$eventname);
                  if (ref($bk) eq "HASH"){
                     if ($bk->{'exitcode'}==0 &&
                         $bk->{'AsyncID'}!=0){
                        $ctrl{$eventname}->{'laststart'}=time();
                        $ctrl{$eventname}->{'lastend'}=undef;
                        $ctrl{$eventname}->{'AsyncID'}= $bk->{'AsyncID'};
                        last EVST;       
                     }
                  }
                  else{
                     die('ERROR: ganz schlecht - bad result from rpcCallEvent');
                  }
               }
            }
         }
      }
      #
      # Job Status checker
      #
      foreach my $eventname (keys(%ctrl)){
         if (defined($ctrl{$eventname}->{'AsyncID'})){
            my $bk=$evrt->W5ServerCall("rpcAsyncState",
                                   $ctrl{$eventname}->{'AsyncID'});
            if (ref($bk) eq "HASH" && $bk->{'exitcode'}==0){
              # printf STDERR ("fifi loop=%s\n",Dumper($bk));
               if (exists($bk->{'process'}->{'exitcode'})){
                  if ($bk->{'process'}->{'exitcode'}==0){
                     $ctrl{$eventname}->{'lastend'}=time();
                  }
                  else{
                     # if a exitcode!=0 came from the event, the event
                     # will be suspend for 1 hour.
                     $ctrl{$eventname}->{'suspend'}=int(3600/$looptimer);
                     msg(ERROR,"exitcode error:".Dumper($bk));
                     msg(ERROR,"now i set $eventname to suspend ".
                               ($ctrl{$eventname}->{'suspend'}*$looptimer).
                               "sec");
                  }
                  $ctrl{$eventname}->{'AsyncID'}=undef; 
               }
            }
            else{
               die('ERROR: ganz schlecht - can not get async state');
            }
            
         }
      }
      #printf STDERR ("fifi from %s at %d\n",$self->Self(),time());
     # printf STDERR ("fifi data=%s\n",Dumper(\%ctrl));
      $self->FullContextReset();
      sleep($looptimer);
      die('lost my parent W5Server process - not good') if (getppid()==1);
   }
}

sub currentRunnings
{
   my $ctrl=shift;
   my %ctrl=%{$ctrl};
   my $n=0;

   foreach my $eventname (keys(%ctrl)){
      if (defined($ctrl{$eventname}->{'AsyncID'})){
         $n++;
      }
   }
   return($n);
}













1;


