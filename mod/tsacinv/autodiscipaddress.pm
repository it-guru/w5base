package tsacinv::autodiscipaddress;
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
use tsacinv::lib::tools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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
                dataobjattr   =>'autodiscipaddress."id"'),

      new kernel::Field::Text(
                name          =>'address',
                label         =>'IP-Address',
                htmlwidth     =>'200px',
                dataobjattr   =>'"address"'),

      new kernel::Field::Text(
                name          =>'physicaladdress',
                label         =>'physical Address',
                dataobjattr   =>'"physicaladdress"'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'"systemid"'),

      new kernel::Field::TextDrop(
                name          =>'systemname',
                label         =>'Systemname',
                vjointo       =>'tsacinv::autodiscsystem',
                vjoinon       =>['systemautodiscid'=>'systemdiscoveryid'],
                vjoindisp     =>'systemname'),
                #dataobjattr   =>'autodiscipaddress."systemname"'),

      new kernel::Field::Text(
                name          =>'usage',
                label         =>'Usage',
                dataobjattr   =>'autodiscipaddress."usage"'),

      new kernel::Field::Text(
                name          =>'systemautodiscid',
                label         =>'System DiscoveryID',
                dataobjattr   =>'autodiscipaddress."systemautodiscid"'),

      new kernel::Field::Date(
                name          =>'scandate',
                group         =>'source',
                label         =>'Scandate',
                dataobjattr   =>'autodiscipaddress."scandate"'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'autodiscipaddress."srcsys"'),


   );
   $self->{use_distinct}=0;
   $self->setWorktable("autodiscipaddress");

   $self->setDefaultView(qw(systemid systemname usage address physicaladdress 
                            scandate));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_scandate"))){
#     Query->Param("search_scandate"=>">now-7d");
#   }
#}

#sub getSqlFrom
#{
#   my $self=shift;
#   my $from="autodiscipaddress join autodiscsystem ".
#            " on autodiscipaddress.\"systemautodiscid\"=".
#            "autodiscsystem.\"systemdiscoveryid\" ";
#   return($from);
#}




sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default software misc source));
}  


1;
