package itil::event::Process_applcistransfer;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use kernel::date;
use kernel::Event;
use kernel::database;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("Process_applcistransfer","Process_applcistransfer");
   return(1);
}

sub Process_applcistransfer
{
   my $self=shift;
   my $debug=0;
   my $id=shift;
   if ($id eq "debug"){
      $id=shift;
      $debug=1;
   }

   my $o=getModuleObject($self->Config,"itil::applcitransfer");

   $o->SetFilter({id=>\$id});
   my ($rec)=$o->getOnlyFirst(qw(ALL));
   if (defined($rec)){
      if ($rec->{"transferdt"} eq "" || 1){
         if ($rec->{"eapplackdate"} ne "" &&
             $rec->{"capplackdate"} ne ""){
            #msg(ERROR,"rec=%s".Dumper($rec));
            my $items=$o->extractAdresses($rec->{'configitems'});
            my $app=getModuleObject($self->Config,"itil::appl");

            $app->SetFilter({id=>[$rec->{"eapplid"},$rec->{"capplid"}]});
            $app->SetCurrentView(qw(ALL));
            my $arec=$app->getHashIndexed("id");

            my @tlog=();
            my $res=$o->ProcessTransfer(\@tlog,$rec,
               $arec->{id}->{$rec->{"eapplid"}},
               $arec->{id}->{$rec->{"capplid"}}
            );

            my $op=$o->Clone();
            $op->ValidatedUpdateRecord($rec,
               {transferdt=>NowStamp("en"),transferlog=>join("\n",@tlog)},
               {
                  id=>$rec->{id}
               }
            );
         }
      }
   }

   return({exitcode=>0});
}

1;
