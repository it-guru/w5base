package W5Warehouse::itemsum_debug;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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

   $self->{useMenuFullnameAsACL}=$self->Self(); 
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                dataobjattr   =>'id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Application',
                ignorecase    =>1,
                dataobjattr   =>'name'),

      new kernel::Field::Textarea(
                name          =>'its',
                label         =>'Item summary',
                searchable    =>0,
                htmlheight    =>'340px',
                dataobjattr   =>'itemsummary'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                onRawValue    =>sub{'w5base'}),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'w5repllastsucc'),
   );

   $self->{use_distinct}=0;
   $self->setWorktable("cddwh_itemsummary");
   $self->setDefaultView(qw(linenumber name id srcload));
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


sub SetFilter {
   my $self=shift;

   if (defined($self->{DB})){
      $self->{DB}->{db}->{LongReadLen}=4000000;
   }
   $self->SUPER::SetFilter(@_);
}


sub isQualityCheckValid
{
   return(0);
}


sub isUploadValid
{
   return(0);
}



1;
