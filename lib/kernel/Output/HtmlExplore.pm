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

   my @fl=$app->getFieldObjsByView(["ALL"]);
   foreach my $fobj (@fl){
      if (exists($fobj->{explore})){
         $f{$fobj->Name()}=$fobj->{explore};
      }
   }
   my @view=sort({$f{$a} <=> $f{$b}} keys(%f));



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

   #######################################################################
   my $UserCache=$self->getParent->getParent->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   my $winsize="normal";
   if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
      $winsize=$UserCache->{winsize};
   }
   #######################################################################




   foreach my $fieldname (@view){
      my $field=$app->getField($fieldname,$rec);
      my $label=$field->Label();
      my $fldname=$fieldname;
      my $val=$field->FormatedDetail($rec,"HtmlExplore");
      my $raw=$field->RawValue($rec);
      my $fclick;
      my $weblinkname;
      if ($val ne "" || $raw ne ""){
         $d.="<div class=FieldLabel>".$label."</div>\n";
         if ($val=~m/\S{35}/){
            $val=~s/(\S{30})(\S+)/$1 $2/g;
         }

         if (ref($field->{onClick}) eq "CODE"){
            my $fc=&{$field->{onClick}}($self,$app);
            $fclick=$fc if ($fc ne "");
         }
         elsif (defined($field->{weblinkto}) && $field->{weblinkto} ne "none"){
            my $weblinkon=$field->{weblinkon};
            my $weblinkto=$field->{weblinkto};
            if (ref($weblinkto) eq "CODE"){
               ($weblinkto,$weblinkon)=&{$weblinkto}($field,$val,$rec);
            }

            if (defined($weblinkto) && 
                defined($weblinkon) && $weblinkto ne "none"){

               # dynamic target dataobj detection
               if (ref($weblinkto) ne "SCALAR"){
                  my $p=$self->getParent;
                  $p=$p->getParent if (defined($p));
                  if (defined($p) && $p->can("findNearestTargetDataObj")){
                     $weblinkto=$p->findNearestTargetDataObj(
                                $weblinkto,"sublist:".$self->getParent->Self);
                  }
                  if (!ref($self->{weblinkto})){ # 
                     $field->{weblinkto}=$weblinkto;
                  }
               }
               if (ref($weblinkto) eq "SCALAR"){
                  $weblinkto=$$weblinkto; # dereferenzieren von weblinkto
               }
               $weblinkto=$$weblinkto if (ref($weblinkto) eq "SCALAR");
               # dynamic target dataobj detection END

               my $target=$weblinkto;
               $weblinkname=$weblinkto;

               $target=~s/::/\//g;
               $target="../../$target/Detail";
               $target=~s/"/ /g;
               my $targetid=$weblinkon->[1];
               my $targetval;

               if (!defined($targetid)){
                  $targetid=$weblinkon->[0];
                  $targetval=undef;
               }
               else{
                  my $linkfield=$self->getParent->getParent->
                                       getField($weblinkon->[0]);
                  if (!defined($linkfield)){
                     msg(ERROR,"can't find field '%s' in '%s'",$weblinkon->[0],
                         $self->getParent);
                     return($d);
                  }
                  $targetval=$linkfield->RawValue($rec);
               }
               if (defined($targetval) && $targetval ne ""){
                  my $detailx=$self->getParent->getParent->DetailX();
                  my $detaily=$self->getParent->getParent->DetailY();
                  $targetval=$targetval->[0] if (ref($targetval) eq "ARRAY");
                  my %q=('AllowClose'=>1,
                         "search_$targetid"=>$targetval);
                  my $winname="_blank";
                  if (defined($UserCache->{winhandling}) &&
                      $UserCache->{winhandling} eq "winonlyone"){
                     $winname="W5BaseDataWindow";
                  }
                  if (defined($UserCache->{winhandling})
                      && $UserCache->{winhandling} eq "winminimal"){
                     $winname="W5B_".$weblinkto."_".$targetval;
                     $winname=~s/[^a-z0-9]/_/gi;
                  }
                  my $dest="$target?".kernel::cgi::Hash2QueryString(%q);
                  $fclick="custopenwin(\"$dest\",\"$winsize\",".
                               "$detailx,$detaily,\"$winname\")";
               }
            }
         }
         $fclick=undef if ($field->Type() eq "SubList");
         $fclick=undef if ($field->Type() eq "DynWebIcon");
         $fclick=undef if ($self->{nodetaillink});
         my $p=$self->getParent->getParent;
         if (defined($fclick)){
            $weblinkname=sprintf($p->T('klick to view &lt;%s&gt;'),
                         $p->T($weblinkname,$weblinkname));
         }
         else{
            $weblinkname="";
         }

         if ($fclick ne ""){
            $d.="<div class=\"SubListExploreClick cssicon arrow_right\" ".
                "style=\"align:right;cursor:pointer;float:right\" ".
                "onClick=$fclick>&nbsp;</div>";
         }

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
