package kernel::App::Web::DBDataDiconary;
#  W5Base Framework
#  Copyright (C) 2008  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
@ISA    = qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                align         =>'left',
                label         =>'ID',
                uivisible     =>'0',
                dataobjattr   =>'f.fieldname'),

      new kernel::Field::Text(
                name          =>'fieldname',
                align         =>'left',
                label         =>'Fieldname',
                dataobjattr   =>'lower(f.fieldname)'),

      new kernel::Field::Text(
                name          =>'datatype',
                uppersearch   =>'1',
                label         =>'Datatype',
                dataobjattr   =>'f.data_type'),

      new kernel::Field::Text(
                name          =>'datalenght',
                uppersearch   =>'1',
                htmlwidth     =>'50px',
                align         =>'right',
                label         =>'Datalenght',
                dataobjattr   =>'f.data_length'),

      new kernel::Field::Boolean(
                name          =>'isindexed',
                label         =>'Index',
                dataobjattr   =>"decode(i.fieldname,null,'0','1')"),

      new kernel::Field::Text(
                name          =>'schemaname',
                align         =>'left',
                uppersearch   =>'1',
                label         =>'Schema',
                dataobjattr   =>'f.owner'),

   );
   $self->setDefaultView(qw(linenumber schemaname fieldname datatype 
                            datalenght isindexed));
   $self->setWorktable("f");

   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $wt=$self->{Worktable};
   my $from=<<EOF;
(select concat(concat(concat(t.owner,'.'),
        concat(t.table_name,'.')),c.column_name) fieldname,
        data_type,data_length,t.owner owner
 from all_TABLES t, all_TAB_COLUMNS c
 where t.TABLE_NAME = c.TABLE_NAME
       and   t.owner = c.OWNER) f,
(select concat(concat(concat(table_owner,'.'),concat(table_name,'.')),column_name) fieldname from all_ind_columns) i
EOF
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="f.fieldname=i.fieldname(+)";
   return($where);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}



