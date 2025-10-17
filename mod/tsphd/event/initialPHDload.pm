package tsphd::event::initialPHDload;
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

   return($self);
}


sub getDatabossId
{
   my $self=shift;
   my $typ=shift;
   my $rec=shift;

   return("12052217570001");
}


sub getMandatorId
{
   my $self=shift;
   my $typ=shift;
   my $rec=shift;

   return("200");
}


sub recreateAssetRec
{
   my $self=shift;
   my $rec=shift;

   my $ass=$self->{ass};
   my $assetid;

   $ass->ResetFilter();
 
   $ass->SetFilter({srcsys=>\'PHD',srcid=>\$rec->{id}});
   my ($w5rec)=$ass->getOnlyFirst(qw(ALL));
   if (defined($w5rec)){
      #$ass->ValidatedDeleteRecord($w5rec);
      return($w5rec->{id});
   }
   my $newrec={
      name=>"PHD_".$rec->{name},
      cistatusid=>4,
      databossid=>$self->getDatabossId("asset",$rec),
      mandatorid=>$self->getMandatorId("asset",$rec),
      srcsys=>'PHD',
      srcid=>$rec->{id}
   };
   foreach my $v (qw(cpuspeed cpucount memory 
                     serialno
                     locationid room rack place)){
      if ($rec->{$v} ne ""){
         $newrec->{$v}=$rec->{$v};
      }
   }

   $assetid=$ass->ValidatedInsertRecord($newrec);
   return($assetid);
}


sub recreateSystemRec
{
   my $self=shift;
   my $assetid=shift;
   my $rec=shift;

   my $sys=$self->{sys};
   my $systemid;

   $sys->ResetFilter();
 
   $sys->SetFilter({srcsys=>\'PHD',srcid=>\$rec->{id}});
   my ($w5rec)=$sys->getOnlyFirst(qw(ALL));
   if (defined($w5rec)){
      $sys->ValidatedDeleteRecord($w5rec);
   }
   my $newrec={
      name=>$rec->{name},
      cistatusid=>4,
      assetid=>$assetid,
      acinmassingmentgroup=>$rec->{inmassignmentgroup},
      acchmassingmentgroup=>$rec->{chmassignmentgroup},
      relationmodel=>'PERSON',
      databossid=>$self->getDatabossId("system",$rec),
      mandatorid=>$self->getMandatorId("system",$rec),
      srcsys=>'PHD',
      srcid=>$rec->{id}
   };

   my $svemail=$rec->{svmail};

   if ($svemail ne ""){
      my $uid=$self->{usr}->GetW5BaseUserID($svemail,"email");
      if ($uid){
         $newrec->{relpersonid}=$uid;
      }
   }





   foreach my $v (qw(corecount cpucount memory)){
      if (exists($rec->{$v}) && $rec->{$v} ne ""){
         $newrec->{$v}=$rec->{$v};
      }
   }
   foreach my $k (keys(%$newrec)){
      if ($newrec->{$k} eq ""){
         delete($newrec->{$k});
      }
   }

   $systemid=$sys->ValidatedInsertRecord($newrec);

   if (defined($systemid)){
      my $grp="DTAG.GHQ.VTI.DTIT.E-DTO.E-DTOWS.E-DTOWS05.E-TSIWS0503";
      my $lnkcontact=getModuleObject($self->Config,"base::lnkcontact");
      $lnkcontact->ValidatedInsertRecord({
         targetname=>$grp,
         roles=>['write'],
         refid=>$systemid,
         comments=>"PHD-Darwin mig",
         parentobj=>$sys->SelfAsParentObject()
      });
   }

   return($systemid);
}


sub initialPHDload
{
   my $self=shift;
   my $name=shift;

   $self->{usr}=getModuleObject($self->Config,"base::user");
   $self->{ass}=getModuleObject($self->Config,"TS::asset");
   $self->{sys}=getModuleObject($self->Config,"TS::system");
   $self->{agm}=getModuleObject($self->Config,"tsgrpmgmt::grp");
   my $o=getModuleObject($self->Config,"tsphd::sysasset");
   my %flt=();

   if ($name ne ""){
      $flt{name}=$name;
   }

   $o->SetFilter(\%flt);
   $o->SetCurrentView(qw(ALL));
   $o->SetCurrentOrder("name","+id");
   my ($rec,$msg)=$o->getFirst();
   my $recno=0;

   if (defined($rec)){
      READLOOP: do{
         $recno++;
         msg(INFO,"processing system '$rec->{name}' as record $recno");
         # preprocessing record
         $rec->{name}=~s/Ü/UE/g;
         $rec->{name}=~s/Ö/OE/g;
         $rec->{name}=~s/Ä/AE/g;
         $rec->{name}=~s/\s*//g;
         if ($rec->{cpuspeed} eq "0"){
            $rec->{cpuspeed}=undef;
         }
         if ($rec->{memory} eq "0"){
            $rec->{memory}=undef;
         }
         if (defined($rec->{cpuspeed}) && $rec->{cpuspeed} ne "" &&
             $rec->{cpuspeed}<10){
            $rec->{cpuspeed}=$rec->{cpuspeed}*1000;
         }
         if (($rec->{inmassignmentgroup}=~m/\s/) ||
             ($rec->{inmassignmentgroup}=~m/[\*\?]/)){
            $rec->{inmassignmentgroup}=undef;
         }
         if (($rec->{chmassignmentgroup}=~m/\s/) ||
             ($rec->{chmassignmentgroup}=~m/[\*\?]/)){
            $rec->{chmassignmentgroup}=undef;
         }
         foreach my $v (qw(inmassignmentgroup chmassignmentgroup)){
            my $name=$rec->{$v};
            if ($name ne ""){
               $self->{agm}->ResetFilter();
               $self->{agm}->SetFilter({fullname=>\$name});
               my ($w5rec)=$self->{agm}->getOnlyFirst(qw(fullname));
               if (!defined($w5rec)){
                  $rec->{$v}=undef;
               }
            }
            if ($rec->{$v} eq ""){
               $rec->{$v}=undef;
            }
         }
         


         my $assetid=$self->recreateAssetRec($rec);
         if (!defined($assetid)){
            die("can not create assetid for $rec->{name}");
         }
         my $systemid=$self->recreateSystemRec($assetid,$rec);
         #print Dumper($rec);


         ($rec,$msg)=$o->getNext();
         if (defined($msg)){
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>1,msg=>$msg});
         }
      }until(!defined($rec));
   }
   return({exitcode=>0,msg=>'ok'});
}





1;
