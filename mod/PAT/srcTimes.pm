package PAT::srcTimes;
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

   return("Web/Lists(guid'd83a7456-ed7a-45a8-9dab-ae5a404df8ff')/Items");
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
      my @l=qw(Beginn_MoFr Ende_MoFr Beginn_Sa Ende_Sa Beginn_So Ende_So);
      my @tblock;
      my $c=0;
      while(my $t1=shift(@l)){
        my $t2=shift(@l);
        my ($h1,$m1)=$raw->{$t1}=~m/T([0-9]{2}):([0-9]{2})/;
        my ($h2,$m2)=$raw->{$t2}=~m/T([0-9]{2}):([0-9]{2})/;
        $h1+=1;
        $h2+=1;
        $h1="00" if ($h1 eq "24");
        $h2="00" if ($h2 eq "24");
     
        my $d1=sprintf("%02d:%02d",$h1,$m1);
        my $d2=sprintf("%02d:%02d",$h2,$m2);
        $d2="24:00" if ($d2 eq "00:00");
        $d2="24:00" if ($d2 eq "23:59");  # das scheint ein Eingabefehler

        my $trange="$d1-$d2";

        $trange="" if ($d1 eq $d2);

        push(@tblock,"$c($trange)");
        $c++;
      }
      $rec->{title}=join("+",@tblock);
      $rec->{cdate}=$self->ExpandTimeExpression($raw->{Created},"en","GMT");
      $rec->{mdate}=$self->ExpandTimeExpression($raw->{Modified},"en","GMT");
      push(@result,$rec);
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      #print STDERR Dumper($d->{d}->{results}->[0]);
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
