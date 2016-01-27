package kernel::Reporter;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use kernel::Plugable;
use kernel::date;
@ISA=qw(kernel::Plugable);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;
   return(1);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(1); #(24*60)
}


sub taskCreator          # creates new Prozess requests
{
   my $self=shift;
   my $reporter=shift;
   my $Reporter=shift;

   if (!defined($self->{lastrun})){
      my $o=$Reporter->{reportjob};
      $o->SetFilter({srcsys=>\$self->Self,srcid=>\'1'});
      my ($reportrec)=$o->getOnlyFirst(qw(srcload));
      if (defined($reportrec) && $reportrec->{srcload} ne ""){
         $self->{lastrun}=$reportrec->{srcload};
      }
      else{
         $self->{lastrun}="1999-01-01 00:00:00";
      }
   }
   my ($definterval,$deftimes)=$self->getDefaultIntervalMinutes();
   my ($nY,$nM,$nD,$nh,$nm,$ns)=Today_and_Now("en");

   $definterval=int($definterval);
   $definterval=1 if ($definterval<=0);
   if (ref($deftimes) eq "ARRAY"){
      if ($definterval<5){
         $definterval=5;
      }
   }
   else{
      $deftimes=[];
   }
   @$deftimes=sort({ $a<=>$b } 
                  map({ my $s=$_;
                    if (my ($h,$m)=$_=~m/(\d+):(\d+)/){
                       $s=$h+(1.0/60.0*$m);
                    }
                    $s;
                  } @$deftimes));

   my $d=CalcDateDuration($self->{lastrun},NowStamp("en"));
   if ($d->{totalminutes}>$definterval){
      my $startTask=0;
      $startTask++ if ($#{$deftimes}==-1);
      for(my $t=0;$t<=$#{$deftimes};$t++){
         my $twinlow=$deftimes->[$t];
         my $twinheight=($twinlow+(1/60)*15);
         my $nowfloat=$nh+(1/60*$nm);
         if ($twinlow<=$nowfloat && $twinheight>$nowfloat){
            if (!defined($deftimes->[$t+1]) || 
                $deftimes->[$t+1]>$nowfloat){
               $startTask++;
            }
         }
         if ($twinlow>$nowfloat){ # weitere checks machen dann ohnehin
            last;                   # keine Sinn mehr
         }
      }
      if ($startTask){
         $reporter->addTask($self->Self,{maxstdout=>undef,maxstderr=>1024});
         $self->{lastrun}=NowStamp("en");
      }
   }
}


sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;
   return(1);
}


sub isViewValid
{
   my $reporter=shift;
   my $self=shift;
   my $rec=shift;
   return(1);
}


sub stdout              # will be called on stdout line output
{
   my $self=shift;
   my $line=shift;
   my $task=shift;
   my $reporter=shift;
   push(@{$task->{stdout}},$line);
   if (defined($task->{param}->{maxstdout})){
      if ($#{$task->{stdout}}>$task->{param}->{maxstdout}){
         shift(@{$task->{stdout}});
      }
   }
   #printf STDERR ("%s(OUT):%s\n",$self->Self,$line);
}

sub stderr             # will be called on stderr line output
{
   my $self=shift;
   my $line=shift;
   my $task=shift;
   my $reporter=shift;
   if (!($line=~m/^(INFO|DEBUG):/)){
      push(@{$task->{stderr}},$line);
      if (defined($task->{param}->{maxstderr})){
         if ($#{$task->{stderr}}>$task->{param}->{maxstderr}){
            shift(@{$task->{stderr}});
         }
      }
   }
}



sub Finish
{
   my $self=shift;
   my $task=shift;
   my $reporter=shift;


   if (ref($self->{fieldlist}) eq "ARRAY"){
      unshift(@{$task->{stdout}},join(";",@{$self->{fieldlist}}));
   }
   my $o=$reporter->{reportjob};
   $o->SetFilter({srcsys=>\$self->Self,srcid=>\'1'});
   my ($reportrec)=$o->getOnlyFirst(qw(ALL));

   my $d=join("\n",@{$task->{stdout}});

   my ($interval)=$self->getDefaultIntervalMinutes();
   my $validto=60*24;
   $validto=60*24*7 if ($interval>60*12);
   if ($validto<$interval){
      $validto=int(2.5*$interval);
   }
   $validto=$o->ExpandTimeExpression("now+${validto}m"),;

   my $name=$self->{name};
   $name=$self->Self if ($name eq "");
   my $newrec={
       textdata=>$d, name=>$name,
       srcsys=>$self->Self,srcid=>'1',srcload =>NowStamp("en")
   };
   if ($#{$task->{stderr}}!=-1){
      $newrec->{errbuffer}=join("\n",@{$task->{stderr}});
   }
   else{
      $newrec->{errbuffer}=undef;
   }
   if (!defined($newrec->{errbuffer}) ||
       $newrec->{errbuffer} eq ""){   # set new validto only if no errors
      $newrec->{validto}=$validto;    # are ocured
   }
   
   
   if (defined($reportrec) && $d eq $reportrec->{textdata}){
      $newrec->{mdate}=$reportrec->{mdate};
   }

   if (!defined($reportrec)){
      $o->ValidatedInsertRecord($newrec);
   }
   else{
      $o->ValidatedUpdateRecord($reportrec,$newrec,{id=>\$reportrec->{id}});
   }
}






1;
