package FLEXERAatW5W::rawsystemidmapof;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>"flexerasystemid"),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'mapstate',
                htmldetail    =>0,
                label         =>'MapState',
                dataobjattr   =>'mapstate'),

      new kernel::Field::Textarea(
                name          =>'coment',
                label         =>'Comments',
                dataobjattr   =>'cmt'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'firstdate')
   );
   $self->setWorktable("FLEXERA__systemidmap_of");
   $self->setDefaultView(qw(id systemid mapstate mdate));
   return($self);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default  source));
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








1;
