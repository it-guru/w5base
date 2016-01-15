package AL_TCom::Reporter::prio1appl;
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
   $self->{fieldlist}=[qw(name id customerprio customer)];
   $self->{name}="DTAG Application Prio1";
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(60,['5:50','20:40']);    
}

sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;

   my $appl=getModuleObject($self->Config,"AL_TCom::appl");
   $appl->SetFilter({cistatusid=>\'4',customerprio=>\'1',
                     customer=>"DTAG DTAG.*"});
   foreach my $arec ($appl->getHashList(@{$self->{fieldlist}})){
      my $d=sprintf("%s;%d;%d;%s\n",
                    $arec->{name},
                    $arec->{id},
                    $arec->{customerprio},$arec->{customer});
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
   my $old=CSV2Hash($oldrec->{textdata},"id");
   my $new=CSV2Hash($newrec->{textdata},"id");
   foreach my $id (keys(%{$old->{id}})){
      if (!exists($new->{id}->{$id})){
         my $m=$self->T('- "%s" (W5BaseID:%s) has left the list');
         $msg.=sprintf($m."\n",$old->{id}->{$id}->{name},$id);
         #$msg.="  ".join(",",
         #    map({$_=$old->{id}->{$id}->{$_}} keys(%{$old->{id}->{$id}})));
      }
   }
   foreach my $id (keys(%{$new->{id}})){
      if (!exists($old->{id}->{$id})){
         my $m=$self->T('+ "%s" (W5BaseID:%s) has been added to the list');
         $msg.=sprintf($m."\n",$new->{id}->{$id}->{name},$id);
      }
      else{
         if ($old->{id}->{$id}->{name} ne 
             $new->{id}->{$id}->{name}){
            my $m=$self->T('<> "%s" (W5BaseID:%s) renamed to "%s"');
            $msg.=sprintf($m."\n",$old->{id}->{$id}->{name},$id,
                                  $new->{id}->{$id}->{name});
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



1;
