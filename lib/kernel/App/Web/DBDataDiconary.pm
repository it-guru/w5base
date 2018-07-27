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
   if (!defined($param{MainSearchFieldLines})){
      $param{MainSearchFieldLines}=4;
   }
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
                dataobjattr   =>'f.fullfieldname'),

      new kernel::Field::Text(
                name          =>'fullname',
                align         =>'left',
                label         =>'full fieldpath',
                dataobjattr   =>'lower(f.fullfieldname)'),

      new kernel::Field::Text(
                name          =>'fieldname',
                align         =>'left',
                label         =>'Fieldname',
                dataobjattr   =>'f.fieldname'),

      new kernel::Field::Text(
                name          =>'tablename',
                align         =>'left',
                label         =>'Table',
                dataobjattr   =>'f.tablename'),

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
                dataobjattr   =>"f.isindexed"),

      new kernel::Field::Text(
                name          =>'colid',
                label         =>'ColID',
                dataobjattr   =>"f.colid"),

      new kernel::Field::Text(
                name          =>'schemaname',
                align         =>'left',
                uppersearch   =>'1',
                label         =>'Schema',
                dataobjattr   =>'f.owner'),

   );
   $self->setDefaultView(qw(linenumber schemaname fullname datatype 
                            datalenght isindexed));
   $self->setWorktable("f");

   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $wt=$self->{Worktable};
   my $from="tablefields";

   if ($self->{DictionaryMode} eq "Oracle"){
      $from=<<EOF;
(select distinct t.owner schemaname,
       lower(t.owner||'.'||t.table_name||'.'||t.column_name) fullfieldname,
       t.data_type,
       t.table_name tablename,
       t.column_name fieldname,
       t.column_id colid,
       t.owner,
       t.data_length,
       decode(i.index_name,null,0,1) isindexed,
       t.owner||'.'||t.table_name||'.'||t.column_name id
from all_tab_columns t, all_ind_columns i 
where t.table_name=i.table_name(+) 
      and t.owner=i.table_owner(+) 
      and t.column_name=i.column_name(+)) f
EOF
   }

   if ($self->{DictionaryMode} eq "DB2"){
      $from=<<EOF;
(select trim(tabschema)||'.'||trim(tabname)||'.'||colname fullfieldname,
        trim(tabschema)||'.'||trim(tabname)||'.'||colname colid,
        typename data_type,
        trim(tabname) tablename,
        colname fieldname,
        length   data_length,
        (select '1' from syscat.indexes
         where syscat.indexes.tabschema=syscat.columns.tabschema and
               syscat.indexes.tabname=syscat.columns.tabname and
               syscat.indexes.colnames like '\%+'||syscat.columns.colname||'\%'
         fetch first 1 rows only) isindexed,
        trim(tabschema) owner
 from syscat.columns) f
EOF
   }

   if ($self->{DictionaryMode} eq "MSSQL"){
      $from=<<EOF;
(select 
   lower( table_catalog+'.'+table_name+'.'+column_name)           fullfieldname,
   table_catalog                                                  schemaname,
   table_name                                                     tablename, 
   column_name                                                    fieldname,
   table_catalog                                                  owner, 
   data_type                                                      data_type,
   NULL                                                           isindexed,
   character_maximum_length                                       data_length,
   lower( table_catalog+'.'+table_name+'.'+column_name)           fieldid
from information_schema.columns) f
EOF
   }



   return($from);
}

sub initSearchQuery
{
   my $self=shift;

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   if ($self->{DB}->{dbschema} ne ""){
      if (!defined(Query->Param("search_schemaname"))){
         Query->Param("search_schemaname"=>$self->{DB}->{dbschema});
      }
   }
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}



