package tsbflexx::event::processWorkflowReviews;
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

   $self->RegisterEvent("processWorkflowReviews","processWorkflowReviews");
   return(1);
}

sub processWorkflowReviews
{
   my $self=shift;

   my $req=getModuleObject($self->Config,"tsbflexx::reviewreq");
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfact=getModuleObject($self->Config,"base::workflowaction");

   my @errmsg;
   $req->SetFilter({status=>\'0'});

   $req->SetCurrentView(qw(reason activity w5baseid));
   my ($rec,$msg)=$req->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         if ($rec->{w5baseid}=~m/^\d+$/){
            $wf->ResetFilter();
            $wf->SetFilter({id=>\$rec->{w5baseid}});
            my ($WfRec)=$wf->getOnlyFirst(qw(ALL));
            if (defined($WfRec)){
               my $res=$self->ProcessWorkflow($wf,$wfact,\@errmsg,$WfRec,$rec);
               if (defined($res)){
                  # add result to oplog, set state to 1 in review file
               }
            }
            else{
              push(@errmsg,"workflow id $rec->{w5baseid} ".
                           "not found in w5base workflow engined");
            }
         }
         ($rec,$msg)=$req->getNext();
      } until(!defined($rec));
   }

   return({exitcode=>0}); 
}

sub ProcessWorkflow
{
   my $self=shift;
   my $wf=shift;
   my $wfact=shift;
   my $errmsg=shift;
   my $WfRec=shift;
   my $rec=shift;

   if (!($WfRec->{class}=~m/^AL_TCom.*$/)){
      push(@$errmsg,"can not review workflow id $rec->{w5baseid} ".
                    "in workflow class $WfRec->{class}");
      return();
   }
   if (ref($WfRec->{affectedapplicationid}) ne "ARRAY" ||
       $#{$WfRec->{affectedapplicationid}}==-1){
      push(@$errmsg,"no applications found in workflow ".
                    "workflow id $rec->{w5baseid} ".
                    "soo review is not posible");
      return();
   }
   my @applid=@{$WfRec->{affectedapplicationid}};


   msg(INFO,"handle %s",$rec->{w5baseid});
   $wfact->ValidatedInsertRecord({
      wfheadid=>$rec->{w5baseid},
      translation=>'tsbflexx::reviewreq',
      name=>'bflexxmessage',
      comments=>$rec->{reason}
   });
   exit(0);

}


1;
