package tsacinv::autodiscsoftware;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
                group         =>'source',
                label         =>'DiscoveryID',
                dataobjattr   =>'amtsiautodiscsw.ladswid'),

      new kernel::Field::Text(
                name          =>'software',
                label         =>'Software',
                htmlwidth     =>'350px',
                dataobjattr   =>'amtsiautodiscsw.productname'),

      new kernel::Field::Text(
                name          =>'producer',
                label         =>'Producer',
                dataobjattr   =>'amtsiautodiscsw.manufacturer'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                dataobjattr   =>'amtsiautodiscsw.version'),

      new kernel::Field::Text(
                name          =>'path',
                label         =>'path',
                dataobjattr   =>'amtsiautodiscsw.path'),

      new kernel::Field::TextDrop(
                name          =>'systemname',
                label         =>'Systemname',
                vjointo       =>'tsacinv::autodiscsystem',
                vjoinon       =>['systemautodiscid'=>'systemdiscoveryid'],
                vjoindisp     =>'systemname'),

      new kernel::Field::Link(
                name          =>'systemautodiscid',
                label         =>'SystemID',
                dataobjattr   =>'amtsiautodiscsw.lautodiscsystemid'),

      new kernel::Field::Date(
                name          =>'scandate',
                group         =>'source',
                label         =>'Scandate',
                dataobjattr   =>'amtsiautodiscsw.dtscan'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amtsiautodiscsw.source'),


   );
   $self->{use_distinct}=0;

   $self->setDefaultView(qw(software producer version path systemname scandate));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_scandate"))){
     Query->Param("search_scandate"=>">now-7d");
   }
}



sub getSqlFrom
{
   my $self=shift;
   my $from="amtsiautodiscsw";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="";
   return($where);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default software misc source));
}  


1;
