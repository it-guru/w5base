package tscape::event::CapeNORtargetImport;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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


sub CapeNORtargetImport
{
   my $self=shift;
   my %param=@_;

   my $changedlimit=$param{changedlimit};
   $changedlimit=10 if ($changedlimit eq "");

   my $start=">now-3Y";
   my $srcsys="Cape";

   my $user=getModuleObject($self->Config,"base::user");
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $itno=getModuleObject($self->Config,"itil::itnormodel");
   if ($appl->isSuspended() ||
       $itno->isSuspended()){
      return({ exitcode=>0, msg=>'necessary objects suspended' });
   }
   $itno->SetFilter({cistatusid=>'4'});
   $itno->SetCurrentView(qw(id name));
   my $itnormodel=$itno->getHashIndexed("name");
   

   my $nor=getModuleObject($self->Config,"itil::appladv");
   my @norfields=qw( dstate dstateid cistatusid databossid modules comments
                     itnormodel itnormodelid
                     processingpersdata processingtkgdata scddata
                     srcsys srcid srcload );
   $nor->SetFilter({srcsys=>\$srcsys});
   $nor->Limit(1);
   my @l=$nor->getHashList(qw(srcload));
   if ($#l!=-1){
      $start=">=\"$l[0]->{srcload}\"-3d";
   }
   msg(INFO,"start='$start'");


   my $nortarget=getModuleObject($self->Config,"tscape::nortarget");
   if ($nortarget->isSuspended()){
      return({ exitcode=>0, msg=>'necessary objects suspended' });
   }
   $nortarget->SetCurrentOrder("mdate");
   $nortarget->SetCurrentView(qw(ALL));
   if (!exists($param{debug})){
      $nortarget->SetFilter({mdate=>$start,nortargetdefined=>\'1'});
   }
   else{
      $nortarget->SetFilter({w5baseid=>$param{debug},nortargetdefined=>\'1'});
   }
   my $downgrade=0;
   my $unchanged=0;
   my $changed=0;

   my ($nrec,$msg)=$nortarget->getFirst(unbuffered=>1);
   if (defined($nrec)){
      do{
         #print Dumper($nrec);
         my $applid=$nrec->{w5baseid};
         $appl->ResetFilter();
         $appl->SetFilter({id=>\$applid});
         my ($applrec)=$appl->getOnlyFirst(qw(id));
         if (!defined($applrec)){
            msg(WARN,"skip not existing w5baseid for appl $applid");
         }
         else{
            my $oldnordoc;
            $nor->ResetFilter();
            $nor->SetFilter({srcparentid=>\$nrec->{w5baseid},
                             isactive=>'1',dstate=>\'20'});
            ($oldnordoc)=$nor->getOnlyFirst(qw(ALL));

            $nor->ResetFilter();
            $nor->SetFilter({srcparentid=>\$nrec->{w5baseid},
                             isactive=>'1'});
            my @w5norlist=$nor->getHashList(@norfields);
            if ($#w5norlist!=0){
               msg(ERROR,"missing active nor target docuument ".
                         "for w5baseid=$nrec->{w5baseid} ".
                         "application=$nrec->{appl} ictoid=$nrec->{archapplid}");
               $nor->ResetFilter();
               $nor->SetFilter({srcparentid=>\$nrec->{w5baseid},
                                dstate=>'10'});
               @w5norlist=$nor->getHashList(@norfields);
               if ($#w5norlist!=0){
                   msg(ERROR,"also missing auto created nor target docuument ".
                             "application=$nrec->{appl}");
                  die();
               }
           }
           # Compare       W5Base              Cape
           #
           #               itnormodel          itnormodel
           #               processingpersdata  persdata
           #               processingtkgdata   tkdata
           # 
           # Deltas on these informations are trigger to create a news
           # appladv document based on cape data
           my @changes;
           if ($w5norlist[0]->{itnormodel} ne $nrec->{itnormodel}){
              push(@changes,$self->T("NOR-Target"));
           }
           if ($w5norlist[0]->{processingpersdata} ne $nrec->{persdata}){
              push(@changes,$self->T("Personal Data"));
           }
           if ($w5norlist[0]->{processingtkgdata}  ne $nrec->{tkdata}){
              push(@changes,$self->T("Telecommunication Data"));
           }
           if ($#changes!=-1){
              if ($nrec->{itnormodel} eq "S" &&
                  $w5norlist[0]->{itnormodel} ne "S"){
                 $downgrade++;
              }
              my $uid=undef;
              if ($nrec->{cnfciam} ne ""){
                 $uid=$user->GetW5BaseUserID($nrec->{cnfciam},"dsid");
              }
              if ($nrec->{cnfciam} eq "" || $uid eq ""){
                 # msg(ERROR,"can not import CIAM ID $nrec->{cnfciam} for ".
                 #           "NOR Target $nrec->{appl}");
                 # Stacktrace();
              }
              my $nmodid=$itnormodel->{name}->{$nrec->{itnormodel}}->{id};
              msg(INFO,"NOR Model update for $nrec->{appl} ".
                       "from $w5norlist[0]->{itnormodel} ".
                       "to $nrec->{itnormodel} (nmodid=$nmodid)");
              $appl->ResetFilter();
              $appl->SetFilter({id=>$nrec->{w5baseid},cistatusid=>"<6"});
              my ($arec)=$appl->getOnlyFirst(qw(ALL));
              if (defined($arec) && $nmodid ne ""){
                 $nor->ResetFilter();
                 $nor->SetFilter({srcparentid=>\$nrec->{w5baseid},
                                  dstate=>'10'});
                 my ($autorec)=$nor->getHashList(qw(ALL));
                 if (!defined($autorec) || $autorec->{id} eq ""){
                    msg(WARN,"auto create adv record for $nrec->{appl}");
                    $nor->ValidatedInsertRecord({
                       parentid=>$nrec->{w5baseid},
                       rawisactive=>undef
                    }); # create missing autorecord
                    $nor->ResetFilter();
                    $nor->SetFilter({srcparentid=>\$nrec->{w5baseid},
                                     dstate=>'10'});
                    ($autorec)=$nor->getHashList(qw(ALL));
                 }
                 my $newrec={
                    itnormodelid=>$nmodid,
                    processingpersdata=>$nrec->{persdata},
                    processingtkgdata=>$nrec->{tkdata},
                    owner=>$uid,
                    comments=>"AutoImport based on ...\n".
                              $nrec->{urlofcurrentrec}
                 };
                 if (!exists($param{debug})){
                    $newrec->{srcsys}=$srcsys;
                    $newrec->{srcload}=$nrec->{mdate};
                 }
                 if ($uid){
                    $newrec->{owner}=$uid;
                 }
                 if ($nor->ValidatedUpdateRecord($autorec,$newrec,
                                                 {id=>\$autorec->{id}})) {
                    my @emailcc=();
                    if ($arec->{haveitsem}) {
                       push(@emailcc,$arec->{itsemid});
                       push(@emailcc,$arec->{itsem2id});
                    }
                    else {
                       push(@emailcc,$arec->{semid});
                       push(@emailcc,$arec->{sem2id});
                    }
          
                    $appl->NotifyWriteAuthorizedContacts($arec,{},{
                          emailcc=>\@emailcc
                       },
                       {
                          autosubject=>1,
                          datasource=>'Cape CNDB'
                       },
                       sub{
                          my $ntext=$self->T("Dear databoss",'kernel::QRule');
                          $ntext.=",\n\n";
                          $ntext.=sprintf(
                                  $self->T("based on informations from Cape ".
                                           "(NOR Pass/VVZ of %s), ".
                                           "the following attribute/s has/have been ".
                                           "changed and a new NOR-Target document ".
                                           "for the application %s  has been created:"),
                                           $nrec->{archapplid},$arec->{name});
                          $ntext.="\n\n";
                          $ntext.=join("\n",@changes);
                          $ntext.="\n\n";
                          $ntext.=$self->T("new NOR-Target document:");
                          $ntext.="\n";
                          $ntext.=$autorec->{urlofcurrentrec};
                          $ntext.="\n";
                          $ntext.="\n";
                          if (defined($oldnordoc)){
                             $ntext.="\n";
                             $ntext.=$self->T("The former NOR-Target document");
                             $ntext.="...\n";
                             $ntext.=$oldnordoc->{urlofcurrentrec};
                             $ntext.="\n.... ";
                             $ntext.=$self->T("has been archived.");
                          }
                          return($arec->{name},$ntext);
                       }
                    );
                 }
              } 
              $changed++;
           }
           else{
              $unchanged++;
           }
         }
         ($nrec,$msg)=$nortarget->getNext();
      }until(!defined($nrec) || $changed>$changedlimit);
   }

   return({
      exitcode=>0,
      msg=>'ok',
      downgrade=>$downgrade,
      unchanged=>$unchanged,
      changed=>$changed
   });
}

1;
