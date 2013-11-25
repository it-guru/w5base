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
      $reporter->addTask($self->Self,{maxstdout=>1024,maxstderr=>1024});
      my $o=$Reporter->{reportjob};
      $o->SetFilter({srcsys=>[$self->Self],srcid=>[$self->Self]});
      my ($reportrec)=$o->getOnlyFirst(qw(ALL));
      $self->{lastrun}=NowStamp("en");
   }
   my $d=CalcDateDuration($self->{lastrun},NowStamp("en"));
   if ($d->{totalminutes}>$self->getDefaultIntervalMinutes()){
      $reporter->addTask($self->Self,{maxstdout=>1024,maxstderr=>1024});
      $self->{lastrun}=NowStamp("en");
   }
}


sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;
   return(1);
}


sub stdout              # will be called on stdout line output
{
   my $self=shift;
   my $line=shift;
   my $task=shift;
   my $reporter=shift;
   push(@{$task->{stdout}},$line);
   if ($#{$task->{stdout}}>$task->{param}->{maxstdout}){
      shift(@{$task->{stdout}});
   }
   #printf STDERR ("%s(OUT):%s\n",$self->Self,$line);
}

sub stderr             # will be called on stderr line output
{
   my $self=shift;
   my $line=shift;
   my $task=shift;
   my $reporter=shift;
   #printf STDERR ("%s(ERR):%s\n",$self->Self,$line);
   push(@{$task->{stderr}},$line);
   if ($#{$task->{stderr}}>$task->{param}->{maxstderr}){
      shift(@{$task->{stderr}});
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

   my $interval=$self->getDefaultIntervalMinutes();
   my $validto=60*24;
   $validto=60*24*7 if ($interval>60*12);
   if ($validto<$interval){
      $validto=int(2.5*$interval);
   }
   $validto=$o->ExpandTimeExpression("now+${validto}m"),;

   my $name=$self->{name};
   $name=$self->Self if ($name eq "");
   my $newrec={
       textdata=>$d, name=>$name, validto=>$validto,
       srcsys=>$self->Self,srcid=>'1',srcload =>NowStamp("en")
   };
   
   
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
