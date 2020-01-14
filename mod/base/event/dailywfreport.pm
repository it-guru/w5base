package base::event::dailywfreport;
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
use kernel::Event;
use kernel::Wf;
use kernel::Field::Date;
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

   $self->RegisterEvent("dailywfreport","dailywfreport");
   return(1);
}

sub dailywfreport
{
   my $self=shift;
   my %param=@_;
   $param{hours}=1  if ($param{hours}<1);
   $param{hours}=72 if ($param{hours}>72);

   my $user=getModuleObject($self->Config,"base::user");
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $ia=getModuleObject($self->Config,"base::infoabo");
   my $ac=getModuleObject($self->Config,"base::workflowaction");


   $wf->SetFilter({mdate=>">now-$param{hours}h",isdeleted=>\'0'});
   msg(INFO,"collecting data");
   my @wflist=$wf->getHashList(qw(mdate id class affectedapplicationid 
                                  affectedapplication affectedsystem
                                  affectedsystemid));
   msg(INFO,"workflow list loaded - %d records found",$#wflist);
   #msg(INFO,"d=%s\n",Dumper(\@wflist));
   $ia->SetFilter({rawmode=>'daily_*',active=>\'1'});
   my %user=();
   # comperators collect
   my @comperator=();
   foreach my $ia (values(%{$ia->{infoabo}})){
      push(@comperator,$ia) if ($ia->can("dailywfreportCompare"));
   }
   foreach my $irec ($ia->getHashList(qw(parentobj refid userid mode))){
      foreach my $wfrec (reverse(@wflist)){
         my $dorep=0;
         foreach my $comperator (@comperator){
            $dorep+=$comperator->dailywfreportCompare($irec,$wfrec);
            last if ($dorep);
         }
         if ($dorep){
            if (defined($user{$irec->{userid}})){
               if (!grep(/^$wfrec->{id}$/,@{$user{$irec->{userid}}})){
                  push(@{$user{$irec->{userid}}},$wfrec->{id});
               }
            } 
            else{
               $user{$irec->{userid}}=[$wfrec->{id}];
            }
         }
      }
   }
   msg(INFO,"information routing finished");

   foreach my $userid (keys(%user)){
      my (@emailtstamp,@emailpostfix,@emailsubheader,@emailhead,@emailtext,
          @emailbottom,@emailprefix);

      $user->ResetFilter();
      $user->SetFilter({userid=>\$userid});
      my ($urec,$msg)=$user->getOnlyFirst(qw(email cistatusid tz lastlang));
      if (defined($urec) && $urec->{cistatusid}<=4){
         if ($urec->{lastlang} ne ""){
            $ENV{HTTP_FORCE_LANGUAGE}=$urec->{lastlang};
         }
         my $subject="daily Workflow activity report";
         foreach my $wfheadid (@{$user{$userid}}){
            addWorkflow2Mail($self->getParent,
                         $wf,$user,$wfheadid,
                         {mode=>"dailywfreport",tz=>$urec->{tz},
                          hours=>$param{hours}},
                         \@emailhead,\@emailsubheader,
                         \@emailprefix,\@emailtstamp,\@emailtext,\@emailpostfix,
                         \@emailbottom);
         }
         msg(DEBUG,"translation=%s lang=$ENV{HTTP_FORCE_LANGUAGE}",$self->Self);
         my $subject=$self->getParent->T("daily Workflow activity report",
                                         $self->Self);
         my @emailto=($urec->{email});
     
         ###################################################
         my $sitename=$self->Config->Param("SITENAME");
         if ($sitename ne ""){
            $subject=$sitename.": ".$subject;
         }
         my $from=$self->Config->Param("DEFAULTFROM");
         $sitename="W5Base" if ($sitename eq "");
         my $fromemail='"'.$sitename.'" <>';
         ###################################################
         if (my $id=$wf->Store(undef,{
                               class =>'base::workflow::mailsend',
                               step  =>'base::workflow::mailsend::dataload',
                               name  =>$subject,
                               emailfrom      =>$fromemail,
                               emailto        =>\@emailto,
                               emailtstamp    =>\@emailtstamp,
                               emailpostfix   =>\@emailpostfix,
                               emailhead      =>\@emailhead,
                               emailsubheader =>\@emailsubheader,
                               emailtemplate  =>"base/dailywfreport",
                               emailtext      =>\@emailtext})){
            my %d=(step=>'base::workflow::mailsend::waitforspool');
            my $r=$wf->Store($id,%d);
         }
         delete($ENV{HTTP_FORCE_LANGUAGE});
      }
   }
   #msg(DEBUG,"d=%s",Dumper(\%user));
   return({exitcode=>'0'});
}




1;
