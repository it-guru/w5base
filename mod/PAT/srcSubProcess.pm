package PAT::srcSubProcess;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::ShellConnectJSON;
use kernel::App::Web::Listedit;


@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::ShellConnectJSON);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'ID'),

      new kernel::Field::Text(
                name          =>'title',
                htmlwidth     =>'150',
                label         =>'Title'),

      new kernel::Field::Text(
                name          =>'subarea',
                htmlwidth     =>'150',
                label         =>'Sub-Area'),

      new kernel::Field::Text(
                name          =>'subprocess',
                htmlwidth     =>'150',
                label         =>'Sub-Process'),

      new kernel::Field::Date(
                name          =>'cdate',
                searchable    =>0,
                label         =>'Creation-Date'),

      new kernel::Field::Date(
                name          =>'mdate',
                searchable    =>0,
                label         =>'Modification-Date'),

   );
   $self->setDefaultView(qw(title subarea subprocess mdate cdate));
   return($self);
}

sub getConfigParameterTag
{
   my $self=shift;
   my $filterset=shift;

   return("srcPAT");
}


sub getShellParameterList
{
   my $self=shift;
   my $filterset=shift;

   return("Web/Lists(guid'93d415f2-711f-48f8-b8a1-edd59b1d7631')/Items");
}


sub reformatExternal
{
   my $self=shift;
   my $d=shift;
   my $filterset=shift;
   my @result;

   foreach my $raw (@{$d->{d}->{results}}){
      my $rec={};
      $rec->{id}=$raw->{Id};
      $rec->{title}=$raw->{Title};
      $rec->{subarea}=$raw->{Teilbereich};
      $rec->{subprocess}=$raw->{Teilprozess};
      $rec->{cdate}=$self->ExpandTimeExpression($raw->{Created},"en","GMT");
      $rec->{mdate}=$self->ExpandTimeExpression($raw->{Modified},"en","GMT");
      push(@result,$rec);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      print STDERR Dumper($d->{d}->{results}->[0]);
   }
   return(\@result);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default",
          "source");
}



1;
