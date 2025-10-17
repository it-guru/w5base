package tsacinv::sclocation;
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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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
                label         =>'SCLocationID',
                dataobjattr   =>'"id"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                uppersearch   =>1,
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(      
                name          =>'company',
                ignorecase    =>1,
                label         =>'Company',
                dataobjattr   =>'"company"'),

      new kernel::Field::Text(
                name          =>'subcompany',
                ignorecase    =>1,
                label         =>'SubCompany',
                dataobjattr   =>'"subcompany"'),

      new kernel::Field::Text(
                name          =>'sclocationid',
                label         =>'SCLocationKey',
                dataobjattr   =>'"sclocationid"'),

      new kernel::Field::Date(
                name          =>'mdate',
                timezone      =>'CET',
                label         =>'Modification date',
                dataobjattr   =>'"mdate"'),
   );
   $self->setDefaultView(qw(linenumber name company subcompany sclocationid));
   $self->setWorktable("sclocation");
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


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

1;
