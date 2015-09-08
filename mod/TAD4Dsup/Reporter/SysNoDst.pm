package TAD4Dsup::Reporter::SysNoDst;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
   $self->{fieldlist}=[qw(systemname systemid w5base_appl)];
   $self->{name}="TAD4D Systems without Destination env";
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(60,['6:15','20:40']);    
}

sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;

   my $sys=getModuleObject($self->Config,"TAD4Dsup::system");
   $sys->SetFilter({
                    denv=>"[EMPTY]",
                    saphier=>'"9TS_ES.9DTIT" "9TS_ES.9DTIT.*"'});
   foreach my $srec ($sys->getHashList(@{$self->{fieldlist}})){
      #next if ($srec->{systemname}=~m/^q4de3esy.*/);
      my $appl=$srec->{w5base_appl};
      $appl=join(" ",@$appl) if (ref($appl) eq "ARRAY");
      $appl=~s/;/ /g;
      my $d=sprintf("%s;%s;%s\n",
                    $srec->{systemname},
                    $srec->{systemid},
                    $appl);
      print($d);
   }
   return(0);
}



sub onChange
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $msg="";
   my $old=CSV2Hash($oldrec->{textdata},"systemname");
   my $new=CSV2Hash($newrec->{textdata},"systemname");
   foreach my $id (keys(%{$old->{systemname}})){
      my $add=$old->{systemname}->{$id}->{systemid};
      $add.=", " if ($add ne "");
      if ($old->{systemname}->{$id}->{w5base_appl} ne ""){
         $add.=$old->{systemname}->{$id}->{w5base_appl};
      }
      if (!exists($new->{systemname}->{$id})){
         my $m=$self->T('- "%s" (%s) has left the list');
         $msg.=sprintf($m."\n",$old->{systemname}->{$id}->{systemname},$add);
         #$msg.="  ".join(",",
         #    map({$_=$old->{id}->{$id}->{$_}} keys(%{$old->{id}->{$id}})));
      }
   }
   foreach my $id (keys(%{$new->{systemname}})){
      my $add=$new->{systemname}->{$id}->{systemid};
      $add.=", " if ($add ne "");
      if ($new->{systemname}->{$id}->{w5base_appl} ne ""){
         $add.=$new->{systemname}->{$id}->{w5base_appl};
      }
      if (!exists($old->{systemname}->{$id})){
         my $m=$self->T('+ "%s" (%s) has been added to the list');
         $msg.=sprintf($m."\n",$new->{systemname}->{$id}->{systemname},$add);
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
