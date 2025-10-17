package TS::event::CHMapprmig;
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub CHMapprmig
{
   my $self=shift;

   my $app=getModuleObject($self->Config(),"TS::appl");
   my $lnk=getModuleObject($self->Config(),"TS::lnkapplchmapprgrp");
   $app->SetFilter({});
   $app->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$app->getFirst();
   if (defined($rec)){
      do{
         printf("app=%s\ntech=%s\nfach=%s\n\n",$rec->{name},$rec->{scapprgroup},
                                                        $rec->{scapprgroup2}); 
         my @old;
         if (ref($rec->{chmapprgroups}) eq "ARRAY"){
            @old=@{$rec->{chmapprgroups}};
         }
         if ($rec->{scapprgroup} ne ""){
            my $fnd=0;
            foreach my $r (@old){
               if ($r->{group} eq $rec->{scapprgroup} &&
                   $r->{responsibility} eq "technical"){
                  $fnd=1;
               }
            }
            if (!$fnd){
               $lnk->ValidatedInsertRecord({
                   parentobj=>'TS::appl',
                   refid=>$rec->{id},
                   group=>$rec->{scapprgroup},
                   responsibility=>'technical'
               });
            }
         }
         if ($rec->{scapprgroup2} ne ""){
            my $fnd=0;
            foreach my $r (@old){
               if ($r->{group} eq $rec->{scapprgroup2} &&
                   $r->{responsibility} eq "functional"){
                  $fnd=1;
               }
            }
            if (!$fnd){
               $lnk->ValidatedInsertRecord({
                   parentobj=>'TS::appl',
                   refid=>$rec->{id},
                   group=>$rec->{scapprgroup2},
                   responsibility=>'functional'
               });
            }
         }
         ($rec,$msg)=$app->getNext();
      } until(!defined($rec));
   }



   





   return({exitcode=>0});
}


1;
