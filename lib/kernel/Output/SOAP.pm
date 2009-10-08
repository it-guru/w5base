package kernel::Output::SOAP;
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
   return(0);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_xml.gif");
}
sub Label
{
   return("SubOutput to SOAP");
}
sub Description
{
   return("Format as lowlevel SOAP-File language neutral");
}

sub MimeType
{
   return("text/xml");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".xml");
}


sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:".$self->MimeType()."\n\n";
   return($d);
}

sub Init
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   return();
}

sub getRecordTag
{
   my $self=shift;
   return("record");
}

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my @view=$app->getFieldObjsByView([$app->getCurrentView()],current=>$rec);
   my $fieldbase={};
   map({$fieldbase->{$_->Name()}=$_} @view);

   my %rec=($self->getRecordTag()=>{});
   my %xmlfields;
   foreach my $fo (@view){
      my $name=$fo->Name();
      my $v=$fo->UiVisible("XML",current=>$rec);
      next if (!$v && ($fo->Type() ne "Interface"));
      if (!defined($self->{fieldkeys}->{$name})){
         push(@{$self->{fieldobjects}},$fo);
         $self->{fieldkeys}->{$name}=$#{$self->{fieldobjects}};
      }
    
      $xmlfields{$name}=$fo;
   }
   foreach my $name (sort(keys(%xmlfields))){
      my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                   fieldbase=>$fieldbase,
                                   current=>$rec,
                                   mode=>'SOAP',
                                  },$name,"formated");
      if (defined($data)){
         $rec{$self->getRecordTag()}->{$name}=$data;
      }
   }
   my $d=hash2xml(\%rec);
   my $p=$self->getParent->getParent->Self();
   $p=~s/::/\//g;
   $d=~s/<record>/<record type="$p">/;
   return($d);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my $app=$self->getParent->getParent();
   $d="";
   return($d);
}

sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my $app=$self->getParent->getParent();
   $d="";
   return($d);
}

1;
