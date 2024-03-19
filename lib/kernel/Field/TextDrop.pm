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
use kernel;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{AllowEmpty}=0 if (!defined($self->{AllowEmpty}));
   $self->{SoftValidate}=0 if (!defined($self->{SoftValidate}));
   $self->{_permitted}->{AllowEmpty}=1;
   if (!defined($self->{depend}) && defined($self->{vjoinon})){
      $self->{depend}=[$self->{vjoinon}->[0]]; # if there is a vjoin, we must
   }                         # be sure, to select the local criteria
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
   my $newval=$self->preParseInputValues($newrec->{$name});
   if (($newval=~m/^"/) && ($newval=~m/"$/)){
      $newval=~s/^"//;
      $newval=~s/"$//;
   }

   my $disp=$self->{vjoindisp};


   $disp=$disp->[0] if (ref($disp) eq "ARRAY");
   my $filter={$disp=>'"'.trim($newval).'"'};
   if (trim($newval) eq ""){
      $filter={$disp=>\''};
   }

   $self->FieldCache->{LastDrop}=undef;
   my $fromquery=trim(Query->Param("Formated_$name"));

   if ($self->{'SoftValidate'}){
      if ((!defined($fromquery) || $fromquery eq $oldrec->{$name}) &&
          $newrec->{$name} eq $oldrec->{$name}){  # no change needs no validate
                                                  # (problem EDITBASE!)
         if (exists($oldrec->{$self->{vjoinon}->[0]})){
            my $oldid=$oldrec->{$self->{vjoinon}->[0]};
            return({$self->{vjoinon}->[0]=>$oldid});
         }
         return({});
      }
   }

   my $vjoinobj=$self->vjoinobj->Clone();

   if (defined($self->{vjoinbase})){
      $vjoinobj->SetNamedFilter("BASE",$self->{vjoinbase});
   }
   if (defined($self->{vjoineditbase})){
      $vjoinobj->SetNamedFilter("EDITBASE",$self->{vjoineditbase});
   }
   if (defined($newrec->{$self->{vjoinon}->[0]}) &&  # just test !!
       $newrec->{$self->{vjoinon}->[0]} ne ""){  # if id is already specified
      $filter={$self->{vjoinon}->[1]=>\$newrec->{$self->{vjoinon}->[0]}};
   }
   $vjoinobj->SetFilter($filter);
   my %param=(AllowEmpty=>$self->AllowEmpty);
   if (defined($fromquery)){
      $param{Add}=[{key=>$fromquery,val=>$fromquery},
                   {key=>"",val=>""}];
      $param{onchange}=
         "if (this.value==''){".
         "transformElement(this,{type:'text',className:'finput'});".
         "}";
      $param{selected}=$fromquery;
   }
   my ($dropbox,$keylist,$vallist)=$vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $disp,
                                                  [$disp],%param);
   if ($#{$keylist}<0 && $fromquery ne ""){
      $filter={$disp=>'"*'.$newval.'*"'};
      $vjoinobj->ResetFilter();
      if (defined($self->{vjoineditbase})){
         $vjoinobj->SetNamedFilter("EDITBASE",$self->{vjoineditbase});
      }
      $vjoinobj->SetFilter($filter);
      ($dropbox,$keylist,$vallist)=$vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $disp,
                                                  [$disp],%param);
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
         if (defined($self->{altnamestore})){
            return({$self->{vjoinon}->[0]=>undef,
                    $self->{altnamestore}=>undef});
         }
         return({$self->{vjoinon}->[0]=>undef});
      }
      $self->getParent->LastMsg(ERROR,"'%s' value '%s' ".
                                      "not found or not allowed",$self->Label,
                                      $newval);
      return(undef);
   }
   Query->Param("Formated_".$name=>$vallist->[0]);
   if (defined($comprec) && ref($comprec) eq "HASH"){
      $comprec->{$name}=$vallist->[0];
   }
   my @r=$vjoinobj->getVal($vjoinobj->IdField->Name(),$filter);
   if ($#r>0){
      $self->getParent->LastMsg(ERROR,"software problem - ".
                                      "not unique select result - contact ".
                                      "developer!");
      return(undef);
   }
   
   my $result={$self->{vjoinon}->[0]=>$r[0]};
   if (defined($self->{altnamestore})){
      $result->{$self->{altnamestore}}=$vallist->[0];      
   }
   return($result);
}

sub ViewProcessor
{
   my $self=shift;
   my $mode=shift;
   my $refid=shift;
   if ($mode eq "XML" && $refid ne ""){
      my $response={document=>{}};

      my $obj=$self->getParent();
      my $idfield=$obj->IdField();
      if (defined($idfield)){
         $obj->ResetFilter();
         $obj->SetFilter({$idfield->Name()=>\$refid});
         $obj->SetCurrentOrder("NONE");
         my ($rec,$msg)=$obj->getOnlyFirst(qw(ALL));
         if ($obj->Ping()){
            my $fo=$obj->getField($self->Name(),$rec);
            if (defined($fo) && defined($rec)){
               my $d=$fo->FormatedDetail($rec,$mode);
               $d=$self->addWebLinkToFacility($d,$rec);
               $d=[$d] if (ref($d) ne "ARRAY");
               $response->{document}->{value}=$d;
            }
            else{
               $response->{document}->{value}="";
            }
         }
         else{
            $response->{document}->{value}=
               "[ERROR: layer 1 information temporarily unavailable]";
         }
      }
      print $self->getParent->HttpHeader("text/xml");
      print hash2xml($response,{header=>1});
      #msg(INFO,hash2xml($response,{header=>1})); # only for debug
      return;
   }
   return;
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   if ($self->{async} && $mode eq "HtmlDetail"){
      return($self->AsyncFieldPlaceholder($current,$mode));
   }
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
      $d=quoteHtml($d);

      my $arialable=$self->Label();
      $arialable=~s/"//g;

      return("<input class=finput aria-label=\"$arialable\" ".
             "type=text name=Formated_$name value=\"$d\">");
   }
   if (ref($d) eq "ARRAY"){
      my $vjoinconcat=$self->{vjoinconcat};
      $vjoinconcat="; " if (!defined($vjoinconcat));
      $d=join($vjoinconcat,@$d);
   }
   if (!($d=~m/\[\?\]$/)){
      $d=$self->addWebLinkToFacility($d,$current) if ($mode eq "Html");
      $d=$self->addWebLinkToFacility($d,$current) if ($mode eq "HtmlDetail");
      $d.=$self->getHtmlContextMenu($current) if ($mode eq "HtmlDetail");
   }
   if ($mode eq "SOAP"){
      $d=~s/&/&amp;/g;;
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
         if (!defined($alt)){
            $d="ERROR - no alt field $self->{altnamestore}";
         }
         else{
            $d=$alt->RawValue($current);
            $d.="[?]";
         }
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
