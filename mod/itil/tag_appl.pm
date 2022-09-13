package itil::tag_appl;
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
use kernel::App::Web;
use kernel::App::Web::ItemTag;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::ItemTag kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;

   $param{tagtable}="tag_appl";

   $param{parent}="itil::appl";
   $param{parenttable}="appl";   # for outerjoin to parent
   $param{parentid}="id";

   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'Application',
                dataobjattr   =>"appl.name",
                vjointo       =>"itil::appl",
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'name'),
      insertbefore=>'name'
      
   );
   $self->AddFields(
      new kernel::Field::Link(
                name          =>'applid',
                label         =>'ApplID',
                readonly      =>1,
                uivisible     =>0,
                dataobjattr   =>"appl.id"),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'reference record CI-StatusID',
                readonly      =>1,
                uivisible     =>0,
                dataobjattr   =>"appl.cistatus"),

      new kernel::Field::Date(
                name          =>'cimdate',
                label         =>'reference record ModifyDate',
                readonly      =>1,
                selectfix     =>1,
                uivisible     =>0,
                dataobjattr   =>"appl.modifydate"),

      new kernel::Field::Date(
                name          =>'cicdate',
                label         =>'reference record CreateDate',
                readonly      =>1,
                selectfix     =>1,
                uivisible     =>0,
                dataobjattr   =>"appl.createdate"),

      new kernel::Field::Select(
                name          =>'applcistatus',
                label         =>'Application CI-Status',
                readonly      =>1,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name')
   );

   $self->setDefaultView(qw(appl applcistatus name value));

   return($self);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"".$self->T("CI-Status(4)","base::cistatus")."\"");
   }
}





1;
