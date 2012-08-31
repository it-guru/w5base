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
   my @errmsg;

   my $req=getModuleObject($self->Config,"tsbflexx::reviewreq");
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfact=getModuleObject($self->Config,"base::workflowaction");


   # search for interface defintion
   my $lnkapplappl=getModuleObject($self->Config,"itil::lnkapplappl"); 
   my $fromappl=$self->Config->Param("W5BaseApplicationName");
   my $toappl="b:flexx(P)";

   $lnkapplappl->SetFilter({fromappl=>\$fromappl,
                            toappl=>\$toappl,
                            conmode=>\'online',
                            conproto=>\'ODBC'});
   my @ifid=$lnkapplappl->getVal("id");
   if ($#ifid==-1){
      msg(ERROR,"no interface definition found in itil::lnkapplappl\n".
                "for connect from $fromappl to $toappl with ODBC online");
      msg(ERROR,"this interface is disabled");
      return({exitcode=>1,msg=>'missing interface definition'}); 
   }

   # calc "Interface Support" contacts
   my $lnkapplapplcomp=getModuleObject($self->Config,"itil::lnkapplapplcomp"); 

   $lnkapplapplcomp->SetFilter({lnkapplappl=>\@ifid,
                                comments=>'"Interface Support"'});
   my @to=();
   my @cc=();
   foreach my $ifcomp ($lnkapplapplcomp->getHashList(
                       qw(contactidto contactidcc))){
       if ($#{$ifcomp->{contactidto}}!=-1){
          push(@to,@{$ifcomp->{contactidto}});
       }
       if ($#{$ifcomp->{contactidcc}}!=-1){
          push(@cc,@{$ifcomp->{contactidcc}});
       }
   }

   # ok start operation
   my @wfid=@_;
   my %flt=(statusid=>\'0');

   if ($#wfid!=-1){
      if (grep(/^debug$/i,@wfid)){
         @wfid=grep(!/^debug$/i,@wfid);
         $self->{DebugMode}=1;
         msg(ERROR,"processing DebugMode - loading '%s'",join(",",@wfid));
      }
      $flt{w5baseid}=\@wfid;
   }


   $req->SetFilter(\%flt);
   my @okid=();

   $req->SetCurrentView(qw(id reason activity email w5baseid));
   my ($rec,$msg)=$req->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         if ($rec->{w5baseid}=~m/^\d+$/){
            $wf->ResetFilter();
            $wf->SetFilter({id=>\$rec->{w5baseid}});
            my ($WfRec)=$wf->getOnlyFirst(qw(ALL));
            if (defined($WfRec)){
               my $res=$self->ProcessWorkflow($wf,$wfact,\@errmsg,$WfRec,$rec);
               if (defined($res) && $res==1){
                  push(@okid,$rec->{id});
 
                  #push(@errmsg,"res=$res");
                  # add result to oplog, set state to 1 in review file
               }
            }
         }
         ($rec,$msg)=$req->getNext();
      } until(!defined($rec) || $#okid>5);
   }
   if ($#okid!=-1){
      push(@errmsg,"OK:".join(", ",@okid));
   }
   if ($#errmsg!=-1){
      $wfact->Notify("ERROR","$toappl interface problems",
                     "Meldungen:\n\n".join("\n\n",@errmsg),
                     adminbcc=>1,
                     xemailto=>\@to,
                     xemailcc=>\@cc);
   }
   if (!$self->{DebugMode}){
      $req=$req->Clone();
      $req->ResetFilter();
      $req->ValidatedUpdateRecord({},{statusid=>1},{id=>\@okid});
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

   if (ref($WfRec->{affectedapplicationid}) ne "ARRAY" ||
       $#{$WfRec->{affectedapplicationid}}==-1){
      push(@$errmsg,"no applications found in workflow ".
                    "workflow id $rec->{w5baseid} ".
                    "soo review is not posible");
      return(0);
   }
   my @applid=@{$WfRec->{affectedapplicationid}};


   msg(INFO,"handle %s",$rec->{w5baseid});
 #  push(@$errmsg,"try to handel Workflow $rec->{w5baseid} owner=$WfRec->{owner}");

   my $actions=$WfRec->{posibleactions};
   $actions=[$actions] if (ref($actions) ne "ARRAY");
   if (!grep(/^wfforcerevise$/,@$actions)){
      push(@$errmsg,"do not know, how to handle revise on $rec->{w5baseid}");
      return(0);
   }
   my $msg=$rec->{reason}."\n\n";
   $msg.="revise request from : B:Flexx\n";
   $msg.="further questions to: mailto:$rec->{email}" if ($rec->{email} ne "");
   my $bk=$wf->nativProcess("wfforcerevise",{
                            note=>$msg,
                            emailfrom=>$rec->{email}
                           },$rec->{w5baseid});
   if ($bk ne "1"){
      push(@$errmsg,"Unexpected result while processing W5Base workflow ".
                    "$rec->{w5baseid}\n owner=$WfRec->{owner} ".
                    "class=$WfRec->{class} res='$bk'");
   }
   return($bk);
}


1;
