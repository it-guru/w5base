package kernel::Field::Duration;
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
   my %self=@_;
   $self{selectfix}=1  if (!defined($self{selectfix}));
   $self{autogen}=1    if (!defined($self{autogen}));
   $self{searchable}=0 if (!defined($self{searchable}));
   if (!defined($self{dataobjattr})){
      $self{readonly}=1   if (!defined($self{readonly}));
   }
   $self{htmlwidth}="1%"  if (!defined($self{htmlwidth}));
   $self{align}="right"   if (!defined($self{align}));
   $self{visual}="auto"   if (!defined($self{visual}));
   my $self=bless($type->SUPER::new(%self),$type);
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $p=$self->getParent();
   if (!defined($self->{dataobjattr})){
      return(undef) if (!defined($self->{depend}) ||
                        !(ref($self->{depend}) eq "ARRAY"));
      my $d1=undef;
      my $d2=undef;
      foreach my $fo ($p->getFieldObjsByView($self->{depend},
                                             current=>$current)){
         if ($fo->Name() eq $self->{depend}->[0]){
            $d1=$fo->RawValue($current);
            if (defined($d1)){
               $d1=$self->getParent->ExpandTimeExpression($d1,"en",
                                                          $fo->timezone,"GMT");
            }
         }
         if ($fo->Name() eq $self->{depend}->[1]){
            $d2=$fo->RawValue($current);
            if (defined($d2)){
               $d2=$self->getParent->ExpandTimeExpression($d2,"en",
                                                          $fo->timezone,"GMT");
            }
         }
      }
      my $prefix="";
      if (!defined($d2) || $d2 eq ""){
         $d2=NowStamp("en");
         $prefix="~ ";
      }
      if (my $duration=CalcDateDuration($d1,$d2,"GMT")){
         if ($mode eq "HtmlDetail" || $mode eq "HtmlV01" ||
             ($mode=~m/^XLS/i)){
            my $d="";
            if ($self->{visual} eq "auto"){
               $d=$prefix.$duration->{string};
            }
            elsif ($self->{visual} eq "hours"){
               $d=$prefix.sprintf("%.2f",($duration->{totalminutes}/60.0));
            }
            elsif ($self->{visual} eq "minutes"){
               $d=$prefix.sprintf("%d",int($duration->{totalminutes}));
            }
            elsif ($self->{visual} eq "seconds"){
               $d=$prefix.sprintf("%d",int($duration->{totalseconds}));
            }
            if (exists($self->{background})){
               $d=$self->BackgroundColorHandling($mode,$current,$d);
            }
            return($d);
         }
         return($duration->{totalminutes});
      }
   }
   else{
      my $d=$self->RawValue($current,$mode);
      my $name=$self->Name();

      if (defined($d) && $d ne ""){
         $d=$self->second2visual($d);
      }
      if (($mode eq "edit" || $mode eq "workflow") &&
          !defined($self->{vjointo})){
         my $readonly=0;
         if ($self->readonly($current)){
            $readonly=1;
         }
         my $fromquery=Query->Param("Formated_$name");
         if (defined($fromquery)){
            $d=$fromquery;
         }
         return($self->getSimpleInputField($d,$readonly));
      }
      else{
         if ($mode eq "HtmlSubList" || $mode eq "HtmlV01" ||
             $mode eq "HtmlDetail" || $mode eq "HtmlChart"){
            if (exists($self->{background})){
               $d=$self->BackgroundColorHandling($mode,$current,$d);
            }
         }
      }
      return($d);
   }
   return(undef);
}

sub second2visual
{
   my $self=shift;
   my $d=shift;

   if ($self->{visual} eq "hh:mm"){
      my $h=int($d/60/60);
      my $m=int(($d-($h*60*60))/60);
      $d=sprintf("%02d:%02d",$h,$m);
   }
   return($d);
}


sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;

   if (defined($formated)){
      $formated=[$formated] if (ref($formated) ne "ARRAY");
      return(undef) if (!defined($formated->[0]));
      $formated=trim($formated->[0]) if (ref($formated) eq "ARRAY");
      return({$self->Name()=>undef}) if ($formated=~m/^\s*$/);
      $formated=trim($formated);
      if ($self->{visual} eq "hh:mm"){
         if (my ($h,$m)=$formated=~m/^(\d+):(\d+)$/){
            $formated=($h*60*60)+($m*60);
         } 
         else{
            $self->getParent->LastMsg(ERROR,
                  sprintf($self->getParent->T(
                          'invalid format for duration for "%s"'),
                          $self->Label()));
            return(undef);
         }
      }

      return({$self->Name()=>$formated});
   }
   return({});
}

sub prepUploadRecord   # prepair one record on upload
{
   my $self=shift;
   my $newrec=shift;
   my $oldrec=shift;
   my $bk=$self->Unformat([$newrec->{$self->{name}}],$newrec);

   if (defined($bk)){
      if (exists($bk->{$self->{name}})){
         $newrec->{$self->{name}}=$bk->{$self->{name}};
      }
   }
   return(1);
}









1;
