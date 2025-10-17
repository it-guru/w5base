package tscape::event::CapeICTOimport;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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

   $self->{fieldlist}=[qw(ictono)];

   return($self);
}


sub CapeICTOimport
{
   my $self=shift;

   my $appl=getModuleObject($self->Config,"TS::appl");
   return({}) if ($appl->isSuspended());
   $appl->SetFilter({cistatusid=>['3','4']});
   my $oldictono;
   my %icto=();
   my $start=NowStamp("en");
   msg(INFO,"start reading icto-id list");
   foreach my $arec ($appl->getHashList(@{$self->{fieldlist}},"id")){
      if ($arec->{ictono} ne ""){
         my $i=lc($arec->{ictono});
         $icto{$i}=[] if (!exists($icto{$i}));
         push(@{$icto{$i}},$arec->{id});
      }
      $oldictono=$arec->{ictono};
   }
   if (0){  # reduce data for debugging
      foreach my $i (keys(%icto)){
         if (!in_array([$i],[qw(icto-4340 icto-4488
                                icto-13741 icto-17962)])){
            delete($icto{$i});
         }
      }
   }
   my $nicto=keys(%icto);
   msg(INFO,"found  $nicto ictos in it-inventory");
   my $agrp=getModuleObject($self->Config,"itil::applgrp");
   if ($agrp->isSuspended()){
      return({exitcode=>'100',exitmsg=>'suspended itil::applgrp'});
   }
   my $m=getModuleObject($self->Config,"base::mandator");
   if ($m->isSuspended()){
      return({exitcode=>'100',exitmsg=>'suspended base::mandator'});
   }
   my $grp=getModuleObject($self->Config,"base::grp");
   if ($grp->isSuspended()){
      return({exitcode=>'100',exitmsg=>'suspended base::grp'});
   }
   my $i=getModuleObject($self->Config,"tscape::archappl");
   if ($i->isSuspended()){
      return({exitcode=>'100',exitmsg=>'suspended tscape::archappl'});
   }

   if (!($i->Ping())){
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      if ($infoObj->NotifyInterfaceContacts($i)){
         return({exitcode=>0,exitmsg=>'Interface notified'});
      }
      return({exitcode=>1,exitmsg=>'not all dataobjects available'});
   }


   my $la=getModuleObject($self->Config,"itil::lnkapplgrpappl");
   if ($la->isSuspended()){
      return({exitcode=>'100',exitmsg=>'suspended itil::lnkapplgrpappl'});
   }
   if (!$i->Ping()){
      return({exitcode=>'101',exitmsg=>'tscape::archappl not reachable'});
   }


   my $iname=$i->Self();
   $i->SetFilter({archapplid=>[keys(%icto)]});
   my $c=0;;
   foreach my $irec ($i->getHashList(qw(archapplid fullname description
                                        shortname status organisation))){
      $c++;
      my $mandator="TelekomIT";
      $m->ResetFilter();
      $m->SetFilter({name=>\$mandator,cistatusid=>\'4'});
      my ($mandatorid)=$m->getVal("grpid");
      my $shortname=$irec->{shortname};
      $shortname="NONAME ".$irec->{archapplid} if ($shortname eq "");
      $shortname=~s/[^a-z0-9:-]/_/gi;

      $agrp->ResetFilter();
      $agrp->SetFilter({name=>$shortname,applgrpid=>"!".$irec->{archapplid}});
      my ($agrpid)=$agrp->getVal("id");
      if ($agrpid ne ""){  # make it unique
         $shortname.="_".$irec->{archapplid};
      }

      my $cistatusid="4";
      if ($irec->{status} eq "Plan"){
         $cistatusid="3";
      }
      if ($irec->{status} eq "Retired"){
         $cistatusid="6";
      }

      my $responseorgid=undef;

      my $debug;
      my %lrec=(fullname=>$irec->{organisation});
      if ($irec->{organisation} ne ""){
         my $grpid=$grp->getIdByHashIOMapped("tscape::archappl",\%lrec,
                                                 DEBUG=>\$debug);
         $responseorgid=$grpid;
      }

      my $newrec={
            cistatusid=>$cistatusid,
            name=>$shortname,
            fullname=>$irec->{fullname},
            applgrpid=>$irec->{archapplid},
            comments=>$irec->{description},
            mandatorid=>$mandatorid,
            responseorgid=>$responseorgid,
            srcid=>$irec->{archapplid},
            srcsys=>$iname,
            srcload=>$start
      };

      if ($cistatusid>5){
         $agrp->ResetFilter();
         $agrp->SetFilter({srcsys=>\$iname,srcid=>\$irec->{archapplid}});
         my ($chkrec)=$agrp->getOnlyFirst(qw(id));
         if (defined($chkrec)){  # record exists - and we will only do an update
            delete($newrec->{name}); # update of name makes no sense, if rec is del
         }
      }

      my @idl=$agrp->ValidatedInsertOrUpdateRecord($newrec,
         {srcsys=>\$iname,srcid=>\$irec->{archapplid}}
      );
      if ($#idl==0){
         foreach my $applid (@{$icto{lc($irec->{archapplid})}}){
            my $lid=lc($irec->{archapplid})."-".$applid;
            my @l=$la->ValidatedInsertOrUpdateRecord({
                  applgrpid=>$idl[0],
                  applid=>$applid,
                  srcid=>$lid,
                  srcsys=>$iname,
                  srcload=>$start
               },
               {srcsys=>\$iname,applid=>\$applid}
            );
         }
      }
      else{
         printf STDERR ("update problem: %s\n",Dumper($newrec));
         exit(1);
      }
   }
   if ($c<10){
      return({exitcode=>1,
              exitmsg=>'skipped cleanup due to few import records'});
   }
   else{
      $agrp->ResetFilter();
      $agrp->SetFilter({'srcload'=>"<\"$start\"",srcsys=>\$iname});
      $agrp->SetCurrentView(qw(ALL));
      my $opagrp=$agrp->Clone();

      my ($arec,$msg)=$agrp->getFirst(unbuffered=>1);
      if (defined($arec)){
         do{
            $opagrp->ValidatedUpdateRecord($arec,{cistatusid=>6},{
               id=>\$arec->{id}
            });
            ($arec,$msg)=$agrp->getNext();
         }until(!defined($arec));
      }
      $la->BulkDeleteRecord({'srcload'=>"<\"$start\"",srcsys=>\$iname});
   }
   return({exitcode=>0});
}


1;
