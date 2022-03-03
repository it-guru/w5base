package itil::lnkapplappltagname;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{use_distinct}=1;
  
   $self->AddFields(
      new kernel::Field::Link(
                name          =>'lnkapplappl',
                label         =>'Interface ID',
                dataobjattr   =>'lnkapplappltag.lnkapplappl'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'lnkapplappltag.name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'ifdata',
                label         =>'CI-StateID',
                dataobjattr   =>'lnkapplappl.cistatus'),

      new kernel::Field::Text(
                name          =>'lnkapplapplid',
                label         =>'from Application ID',
                dataobjattr   =>'lnkapplappl.id'),
   );
   $self->setDefaultView(qw(name));
   return($self);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return(undef);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplappltag ".
            "join lnkapplappl ".
            "on lnkapplappltag.lnkapplappl=lnkapplappl.id ".
            "left outer join appl as fromappl ".
            "on lnkapplappl.fromappl=fromappl.id ".
            "left outer join appl as toappl ".
            "on lnkapplappl.toappl=toappl.id ";
   return($from);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}






1;
