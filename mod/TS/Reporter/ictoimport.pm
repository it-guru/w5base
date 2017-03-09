package TS::Reporter::ictoimport;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use kernel::Reporter;
@ISA=qw(kernel::Reporter);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{fieldlist}=[qw(ictono)];
   $self->{name}="ICTO-Object to ApplicationGroup import";
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(10,['6:00',
              '8:00',
              '8:15',
              '8:30',
              '8:45',
              '9:00',
              '9:15',
              '9:30',
              '9:45',
              '10:00',
              '10:15',
              '10:30',
              '10:45',
              '11:00',
              '11:15',
              '11:30',
              '11:45',
              '12:00',
              '12:15',
              '12:30',
              '12:45',
              '13:00',
              '13:15',
              '13:30',
              '13:45',
              '14:00',
              '14:15',
              '14:30',
              '14:45',
              '15:00',
              '15:15',
              '15:30',
              '15:45'
              ]);    
}

sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;

   my $appl=getModuleObject($self->Config,"TS::appl");
   return(1) if ($appl->isSuspended());
   $appl->SetFilter({cistatusid=>\'4'});
   my $oldictono;
   my %icto=();
   my $start=NowStamp("en");
   foreach my $arec ($appl->getHashList(@{$self->{fieldlist}},"id")){
      if ($arec->{ictono} ne ""){
         my $i=lc($arec->{ictono});
         $icto{$i}=[] if (!exists($icto{$i}));
         push(@{$icto{$i}},$arec->{id});
         $self->logRecord($arec) if ($oldictono ne $arec->{ictono});
      }
      $oldictono=$arec->{ictono};
   }
   my $agrp=getModuleObject($self->Config,"itil::applgrp");
   return(1) if ($agrp->isSuspended());
   my $m=getModuleObject($self->Config,"base::mandator");
   return(1) if ($m->isSuspended());
   my $grp=getModuleObject($self->Config,"base::grp");
   return(1) if ($grp->isSuspended());
   my $i=getModuleObject($self->Config,"tscape::archappl");
   return(1) if ($i->isSuspended());
   my $la=getModuleObject($self->Config,"itil::lnkapplgrpappl");
   return(1) if ($la->isSuspended());


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

      my @idl=$agrp->ValidatedInsertOrUpdateRecord({
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
         },
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
               {srcsys=>\$iname,srcid=>\$lid}
            );
         }
      }
   }
   $agrp->BulkDeleteRecord({'srcload'=>"<\"$start\"",srcsys=>\$iname});
   $la->BulkDeleteRecord({'srcload'=>"<\"$start\"",srcsys=>\$iname});
   return(0);
}

sub logRecord
{
   my $self=shift;
   my $arec=shift;

   my $d=sprintf("%s\n",$arec->{ictono});
   print($d);
}



sub onChange
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $msg="";
   my $old=CSV2Hash($oldrec->{textdata},"ictono");
   my $new=CSV2Hash($newrec->{textdata},"ictono");
   foreach my $id (keys(%{$old->{ictono}})){
      if (!exists($new->{ictono}->{$id})){
         my $m=$self->T('- "%s" (W5BaseID:%s) has left the list');
         $msg.=sprintf($m."\n",$old->{ictono}->{$id}->{ictono},$id);
         #$msg.="  ".join(",",
         #    map({$_=$old->{id}->{$id}->{$_}} keys(%{$old->{id}->{$id}})));
      }
   }
   foreach my $id (keys(%{$new->{ictono}})){
      if (!exists($old->{ictono}->{$id})){
         my $m=$self->T('+ "%s" (W5BaseID:%s) has been added to the list');
         $msg.=sprintf($m."\n",$new->{ictono}->{$id}->{ictono},$id);
      }
   }
   if ($msg ne ""){
      $msg="Dear W5Base User,\n\n".
           "the following changes where detected in the report:\n\n".
           $msg;
   }

   return($msg);
}



1;
