package AL_TCom::event::ApplicationWorkflowXLSRep;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
#  based on Request ...
#  https://darwin.telekom.de/darwin/auth/base/workflow/ById/14128586800001

use strict;
use vars qw(@ISA);
use kernel;
use kernel::Event;
use kernel::date;
use kernel::Field;
use kernel::XLSReport;

@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub ApplicationWorkflowXLSRep
{
   my $self=shift;
   my %param=@_;
   my %flt;
   $ENV{LANG}="de";


   if ($param{'timezone'} eq ""){
      $param{'timezone'}="CET"
   }
   if ($param{'year'} eq ""){
      my ($year,$month,$day, $hour,$min,$sec)=Today_and_Now($param{'timezone'});
      $param{'year'}=$year;
   }
   my $year=$param{'year'};

   if ($param{'filename'} eq ""){
      $param{'filename'}="/tmp/ApplicationWorkflowXLSRep.xls";
   }
#   msg(INFO,"start Report to $param{'filename'}");
#   my $t0=time();
   my $appl=getModuleObject($self->Config,"TS::appl");

   $appl->AddFields(
      new kernel::Field::Number(
                name          =>'NUMchm',
                label         =>'Anzahl geschlossener Changes '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMinm',
                label         =>'Anzahl geschlossener Incidents '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMprm',
                label         =>'Anzahl geschlossener Problems '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMdi',
                label         =>'Anzahl geschlossener DataIssues '.$year,
                xlswidth      =>10),
   );

   my $grpteam=getModuleObject($self->Config,"base::grp");

   $grpteam->AddFields(
      new kernel::Field::Number(
                name          =>'NUMchm',
                label         =>'Anzahl geschlossener Changes '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMinm',
                label         =>'Anzahl geschlossener Incidents '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMprm',
                label         =>'Anzahl geschlossener Problems '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMdi',
                label         =>'Anzahl geschlossener DataIssues '.$year,
                xlswidth      =>10),
   );


   my $grpsol=getModuleObject($self->Config,"base::grp");



   $grpsol->AddFields(
      new kernel::Field::Number(
                name          =>'NUMchm',
                label         =>'Anzahl geschlossener Changes '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMinm',
                label         =>'Anzahl geschlossener Incidents '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMprm',
                label         =>'Anzahl geschlossener Problems '.$year,
                xlswidth      =>10),

      new kernel::Field::Number(
                name          =>'NUMdi',
                label         =>'Anzahl geschlossener DataIssues '.$year,
                xlswidth      =>10),
   );





   my @control;
   push(@control,
      {
         sheet=>'Anwendungereport',
         DataObj=>$appl,
         recPreProcess=>\&recPreProcess,
         filter=>{cistatusid=>\'4',
             #     name=>'W*',
                  mandator=>"!Extern !Sec*"},
         unbuffered=>0,  # unbuffered führt zu Problemen, wenn ein gefitertes
                         # feld gleichzeitig in der Ausgabe view steht!
         view=>['name',
                'cistatus',
                'businessteam',
                'mandator','ictono',
                'applid',
                'tsm','applmgr',
                'customer','customerprio','criticality',
                'NUMchm','NUMinm','NUMprm','NUMdi',
                'acinmassingmentgroup',
                'applgroup',
                'id'
         ]
      },
      {
         sheet=>'Teamactivity',
         DataObj=>$grpteam,
         recPreProcess=>\&recPreTeamProcess,
         filter=>{cistatusid=>\'4'},
         view=>['fullname',
                'NUMchm','NUMinm','NUMprm','NUMdi',
         ]
      },
      {
         sheet=>'Solutionactivity',
         DataObj=>$grpsol,
         recPreProcess=>\&recPreSolProcess,
         filter=>{cistatusid=>\'4'},
         view=>['fullname',
                'NUMchm','NUMinm','NUMprm','NUMdi',
         ]
      },
   );

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   $self->{year}=$year;
   $out->Process(@control);
   return({exitcode=>0,msg=>'OK'});
}

sub recPreTeamProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;

   $rec->{NUMchm}=0;
   $rec->{NUMinm}=0;
   $rec->{NUMprm}=0;
   $rec->{NUMdi}=0;
   if (exists($self->{GROUP}->{$rec->{grpid}})){
      $rec->{NUMchm}=$self->{GROUP}->{$rec->{grpid}}->{NUMchm};
      $rec->{NUMinm}=$self->{GROUP}->{$rec->{grpid}}->{NUMinm};
      $rec->{NUMprm}=$self->{GROUP}->{$rec->{grpid}}->{NUMprm};
      $rec->{NUMdi}=$self->{GROUP}->{$rec->{grpid}}->{NUMdi};
      return(1);
   }

   return(0);
}

sub recPreSolProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;

   $rec->{NUMchm}=0;
   $rec->{NUMinm}=0;
   $rec->{NUMprm}=0;
   $rec->{NUMdi}=0;
   if (exists($self->{SOL}->{$rec->{grpid}})){
      $rec->{NUMchm}=$self->{SOL}->{$rec->{grpid}}->{NUMchm};
      $rec->{NUMinm}=$self->{SOL}->{$rec->{grpid}}->{NUMinm};
      $rec->{NUMprm}=$self->{SOL}->{$rec->{grpid}}->{NUMprm};
      $rec->{NUMdi}=$self->{SOL}->{$rec->{grpid}}->{NUMdi};
      return(1);
   }

   return(0);
}

sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;
   my $year=$self->{year};
   my $w=$DataObj->getRelatedWorkflows($rec->{id},{
      timerange=>"(".$year.")",
      limit=>10000
   });
   $rec->{NUMdi}=undef;
   $rec->{NUMchm}=undef;
   $rec->{NUMinm}=undef;
   $rec->{NUMprm}=undef;
   if (keys(%$w)!=0){
      $rec->{NUMdi}=0;
      $rec->{NUMchm}=0;
      $rec->{NUMinm}=0;
      $rec->{NUMprm}=0;
   }
   foreach my $wf (values(%$w)){
      if ($wf->{class}=~m/::change$/){
         $rec->{NUMchm}++;
         $self->{GROUP}->{$rec->{businessteamid}}->{NUMchm}++;
         $self->{SOL}->{$rec->{mandatorid}}->{NUMchm}++;
      }
      if ($wf->{class}=~m/::incident$/){
         $rec->{NUMinm}++;
         $self->{GROUP}->{$rec->{businessteamid}}->{NUMinm}++;
         $self->{SOL}->{$rec->{mandatorid}}->{NUMinm}++;
      }
      if ($wf->{class}=~m/::problem$/){
         $rec->{NUMprm}++;
         $self->{GROUP}->{$rec->{businessteamid}}->{NUMprm}++;
         $self->{SOL}->{$rec->{mandatorid}}->{NUMprm}++;
      }
      if ($wf->{class}=~m/::DataIssue$/){
         $rec->{NUMdi}++;
         $self->{GROUP}->{$rec->{businessteamid}}->{NUMdi}++;
         $self->{SOL}->{$rec->{mandatorid}}->{NUMdi}++;
      }
   }
   return(1);
}





1;
