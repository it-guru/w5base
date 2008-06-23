package base::event::w5stat;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use Data::Dumper;
use kernel;
use kernel::date;
use kernel::Event;
@ISA=qw(kernel::Event);

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


   $self->RegisterEvent("w5stat","w5stat",timeout=>21600);
   $self->RegisterEvent("w5statsend","w5statsend");
   return(1);
}

sub w5stat
{
   my $self=shift;
   my $month=shift;

   if (!defined($month)){
      my ($year,$mon,$day, $hour,$min,$sec) = Today_and_Now("GMT");
      $month=sprintf("%04d%02d",$year,$mon);
   }

   my $stat=getModuleObject($self->Config,"base::w5stat");

   $stat->recreateStats("w5stat",$month);

   return({exitcode=>0});
}

sub w5statsend
{
   my $self=shift;
   my $user=getModuleObject($self->Config,"base::user");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $ia=getModuleObject($self->Config,"base::infoabo");
   my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
   my $lnkrole=getModuleObject($self->Config,"base::lnkgrpuserrole");

   $grp->SetFilter({cistatusid=>[3,4]});
   $grp->SetCurrentView(qw(grpid fullname));
   my ($rec,$msg)=$grp->getFirst();
   if (defined($rec)){
      do{
         my $emailto={};
         $lnkgrp->ResetFilter();
         $lnkgrp->SetFilter({grpid=>\$rec->{grpid}});
         my @RBoss;
         my @RReportReceive;
         foreach my $lnkrec ($lnkgrp->getHashList(qw(userid lnkgrpuserid))){
            $lnkrole->ResetFilter();
            $lnkrole->SetFilter({lnkgrpuserid=>\$lnkrec->{lnkgrpuserid}});
            foreach my $lnkrolerec ($lnkrole->getHashList("role")){
               if ($lnkrolerec->{role} eq "RBoss"){
                  push(@RBoss,$lnkrec->{userid});
               }
               if ($lnkrolerec->{role} eq "RReportReceive"){
                  push(@RReportReceive,$lnkrec->{userid});
               }
            }
         }
         $ia->LoadTargets($emailto,'base::staticinfoabo',\'STEVqreportbyorg',
                                   '110000002',\@RBoss,default=>1);
         $user->ResetFilter();
         $user->SetFilter({userid=>\@RReportReceive,cistatusid=>'<=4'});
         foreach my $urec ($user->getHashList("email")){
            if ($urec->{email} ne ""){
               $emailto->{$urec->{email}}++;
            }
         }
         if (keys(%$emailto)){
msg(INFO,"email=".Dumper($emailto));

            msg(INFO,"process group $rec->{fullname}($rec->{grpid})");
         }
         ($rec,$msg)=$grp->getNext();
      }until(!defined($rec));
   }

   

   return({exitcode=>0});
}

1;
