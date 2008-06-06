package kernel::Output::FieldnameTrans;
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
use Data::Dumper;
use base::load;
use kernel::Output::HtmlSubList;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   return(1);
}
sub Label
{
   return("Field translation");
}
sub Description
{
   return("Writes translation from external fieldnames to internal names.");
}

sub MimeType
{
   return("text/plain");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".txt");
}

sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:".$self->MimeType().";charset=iso-8859-1\n\n";
   return($d);
}

sub Init
{
   my $self=shift;
   my ($fh)=@_;
   $self->{out}={};
   $self->{langmax}={};
   $self->{namemax}=0;

   return($self->SUPER::Init(@_));
}


sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $d;
   my @cell=();
   my @cellobj=();
   foreach my $fo (@{$recordview}){
      next if ($fo->Type() eq "Link");
      next if ($fo->Type() eq "Interface");
      next if (!$fo->UiVisible());
      my $name=$fo->Name();
      $name=$fo->{namepref}.$name if (defined($fo->{namepref}));
      foreach my $lang (LangTable()){
         $ENV{HTTP_FORCE_LANGUAGE}=$lang;
         my $label=$fo->Label();
         delete($ENV{HTTP_FORCE_LANGUAGE});
         $self->{namemax}=length($name) if ($self->{namemax}<length($name));
         if ($self->{langmax}->{$lang}<length($label)){
            $self->{langmax}->{$lang}=length($label);
         }
         $self->{out}->{$name}->{$lang}=$label;
      }
   }
   return(undef);
}


sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my @view=@{$self->{fieldobjects}};
   my $d="";
   my $colmax=35;
   $self->{langmax}->{de}=$colmax if ($self->{langmax}->{de}>$colmax);
   $self->{langmax}->{en}=$colmax if ($self->{langmax}->{en}>$colmax);
   $self->{namemax}=8 if ($self->{namemax}<8);
   my $f=sprintf("| %%-%ds | %%-%ds | %%-%ds |\r\n",
             $self->{namemax},$self->{langmax}->{de},$self->{langmax}->{en});
   $d.=sprintf($f,"internal","de","en");
   my $l=sprintf($f,"","","");
   $l=~s/ /-/g;
   $d.=$l;
   foreach my $name (sort(keys(%{$self->{out}}))){
      if (length($self->{out}->{$name}->{de})>$colmax){
         $self->{out}->{$name}->{de}=
           substr($self->{out}->{$name}->{de},0,$colmax-3)."...";
      }
      if (length($self->{out}->{$name}->{en})>$colmax){
         $self->{out}->{$name}->{en}=
           substr($self->{out}->{$name}->{en},0,$colmax-3)."...";
      }
      $d.=sprintf($f,$name,$self->{out}->{$name}->{de},
                           $self->{out}->{$name}->{en});
   }
   return($d);
}

sub getRecordImageUrl
{
   my $self=shift;

   return("../../../public/base/load/icon_translation.gif");
}



1;
