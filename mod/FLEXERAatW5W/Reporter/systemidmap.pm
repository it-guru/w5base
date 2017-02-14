package FLEXERAatW5W::Reporter::systemidmap;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
   $self->{fieldlist}=[qw(systemname flexerasystemid mapstate)];
   $self->{name}="Flexera SystemID Mapper";
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(10,['6:00',
              '7:00',
              '8:00',
              '9:00',
              '10:00',
              '11:00',
              '12:00',
              '13:00',
              '14:00',
              '15:00',
              '16:00'
              ]);    
}

sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;


   my $smap=getModuleObject($self->Config,"FLEXERAatW5W::syssystemidmap");
   $smap->SetFilter({mapstate=>\undef});
   $smap->Limit(10);
   my $smapop=$smap->Clone();
   my $sys=getModuleObject($self->Config,"itil::system");
   foreach my $mrec ($smap->getHashList(qw(ALL))){
      my $systemname=$mrec->{systemname};
      $systemname=~s/\*//g;
      $systemname=~s/\?//g;
      $systemname=~s/\s//g;
      my @l;
      if ($systemname ne ""){
         $sys->ResetFilter();
         $sys->SetFilter({name=>$systemname,cistatusid=>"<6"});
         @l=$sys->getHashList(qw(name systemid id));
      }
      my $mapstate="FAIL";
      my $systemid="";
      if ($#l==-1){
         $mapstate="NOT FOUND";
      }
      elsif ($#l>0){
         $mapstate="NOT UNIQUE";
      }
      elsif ($#l==0){
         $mapstate="OK";
         $systemid=$l[0]->{systemid};
      }
      $smapop->ResetFilter();
      my $bk=$smapop->ValidatedUpdateRecord($mrec,{
         systemid=>$systemid,
         mapstate=>$mapstate,
         owner=>\undef
      },{id=>$mrec->{id}});
   }
   $smap->ResetFilter();
   $smap->SetFilter({mapstate=>'"FAIL" "NOT FOUND" "NOT UNIQUE"'});

   my $start=NowStamp("en");
   foreach my $rec ($smap->getHashList(@{$self->{fieldlist}},"id")){
      $self->logRecord($rec);
   }
   return(0);
}

sub logRecord
{
   my $self=shift;
   my $arec=shift;

   my $d=sprintf("%s;%s;%s\n",$arec->{systemname},
                              $arec->{flexerasystemid},
                              $arec->{mapstate});
   print($d);
}



sub onChange
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $msg="";
   my $old=CSV2Hash($oldrec->{textdata},"flexerasystemid");
   my $new=CSV2Hash($newrec->{textdata},"flexerasystemid");
   foreach my $id (keys(%{$old->{flexerasystemid}})){
      if (!exists($new->{flexerasystemid}->{$id})){
         my $m=$self->T('- "%s" (FlexeraID:%s) has left the list');
         $msg.=sprintf($m."\n",
               $old->{flexerasystemid}->{$id}->{systemname},$id);
      }
   }
   foreach my $id (keys(%{$new->{flexerasystemid}})){
      if (!exists($old->{flexerasystemid}->{$id})){
         my $m=$self->T('+ "%s" (FlexeraID:%s) has been added to the list');
         $msg.=sprintf($m."\n",
              $new->{flexerasystemid}->{$id}->{systemname}."=".
              $new->{flexerasystemid}->{$id}->{mapstate},$id);
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
