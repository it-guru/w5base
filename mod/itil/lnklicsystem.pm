package itil::lnklicsystem;
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
use kernel::DataObj::DB;
use kernel::Field;
use itil::lnksoftwaresystem;
@ISA=qw(itil::lnksoftwaresystem);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5 if (!defined($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);


   $self->setDefaultView(qw(software liccontract liccontractcistatus 
                            quantity system systemcistatus));

   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_systemcistatus"))){
     Query->Param("search_systemcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_liccontractcistatus"))){
     Query->Param("search_liccontractcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="lnksoftwaresystem.liccontract is not null";
   return($where);
}






1;
