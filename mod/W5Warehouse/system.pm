package W5Warehouse::system;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>"(systemid||'-'||systemname)"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                lowersearch   =>1,
                size          =>'16',
                dataobjattr   =>'systemname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemId',
                searchable    =>1,
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP Hier',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'saphier'),

      new kernel::Field::Boolean(
                name          =>'is_w5',
                label         =>'found in W5Base/Darwin',
                dataobjattr   =>'is_w5'),

      new kernel::Field::Boolean(
                name          =>'is_am',
                label         =>'found in AssetManager',
                dataobjattr   =>'is_am'),

      new kernel::Field::Boolean(
                name          =>'is_t4dp',
                label         =>'found in TAD4D Prod',
                dataobjattr   =>'is_t4dp'),

      new kernel::Field::Text(
                name          =>'amtype',
                label         =>'AM Type',
                dataobjattr   =>'amtype'),

      new kernel::Field::Text(
                name          =>'ammodel',
                label         =>'AM Model',
                dataobjattr   =>'ammodel'),

      new kernel::Field::Text(
                name          =>'amusage',
                label         =>'AM Usage',
                dataobjattr   =>'amusage'),

      new kernel::Field::Text(
                name          =>'amnature',
                label         =>'AM Nature',
                dataobjattr   =>'amnature'),

   );
   $self->setWorktable("system_universum");
   $self->setDefaultView(qw(systemname systemid is_w5 is_am is_t4dp 
                            saphier));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_saphier"))){
     Query->Param("search_saphier"=>
                  "\"YT5AGH\" ".
                  "\"YT5AGH.*\" ".
                  "\"YT5A_DTIT\" ".
                  "\"YT5A_DTIT.*\" "
                  );
   }
}


1;
