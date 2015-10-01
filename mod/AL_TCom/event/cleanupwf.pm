package AL_TCom::event::cleanupwf;
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


   $self->RegisterEvent("cleanupwf","cleanupwf");
   return(1);
}

sub cleanupwf
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfop=$wf->Clone();

   $wf->SetFilter({class=>\'base::workflow::DataIssue',
                   state=>\'2'});
   $wf->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{id}: $rec->{name}");
         msg(INFO,"                  | ".
                  "$rec->{affectedobject} - $rec->{affectedobjectid}");
         my $ok=0;
         if ($rec->{affectedobject} ne ""){
            my $chk=getModuleObject($self->Config,$rec->{affectedobject});
            if (defined($chk)){
               my $idobj=$chk->IdField();
               if (defined($idobj)){
                  my $idname=$idobj->Name();
                  $chk->SetFilter({$idname=>\$rec->{affectedobjectid}});
                  my ($chkrec)=$chk->getOnlyFirst($idname);
                  if (defined($chkrec)){
                     $ok++
                  }
               }
            }
         }
         if (!$ok){
            msg(WARN,"invalid referenz for workflow $rec->{id}");
            $wfop->Store($rec,{stateid=>'25',
                               fwddebtarget=>undef,
                               fwddebtargetid=>undef,
                               fwdtarget=>undef,
                               fwdtargetid=>undef});
         }
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   return({exitcode=>0});
}

1;
