package AL_TCom::Reporter::bossWithNoQRep;
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
local $| = 1;
use vars qw(@ISA);
use kernel;
use kernel::Reporter;
@ISA=qw(kernel::Reporter);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{fieldlist}=[qw(userid user)];
   $self->{name}="TelekomIT Leiter mit deaktiviertem QualityReport";
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(60,['6:44','21:33']);    
}

sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;

   my $lnk=getModuleObject($self->Config,"base::lnkgrpuser");

   $lnk->SetFilter({group=>"dtag.tsi.ti dtag.tsi.ti.*",
                    rawnativroles=>'RBoss'});
   my %userid;
   foreach my $lrec ($lnk->getHashList(qw(userid))){
      $userid{$lrec->{userid}}++;
   }
   
   my $o=getModuleObject($self->Config,"base::infoabo");
   $o->SetFilter({userid=>[keys(%userid)],
                  active=>0,
                  rawmode=>\'STEVqreportbyorg'});
   foreach my $arec ($o->getHashList(@{$self->{fieldlist}})){
      print(join(";",map({$arec->{$_}} @{$self->{fieldlist}}))."\n");
   }
   return(0);
}



sub onChange
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $msg="";
   my $old=CSV2Hash($oldrec->{textdata},"userid");
   my $new=CSV2Hash($newrec->{textdata},"userid");
   foreach my $userid (keys(%{$old->{userid}})){
      if (!exists($new->{userid}->{$userid})){
         my $m=$self->T('- "%s" (W5BaseID:%s) has left the list');
         $msg.=sprintf($m."\n",$old->{userid}->{$userid}->{user},$userid);
         #$msg.="  ".join(",",
         #    map({$_=$old->{id}->{$id}->{$_}} keys(%{$old->{id}->{$id}})));
      }
   }
   foreach my $userid (keys(%{$new->{userid}})){
      if (!exists($old->{userid}->{$userid})){
         my $m=$self->T('+ "%s" (W5BaseID:%s) has been added to the list');
         $msg.=sprintf($m."\n",$new->{userid}->{$userid}->{user},$userid);
      }
      else{
         if ($old->{userid}->{$userid}->{user} ne 
             $new->{userid}->{$userid}->{user}){
            my $m=$self->T('<> "%s" (W5BaseID:%s) renamed to "%s"');
            $msg.=sprintf($m."\n",$old->{userid}->{$userid}->{user},$userid,
                                  $new->{userid}->{$userid}->{user});
         }
      }
   }
   if ($msg ne ""){
      $msg="Dear W5Base User,\n\n".
           "the following changes where detected in the report:\n\n".
           $msg;
   }

   return($msg);
}

sub isViewValid
{
   my $reporter=shift;
   my $self=shift;
   my $rec=shift;

   return(1) if ($self->IsMemberOf("admin"));
   return(1) if ($self->IsMemberOf("DTAG.TSI.TI",[qw(RCFManager RCFManager2)],
                                   "up"));

   return(0);
}





1;
