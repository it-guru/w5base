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
         if ($hour>=7 and $hour<=22){
            $insleep=0;
         }
         else{
            $insleep=1;
         }
         if (time()-$spoolRefresh>300){
            $spoolRefresh=time();
            msg(INFO,"FastQualityChecker: doSpoolRefresh");
            my $o=getModuleObject($self->Config,"itil::system");
            $o->SetFilter({
                cistatusid=>\'4',
                instdate=>'<now-70m AND >now-90m',
                itcloudareaid=>"![EMPTY]",
                lastqcheck=>'<now-1h'
            });
            my @l=$o->getHashList(qw(id instdate lastqcheck mdate));
            #print STDERR Dumper(\@l);
            foreach my $rec (@l){
               if (!in_array($self->{'itil::system'}->{'SPOOL'},$rec->{id})){
                  push(@{$self->{'itil::system'}->{'SPOOL'}},$rec->{id});
               }
            }
         }
         if ((!$insleep) &&
             ($#{$self->{'itil::system'}->{'SPOOL'}}!=-1)){
            my $o=getModuleObject($self->Config,"itil::system");
            my $st=time();
            while(my $id=shift(@{$self->{'itil::system'}->{'SPOOL'}})){
               $o->SetFilter({
                  id=>\$id,
                  lastqcheck=>'<now-1h',
                  cistatusid=>\'4',
                  itcloudareaid=>"![EMPTY]"
               });
               my @l=$o->getHashList(qw(id lastqcheck 
                                        qcstate mdate cistatusid));
              
               #print STDERR Dumper(\@l);
               if ($st-time()>60){
                  last;
               }
            }
            sleep(10);
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


