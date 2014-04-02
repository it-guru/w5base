package AL_TCom::event::analyseApplMgr;
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
use kernel;
use kernel::date;
use kernel::Event;
use kernel::database;
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


   $self->RegisterEvent("analyseApplMgr","analyseApplMgr");
   return(1);
}

sub analyseApplMgr
{
   my $self=shift;
   my $user=getModuleObject($self->Config,"base::user");
   my $wiwuser=getModuleObject($self->Config,"tswiw::user");
   my $cape=getModuleObject($self->Config,"tscape::archappl");

   $cape->SetCurrentView(qw(fullname archapplid applmgremail organisation));
   $cape->SetFilter({status=>"!Retired"});
   #$cape->Limit(50);

   my %msg;

   my ($rec,$msg)=$cape->getFirst();
   if (defined($rec)){
      do{
         if ($rec->{applmgremail} ne ""){
            $wiwuser->ResetFilter();
            $wiwuser->SetFilter({email=>$rec->{applmgremail}});
            my ($wiwurec,$msg)=$wiwuser->getOnlyFirst(qw(office_orgunit)); 
            if (!defined($wiwurec)){
               my $chkmail=$rec->{applmgremail};
               if ($rec->{applmgremail}=~m/\@t-systems\.com$/){
                  $chkmail=~s/\@t-systems\.com$/\@telekom.de/;
               }
               if ($rec->{applmgremail}=~m/\@telekom\.de$/){
                  $chkmail=~s/\@telekom\.de$/\@t-systems.com/;
               }
               $wiwuser->ResetFilter();
               $wiwuser->SetFilter({email=>$chkmail});
               ($wiwurec)=$wiwuser->getOnlyFirst(qw(office_orgunit)); 
            }
            if (!defined($wiwurec)){
               if ($rec->{organisation}=~m/ T-TI /){
                  $msg{"Application Manager $rec->{applmgremail} ".
                       "for $rec->{archapplid} not found in WhoIsWho"}++;
               }
            }
            else{
               if ($wiwurec->{office_orgunit}=~m/^E-/){
                  $user->ResetFilter();
                  $user->SetFilter({email=>$rec->{applmgremail}});
                  my ($w5urec,$msg)=$user->getOnlyFirst(qw(cistatusid)); 
                  $self->validateTelITApplication(\%msg,
                                                  $rec->{fullname},
                                                  $rec->{archapplid},
                                                  $rec->{applmgremail},
                                                  $rec->{organisation},
                                                  $wiwurec);
               }
            }
         }
         ($rec,$msg)=$cape->getNext();
      } until(!defined($rec));
   }
   if (open(F,">analyseApplMgr.csv")){
      foreach my $msg (sort(keys(%msg))){
         printf F ("- %s\n\n",$msg);

      }
   }
   close(F);
   return({exitcode=>0});
}

sub validateTelITApplication
{
   my $self=shift;
   my $msg=shift;
   my $fullname=shift;
   my $ictoid=shift;
   my $applmgremail=shift;
   my $organisation=shift;
   my $wiwurec=shift;

   my ($solution)=$wiwurec->{office_orgunit}=~m/^(\S-\S\S\S).*$/;

   my $m=$self->getPersistentModuleObject("base::mandator");

   # Mandanten bestimmen
   my $w5group="DTAG.TSI.TI.".$solution;
   $m->SetFilter({groupname=>\$w5group});
   my ($mrec)=$m->getOnlyFirst(qw(ALL)); 

   my $appl=$self->getPersistentModuleObject("AL_TCom::appl");

   $appl->SetFilter({ictono=>\$ictoid,cistatusid=>"<=5"});
   my @arec=$appl->getHashList(qw(mandatorid name));

   msg(INFO,"process: $fullname");
   msg(INFO,"         * $applmgremail");
   msg(INFO,"         * $wiwurec->{office_orgunit}");
   msg(INFO,"         * Soution: $solution");
   msg(INFO,"         * W5Group: $w5group");
   msg(INFO,"         * Mandant: $mrec->{name}");
   msg(INFO,"         * Appl-Count: ".($#arec+1));

   if ($#arec==-1){
      if ($organisation=~m/ T-IT /){
         $msg->{"No Applications for ICTO-Object $ictoid from ".
                "ApplicationManager $applmgremail in '$mrec->{name}'".
                ";$ictoid;$applmgremail;$solution"}++;
      }
   }
   else{
      foreach my $arec (@arec){
         if ($arec->{mandatorid} ne $mrec->{grpid}){
            $msg->{"Mandator of Application $arec->{name} ($arec->{mandator}) ".
                   "did not match Solution of ApplicationManager".
                   ";$ictoid;$applmgremail;$solution"}++;

         }
      }
   }

}



1;
