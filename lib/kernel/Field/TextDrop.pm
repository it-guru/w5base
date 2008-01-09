package kernel::Field::TextDrop;
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
   $self->{AllowEmpty}=0 if (!defined($self->{AllowEmpty}));
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record
   my $comprec=shift;        # values vor History Handling
   my $name=$self->Name();
   return({}) if (!exists($newrec->{$name}));
   my $newval=$newrec->{$name};
   my $filter={$self->{vjoindisp}=>'"'.$newval.'"'};

   $self->FieldCache->{LastDrop}=undef;

   if (defined($self->{vjoinbase})){
      $self->vjoinobj->SetNamedFilter("BASE",$self->{vjoinbase});
   }
   if (defined($self->{vjoineditbase})){
      $self->vjoinobj->SetNamedFilter("EDITBASE",$self->{vjoineditbase});
   }
   $self->vjoinobj->SetFilter($filter);
   my %param=(AllowEmpty=>$self->{AllowEmpty});
   my $fromquery=Query->Param("Formated_$name");
   if (defined($fromquery)){
      $param{Add}=[{key=>$fromquery,val=>$fromquery}];
      $param{selected}=$fromquery;
   }
   my ($dropbox,$keylist,$vallist)=$self->vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $self->{vjoindisp},
                                                  [$self->{vjoindisp}],%param);
   if ($#{$keylist}<0 && $fromquery ne ""){
      $filter={$self->{vjoindisp}=>'"*'.$newval.'*"'};
      $self->vjoinobj->ResetFilter();
      $self->vjoinobj->SetFilter($filter);
      ($dropbox,$keylist,$vallist)=$self->vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $self->{vjoindisp},
                                                  [$self->{vjoindisp}],%param);
   }
   if ($#{$keylist}>0){
      $self->FieldCache->{LastDrop}=$dropbox;
      $self->getParent->LastMsg(ERROR,"'%s' value '%s' is not unique",
                                      $self->Label,$newval);
      return(undef);
   }
   if ($#{$keylist}<0 && ((defined($fromquery) && $fromquery ne "") ||
                          (defined($newrec->{$name}) && 
                           $newrec->{$name} ne $oldrec->{$name}))){
      if ($newrec->{$name} eq "" && $self->{AllowEmpty}){
         return({$self->{vjoinon}->[0]=>undef});
      }
      $self->getParent->LastMsg(ERROR,"'%s' value '%s' not found",$self->Label,
                                      $newval);
      return(undef);
   }
   Query->Param("Formated_".$name=>$vallist->[0]);
   if (defined($comprec) && ref($comprec) eq "HASH"){
      $comprec->{$name}=$vallist->[0];
   }
   my $result={$self->{vjoinon}->[0]=>
           $self->vjoinobj->getVal($self->vjoinobj->IdField->Name(),$filter)};
   if (defined($self->{altnamestore})){
      $result->{$self->{altnamestore}}=$vallist->[0];      
   }
   return($result);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   my $app=$self->getParent();

   if (!defined($current)){
      # init from Query
      $d=Query->Param("Formated_".$name);
   }
   if ($mode eq "storedworkspace"){
      return($self->FormatedStoredWorkspace());
   }
   my $readonly=0;
   if ($self->readonly($current)){
      $readonly=1;
   }
   if ($self->frontreadonly($current)){
      $readonly=1;
   }

   if (($mode eq "edit" || $mode eq "workflow") && !$readonly){
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      if ($self->FieldCache->{LastDrop}){
         return($self->FieldCache->{LastDrop});
      }
      return("<input class=finput type=text name=Formated_$name value=\"$d\">");
   }
   if (!($d=~m/\[\?\]$/)){
      $d=$self->addWebLinkToFacility($d,$current) if ($mode eq "HtmlDetail");
   }
   return($d);
}

sub RawValue
{
   my $self=shift;
   my $d=$self->SUPER::RawValue(@_);
   my $current=shift;

   if ($self->{VJOINSTATE} eq "not found"){
      if (defined($self->{altnamestore})){
         my $alt=$self->getParent->getField($self->{altnamestore});
         $d=$alt->RawValue($current);
         $d.="[?]";
      }
   }
   return($d);
}


sub FormatedStoredWorkspace
{
   my $self=shift;
   my $name=$self->{name};
   my $d="";

   my @curval=Query->Param("Formated_".$name);
   my $disp="";
   $d="<!-- FormatedStoredWorkspace from textdrop -->";
   foreach my $var (@curval){
      $disp.=$var;
      $d.="<input type=hidden name=Formated_$name value=\"$var\">";
   }
   $d=$disp.$d;
   return($d);
}




1;
