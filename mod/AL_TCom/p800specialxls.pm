package AL_TCom::p800specialxls;

use strict;
use vars qw(@ISA);
use kernel;
use kernel::Field;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(      name     =>'custcontract',
                                  align    =>'left',
                                  label    =>'Vertragsnummer'),
      new kernel::Field::Text(    name     =>'conumber',
                                  label    =>'CO-Number'),
      new kernel::Field::Number(  name     =>'worktime_mminus1',
                                  searchable =>0,
                                  unit     =>'min',
                                  label    =>'Sonderleistung aktueller Monat-1Monat'),
      new kernel::Field::Number(  name     =>'worktime_mminus2',
                                  searchable =>0,
                                  unit     =>'min',
                                  label    =>'Sonderleistung aktueller Monat-2Monate'),
      new kernel::Field::Number(  name     =>'worktime_mminus3',
                                  searchable =>0,
                                  unit     =>'min',
                                  label    =>'Sonderleistung aktueller Monat-3Monate'),
      new kernel::Field::Number(  name     =>'worktime_mminus4',
                                  searchable =>0,
                                  unit     =>'min',
                                  label    =>'Sonderleistung aktueller Monat-4Monate'),
      new kernel::Field::Number(  name     =>'worktime_mminus5',
                                  searchable =>0,
                                  unit     =>'min',
                                  label    =>'Sonderleistung aktueller Monat-5Monate'),
      new kernel::Field::Number(  name     =>'worktime_mminus6',
                                  searchable =>0,
                                  unit     =>'min',
                                  label    =>'Sonderleistung aktueller Monat-6Monate'),
      new kernel::Field::Number(  name     =>'worktimesum',
                                  searchable =>0,
                                  group    =>'calc',
                                  unit     =>'min',
                                  label    =>'Summe Sonderleistung 6 Monate'),
      new kernel::Field::Number(  name     =>'worktimeavg',
                                  searchable =>0,
                                  unit     =>'min',
                                  group    =>'calc',
                                  label    =>'Mittlere Sonderleistung'),
      new kernel::Field::Percent( name     =>'maxdrift',
                                  searchable =>0,
                                  group    =>'calc',
                                  label    =>'max. drift'),
   );
   $self->{'data'}=\&recalcData;
   $self->setDefaultView(qw(custcontract conumber 
                            worktime_mminus1
                            worktime_mminus2
                            worktime_mminus3
                            worktime_mminus4
                            worktime_mminus5
                            worktime_mminus6
                            worktimesum
                            worktimeavg
                            maxdrift
                           ));
   return($self);
}

sub recalcData
{
   my $self=shift;

   if (!defined($self->{Data}) ||
       $self->{Data}->{T}<time()-10){
      $self->{Data}={List=>$self->loadDataList(),
                     T   =>time()};
   }
   return($self->{Data}->{List});

}

sub loadDataList
{
   my $self=shift;
   my @l;
   my %l;
   my $wf=getModuleObject($self->Config,"base::workflow");
   $wf->SetFilter({class=>\'AL_TCom::workflow::P800special',
                   eventstart=>'>now-7M'});

   $wf->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
        # msg(INFO,"prozess %s",Dumper($rec));
         if (defined($rec->{affectedcontract}) && 
             ref($rec->{affectedcontract}) eq "ARRAY"){
            foreach my $custcontract (@{$rec->{affectedcontract}}){
               if ($custcontract ne ""){
                  $l{$custcontract}={} if (!exists($l{$custcontract}));
                  my $wt=$rec->{'p800_app_speicalwt'};
                  my $rmon=$rec->{'p800_reportmonth'};
                  for (my $off=1;$off<=6;$off++){
                      my $crmon=$self->ExpandTimeExpression("now-${off}M",
                                "stamp");
                      $crmon=~s/^(\d{4})(\d{2}).*$/$2\/$1/;
                      if ($crmon eq $rmon){
                         $l{$custcontract}->{'worktime_mminus'.$off}+=$wt;
                      }
                    
                  }
               }
            }
         }
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   foreach my $custcontract (sort(keys(%l))){
      my $h={%{$l{$custcontract}},custcontract=>$custcontract,
             worktimesum=>$l{$custcontract}->{worktime_mminus1}+
                          $l{$custcontract}->{worktime_mminus2}+
                          $l{$custcontract}->{worktime_mminus3}+
                          $l{$custcontract}->{worktime_mminus4}+
                          $l{$custcontract}->{worktime_mminus5}+
                          $l{$custcontract}->{worktime_mminus6}};
      $h->{worktimeavg}=$h->{worktimesum}/6;
      my $maxdrift;
      for (my $off=1;$off<=6;$off++){
          my $d=abs($h->{worktimeavg}-$h->{'worktime_mminus'.$off});
          if ($d>0 && $h->{worktimeavg}>0){
             my $drift=$d*100/$h->{worktimeavg};
             $maxdrift=$drift if ($maxdrift<$drift);
          }
      }
      if (defined($maxdrift)){
         $h->{maxdrift}=$maxdrift;
      }
      
      push(@l,$h);
   }
   return(\@l);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
   return(undef) if ($self->IsMemberOf("admin"));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  
   









1;
