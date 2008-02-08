package kernel::Field::MultiDst;
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
use Data::Dumper;
use kernel;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{isinitialized}=0;
   $self->{depend}=[] if (!defined($self->{depend}));
   push(@{$self->{depend}},$self->{dsttypfield},$self->{dstidfield});
   if (ref($self->{dst}) ne "ARRAY" && $self->{dst} ne ""){
      push(@{$self->{depend}},$self->{dst}); # the type is loaded from a field
   }
   return($self);
}


sub initialize
{
   my $self=shift;
   my $app=$self->getParent();

   if (ref($self->{dst}) eq "ARRAY"){
      my @dst=@{$self->{dst}};
      my @vjoineditbase=();
      if (defined($self->{vjoineditbase})){
         @vjoineditbase=@{$self->{vjoineditbase}};
      }
      $self->{dstobj}=[];
      $self->{vjoineditbase}=[];
      while(my $objname=shift(@dst)){
         my $display=shift(@dst);
         my $vjoineditbase=shift(@vjoineditbase);
         my $o=getModuleObject($app->Config,$objname);
         my $idname=$o->IdField->Name();
         my $dstrec={idname =>$idname,
                     name   =>$objname,
                     disp   =>$display};
         $dstrec->{obj}=$o;
         if (defined($vjoineditbase)){
            $dstrec->{vjoineditbase}=$vjoineditbase;
         }
         push(@{$self->{dstobj}},$dstrec);
      }
   }
   $self->{isinitialized}=1;
}


sub RawValue
{
   my $self=shift;
   my $current=shift;

   $self->initialize() if (!$self->{isinitialized});
   if (defined($current)){
      if ($current->{$self->{dsttypfield}}){
         my $targetid=$current->{$self->{dstidfield}};
         if (defined($targetid)){
            foreach my $dststruct (@{$self->{dstobj}}){
               next if ($dststruct->{name} ne $current->{$self->{dsttypfield}});
               my $idobj=$dststruct->{obj}->IdField();
               $dststruct->{obj}->ResetFilter();
               $dststruct->{obj}->SetFilter({$idobj->Name()=>\$targetid});
               my ($rec,$msg)=$dststruct->{obj}->getOnlyFirst($dststruct->{disp});
               if (defined($rec)){
                  return($rec->{$dststruct->{disp}});
               }
               if (defined($self->{altnamestore})){
                  my $alt=$self->getParent->getField($self->{altnamestore});
                  my $d=$alt->RawValue($current);
                  $d.="[?]";
                  return($d);
               }
               return("?-unknown dstid-?");
            }
         }
         return;
      }
   }
   return(undef);
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $fobj=$self;
   my $field=$self->Name();
   my $changed=0;
   my $err;

   my $oldval=$hflt->{$field};
   delete($hflt->{$field});
   $fobj->initialize() if (!$fobj->{isinitialized});
   my %k=();
   foreach my $dststruct (@{$fobj->{dstobj}}){
      $dststruct->{obj}->SetFilter({$dststruct->{disp}=>$oldval});
      my $idname=$dststruct->{idname};
      my @l=$dststruct->{obj}->getHashList($idname);
      my @subidlist=();
      foreach my $rec (@l){
         push(@subidlist,$rec->{$idname});
      }
      $k{$dststruct->{name}}=[] if (!defined($k{$dststruct->{name}}));
      push(@{$k{$dststruct->{name}}},@subidlist);
   }
   my $tmpobj=getModuleObject($self->getParent->Config,
                              $self->getParent->Self);
   my @search=();
   foreach my $name (keys(%k)){
      push(@search,{$fobj->{dsttypfield}=>\$name,
                    $fobj->{dstidfield}=>$k{$name}});
   }
   my $idname=$self->getParent->IdField->Name();
   $tmpobj->SetFilter(\@search);
   $tmpobj->SetCurrentView($idname);
   my @l=$tmpobj->getHashList($idname);
   $hflt->{$idname}=[map({$_->{$idname}} @l)];
   my ($subchanged,$suberr)=$self->SUPER::preProcessFilter($hflt);
   return($subchanged+$changed,$err);
}


