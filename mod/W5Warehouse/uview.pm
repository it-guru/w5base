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
                dataobjattr   =>"view_name"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'View Name',
                ignorecase    =>1,
                dataobjattr   =>'view_name'),

      new kernel::Field::Text(
                name          =>'ifaceuser',
                label         =>'Interface User',
                ignorecase    =>1,
                dataobjattr   =>"decode(regexp_replace(view_name,'_.*',''),".
                                "NULL,'[ANY]',".
                                "upper(regexp_replace(view_name,'_.*','')))"),

      new kernel::Field::Text(
                name          =>'ifacetable',
                label         =>'Interface Table',
                ignorecase    =>1,
                dataobjattr   =>"regexp_replace(view_name,'^.*?_','')"),

      new kernel::Field::Textarea(
                name          =>'viewcommand',
                label         =>'View Command',
                htmldetail    =>0,
                searchable    =>0,
                ignorecase    =>1,
                dataobjattr   =>'text'),

      new kernel::Field::Textarea(
                name          =>'recreatecommand',
                label         =>'Recreate Command',
                htmlheight    =>'400px',
                searchable    =>0,
                depend        =>['name','viewcommand','ifaceuser','ifacetable'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $n="create or replace view \"".$current->{name}."\"".
                          " as\n".
                          $current->{viewcommand}.";\n\n";
                   $n.="grant select on \"$current->{name}\" to W5I;\n";
                   if ($current->{ifaceuser} ne "" &&
                       $current->{ifaceuser} ne "[ANY]"){
                      $n.="grant select on \"$current->{name}\" to ".
                          $current->{ifaceuser}.";\n".
                          "create or replace synonym ".
                          $current->{ifaceuser}.".".$current->{ifacetable}." ".
                          "for \"$current->{name}\";\n".
                          "\n\n";
                   }
                   return($n);
                }),

   );
   $self->setWorktable("all_views");
   $self->setDefaultView(qw(linenumber ifaceuser ifacetable name));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="owner='W5REPO' ";
   return($where);
}




1;
