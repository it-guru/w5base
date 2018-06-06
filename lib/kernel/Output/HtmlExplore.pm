package kernel::Output::HtmlExplore;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use kernel::TemplateParsing;
use base::load;
use kernel::TabSelector;
use kernel::Field::Date;
@ISA    = qw(kernel::Formater kernel::TemplateParsing);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
  # my $config=$self->getParent->getParent->Config();
   #$self->{SkinLoad}=getModuleObject($config,"base::load");

   return($self);
}

sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.=$app->HttpHeader();
   return($d);
}


sub prepareParent
{
   my $self=shift;
   my $app=shift;

   my %f=(); 

   foreach my $fobj ($app->getFieldObjsByView(["ALL"])){
      if (exists($fobj->{explore})){
         $f{$fobj->Name()}=$fobj->{explore};
      }
   }
   my @view=sort({$f{$a} cmp $f{$b}} keys(%f));



   $app->SetCurrentView(@view);

}



sub ProcessHead
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();

   my $d="";
   $self->Context->{LINE}=0;
   $d="<div class=ExploreOutput>\n\n";

   return($d);
}




sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $fieldbase={};
   my $editgroups=[$app->isWriteValid($rec)];

   my $d="<div class=Record data-id='$rec->{id}'>\n";
   foreach my $fldname (@view){
      my $fld=$app->getField($fldname,$rec);
      my $label=$fld->Label();
      my $val=$fld->FormatedDetail($rec,"HtmlExplore");
      my $raw=$fld->RawValue($rec);
      if ($val ne "" || $raw ne ""){
         $d.="<div class=FieldLabel>".$label."</div>\n";
         $d.="<div class=FieldValue data-id='$fldname' data-raw='$raw'>".
              $val."</div>\n";
      }
   }
   $d.="</div>\n\n";



   $self->Context->{LINE}+=1;
   utf8::encode($d);
   return($d);
}





sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="</div>";

   return($d);
}



1;
