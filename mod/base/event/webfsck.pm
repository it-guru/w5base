package base::event::webfsck;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use Data::Dumper;
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

sub Init
{
   my $self=shift;


   $self->RegisterEvent("webfsck","WebFSck");
   return(1);
}

sub WebFSck
{
   my $self=shift;
   my $exitcode=0;

   my $fm=getModuleObject($self->Config,"base::filemgmt");
   my $fm2=getModuleObject($self->Config,"base::filemgmt");

   msg(DEBUG,"Pass1: database check and parent strucktures");
   $fm->ResetFilter();
   $fm->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$fm->getFirst();
   if (defined($rec)){
      do{
         if ($rec->{contentstate} ne "ok"){
            $exitcode++;
            msg(ERROR,"bad contentstate file '%s' fid=%s",
                      $rec->{fullname},$rec->{fid});
         }
         if (defined($rec->{parentid})){
            $fm2->ResetFilter();
            $fm2->SetFilter({fid=>\$rec->{parentid}});
            my ($lnkrec,$msg)=$fm2->getOnlyFirst(qw(fid fullname));
            if (!defined($lnkrec)){
               $exitcode++;
               msg(ERROR,"bad parent file '%s' fid=%s",
                         $rec->{fullname},$rec->{fid});
            }
            else{
               if (substr($rec->{fullname},0,length($lnkrec->{fullname}))
                   ne $lnkrec->{fullname}){
                  $exitcode++;
                  msg(ERROR,"fullname error in file fid=%s",$rec->{fid});
                  msg(ERROR,"parent=%s",$lnkrec->{fullname});
                  msg(ERROR,"sub   =%s",$rec->{fullname});
               }
            }
         }
         ($rec,$msg)=$fm->getNext();
      }until(!defined($rec));
   }


   msg(DEBUG,"Pass2: filesystem check");
   return({exitcode=>$exitcode});
}

1;
