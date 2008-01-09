package itil::W5Server::controlcenter;
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

sub start
{
   my $self=shift;
   my $statedir=$self->getParent->Config->Param("W5ServerState");
   $statedir.="/ServerJob";
   if ( ! -d $statedir){
      msg(DEBUG,"create '%s'",$statedir);
      if (!mkdir($statedir)){
         msg(ERROR,"create '%s' failed",$statedir);
      }
   }
   if (opendir(D,$statedir)){
      foreach my $job (grep { !/^\./ } readdir(D)){
         printf STDERR ("fifi run job $job\n");
         my $b=$self->getParent->W5ServerCall("rpcCallSerialEvent",
                                              "systemjob",$job);
         printf STDERR ("fifi d=%s\n",Dumper($b));
      }
   }
   $self->{Reload}=1;
}

sub process
{
   my $self=shift;

   while(1){
      my $currenttime=time();
      if ($self->{Reload} || $currenttime>=($self->{QueueMaxTime}-60)){
         $self->ReloadProcessQueue();
      }
      QueueCheck: for(my $qp=0;$qp<=$#{$self->{Queue}};$qp++){
         if ($self->{Queue}->[$qp]->{desiredstart}>$currenttime){
            last;
         }
         if ($self->{Queue}->[$qp]->{desiredstart}<=$currenttime){
            #
            # check sync jobs
            #
            
            #
            # start job
            #
            my $startjob=$self->{Queue}->[$qp];
            my $app=$self->getParent;
            my $wf=getModuleObject($app->Config,"base::workflow");
            msg(DEBUG,"StartJob:\n%s",Dumper($startjob));
            my $sysobj=$app->getPersistentModuleObject("itil::system");
            my $jobobj=$app->getPersistentModuleObject("itil::systemjob");
            my $jobtobj=$app->getPersistentModuleObject("itil::systemjobtiming");
            $sysobj->SetFilter({id=>\$startjob->{systemid}});
            my ($sys,$msg)=$sysobj->getOnlyFirst(qw(ALL));
            $jobobj->SetFilter({id=>\$startjob->{jobid}});
            my ($job,$msg)=$jobobj->getOnlyFirst(qw(ALL));
            $jobtobj->SetFilter({id=>\$startjob->{id}});
            my ($jobt,$msg)=$jobtobj->getOnlyFirst(qw(ALL));
            if (defined($wf) && defined($job) && defined($sys) && 
                defined($jobt)){
               my $runcount=$jobt->{runcount};
               my $newrec={
                            class  =>'itil::workflow::systemjob',
                            step   =>'itil::workflow::systemjob::dataload',
                            jobid      =>$job->{id},
                            srcsys     =>$jobtobj->Self,
                            srcid      =>$startjob->{id}."-".$runcount,
                            srcload    =>scalar($app->ExpandTimeExpression("now")),
                            affectedsystemid=>$sys->{id},
                            affectedsystem  =>$sys->{name},
                            jobsystemname   =>$sys->{name},
                            name            =>"Timer: ".$job->{name}};
               if ($sys->{mandatorid} ne ""){
                  $newrec->{mandatorid}=[$sys->{mandatorid}];
               }
               if ($sys->{mandator} ne ""){
                  $newrec->{mandator}=[$sys->{mandator}];
               }
               if ($sys->{adminteam} ne ""){
                  $newrec->{responsablegrp}=[$sys->{adminteam}];
               }
               if ($sys->{adminteamid} ne ""){
                  $newrec->{responsablegrpid}=[$sys->{adminteamid}];
               }
               if ($jobt->{owner} ne ""){
                  $newrec->{openuser}=$jobt->{owner};
                  $newrec->{openusername}=$jobt->{ownername};
               }
               if (my $id=$wf->Store(undef,$newrec)){
                  my %d=(step=>'itil::workflow::systemjob::pending');
                  my $r=$wf->Store($id,\%d);
                  $runcount++;
                  $jobtobj->ValidatedUpdateRecord($jobt,
                                                  {runcount=>$runcount},
                                                  {id=>\$jobt->{id}});
               }
            }

            # remove job from queue
            splice(@{$self->{Queue}},$qp,1);
            last QueueCheck;
         }
      }
      printf STDERR ("W5Server process ($self)\n");
      sleep(1);
   }
}

sub ReloadProcessQueue
{
   my $self=shift;
   my $app=$self->getParent;

   $self->{Reload}=0;
   msg(DEBUG,"ReloadProcessQueue: == Job Scheduler Reload Event ==");
   my $t=$app->getPersistentModuleObject("itil::systemjobtiming");
   my $mintime=time();
   my $maxtime=time()+86400;
   my @days=qw(sun mon tue wed thu fri sat);
   $self->{QueueMaxTime}=$maxtime;
   $self->{QueueMinTime}=$mintime;

   $t->SetCurrentView(qw(ALL));
   $t->SetFilter({tintervalid=>">0"});
   my ($rec,$msg)=$t->getFirst();
   my %desjobs;
   if (defined($rec)){
      do{
         if ($rec->{tinterval}==1){
             my $tdest;
             eval('$tdest=Date_to_Time("GMT",$rec->{plannedyear},
                                       $rec->{plannedmon},
                                       $rec->{plannedday},
                                       $rec->{plannedhour},
                                       $rec->{plannedmin},0);');
             if (defined($tdest)){
                if ($tdest>=$mintime && $tdest<=$maxtime){
                  my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date($tdest);
                  my $d="$day.$month.$year $hour:$min:$sec";
                  $desjobs{$rec->{id}}={id=>$rec->{id},
                                        jobid=>$rec->{jobid},
                                        systemid=>$rec->{systemid},
                                        debug_start_GMT=>$d,
                                        desiredstart=>$tdest};
                }
             }
         }elsif ($rec->{tinterval}==2){
            my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date("GMT",$mintime);
            my $dow=Day_of_Week($year,$month,$day);
            for(my $c=0;$c<=6;$c++){
               $dow+=$c;
               $dow=0 if ($dow>6);
               my $dayname=$days[$dow];
               next if (!($rec->{"plannedwd".$dayname}));
               my $tdest=Date_to_Time("GMT",Add_Delta_YMD("GMT",$year,$month,$day,0,0,$c),
                                      $rec->{plannedhour},$rec->{plannedmin},0);
               if ($tdest>=$mintime && $tdest<=$maxtime){
                  my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date("GMT",$tdest);
                  my $d="$day.$month.$year $hour:$min:$sec";
                  $desjobs{$rec->{id}}={id=>$rec->{id},
                                        jobid=>$rec->{jobid},
                                        systemid=>$rec->{systemid},
                                        debug_start_GMT=>$d,
                                        desiredstart=>$tdest};
                  last;
               }
            }
         }
         ($rec,$msg)=$t->getNext();
      } until(!defined($rec));
   }
   $self->{Queue}=[sort({$a->{desiredstart}<=>$b->{desiredstart}} 
                        values(%desjobs))];
   msg(DEBUG,"desjobs=%s\n",Dumper($self->{Queue}));
}





sub reload
{
   my $self=shift;

   $self->{Reload}=1;
}





1;


