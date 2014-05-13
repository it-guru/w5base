package TS::event::LicProduct2LicContract;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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

sub LicProduct2LicContract
{
   my $self=shift;
   my %param=@_;

   my $lp=getModuleObject($self->Config,"itil::licproduct");
   my $lc=getModuleObject($self->Config,"itil::liccontract");
   $lp->SetFilter({cistatusid=>\'4'});
   $lp->SetCurrentView(qw(id fullname));
     
   my ($rec,$msg)=$lp->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         $lc->ValidatedInsertOrUpdateRecord({
            cistatusid=>'4',
            name=>$rec->{fullname},
            licproduct=>$rec->{fullname},
            units=>undef,
            mandatorid=>'12',
            srcid=>$rec->{id},
            srcsys=>$self->Self,
            srcload=>NowStamp("en")
         },{srcid=>\$rec->{id},srcsys=>[$self->Self]});

         ($rec,$msg)=$lp->getNext();
      } until(!defined($rec));
   }

   return({exitcode=>0,msg=>'transfer ok'});
}
1;
