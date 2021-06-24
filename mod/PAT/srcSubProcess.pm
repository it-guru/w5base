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
                name          =>'srcBusinessSegId',
                htmlwidth     =>'150',
                label         =>'srcBusinessSegId'),

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

      new kernel::Field::Text(
                name          =>'business',
                label         =>'Business'),

      new kernel::Field::Text(
                name          =>'r1',
                label         =>'K1 Ids'),

      new kernel::Field::Text(
                name          =>'r2',
                label         =>'K2 Ids'),

      new kernel::Field::Text(
                name          =>'r3',
                label         =>'R3 Ids'),

      new kernel::Field::Text(
                name          =>'r4',
                label         =>'R4 Ids'),

      new kernel::Field::Text(
                name          =>'onlinetimeid',
                label         =>'OnlinezeitId'),

      new kernel::Field::Text(
                name          =>'usetimeid',
                label         =>'NutzungszeitId'),

      new kernel::Field::Text(
                name          =>'coretimeid',
                label         =>'KernzeitId'),

      new kernel::Field::Text(
                name          =>'ibicoretimeid',
                label         =>'IBI KernzeitId'),

      new kernel::Field::Text(
                name          =>'ibinonprodtimeid',
                label         =>'IBI NutzungszeitId'),

      new kernel::Field::Text(
                name          =>'ibithcoretimeid',
                label         =>'IBI TH KernzeitId'),

      new kernel::Field::Text(
                name          =>'ibithnonprodtimeid',
                label         =>'IBI TH NutzungszeitId'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments'),

      new kernel::Field::Date(
                name          =>'cdate',
                searchable    =>0,
                label         =>'Creation-Date'),

      new kernel::Field::Date(
                name          =>'mdate',
                searchable    =>0,
                label         =>'Modification-Date'),

   );
   $self->setDefaultView(qw(srcBusinessSegId title subarea subprocess mdate cdate));
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

   return("Web/Lists(guid'93d415f2-711f-48f8-b8a1-edd59b1d7631')/Items".
          '?$top=1000');
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
      $rec->{srcBusinessSegId}=$raw->{Gesch_x00e4_ftssegmentId};
      $rec->{title}=$raw->{Title};
      $rec->{description}=$raw->{Beschreibung};
      $rec->{comments}=$raw->{Anmerkungen};
      $rec->{subarea}=$raw->{Teilbereich};
      $rec->{subprocess}=$raw->{Teilprozess};
      $rec->{business}=$raw->{Business};
      $rec->{r1}=$raw->{Kernapplikationen_K1Id}->{results};
      $rec->{r2}=$raw->{Kernapplikationen_K2Id}->{results};
      $rec->{r3}=$raw->{Randapplikationen_R3Id}->{results};
      $rec->{r4}=$raw->{Randapplikationen_R4Id}->{results};
      $rec->{onlinetimeid}=$raw->{OnlinezeitId};
      $rec->{usetimeid}=$raw->{NutzungszeitId};
      $rec->{coretimeid}=$raw->{KernzeitId};
      $rec->{ibicoretimeid}=$raw->{Kernzeit_IBIId};
      $rec->{ibinonprodtimeid}=$raw->{Nutzungszeit_IBIId};
      $rec->{ibithcoretimeid}=$raw->{IBI_Schwelle_KernzeitId};
      $rec->{ibithnonprodtimeid}=$raw->{IBI_Schwelle_NebenzeitId};
      $rec->{cdate}=$self->ExpandTimeExpression($raw->{Created},"en","GMT");
      $rec->{mdate}=$self->ExpandTimeExpression($raw->{Modified},"en","GMT");
      push(@result,$rec);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      #print STDERR Dumper($d->{d}->{results}->[0]);
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
