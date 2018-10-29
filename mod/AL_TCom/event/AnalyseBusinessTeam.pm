package AL_TCom::event::AnalyseBusinessTeam;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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


sub AnalyseBusinessTeam
{
   my $self=shift;

   my $appl=getModuleObject($self->Config,"itil::appl");

   my $log;

   if (!open($log,">AnalyseBusinessTeam.log.csv")){
      msg(ERROR,"can not open output");
      return({exitcode=>1});
   }

   $appl->SetFilter({cistatusid=>[3,4,5],
                     mandator=>"!Extern"});

   $appl->SetCurrentView(qw(name id businessteam businessteamid 
                            tsm tsmid tsm2id tsm2));
   #$appl->SetNamedFilter("X",{name=>'!ab1*'});
   #$appl->Limit(100,0,0);
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         msg(INFO,"process system: $rec->{name}");
         my @msg;
         if ($rec->{businessteam} ne "Extern"){
            if ($rec->{tsmid} ne ""){
               my %grps=$self->getGroupsOf($rec->{tsmid},[orgRoles()],"up");
               if ($rec->{businessteamid} eq ""){
                 # push(@msg,"noBTeam");
               }
               else{
                  if (!exists($grps{$rec->{businessteamid}})){
                     push(@msg,"TSMnotinBTeam");
                  }
                  my $grec=$grps{$rec->{businessteamid}};
                  if ($grec->{distance}>1){
                     push(@msg,"TSMfarfromBTeam");
                  }
               }
            }
            else{
               #push(@msg,"noTSM");
            }
         }
         if ($#msg!=-1){
            printf $log ("%s;%s;%s;%s\r\n",
                         $rec->{name},
                         $rec->{businessteam},
                         $rec->{tsm},
                         join(";",@msg));
         }
         ($rec,$msg)=$appl->getNext();
      } until(!defined($rec));
   }
   close($log);
   return({exitcode=>0});
}




1;
