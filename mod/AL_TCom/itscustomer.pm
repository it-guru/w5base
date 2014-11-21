package AL_TCom::itscustomer;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(

      new kernel::Field::Link(
                name          =>'its_id',
                dataobjattr   =>"its.businessservice"),

      new kernel::Field::Link(
                name          =>'es_id',
                dataobjattr   =>"es.businessservice"),

      new kernel::Field::Link(
                name          =>'ta_id',
                dataobjattr   =>"ta.businessservice"),

      new kernel::Field::Link(
                name          =>'customerid',
                dataobjattr   =>"app.customer"),

      new kernel::Field::Link(
                name          =>'customer',
                label         =>'Customer',
                weblinkto     =>'base::grp',
                weblinkon     =>['customer'=>'fullname'],
                dataobjattr   =>"grp.fullname"),

   );

   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;

   my $from="grp ".
            "join appl on appl.customer=grp.grpid ".
            "left outer join lnkbscomp ta".
            " on (ta.objtype='itil::appl' and appl.id=ta.obj1id) ".
            "left outer join lnkbscomp es".
            " on (es.objtype='itil::businessservice' and".
            "     ta.businessservice=es.obj1id) ".
            "left outer join lnkbscomp its".
            " on (its.objtype='itil::businessservice' and".
            "     es.businessservice=its.obj1id)";

   return($from);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isUploadValid
{
   return(undef);
}



1;
