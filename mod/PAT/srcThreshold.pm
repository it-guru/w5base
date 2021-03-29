package PAT::srcThreshold;
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

   return("Web/Lists(guid'60c0ac17-bc63-4483-9063-36e392ad45bd')/Items");
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
      my @l=qw(Schwelle_MoFr Schwelle_Sa Schwelle_So);
      my @tblock;
      my $c=0;
      for(my $c=0;$c<=$#l;$c++){
         my $vname=$l[$c];
         my $val=$raw->{$vname};
         my ($h1,$m1)=$val=~m/T([0-9]{2}):([0-9]{2})/;
         $h1+=1;
         $h1="00" if ($h1 eq "24");

         #printf STDERR ("f=$vname val=$val h1=$h1 m1=$m1\n");
         my $min=($h1*60)+$m1;
         $min="" if ($min==0);
         $tblock[$c]="$min";
      }
      $rec->{title}=join(";",@tblock);
      $rec->{cdate}=$self->ExpandTimeExpression($raw->{Created},"en","GMT");
      $rec->{mdate}=$self->ExpandTimeExpression($raw->{Modified},"en","GMT");
      push(@result,$rec);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
  #    print STDERR Dumper($d->{d}->{results}->[0]);
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
