package base::reflexion_translation;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'tab',
                align         =>'left',
                label         =>'translation table'),

      new kernel::Field::Text(
                name          =>'internalname',
                label         =>'internal name'),

      new kernel::Field::Text(
                name          =>'de',
                searchable    =>0,
                label         =>'german'),

      new kernel::Field::Text(
                name          =>'en',
                searchable    =>0,
                label         =>'englisch'),

   );
   $self->{'data'}=[];

   $self->setDefaultView(qw(linenumber internalname de en));
   return($self);
}

sub validateSearchQuery
{
   my $self=shift;
   my $trsearch=Query->Param("search_tab");
   if ($trsearch=~m/[\*\?]/){
      $self->LastMsg(ERROR,"wildcard searches are not posible");
      return(undef);
   }
   if ($trsearch=~m/^\s*$/){
      $self->LastMsg(ERROR,"translation table must be specified");
      return(undef);
   }
   my $tr=$self->LoadTranslation($trsearch,1);
   my %tags=();
   foreach my $lang (keys(%$tr)){
      foreach my $tag (keys(%{$tr->{$lang}})){
         $tags{$tag}=1;
      }
   }
   $self->{'data'}=[];
   foreach my $tag (sort(keys(%tags))){
      my %rec=(internalname=>$tag,tab=>$trsearch);
      $rec{de}=$tag;
      $rec{de}=$tr->{de}->{$tag} if (defined($tr->{de}->{$tag}));;
      $rec{en}=$tag;
      $rec{en}=$tr->{en}->{$tag} if (defined($tr->{en}->{$tag}));;
      push(@{$self->{'data'}},\%rec);
   }
   return(1);
}




sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(show),$self->SUPER::getValidWebFunctions());
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
