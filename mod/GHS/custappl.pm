package GHS::custappl;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use itcrm::custappl;
@ISA=qw(itcrm::custappl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'itmgr',
                searchable    =>0,
                group         =>'ghscontact',
                label         =>'IT-Manager',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['itmgrid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'itmgrid',
                group         =>'ghscontact',
                dataobjattr   =>'itcrmappl.itmanager'),

   );
   $self->getField("itmanager")->{htmldetail}=0;
   $self->getField("itmanager")->{searchable}=0;
   $self->getField("businessowner")->{htmldetail}=0;
   $self->getField("businessowner")->{searchable}=0;
   $self->setDefaultView(qw(name custname cistatus itmgr));
   return($self);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default custapplnameing 
          ghscontact tscontact custcontracts));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isWriteValid($rec);
   if (grep(/^custapplnameing$/,@l)){
      push(@l,"ghscontact");
   }
   return(@l);
}




















1;
