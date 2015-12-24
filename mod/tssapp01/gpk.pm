package tssapp01::gpk;
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'interface_tssapp01_gpk.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'GPK',
                dataobjattr   =>'interface_tssapp01_gpk.name'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Text',
                dataobjattr   =>'interface_tssapp01_gpk.description'),

      new kernel::Field::Text(
                name          =>'phase',
                label         =>'Phase',
                dataobjattr   =>'interface_tssapp01_gpk.phase'),

      new kernel::Field::Text(
                name          =>'perftype',
                label         =>'Leistungstyp',
                dataobjattr   =>'interface_tssapp01_gpk.perftype'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Bemerkung',
                dataobjattr   =>'interface_tssapp01_gpk.comments'),

      new kernel::Field::Text(
                name          =>'response',
                label         =>'Verantwortung',
                dataobjattr   =>'interface_tssapp01_gpk.response'),

      new kernel::Field::Text(
                name          =>'allocation',
                label         =>'Besetzung PL',
                dataobjattr   =>'interface_tssapp01_gpk.allocation'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'interface_tssapp01_gpk.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'interface_tssapp01_gpk.modifydate'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'interface_tssapp01_gpk.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'interface_tssapp01_gpk.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'interface_tssapp01_gpk.srcload'),

   );
   $self->setDefaultView(qw(name description phase perftype mdate));
   $self->setWorktable("interface_tssapp01_gpk");
   $self->{history}={
      update=>[
         'local'
      ]
   };
   return($self);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (effVal($oldrec,$newrec,"name") eq ""){
      $self->LastMsg(ERROR,"invalid GPK");
      return(0);
   }
   if (effVal($oldrec,$newrec,"phase") eq ""){
      $self->LastMsg(ERROR,"invalid Phase");
      return(0);
   }


   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default source));
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
   return("default") if ($self->IsMemberOf("admin"));
   return($self->SUPER::isWriteValid($rec));
}



1;
