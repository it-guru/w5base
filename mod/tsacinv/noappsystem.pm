package tsacinv::noappsystem;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use tsacinv::system;

@ISA=qw(tsacinv::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{MainSearchFieldLines}=5;

   foreach my $fname (qw(tsacinv_locationlocation tsacinv_locationfullname
                         assetroom assetplace 
                         assignmentgroupsupervisoremail
                         assignmentgroupsupervisor bc)){
      my $fld=$self->getField($fname);
      $fld->{searchable}=0 if (defined($fld));
   }

   $self->setDefaultView(qw(id name));
   $self->setDefaultView(qw(installdate 
                            systemname status conumber customerlink));

   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $from=$self->SUPER::getSqlFrom(@_);

   $from.=" left outer join lnkapplsystem ".
            "on system.\"lportfolioitemid\"=lnkapplsystem.\"lchildid\" ".
               "and lnkapplsystem.\"deleted\"=0 ";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="lnkapplsystem.\"lchildid\" is null";
   return($where);
}




sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"in operation\"");
   }

   $self->SUPER::initSearchQuery();

   if (!defined(Query->Param("search_customerlink"))){
     Query->Param("search_customerlink"=>"DTAG.TEL-IT DTAG.TEL-IT.*");
   }
   if (!defined(Query->Param("search_iassignmentgroup"))){
     Query->Param("search_iassignmentgroup"=>"C.TC C.TC.* C.CSS C.CCS.*");
   }
}





1;
