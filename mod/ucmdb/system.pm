package ucmdb::system;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web::Listedit;
use kernel::DataObj::SOAPuCMDB;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::SOAPuCMDB );

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
                label         =>'GlobalID',
                align         =>'left',
                dataobjattr   =>'global_id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>"name"),

      new kernel::Field::Text(
                name          =>'serialno',
                label         =>'Serialnumber',
                dataobjattr   =>"serial_number"),

      new kernel::Field::Text(
                name          =>'os_vendor',
                label         =>'OS-Vendor',
                dataobjattr   =>"os_vendor"),

      new kernel::Field::Text(
                name          =>'assignmentgroup',
                label         =>'Assignmentgroup',
                dataobjattr   =>'tec_calculated_ag'),

      new kernel::Field::Text(
                name          =>'iassignmentgroup',
                label         =>'Incident-Assignmentgroup',
                dataobjattr   =>'tec_calculated_iag'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'tec_data_source'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'data_externalid'),


      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Description',
                dataobjattr   =>'description'),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                searchable    =>'0', # das hat noch einen Bug
                group         =>'applications',
                vjointo       =>'ucmdb::appl',
                vjoinon       =>['id'=>'LinkedToID'],
                vjoindisp     =>['name']),


      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>"create_time"),

      new kernel::Field::Link(   # this is always needed for SubList access
                name          =>'LinkedToID',
                label         =>'internal access for relations',
                dataobjattr   =>"__LinkedToID"),

   );
   $self->setDefaultView(qw(name os_vendor id));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddSoapPartner('coreucmdb','host_node');
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(0);
}








1;
