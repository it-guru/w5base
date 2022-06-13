package itil::businessprocess;
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
use kernel::App::Web;
use kernel::Field;
use crm::businessprocess;
@ISA=qw(crm::businessprocess);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::SubList(    
                name          =>'businessservices',
                label         =>'Businessservices',
                group         =>'businessservices',
                subeditmsk    =>'subedit.businessservice',
                vjointo       =>'itil::lnkbprocessbservice',
                vjoinon       =>['id'=>'bprocessid'],
                vjoindisp     =>['businessservice'],
                vjoininhash   =>['businessservice','businessserviceid',
                                 'bservicecistatusid']),
   );
   $self->getField("pbusinessprocess")->{'vjointo'}='itil::businessprocess';
   $self->getField("pbusinessprocess")->{'weblinkto'}='itil::businessprocess';
   $self->getField("subproc")->{'vjointo'}='itil::businessprocess';

   return($self);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("header","default") if (!defined($rec));
   my @l=$self->SUPER::isViewValid($rec);
   push(@l,"businessservices") if (in_array("default",\@l));
   
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my @res=$self->SUPER::isWriteValid(@_);
   push(@res,"businessservices") if (grep(/^procdesc$/,@res) ||
                                 grep(/^ALL$/,@res));
   return(@res);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::getDetailBlockPriority($rec);
   array_insert(\@l,"subproc","businessservices");
   return(@l);
}








1;
