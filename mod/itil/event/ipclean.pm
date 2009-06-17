package itil::event::ipclean;
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


   $self->RegisterEvent("ipclean","ipclean");
   return(1);
}

sub ipclean
{
   my $self=shift;
   my $sys=getModuleObject($self->Config,"itil::system");
   my $ip=getModuleObject($self->Config,"itil::ipaddress");
   my $ipop=getModuleObject($self->Config,"itil::ipaddress");
   $ip->SetFilter({cistatusid=>"<6"});
   $ip->SetCurrentOrder(qw(NONE));
   $ip->SetCurrentView(qw(ALL));

   my ($iprec,$msg)=$ip->getFirst(unbuffered=>1);
   if (defined($iprec)){
      do{
         msg(DEBUG,"check %s",$iprec->{name});
         $sys->ResetFilter();
         $sys->SetFilter({id=>\$iprec->{systemid}});
         my ($sysrec,$msg)=$sys->getOnlyFirst(qw(cistatusid name));
         if (!defined($sysrec)){
            msg(ERROR,"sysrec miss on ip $iprec->{name}");
            $ipop->ValidatedDeleteRecord($iprec);
         }
         if ($sysrec->{cistatusid}==6){
            msg(ERROR,"system $sysrec->{name} for $iprec->{name} is deleted");
            if ($iprec->{networkid} eq ""){
               $ipop->ValidatedDeleteRecord($iprec);
            }
            $ipop->ValidatedUpdateRecord($iprec,{cistatusid=>6},
                                         {id=>\$iprec->{id}});
         }
         ($iprec,$msg)=$ip->getNext();
      }until(!defined($iprec));
   }

   return({exitcode=>0,msg=>'ok'});
}

1;
