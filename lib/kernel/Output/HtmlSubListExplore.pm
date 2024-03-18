package kernel::Output::HtmlSubListExplore;
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
use kernel::cgi;
use base::load;
use Class::ISA;
use kernel::Output::HtmlSubList;
@ISA    = qw( kernel::Output::HtmlSubList);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
  # my $config=$self->getParent->getParent->Config();
   #$self->{SkinLoad}=getModuleObject($config,"base::load");

   return($self);
}

sub Description
{
   return("Explore SubList elements");
}


sub ProcessHead
{
   my ($self,$fh,$rec,$msg,$param)=@_;

   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="";
   $d.="<table class=SubListExplore width=\"100%\">\n";

   $d.="<tbody>\n";
   return($d);
}
sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   $self->{lineclass}=1 if (!exists($self->{lineclass}));
   my $d="";
   my $lineclass="subline".$self->{lineclass};
   my $lineonclick;
   my $idfield=$app->IdField();
   my $idfieldname=ref($idfield) ? $idfield->Name():undef;
   my $id=ref($idfield) ? $idfield->RawValue($rec):undef;
   $id=$id->[0] if (ref($id) eq "ARRAY");


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


   if (grep(/^Detail$/,$app->getValidWebFunctions())){
      if ($idfield){
         my $dest=$app->Self();
         if (defined($id)){
            my $lq=new kernel::cgi({});
            $lq->Param($idfieldname=>$id);
            $lq->Param(AllowClose=>1);
            my $urlparam=$lq->QueryString();
            $dest=~s/::/\//g;
            $dest="../../$dest/Detail?$urlparam";
            $dest=~s/"/ /g;
            my $detailx=$app->DetailX();
            my $detaily=$app->DetailY();
            my $winname="_blank";
            if (defined($UserCache->{winhandling}) &&
                $UserCache->{winhandling} eq "winonlyone"){
               $winname="W5BaseDataWindow";
            }
            if (defined($UserCache->{winhandling})
                && $UserCache->{winhandling} eq "winminimal"){
               $winname="W5B_".$dest."_".$id;
               $winname=~s/[^a-z0-9]/_/gi;
            }
            $lineonclick="custopenwin(\"$dest\",\"$winsize\",".
                         "$detailx,$detaily,\"$winname\")";
         }
         else{
           $lineonclick=undef;
         }
      }
   }
   $d.="<tr><td>";
   for(my $c=0;$c<=$#view;$c++){
      my $fieldname=$view[$c];
      my $field=$app->getField($fieldname);
      my $data="undefined";
      my $fclick=$lineonclick;
      my $weblinkname=$app->Self();
      if (defined($field)){
         $data=$app->findtemplvar({
                                   viewgroups=>$viewgroups,
                                   mode=>'HtmlSubList',
                                   current=>$rec
                                  },$fieldname,
                                     "formated");
        # my $data=$field->FormatedResult("html");
         if (ref($field->{onClick}) eq "CODE"){
            my $fc=&{$field->{onClick}}($field,$self,$app,$rec);
            $fclick=$fc if ($fc ne "");
         }
         elsif (defined($field->{weblinkto}) && $field->{weblinkto} ne "none"){
            my $weblinkon=$field->{weblinkon};
            my $weblinkto=$field->{weblinkto};
            if (ref($weblinkto) eq "CODE"){
               ($weblinkto,$weblinkon)=&{$weblinkto}($field,$data,$rec);
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
      }
      my $style;
      my $align;
      if (defined($field->{align})){
         $align=" align=$field->{align}";
      }
      my $nowrap="";
      if (defined($field->{nowrap}) && $field->{nowrap}==1){
         $style.="white-space:nowrap;";
         $nowrap=" nowrap";
      }
      if ($c==0){
         if ($fclick ne ""){
            $d.="<div class=\"SubListExploreClick cssicon arrow_right\" ".
                "style=\"align:right;cursor:pointer;float:right\" ".
                "onClick=$fclick>&nbsp;</div>";
         }
      }

      $d.="<div class=subdatafield valign=top $align";
      $data="&nbsp;" if ($data=~m/^\s*$/);
      $d.=" style=\"$style\"";
      if ($data=~m/\S{38}/){
         $data=~s/(\S{37})(\S+)/$1 $2/g;
      }
      $d.="$nowrap>".$data."</div>\n";
   }
   $d.="</td></tr>\n";
   $self->{lineclass}++;
   $self->{lineclass}=1 if ($self->{lineclass}>2);
   return($d);
}
sub ProcessBottom
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="</tbody></table>";

   return($d);
}


1;
