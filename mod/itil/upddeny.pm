package itil::upddeny;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(      name     =>'id',
                                  label    =>'Update/Refresh argumentation ID'),
      new kernel::Field::Text(    name     =>'name',
                                  searchable=>0, 
                                  label    =>'Update/Refresh possibility'),
      new kernel::Field::Text(    name     =>'dename',
                                  searchable=>0, 
                                  label    =>'de Update/Refresh possibility'),
      new kernel::Field::Text(    name     =>'enname',
                                  searchable=>0, 
                                  label    =>'en Update/Refresh possibility')
   );
   $self->{'data'}=[ 
      {id=>0 },  # Ja 
      {id=>5 },  # Nein, wirtschaftlich nicht sinnvoll
      {id=>10 }, # Nein Technische Kompatibilitätsgründe
      {id=>20 }, # Nein, keine Freigabe durch Hersteller
      {id=>30 }, # Nein, keine Freigabe durch Kunde
      # 35 fällt weg
      # 38 fällt weg
      {id=>38 }, # Nein, Retirement
      {id=>40 }, # Nein, fehlendes Budget
      #{id=>50 }, # Nein, fehlende Resourcen
      {id=>60 }, # Nein, fehlende oder negative Testergebnisse
      {id=>70 }, # Nein, hohes Risiko
      #{id=>99 }, # Nein, other 
      {id=>110 }, # Nein langfristig Technische Kompatibilitätsgründe
      {id=>120 }, # Nein, langfristig keine Freigabe durch Hersteller
      {id=>130 }, # Nein, langfristig keine Freigabe durch Kunde
      #{id=>140 }, # Nein, langfristig fehlendes Budget
      #{id=>150 }, # Nein, langfristig fehlende Resourcen
      {id=>170 }, # Nein, langfristig hohes Risiko
      {id=>180 }, # Nein, mittelfristig bereits geplant
      ];
   $self->setDefaultView(qw(id enname dename));
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(show),$self->SUPER::getValidWebFunctions());
}


sub RawValue
{
   my $self=shift;
   my $field=shift;
   my $rec=shift;

   if ($field eq "name"){
      return($self->T("UpdateDeny($rec->{id})"));
   }
   if ($field eq "dename"){
      $ENV{HTTP_FORCE_LANGUAGE}="de";
      my $t=$self->T("UpdateDeny($rec->{id})");
      delete($ENV{HTTP_FORCE_LANGUAGE});
      return($t);
   }
   if ($field eq "enname"){
      $ENV{HTTP_FORCE_LANGUAGE}="en";
      my $t=$self->T("UpdateDeny($rec->{id})");
      delete($ENV{HTTP_FORCE_LANGUAGE});
      return($t);
   }
   return($self->SUPER::RawValue($field,$rec));
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
