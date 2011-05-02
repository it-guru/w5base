package sandbox::event::sample;
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


   $self->RegisterEvent("rangetest","rangetest");
   $self->RegisterEvent("usertest","usertest");
   return(1);
}

sub usertest
{
   my $self=shift;
   my $user=getModuleObject($self->Config,"base::user");

   $user->SetFilter({fullname=>"Vogle*"});
   my ($urec)=$user->getOnlyFirst(qw(fullname));

   printf STDERR ("d=%s\n",Dumper($urec));





}


sub rangetest
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfrange=getModuleObject($self->Config,"sandbox::wfrange");

   $wf->SetCurrentView(qw(id eventstart eventend));
   $wf->SetCurrentOrder(qw(NONE));
#   $wf->Limit(100);

   my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         my $eventstart=$wf->ExpandTimeExpression($rec->{eventstart},
                                                  "unixtime","GMT","GMT");
         my $eventend=$wf->ExpandTimeExpression($rec->{eventend},
                                                  "unixtime","GMT","GMT");
         $wfrange->ValidatedInsertOrUpdateRecord(
                   {wfheadid=>$rec->{id},
                    range=>[$eventstart,0,$eventend,0]},
                   {wfheadid=>\$rec->{id}});
         $wfrange->ResetFilter();
         $wfrange->SetFilter({wfheadid=>\$rec->{id}});
         my ($rrec)=$wfrange->getOnlyFirst(qw(ALL));
         my $rangeobj=$wfrange->getField("range",$rrec);
         my $r=$rangeobj->RawValue($rrec);
         printf STDERR ("fifi rrec=%s\nr=%s\n",Dumper($rrec),Dumper($r));
         
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }

   return({exitcode=>0,msg=>'ok'});
}





1;
