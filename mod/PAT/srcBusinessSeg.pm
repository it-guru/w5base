package PAT::srcBusinessSeg;
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
                name          =>'organisation',
                label         =>'Organisation'),

      new kernel::Field::Text(
                name          =>'orgshort',
                label         =>'Orgshort'),

      new kernel::Field::Text(
                name          =>'sopt',
                label         =>'S-OPT'),

      new kernel::Field::Text(
                name          =>'bseg',
                label         =>'Business-Segement'),

      new kernel::Field::Text(
                name          =>'bsegopt',
                label         =>'Business-Segement OPT'),

      new kernel::Field::Date(
                name          =>'cdate',
                searchable    =>0,
                label         =>'Creation-Date'),

      new kernel::Field::Date(
                name          =>'mdate',
                searchable    =>0,
                label         =>'Modification-Date'),

   );
   $self->setDefaultView(qw(id title count organisation mdate cdate));
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

   return("Web/Lists(guid'a80750a7-0e23-4307-a0e7-35a905422963')/Items");
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
      $rec->{organisation}=$raw->{Gesellschaft};
      $rec->{orgshort}=$raw->{"Gesellschaft_K_x00fc_rzel"};
      $rec->{sopt}=$raw->{"S_x002d_OPT"};
      $rec->{bseg}=$raw->{"Gesch_x00e4_ftssegment"};
      $rec->{bsegopt}=$raw->{"Gesch_x00e4_ftssegment_OPT"};
      $rec->{cdate}=$self->ExpandTimeExpression($raw->{Created},"en","GMT");
      $rec->{mdate}=$self->ExpandTimeExpression($raw->{Modified},"en","GMT");
      push(@result,$rec);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      print STDERR Dumper($d->{d}->{results}->[0]);
   }
   return(\@result);
}




sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_accountid"))){
#     Query->Param("search_accountid"=>'280962857063');
#   }
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
