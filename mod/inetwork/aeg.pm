package inetwork::aeg;
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'I-Network Application ID',
                dataobjattr   =>"id"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Project-reference',
                dataobjattr   =>'projekt'),

      new kernel::Field::Text(
                name          =>'topstatus',
                label         =>'top state',
                dataobjattr   =>'A_3214'),

      new kernel::Field::Text(
                name          =>'sdbid',
                group         =>'sdb',
                label         =>'Support Data base ID',
                dataobjattr   =>'A_2476'),

      new kernel::Field::Text(
                name          =>'sdbapplname',
                group         =>'sdb',
                weblinkto     =>'tbestsupport::sdbappl',
                weblinkon     =>['sdbid'=>'id'],
                label         =>'Applicationname',
                dataobjattr   =>'A_1545'),

      new kernel::Field::Text(
                name          =>'ictoid',
                group         =>'cape',
                label         =>'ICTO-ID',
                dataobjattr   =>'A_3981'),

      new kernel::Field::Text(
                name          =>'w5baseid',
                group         =>'w5base',
                label         =>'W5BaseID',
                dataobjattr   =>"w5baseid"),

      new kernel::Field::Text(
                name          =>'applname',
                group         =>'w5base',
                label         =>'SACM Applicationname',
                dataobjattr   =>"W5BaseName"),

      new kernel::Field::Text(
                name          =>'applref',
                group         =>'w5base',
                label         =>'SACM Reference',
                dataobjattr   =>"A_4152"),

      new kernel::Field::Email(
                name          =>'smemail',
                group         =>'sdb',
                label         =>'System Manager',
                dataobjattr   =>'lower(A_1552)'),

      new kernel::Field::Email(
                name          =>'pmeemail',
                label         =>'Project Manager Development',
                dataobjattr   =>'lower(A_2981)'),

      new kernel::Field::Email(
                name          =>'dbaemail',
                group         =>'w5base',
                label         =>'Database Administrator',
                dataobjattr   =>'lower(A_4632)'),

      new kernel::Field::Email(
                name          =>'opmemail',
                group         =>'w5base',
                label         =>'OPM',
                dataobjattr   =>'lower(A_4633)'),

      new kernel::Field::Email(
                name          =>'opmemail',
                group         =>'w5base',
                label         =>'OPM',
                dataobjattr   =>'lower(A_4633)'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>"'i-network'"),

      new kernel::Field::Date(
                name          =>'mdate',
                label         =>'Modification-Date',
                timezone      =>'CET',
                group         =>'source',
                dataobjattr   =>'Datum'),
   );
   $self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(name applname project smemail ictoid mdate));
   $self->setWorktable("SSTView_Darwin_AEG2");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"inetwork"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","w5base","sdb","cape","source");
}





1;
