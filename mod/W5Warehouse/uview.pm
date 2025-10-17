package W5Warehouse::uview;
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
use Text::Wrap qw(wrap);
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

      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>"all_views.view_name"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'View Name',
                ignorecase    =>1,
                dataobjattr   =>'all_views.view_name'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'View Status',
                ignorecase    =>1,
                dataobjattr   =>'all_objects.status'),

      new kernel::Field::Text(
                name          =>'ifaceuser',
                label         =>'Interface User',
                ignorecase    =>1,
                dataobjattr   =>
                      "decode(regexp_replace(all_views.view_name,'_.*',''),".
                      "NULL,'[UNDEF]',".
                      "upper(regexp_replace(all_views.view_name,'_.*','')))"),

      new kernel::Field::Text(
                name          =>'ifacetable',
                label         =>'Interface Table',
                ignorecase    =>1,
                dataobjattr   =>"regexp_replace(all_views.view_name,".
                                "'^.*?_','')"),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'FQ Interface Table',
                ignorecase    =>1,
                dataobjattr   =>"regexp_replace(all_views.view_name,".
                                "'^([^_]+)_','\\1.')"),

      new kernel::Field::Textarea(
                name          =>'viewcommand',
                label         =>'View Command',
                htmldetail    =>0,
                searchable    =>0,
                ignorecase    =>1,
                dataobjattr   =>'all_views.text'),

      new kernel::Field::Textarea(
                name          =>'recreatecommand',
                label         =>'Recreate Command',
                htmlheight    =>'400px',
                searchable    =>0,
                depend        =>['name','viewcommand','ifaceuser','ifacetable'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $viewcommand=$current->{viewcommand};
                   $viewcommand=~s/\s*$//s;
                   my $n="create or replace view \"".$current->{name}."\"".
                          " as\n".$viewcommand.";\n\n";
                   $n.="grant select on \"$current->{name}\" to W5I;\n";
                   if ($current->{ifaceuser} ne "" &&
                       $current->{ifaceuser} ne "[UNDEF]"){
                      $n.="grant select on \"$current->{name}\" to ".
                          $current->{ifaceuser}.";\n".
                          "create or replace synonym ".
                          $current->{ifaceuser}.".".$current->{ifacetable}." ".
                          "for \"$current->{name}\";\n".
                          "\n\n";
                   }
                   return($n);
                }),

      new kernel::Field::Textarea(
                name          =>'objectdef',
                label         =>'IO-Object Defintion',
                htmlheight    =>'400px',
                searchable    =>0,
                depend        =>['ifaceuser','ifacetable','viewfields'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $n="NO IO-Object";
                   if ($current->{ifaceuser} ne "" &&
                       $current->{ifaceuser} ne "[UNDEF]"){
                      $n="";
                      my $label=$current->{ifaceuser}.".".
                                $current->{ifacetable}.":";
                      $label.="\n".("=" x length($label))."\n";
                      $Text::Wrap::columns=50;
                      $n.=$label.wrap('','',$current->{viewfields}); 
                      $n.="\n".("-" x $Text::Wrap::columns)."\n";
                   }
                   return($n);
                }),

      new kernel::Field::Textarea(
                name          =>'viewfields',
                label         =>'View Fields',
                ignorecase    =>1,
                dataobjattr   =>
                      "(select listagg(column_name,', ') ".
                      "within group (order by column_name) ".
                      "from all_tab_columns where ".
                      "all_tab_columns.owner='W5REPO' and ".
                      "all_tab_columns.table_name=all_views.view_name) "),
   );
   $self->setWorktable("all_views");
   $self->setDefaultView(qw(linenumber ifaceuser ifacetable name status));
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

sub initSqlWhere
{
   my $self=shift;
   my $where="all_views.owner='W5REPO' ";
   return($where);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable ";

   $from.="join all_objects on ($worktable.owner=all_objects.owner and ".
          "$worktable.view_name=all_objects.object_name)";

   return($from);
}






1;