sub getSelectiveTypeVal
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ($self->{selectivetyp}){
      my $fieldobject=$self->getParent->getField($self->{dsttypfield});
      my $fieldname=$fieldobject->Name();
      my $formval=Query->Param("Formated_".$fieldname);
      if (!defined($formval)){
         $formval=effVal($oldrec,$newrec,$fieldname);
      }
      return($formval);
   }
   return;
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $name=$self->Name();
   return({}) if (!exists($newrec->{$name}));
   my $newval=$newrec->{$name};
   $self->initialize() if (!$self->{isinitialized});

   my $selectivetyp=$self->getSelectiveTypeVal($oldrec,$newrec);
   if ($newval ne ""){
      if (!($newval=~m/^\*/)){
         foreach my $dststruct (@{$self->{dstobj}}){
            next if (defined($selectivetyp) && 
                     $selectivetyp ne $dststruct->{name});
            $dststruct->{obj}->ResetFilter();
            $dststruct->{obj}->SetFilter({$dststruct->{disp}=>\$newval});
            if (defined($dststruct->{vjoineditbase})){
               $dststruct->{obj}->SetNamedFilter("EDITBASE",
                                                 $dststruct->{vjoineditbase});
            }
            my $idname=$dststruct->{obj}->IdField->Name();
            my @l=$dststruct->{obj}->getHashList($dststruct->{disp},$idname);
            if ($#l==0){
               Query->Param("Formated_$name"=>$l[0]->{$dststruct->{disp}});
               my $result={$self->{dstidfield} =>$l[0]->{$idname},
                           $self->{dsttypfield}=>$dststruct->{name}};
               if (defined($self->{altnamestore})){
                  $result->{$self->{altnamestore}}=$l[0]->{$dststruct->{disp}};
               }
               return($result);
            }
         }
      }
      my @select=();
      my $altnewval='"*'.$newval.'*"';

      if (defined($self->{dst})){
         foreach my $dststruct (@{$self->{dstobj}}){
            next if (defined($selectivetyp) && 
                     $selectivetyp ne $dststruct->{name});
            $dststruct->{obj}->ResetFilter();
            $dststruct->{obj}->SetFilter({$dststruct->{disp}=>$altnewval});
            if (defined($dststruct->{vjoineditbase})){
               $dststruct->{obj}->SetNamedFilter("EDITBASE",
                                                 $dststruct->{vjoineditbase});
            }
            my $idname=$dststruct->{obj}->IdField->Name();
            my @l=$dststruct->{obj}->getHashList($dststruct->{disp},$idname);
            foreach my $rec (@l){
               push(@select,{disp=>$rec->{$dststruct->{disp}},
                             name=>$dststruct->{name},
                             id=>$rec->{$idname}});
            }
         }
      }
      if ($#select==0){
         Query->Param("Formated_$name"=>$select[0]->{disp});
         my $result={$self->{dstidfield} =>$select[0]->{id},
                     $self->{dsttypfield}=>$select[0]->{name}};
         if (defined($self->{altnamestore})){
            $result->{$self->{altnamestore}}=$select[0]->{disp};
         }
         return($result);
      }
      if ($#select==-1){
         $self->getParent->LastMsg(ERROR,
                $self->getParent->T("'%s' value not found"), $self->Label);
         return(undef);
      }
      else{
         unshift(@select,{disp=>$newval},{disp=>""});
         my $width="100%";
         $width=$self->{selectwidth} if (defined($self->{selectwidth})); 
         $self->FieldCache->{LastDrop}="<select name=Formated_$name ".
                                       "style=\"width:$width\">";
         foreach my $valrec (@select){
            my $val=$valrec->{disp};
            $self->FieldCache->{LastDrop}.="<option value=\"$val\"";
            if (Query->Param("Formated_$name") eq $val){
               $self->FieldCache->{LastDrop}.=" selected";
            }
            $self->FieldCache->{LastDrop}.=">";
            $self->FieldCache->{LastDrop}.=$val;
            $self->FieldCache->{LastDrop}.="</option>";
         }
         $self->FieldCache->{LastDrop}.="</select>";
         $self->getParent->LastMsg(ERROR,"'%s' value is not unique",
                                         $self->Label);
         return(undef);
      }
   }
   return({});
}



sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   my $app=$self->getParent();
   $self->initialize() if (!$self->{isinitialized});


   if (($mode eq "edit" || $mode eq "workflow") && !$self->{readonly}==1){
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      if ($self->FieldCache->{LastDrop}){
         return($self->FieldCache->{LastDrop});
      }
      return("<input class=finput type=text name=Formated_$name value=\"$d\">");
   }
   if (defined($current->{$self->{dstidfield}}) &&
       defined($current->{$self->{dsttypfield}})){
      my $target=$current->{$self->{dsttypfield}};
      my $targetid;
      foreach my $dststruct (@{$self->{dstobj}}){
         if ($dststruct->{name} eq $target){
            $targetid=$dststruct->{idname};
            last;
         }
      }
      if (defined($targetid)){
         $target=~s/::/\//g;
         $target="../../$target/Detail";
         my $app=$self->getParent();
         my $targetval=$current->{$self->{dstidfield}};
         my $detailx=$app->DetailX();
         my $detaily=$app->DetailY();
         $targetval=$targetval->[0] if (ref($targetval) eq "ARRAY");
         if ($mode eq "HtmlDetail"){
            my $onclick="openwin(\"".
                        "$target?AllowClose=1&$targetid=$targetval\",".
                        "\"_blank\",".
                        "\"height=$detaily,width=$detailx,toolbar=no,".
                        "status=no,resizable=yes,scrollbars=no\")";
            $d="<a class=sublink href=JavaScript:$onclick>".$d."</a>";
         }
      }
   }
   return($d);
}



1;
