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
use kernel;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{isinitialized}=0;
   $self->{weblinkto}=\&calcWebLink;
   $self->{depend}=[] if (!defined($self->{depend}));
   push(@{$self->{depend}},$self->{dsttypfield},$self->{dstidfield});
   if (ref($self->{dst}) ne "ARRAY" && $self->{dst} ne ""){
      push(@{$self->{depend}},$self->{dst}); # the type is loaded from a field
   }
   return($self);
}

sub calcWebLink
{
   my $self=shift;
   my $d=shift;
   my $current=shift;
   my $weblinkto;
   my $weblinkon;

   my $target=$current->{$self->{dsttypfield}};
   if ($target ne "" && $target ne "none"){
      my $targetid;
      foreach my $dststruct (@{$self->{dstobj}}){
         if ($dststruct->{name} eq $target){
            $targetid=$dststruct->{idname};
            last;
         }
      }
      return($target,[$self->{dstidfield}=>$targetid]);
   }

   return($weblinkto,$weblinkon);
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
   my $mode=shift;

   $self->initialize() if (!$self->{isinitialized});
   if (defined($current)){
      my $dsttyp;
      my $dsttypobj=$self->getParent->getField($self->{dsttypfield});
      if (defined($dsttypobj)){
         $dsttyp=$dsttypobj->RawValue($current,$mode);
      }
      if (defined($dsttyp) && $dsttyp ne ""){
         my $targetidobj=$self->getParent->getField($self->{dstidfield});
         my $targetid;
         if (defined($targetidobj)){
            $targetid=$targetidobj->RawValue($current,$mode);
         }
         if (defined($targetid) && $targetid ne ""){
            my $attr=$self->{dataobjattr};
            $attr=$self->{name} if ($attr eq "");
            if (exists($current->{$attr})){
               return($current->{$attr});
            }
            foreach my $dststruct (@{$self->{dstobj}}){
               next if ($dststruct->{name} ne $dsttyp);

               my $idobj=$dststruct->{obj}->IdField();
               $dststruct->{obj}->ResetFilter();
               $dststruct->{obj}->SetFilter({$idobj->Name()=>\$targetid});
               my ($rec,$msg)=$dststruct->{obj}->getOnlyFirst($dststruct->{disp});
               if (defined($rec)){
                  my $dstfld=$dststruct->{obj}->getField($dststruct->{disp},
                                                         $rec);
                  if (!defined($dstfld)){
                     msg(ERROR,"fail to find $dststruct->{disp} ".
                               "in $dststruct->{obj}");
                  }
                  return($dstfld->RawValue($rec));
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
         return(undef);
      }
      if (defined($self->{altnamestore})){
         my $alt=$self->getParent->getField($self->{altnamestore});
         my $d=$alt->RawValue($current);
         return($d) if ($d ne "");
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
   my $newval=$self->preParseInputValues($newrec->{$name});
   $self->initialize() if (!$self->{isinitialized});

   my $selectivetyp=$self->getSelectiveTypeVal($oldrec,$newrec);
   if ($newval ne ""){
      if (!($newval=~m/^\*/)){
         $newval=trim($newval);  # remove all spaces
         if (($newval=~m/^"/) && ($newval=~m/"$/)){
            $newval=~s/^"//;
            $newval=~s/"$//;
         }
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
      my $altnewval=$newval;
      $altnewval='"*'.$newval.'*"' if (!($newval=~m/[\*\?]/));

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
               my $fo=$dststruct->{obj}->getField($dststruct->{disp},$rec);
              
               push(@select,{disp=>$fo->RawValue($rec),
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
         $width=$self->{htmleditwidth} if (defined($self->{htmleditwidth})); 
         $self->FieldCache->{LastDrop}="<select name=Formated_$name ".
                                       "style=\"width:$width\" ".
                "onchange=\"if (this.value==''){".
                "transformElement(this,{type:'text',className:'finput'});".
                "}\" ".
                 ">";
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
   my $d;
   my $fromquery=Query->Param("Formated_".$self->Name());
   $d=$self->RawValue($current);
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
      $d=quoteHtml($d);
      return("<input class=finput type=text name=Formated_$name value=\"$d\">");
   }
   if (!($d=~m/\[\?\]$/)){
      $d=$self->addWebLinkToFacility($d,$current) if ($mode eq "HtmlDetail");
   }
   return($d);
}



1;
