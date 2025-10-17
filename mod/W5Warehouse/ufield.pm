package W5Warehouse::ufield;
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
   $self->{use_distinct}=0;

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'viewname',
                label         =>'original Viewname',
                dataobjattr   =>'all_synonyms.table_name'),

      new kernel::Field::Text(
                name          =>'aliasowner',
                label         =>'Interface User',
                dataobjattr   =>'all_synonyms.owner'),

      new kernel::Field::Text(
                name          =>'alias',
                label         =>'Interface Table',
                dataobjattr   =>'all_synonyms.synonym_name'),

      new kernel::Field::Text(
                name          =>'fieldname',
                label         =>'Fieldname',
                dataobjattr   =>'all_tab_columns.column_name'),

      new kernel::Field::Text(
                name          =>'fieldtype',
                label         =>'Fieldtype',
                dataobjattr   =>'all_tab_columns.data_type'),

   );
   $self->setDefaultView(qw(linenumber viewname aliasowner alias fieldname));
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


sub getSqlFrom
{
   my $self=shift;
   my $from="all_synonyms ".
            "join all_tab_columns ".
            "on all_synonyms.table_name=all_tab_columns.table_name";

   return($from);
}

sub initSqlOrder
{
   return("all_synonyms.table_name,all_tab_columns.column_id");
}




sub initSqlWhere
{
   my $self=shift;
   my $where="all_synonyms.table_owner='W5REPO' ";
   return($where);
}




1;
