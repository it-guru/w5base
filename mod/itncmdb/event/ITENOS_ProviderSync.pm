package itncmdb::event::ITENOS_ProviderSync;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
use Digest::MD5 qw(md5_base64);
@ISA=qw(kernel::Event);



sub ITENOS_ProviderSync
{
   my $self=shift;
   my $queryparam=shift;

   my @O=qw(
      itil::asset TS::system TS::appl
      itil::lnkapplsystem
      itncmdb::system itncmdb::asset
   );
   my $O={};

   my $staleRetry;
   my $ast="2h";    # allowed stale time
   my $ast=undef;   # no allowed stale time
   my $initBk=$self->robustEventObjectInitialize(\$staleRetry,$ast,$O,@O);
   return($initBk) if ($initBk);

   my $SRCSYS=$O->{'itncmdb::system'}->{SRCSYS};
   my $AssetW5BaseID=$O->{'itncmdb::asset'}->getPrimaryAssetW5BaseID();

   if (!defined($AssetW5BaseID)){
      return({
         exitcode=>1,
         exitmsg=>'ITENOS AssetID can not be detected'
      });
   }

   $O->{'itncmdb::system'}->ResetFilter();
   $O->{'itncmdb::system'}->SetFilter({id=>'73DC1B2U2R4M3U'});
   my @l= $O->{'itncmdb::system'}->getHashList(qw(id));
   if ($#l>0){
      return({
         exitcode=>1,
         exitmsg=>'ITENOS logical system Access '.
                  'to ID 73DC1B2U2R4M3U not unique'
      });
   }



   $O->{'itncmdb::system'}->ResetFilter();
   $O->{'itncmdb::system'}->SetFilter({});
   $O->{'itncmdb::system'}->SetCurrentView(qw(id systemname name applw5baseid));
  
   my $remoteSys=$O->{'itncmdb::system'}->getHashIndexed(qw(id));

   my @curIDs=keys(%{$remoteSys->{id}});

   $O->{'TS::system'}->ResetFilter();
   $O->{'TS::system'}->SetFilter({srcid=>\@curIDs,srcsys=>\$SRCSYS});
   $O->{'TS::system'}->SetCurrentView(qw(id name cistatusid srcsys srcid));
   my $cur=$O->{'TS::system'}->getHashIndexed(qw(id srcid));

   foreach my $itncmdbid (@curIDs){
      
      my $ApplW5BaseID;
      my $systemname;
      msg(INFO,"processing ITNCMDID: $itncmdbid");
      if (ref($remoteSys->{id}->{$itncmdbid}) eq "ARRAY"){
         msg(ERROR,"structure error while loading ITENOS ITNCMDBID $itncmdbid ".
                  "- ID not unique");
         next;
      }
      if (ref($remoteSys->{id}->{$itncmdbid}) eq "HASH"){
         $ApplW5BaseID=$remoteSys->{id}->{$itncmdbid}->{applw5baseid};
         $systemname=$remoteSys->{id}->{$itncmdbid}->{systemname};
         msg(INFO,"start handling of $systemname for ApplW5BaseID: ".
                  "$ApplW5BaseID");
      }
      my $identifyby;
      if (!exists($cur->{srcid}->{$itncmdbid})){
         msg(INFO,"try to insert $itncmdbid");
         $O->{'TS::appl'}->ResetFilter();
         $O->{'TS::appl'}->SetFilter({id=>$ApplW5BaseID,cistatusid=>[3,4,5]});
         my ($ApplW5BaseRec)=$O->{'TS::appl'}->getOnlyFirst(qw(ALL));
         if (!defined($ApplW5BaseRec)){
            msg(ERROR,"invalid ApplW5BaseID specified in $systemname - ".
                      "import rejected");
            next;
         }
         my $isITENOSapp=0;
         {
            my $kwords=$ApplW5BaseRec->{kwords};
            my @kwords=split(/[\s;,]+/,$kwords);
            if (in_array(\@kwords,"ITENOS")){
               $isITENOSapp=1;
            }
         }

         my $w5baseid;
         $O->{'TS::system'}->ResetFilter();
         $O->{'TS::system'}->SetFilter({
            name=>\$systemname
         });
         my ($chkrec)=$O->{'TS::system'}->getOnlyFirst(qw(ALL));
         my $isImported=0;
         if (defined($chkrec)){
            my $applMatch=0;
            foreach my $applrec (@{$chkrec->{applications}}){
               if ($applrec->{applid} eq $ApplW5BaseID){
                  $applMatch++;
                  last;
               }
            }
            if ($applMatch){
               $O->{'TS::system'}->ValidatedUpdateRecord($chkrec,
                   {cistatusid=>'4',srcsys=>$SRCSYS,srcid=>$itncmdbid},
                   {id=>\$chkrec->{id}}
               );
               $isImported=1;
            }
            else{
               msg(ERROR,"W5Base system $systemname not matches ".
                         "application in itncmdb - import rejected");
            }
         }

         if (!$isImported){
            if ($isITENOSapp){
               msg(INFO,"start ValidatedInsertRecord $systemname");
               my $nSys={
                  name=>$systemname,
                  cistatusid=>'4',
                  mandatorid=>$ApplW5BaseRec->{mandatorid},
                  databossid=>$ApplW5BaseRec->{databossid},
                  assetid=>$AssetW5BaseID,
                  systemtype=>'standard',
                  allowifupdate=>1,
                  srcid=>$itncmdbid,
                  srcsys=>$SRCSYS
               };
               $O->{'TS::system'}->mapApplicationOpModeToSystemOpModeFlags(
                  $ApplW5BaseRec,
                  $nSys
               );


               if ($ApplW5BaseRec->{conumber} ne ""){
                  $nSys->{conumber}=$ApplW5BaseRec->{conumber};
               }
               if (my $W5id=$O->{'TS::system'}->ValidatedInsertRecord($nSys)){
                  $O->{'TS::system'}->addDefContactsFromAppl(
                     $W5id,
                     $ApplW5BaseRec
                  );
                  $O->{'itil::lnkapplsystem'}->ValidatedInsertRecord({
                     applid=>$ApplW5BaseRec->{id},
                     cistatusid=>4,
                     systemid=>$W5id
                  });
                  $identifyby=$W5id;
               }
            }
            else{
               msg(INFO,"ApplicationW5BaseID for $systemname not allowed as ".
                        "ITENOS Application");
               my $infoHash=md5_base64("ITENOS Import reject $systemname --");
               my %notifyparam=(
                  infoHash=>$infoHash,
                  emailcategory=>'ITENOSimportReject',
                  adminbcc=>1
               );
               $O->{'itil::asset'}->ResetFilter();
               $O->{'itil::asset'}->SetFilter({id=>\$AssetW5BaseID});
               my ($ar,$msg)=$O->{'itil::asset'}->getOnlyFirst(qw(databossid));
               if (defined($ar) && $ar->{databossid} ne ""){
                  $notifyparam{emailcc}=[$ar->{databossid}];
               }
               my %notifycontrol=(mode=>'ERROR');
               $O->{'TS::appl'}->NotifyWriteAuthorizedContacts(
                  $ApplW5BaseRec,undef,\%notifyparam,\%notifycontrol,sub{
                     my $self=shift;
                     my $subject="ITENOS Import reject for ".$systemname;
                     my $text=$self->T("Please add keyword ITENOS to ".
                                       "application below linked application ".
                                       "to allow ITENOS imports ".
                                       "or clarify ITENOS documentation with ".
                                       "ITENOS support");
                     return($subject,$text);
                  }
               );
    
            }
         }
      }
      else{
         if ($cur->{srcid}->{$itncmdbid}->{cistatusid} ne "4"){
            if ($O->{'TS::system'}->ValidatedUpdateRecord(
                    $cur->{srcid}->{$itncmdbid},
                    {cistatusid=>'4'},
                    {id=>\$cur->{srcid}->{$itncmdbid}->{id}})){
               $identifyby=$cur->{srcid}->{$itncmdbid}->{id};
            }
         }
      }
      if (defined($identifyby) && $identifyby!=0){
         if ($self->LastMsg()==0){  # do qulity checks only if all is ok
            $O->{'TS::system'}->ResetFilter();
            $O->{'TS::system'}->SetFilter({'id'=>\$identifyby});
            my ($rec,$msg)=$O->{'TS::system'}->getOnlyFirst(qw(ALL));
            if (defined($rec)){
               my %checksession;
               my $qc=getModuleObject($self->Config,"base::qrule");
               $qc->setParent($O->{'TS::system'});
               $checksession{autocorrect}=$rec->{allowifupdate};
               $qc->nativQualityCheck(
                   $O->{'TS::system'}->getQualityCheckCompat($rec),$rec,
                   \%checksession);
            }
         }
      }
   }




   return({exitcode=>0,exitmsg=>'ok'});
}


1;
