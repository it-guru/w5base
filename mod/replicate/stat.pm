package replicate::stat;
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
use kernel::App::Web;
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'replicatestat.id'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'object',
                label         =>'Dataobject',
                vjointo       =>'replicate::obj',
                vjoinon       =>['objectid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'objectid',
                label         =>'Dataobject ID',
                dataobjattr   =>'replicatestat.replobject'),

      new kernel::Field::Text(
                name          =>'phase',
                label         =>'Phase',
                dataobjattr   =>'replicatestat.phase'),

      new kernel::Field::Number(
                name          =>'effentries',
                label         =>'effentries',
                dataobjattr   =>'replicatestat.effentries'),

      new kernel::Field::Number(
                name          =>'duration',
                label         =>'duration',
                dataobjattr   =>'replicatestat.duration'),

      new kernel::Field::Date(
                name          =>'startdate',
                label         =>'Start-Date',
                sqlorder      =>'desc',
                dataobjattr   =>'replicatestat.startdate'),
                                                  
      new kernel::Field::Date(
                name          =>'enddate',
                label         =>'End-Date',
                sqlorder      =>'desc',
                dataobjattr   =>'replicatestat.enddate'),
                                                  
   );
   $self->setDefaultView(qw(linenumber startdate  object phase enddate));
   $self->setWorktable("replicatestat");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}





1;
