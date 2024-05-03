package kernel::Field;
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
use kernel::Field::Id;
use kernel::Field::RecordUrl;
use kernel::Field::Vector;
use kernel::Field::Text;
use kernel::Field::TextURL;
use kernel::Field::FlexBox;
use kernel::Field::Databoss;
use kernel::Field::Password;
use kernel::Field::JoinUniqMerge;
use kernel::Field::Phonenumber;
use kernel::Field::File;
use kernel::Field::Float;
use kernel::Field::Currency;
use kernel::Field::Number;
use kernel::Field::Percent;
use kernel::Field::Email;
use kernel::Field::Link;
use kernel::Field::DynWebIcon;
use kernel::Field::Interface;
use kernel::Field::XMLInterface;
use kernel::Field::Linenumber;
use kernel::Field::TextDrop;
use kernel::Field::MultiDst;
use kernel::Field::Textarea;
use kernel::Field::Htmlarea;
use kernel::Field::GoogleMap;
use kernel::Field::GoogleAddrChk;
use kernel::Field::ListWebLink;
use kernel::Field::Select;
use kernel::Field::Boolean;
use kernel::Field::SubList;
use kernel::Field::Group;
use kernel::Field::Contact;
use kernel::Field::ContactLnk;
use kernel::Field::PhoneLnk;
use kernel::Field::FileList;
use kernel::Field::TimeSpans;
use kernel::Field::Date;
use kernel::Field::MDate;
use kernel::Field::CDate;
use kernel::Field::Owner;
use kernel::Field::Creator;
use kernel::Field::Editor;
use kernel::Field::RealEditor;
use kernel::Field::Import;
use kernel::Field::Dynamic;
use kernel::Field::Container;
use kernel::Field::Objects;
use kernel::Field::KeyHandler;
use kernel::Field::KeyText;
use kernel::Field::Mandator;
use kernel::Field::Duration;
use kernel::Field::Message;
use kernel::Field::QualityText;
use kernel::Field::QualityState;
use kernel::Field::QualityOk;
use kernel::Field::QualityLastDate;
use kernel::Field::EnrichLastDate;
use kernel::Field::QualityResponseArea;
use kernel::Field::IssueState;
use kernel::Field::Fulltext;
use kernel::Field::Interview;
use kernel::Field::InterviewState;
use kernel::Field::WorkflowLink;
use kernel::Field::MatrixHeader;
use kernel::Field::DatacareAssistant;
use kernel::Field::CryptText;
use kernel::Field::TRange;
use kernel::Field::RecordRights;
use kernel::Field::IndividualAttr;
use kernel::Universal;
use Text::ParseWhere;
@ISA    = qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   $self->{group}="default" if (!defined($self->{group}));
   $self->{_permitted}->{mainsearch}=1; # erzeugt großes Suchfeld
   $self->{_permitted}->{searchable}=1; # stellt das Feld als suchfeld dar
   $self->{_permitted}->{defsearch}=1;  # automatischer Focus beim Suchen
   $self->{_permitted}->{selectable}=1; # Feld kann im select statement stehen
   $self->{_permitted}->{fields}=1;     # Feld erzeugt dynamisch zusätzl. Felder
   $self->{_permitted}->{align}=1;      # Ausrichtung
   $self->{_permitted}->{valign}=1;
   $self->{_permitted}->{htmlhalfwidth}=1; # halbe breite in HtmlDetail
   $self->{_permitted}->{nowrap}=1;     # kein automatischer Zeilenumbruch
   $self->{_permitted}->{maxlength}=1;  # Zeichen Anzahl Eingabe limit
   $self->{_permitted}->{htmlwidth}=1;  # Breite in der HTML Ausgabe (Spalten)
   $self->{_permitted}->{xlswidth}=1;   # Breite in der XLS Ausgabe (Spalten)
   $self->{_permitted}->{xlscolor}=1;   # Farbe der Spalte in XLS Ausgabe
   $self->{_permitted}->{xlsbgcolor}=1; # Hintergrund der Spalte in XLS Ausgabe
   $self->{_permitted}->{xlsbcolor}=1;  # Rahmen der Spalte in XLS Ausgabe
   $self->{_permitted}->{xlsnumformat}=1;  # Zellenformat
   $self->{_permitted}->{uivisible}=1;  # Anzeige in der Detailsicht bzw. Listen
   $self->{_permitted}->{history}=1;    # Über das Feld braucht History
   $self->{_permitted}->{htmldetail}=1; # Anzeige in der Detailsicht
   $self->{_permitted}->{htmllabelwidth}=1; # min Breite der Label spalte
   $self->{_permitted}->{detailadd}=1;  # zusätzliche Daten bei HtmlDetail
   $self->{_permitted}->{translation}=1;# Übersetzungsbasis für Labels
   $self->{_permitted}->{selectfix}=1;  # force to use this field alwasy in sql
   $self->{_permitted}->{default}=1;    # Default value on new records
   $self->{_permitted}->{unit}=1;       # Unit prefix in detail view
   $self->{_permitted}->{background}=1; # Color of Background (if posible)
   $self->{_permitted}->{label}=1;      # Die Beschriftung des Felds
   $self->{_permitted}->{readonly}=1;   # Nur zum lesen
   $self->{_permitted}->{allowAnyLatin1}=1; # allow ALL Latin1 Chars (f.e. á)
   $self->{_permitted}->{preparseSearch}=1;  # preparse search hash value
   $self->{_permitted}->{frontreadonly}=1;   # Nur zum lesen
   $self->{_permitted}->{grouplabel}=1; # 1 wenn in HTML Detail Grouplabel soll
   $self->{_permitted}->{dlabelpref}=1; # Beschriftungs prefix in HtmlDetail
   $self->{_permitted}->{extLabelPostfix}=1; # Label Ext on all expect Detail
   $self->{searchable}=1 if (!defined($self->{searchable}));
   $self->{selectable}=1 if (!defined($self->{selectable}));
   $self->{htmldetail}=1 if (!defined($self->{htmldetail}));
   if (!defined($self->{preferArray})){
      $self->{preferArray}=0;
   }
   if (!defined($self->{selectfix})){
      $self->{selectfix}=0;
   }
   if (!defined($self->{uivisible}) && $self->{selectable}){
      $self->{uivisible}=1;
   }
   if (!defined($self->{history})){
      $self->{history}=1;
   }
   if (!defined($self->{allowAnyLatin1})){
      $self->{allowAnyLatin1}=0;
   }
   if (!defined($self->{valign})){
      $self->{valign}="center";
      $self->{valign}="top";
   }
   if (!defined($self->{grouplabel})){
      $self->{grouplabel}=1;
   }
   if (!defined($self->{uivisible}) && !$self->{selectable}){
      $self->{uivisible}=0;
   }
   $self->{vjoinconcat}="; " if (!exists($self->{vjoinconcat}));
   $self->{_permitted}->{vjoinconcat}=1;# Verkettung der Ergebnisse
   if (defined($self->{vjointo})){
      if (!defined($self->{weblinkto})){
         $self->{weblinkto}=$self->{vjointo};
      }
      if (!defined($self->{weblinkon})){
         $self->{weblinkon}=$self->{vjoinon};
      }
   }
   return($self);
}


sub getNearestWebLinkTarget
{
   my $self=shift;
   my $d=shift;
   my $current=shift;

   my $weblinkon=$self->{weblinkon};
   my $weblinkto=$self->{weblinkto};
   if (ref($weblinkto) eq "CODE"){
      ($weblinkto,$weblinkon)=&{$weblinkto}($self,$d,$current);
   }
   if (lc($weblinkto) eq "none"){
      return(undef,undef);
   }
   my $oldweblinkto=$weblinkto;
   if (defined($weblinkto) && defined($weblinkon)){
      if (ref($weblinkto) ne "SCALAR"){
         # dynamic Target DataObject detection
         if ($self->getParent->can("findNearestTargetDataObj")){
            $weblinkto=$self->getParent->findNearestTargetDataObj($weblinkto,
                       "field:".$self->Name);
         }
         if (!ref($self->{weblinkto})){ # if no reference, store it cached
            $self->{weblinkto}=$weblinkto;
         }
      }
   }
   my $newweblinkto=$weblinkto;
   if ($newweblinkto ne $oldweblinkto){
      #printf STDERR ("change target for $self->{name} ".
      #               "from $oldweblinkto to $newweblinkto\n");
   }
   return($weblinkto,$weblinkon);
}



sub getNearestVjoinTarget
{
   my $self=shift;

   my $vjointo=$self->{vjointo};
   if (defined($vjointo) && ref($vjointo) ne "SCALAR" && $vjointo ne ""){
      # dynamic Target DataObject detection
      if ($self->getParent->can("findNearestTargetDataObj")){
         $vjointo=$self->getParent->findNearestTargetDataObj($vjointo,
                    "field:".$self->Name);
      }
      if (!ref($self->{vjointo})){ # if no reference, store it cached
         $self->{vjointo}=$vjointo;
      }
   }
   return($vjointo);
}





sub addWebLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;
   my %param=@_;

   my ($weblinkto,$weblinkon)=$self->getNearestWebLinkTarget($d,$current);

   if (defined($weblinkto) && defined($weblinkon)){
      if (ref($weblinkto) eq "SCALAR"){
         $weblinkto=$$weblinkto; # dereferenzieren von weblinkto
      }
      my $target=$weblinkto;
      $target=~s/::/\//g;
      $target="../../$target/Detail";
      my $targetid=$weblinkon->[1];
      my $targetval;
      if (!defined($targetid)){
         $targetid=$weblinkon->[0];
         $targetval=$d;
      }
      else{
         my $linkfield=$self->getParent->getField($weblinkon->[0]);
         if (!defined($linkfield)){
            msg(ERROR,"can't find field '%s' in '%s'",$weblinkon->[0],
                $self->getParent);
            return($d);
         }
         $targetval=$linkfield->RawValue($current);
      }
      if (defined($targetval) && $targetval ne "" && 
          (!ref($targetval) || 
           (ref($targetval) eq "ARRAY" && $#{$targetval}==0))){
         my $detailx=$self->getParent->DetailX();
         my $detaily=$self->getParent->DetailY();
         $targetval=$targetval->[0] if (ref($targetval) eq "ARRAY");
         my $dest=$target;
         if ($targetval=~m/\s/){  # id contains spaces - new since SM9 interf.
            $targetval='"'.$targetval.'"';
         }
         $dest.="?".kernel::cgi::Hash2QueryString(
            'AllowClose'=>1,
            "search_$targetid"=>'"'.$targetval.'"'
         );
         my $UserCache=$self->getParent->Cache->{User}->{Cache};
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
         }
         my $winsize="normal";
         if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
            $winsize=$UserCache->{winsize};
         }
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
         my $onclick="custopenwin('$dest','$winsize',".
                     "$detailx,$detaily,'$winname')";
         #$d="<a class=sublink href=JavaScript:$onclick>".$d."</a>";
         my $context;
         if (defined($param{contextMenu})){
            $context=" cont=\"$param{contextMenu}\" ";
         }
         $d="<span class=\"sublink\" $context onclick=\"$onclick\">".
            $d."</span>";
      }
   }
   return($d);
}

sub getSimpleInputField
{
   my $self=shift;
   my $value=shift;
   my $readonly=shift;
   my $name=$self->Name();
   $value=quoteHtml($value);
   my $d;

   my $unit=$self->unit;
   if ($unit ne ""){
      $unit="<td nowrap><span style=\"white-space: nowrap;\">$unit</span></td>";
   }
   my $maxlength=$self->maxlength;
   my $maxlengthcode=""; 
   if ($maxlength ne ""  && ($maxlength=~m/^[0-9]+$/)){
      $maxlengthcode="maxlength=\"$maxlength\"";
   }
   my $arialable=$self->Label();
   $arialable=~s/"//g;

   my $inputfield="<input type=\"text\" id=\"$name\" value=\"$value\" ".
                  "name=\"Formated_$name\" $maxlengthcode ".
                  "aria-label=\"$arialable\" ".
                  "class=\"finput\">";
   if (ref($self->{getHtmlImputCode}) eq "CODE"){
      $inputfield=&{$self->{getHtmlImputCode}}($self,$value,$readonly);
   }
   if (!$readonly){
      my $width="100%";
      $width=$self->{htmleditwidth} if (defined($self->{htmleditwidth}));
      $d=<<EOF;
<table aria-hidden=\"true\" style="table-layout:fixed;width:$width" cellspacing=0 cellpadding=0>
<tr><td>$inputfield</td>$unit</tr></table>
EOF
   }
   else{
      $unit="" if ($value eq "");
      $d=<<EOF;
<table aria-hidden=\"true\" style="table-layout:fixed;width:100%" cellspacing=0 cellpadding=0>
<tr><td><span class="readonlyinput">$value</span></td>$unit</tr></table>
EOF
   }
   return($d);
}




sub label
{
   my $self=shift;
   return(&{$self->{label}}($self)) if (ref($self->{label}) eq "CODE");
   return($self->{label});
}

sub Name()
{
   my $self=shift;
   return($self->{name});
}

sub Type()
{
   my $self=shift;
   my ($type)=$self=~m/::([^:]+)=.*$/;
   return($type);
}

sub UiVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   if (ref($self->{uivisible}) eq "CODE"){
      return(&{$self->{uivisible}}($self,$mode,%param));
   }
   return($self->{uivisible});
}

sub extendFieldHeader
{
   my $self=shift;
   my $mode=shift;
   my $current=shift;
   my $curFieldHeadRef=shift;
   if (exists($self->{extLabelPostfix}) && $mode ne "Detail"){
      $$curFieldHeadRef=$self->extLabelPostfix($mode,$current);
   }
#   $$curFieldHeadRef.="x";
}

sub extendPageHeader
{
   my $self=shift;
   my $mode=shift;
   my $current=shift;
   my $curPageHeadRef=shift;
#   $$curPageHeadRef.="z";
}

sub Uploadable
{
   my $self=shift;
   my %param=@_;
   if (defined($self->{uploadable})){
      if (ref($self->{uploadable}) eq "CODE"){
         return(&{$self->{uploadable}}($self,%param));
      }
      else{
         return($self->{uploadable});
      }
   }
   return(0) if (!$self->UiVisible("ViewEditor"));
   if (defined($self->{onRawValue})){
      if (ref($self->{onRawValue}) eq "CODE"){ # calc fields could not uploaded
         return(0);
      }
   }
   return(0) if ($self->readonly);
   return(0) if ($self->{name} eq "srcid");
   return(0) if ($self->{name} eq "srcsys");
   return(0) if ($self->{name} eq "srcload");
   return(1);
}


sub getField
{
   my $self=shift;
   return($self->getParent->getField(@_));
}

sub Config
{
   my $self=shift;
   return($self->getParent->Config(@_));
}

sub DefaultValue
{
   my $self=shift;
   my $newrec=shift;
   if (ref($self->{default}) eq "CODE"){
      return(&{$self->{default}}($self,$newrec));
   }
   return($self->{default});
}


sub FieldCache
{
   my $self=shift;
   my $pc=$self->getParent->Context;
   my $p=$self->getParent();
   my $fieldkey="FieldCache:".$p->Self()."::".$self->Name();
   $pc->{$fieldkey}={} if (!defined($pc->{$fieldkey}));
   return($pc->{$fieldkey});
}

sub vjoinobj
{
   my $self=shift;
   return(undef) if (!exists($self->{vjointo}));
   my $jointo=$self->getNearestVjoinTarget();
   if (ref($jointo) eq "SCALAR"){
      $jointo=$$jointo;
   }
   my $vjoinRewrite={};
   my $p=$self->getParent;
   if (defined($p) && exists($p->{_vjoinRewrite})){
      $vjoinRewrite=$p->{_vjoinRewrite};
   }
   if (defined($vjoinRewrite->{$jointo})){
      $jointo=$vjoinRewrite->{$jointo};
   }
   my $joinparam=$self->{vjoinparam};
   ($jointo,$joinparam)=&{$jointo}($self) if (ref($jointo) eq "CODE");
   $self->{joincache}={} if (!defined($self->{joincache}));

   if (!defined($self->{joincache}->{$jointo})){
      #msg(INFO,"create of '%s'",$jointo);
      #msg(INFO,"create of '%s' in $self %s",$jointo,$self->{_vjoinRewrite});
      my $o=getModuleObject($self->getParent->Config,$jointo,$joinparam);
      foreach my $fobj ($o->getFieldObjsByView(["ALL"])){
         if (defined($fobj) && defined($fobj->{vjointo})){
            if (defined($vjoinRewrite->{$fobj->{vjointo}})){
               $fobj->{vjointo}=$vjoinRewrite->{$fobj->{vjointo}};
            }
         }
      }
      #msg(INFO,"o=$o");
      $self->{joincache}->{$jointo}=$o;
      $self->{joincache}->{$jointo}->setParent($self->getParent);
   }
   $self->{joinobj}=$self->{joincache}->{$jointo};
   return($self->{joinobj});
}

sub vjoinContext
{
   my $self=shift;
   return(undef) if (!defined($self->{vjointo}));
   my $context=$self->{vjointo}.";";
   if (ref($self->{vjoinon}) eq "ARRAY"){
      $context.=join(",",@{$self->{vjoinon}});
   }
   if (defined($self->{vjoinbase})){
      my @l;
      @l=@{$self->{vjoinbase}} if (ref($self->{vjoinbase}) eq "ARRAY");
      @l=%{$self->{vjoinbase}} if (ref($self->{vjoinbase}) eq "HASH");
      $context.="+".join(",",@l);
   }
   return($context);
}

sub Size     # returns the size in chars if any defined
{
   my $self=shift;
   return($self->{size});
}

sub contextMenu
{
   my $self=shift;
   my %param=@_;

   return;
}

sub getHtmlContextMenu
{
   my $self=shift;
   my $rec=shift;
   my $name=$self->Name();

   my @contextMenu=$self->contextMenu(current=>$rec);
   my $contextMenu=$self->getParent->getHtmlContextMenu($name,@contextMenu);
   return($contextMenu);
}

sub Label
{
   my $self=shift;
   my $label=$self->{label};
   my $d;
   if ($label ne ""){
      my $tr=$self->{translation};
      $tr=$self->getParent->Self if (!defined($tr));
      my @tr=($tr);
      if ($tr ne $self->getParent->Self){
         unshift(@tr,$self->getParent->Self);
      }
      if (ref($label) eq "ARRAY"){
         my @d=@$label;
         for(my $c=0;$c<=$#d;$c++){
            $d[$c]=$self->getParent->T($d[$c],@tr);
         }
         return(\@d);
      }
      else{
         $d=$label;
         $d=$self->getParent->T($d,@tr);
      }
   }
   if ($label eq "" || $d eq ""){
      $d="(".$self->Name().")";
   }
   return($d);
}

sub rawLabel
{
   my $self=shift;
   my $label=$self->{label};
   my $d="-NoLabelSet-";
   if ($label ne ""){
      $d=$label;
   }
   else{
      $d="(".$self->Name().")";
   }
   return($d);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record

   if (!exists($newrec->{$self->Name()})){
      if (!defined($oldrec) && (defined($self->{dataobjattr}) ||
                                defined($self->{container}))){
         my $def=$self->DefaultValue($newrec);
         if (defined($def)){
            return({$self->Name()=>$def});
         }
      }
      return({});
   }
   if (!ref($newrec->{$self->Name()}) &&
       $self->Type() ne "File"){
      if (!exists($self->{binary}) || $self->{binary} eq "0"){
         if ($self->allowAnyLatin1()){
            my $txt=rmAnyNonLatin1(trim($newrec->{$self->Name()}));
            return({$self->Name()=>$txt});
         }
         my $txt=rmNonLatin1(trim($newrec->{$self->Name()}));
         return({$self->Name()=>$txt});
      }
      else{
         return({$self->Name()=>$newrec->{$self->Name()}});
      }
   }
   return({$self->Name()=>$newrec->{$self->Name()}});
}

sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   my $oldval=$self->RawValue($oldrec);
   return($oldval);
}

sub finishWriteRequestHash
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(undef);
}

sub prepareToSearch
{
   my $self=shift;
   my $filter=shift;
   return($filter);
}


sub interpreteVJOINSubListFilter
{
   my $self=shift;
   my $dataobj=shift;
   my $hflt=shift;
   my $searchfield=shift;

   my $subfilter;

   if ($searchfield->[0] ne "" && $hflt ne ""){
      if ($hflt=~m/^[a-z,0-9]+\s*=/ || $hflt=~m/^[0-9]+\s*=/){
         #$self->getParent->LastMsg(ERROR,
         #  $self->getParent->T("complex subfilter expression ".
         #                      "not supported in $self->{name}",
         #        $self->Self));
         my $p=new Text::ParseWhere();
         my ($h,$err)=$p->fltHashFromExpression("SIMPLE",$hflt,$searchfield);
         if (!defined($h)){
            $self->getParent->LastMsg(ERROR,"err=$err");
         }
         else{
            $subfilter=$h;
         }
      }
      else{
         $subfilter={$searchfield->[0]=>$hflt};
      }
   }
   else{
      $self->getParent->LastMsg(ERROR,
        $self->getParent->T("invalid sublist filter in field $self->{name}",
              $self->Self));
   }
   return($subfilter);
}

sub preParseInputValues
{
   my $self=shift;
   my $newval=shift;

   if ($newval eq "[SELF]" ||
       $newval eq "[ICH]"){
     my $UserCache=$self->getParent->Cache->{User}->{Cache};
     if (defined($UserCache->{$ENV{REMOTE_USER}})){
        $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
        if (ref($UserCache) eq "HASH" && $UserCache->{fullname} ne ""){
           my $fullname=$UserCache->{fullname};
           $newval=~s/(\[SELF\]|\[ICH\])/"$fullname"/g;
        }
     }
   }

   return($newval);
}


sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $fobj=$self;
   my $field=$self->Name();
   my $changed=0;
   my $err;

   if ($hflt->{$field} eq "[SELF]" ||
       $hflt->{$field} eq "[ICH]"){ 
     my $UserCache=$self->getParent->Cache->{User}->{Cache};
     if (defined($UserCache->{$ENV{REMOTE_USER}})){
        $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
        if (ref($UserCache) eq "HASH" && $UserCache->{fullname} ne ""){
           my $fullname=$UserCache->{fullname};
           $hflt->{$field}=~s/(\[SELF\]|\[ICH\])/"$fullname"/g;
           $changed=1;
           return($changed,$err); 
        }
     }
   }
   if (defined($self->{onPreProcessFilter}) &&
       ref($self->{onPreProcessFilter}) eq "CODE"){
      return(&{$self->{onPreProcessFilter}}($self,$hflt));
   }
   if (defined($fobj->{vjointo}) && !defined($fobj->{dataobjattr})){
      $fobj->vjoinobj->ResetFilter();
      my $loadfield=$fobj->{vjoinon}->[1];
      my @searchfield;
      if (ref($fobj->{vjoindisp}) eq "ARRAY"){
         for(my $findex=0;$findex<=$#{$fobj->{vjoindisp}};$findex++){
            my $sfobj=$fobj->vjoinobj->getField($fobj->{vjoindisp}->[$findex]);
            if (defined($sfobj)){
               if ($sfobj->Self ne "kernel::Field::DynWebIcon"){
                  push(@searchfield,$fobj->{vjoindisp}->[$findex]);
               }
            }
         }
      }
      else{
         @searchfield=($fobj->{vjoindisp});
      }
      if (defined($fobj->{vjoinbase})){
         my $base=$fobj->{vjoinbase};
         if (ref($base) eq "HASH"){
            $base=[$base];
         }
         if (ref($base) ne "ARRAY"){
            $base=[$base];
         }
         $fobj->vjoinobj->SetNamedFilter("BASE",@{$base});
      }

      my @keylist=();


      my $subflt=$self->interpreteVJOINSubListFilter($fobj->vjoinobj,
                                                     $hflt->{$field},
                                                     \@searchfield);
      if (!defined($subflt)){
         return($changed,
             "error while compilining ".
             "expression '$hflt->{$field}' for field $self->{name}");
      }
      my $vjoinslimit;
      if (exists($self->{vjoinslimit})){
         $vjoinslimit=$self->{vjoinslimit};
      }
      if (exists($fobj->{vjoinreverse})){
         my $localFld=$fobj->{vjoinreverse}->[0];
         my $remoteFld=$fobj->{vjoinreverse}->[1];
         $fobj->vjoinobj->ResetFilter();
         if ($fobj->vjoinobj->SetFilter($subflt)){
            $fobj->vjoinobj->SetCurrentView($remoteFld);
            #if (defined($vjoinslimit)){ # not working, because key can
            #   $fobj->vjoinobj->Limit($vjoinslimit+1); # not be unique
            #}
            my $d=$fobj->vjoinobj->getHashIndexed($remoteFld);
            @keylist=keys(%{$d->{$remoteFld}});
            if (($hflt->{$field}=~m/^\[LEER\]$/) || 
                ($hflt->{$field}=~m/^\[EMPTY\]$/)){
               push(@keylist,undef,"");
            }
            if ($#keylist==-1){
               @keylist=(-99);
            }
            delete($hflt->{$field});
         }
         else{
            delete($hflt->{$field});
            @keylist=(-99);
            $changed=1;
         }
         $hflt->{$localFld}=\@keylist;
         if ($localFld ne $self->Name()){
            $changed=1;
         }
      }
      else{
         my $localFld=$fobj->{vjoinon}->[0];
         my $remoteFld=$fobj->{vjoinon}->[1];
         @keylist=(-99);

         if (($hflt->{$field}=~m/^\[LEER\]$/) || 
             ($hflt->{$field}=~m/^\[EMPTY\]$/)){
            push(@keylist,undef,"");
            delete($hflt->{$field});
            $changed=1;
         }
         elsif (($hflt->{$field}=~m/^!\[LEER\]$/) || 
             ($hflt->{$field}=~m/^!\[EMPTY\]$/)){
            delete($hflt->{$field});
            $changed=1;
            $self->getParent->LastMsg(ERROR,
                 $self->getParent->T("search filter not supported"));
         }
         else{
            if ($fobj->vjoinobj->SetFilter($subflt)){
               if (defined($hflt->{$localFld}) &&
                   !defined($self->{dataobjattr})){
                  $fobj->vjoinobj->SetNamedFilter("vjoinadd".$field,
                         {$fobj->{vjoinon}->[1]=>$hflt->{$localFld}});
               }
               $fobj->vjoinobj->SetCurrentView($remoteFld);
               #if (defined($vjoinslimit)){ # not working, because key can
               #   $fobj->vjoinobj->Limit($vjoinslimit+1); # not be unique
               #}
               my $d=$fobj->vjoinobj->getHashIndexed($remoteFld);
               @keylist=keys(%{$d->{$remoteFld}});
               if ($#keylist==-1){
                  @keylist=(-99);
                  $changed=1;
               }
            }
            else{
               delete($hflt->{$field});
               @keylist=(-99);
               $changed=1;
            }
            delete($hflt->{$field});
         }
         if (defined($vjoinslimit) && $#keylist>=($vjoinslimit)){
            my $msg=$self->getParent->T('filter on "%s" not selective enough',
                    'kernel::Field');
            $err=sprintf($msg,$self->Label());
         }

         $hflt->{$localFld}=\@keylist;
         if ($localFld ne $self->Name()){
            $changed=1;
         }
      }

   }
   else{
      if ($hflt->{$field} eq "[NONE]"){   # das wäre eine Idee, wie man mit
         $err="ERROR: ".
              $self->getParent->T("search for NONE only posible on sublists",
                 $self->Self);           # umgehen könnte .... ist aber noch
      }
   }
   return($changed,$err);
}

sub doUnformat
{
   my $self=shift;

   if (defined($self->{onUnformat}) && ref($self->{onUnformat}) eq "CODE"){
      return(&{$self->{onUnformat}}($self,@_));
   }
   return($self->Unformat(@_));
}


sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;

   return({}) if ($self->readonly);
   if ($#{$formated}>0){
      return({$self->Name()=>$formated});
   }
   return({$self->Name()=>$formated->[0]});
}

sub prepUploadRecord   # prepair one record on upload
{
   my $self=shift;
   my $newrec=shift;
   my $oldrec=shift;
   return(1);
}


sub getBackendName     # returns the name/function to place in select
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   if (defined($self->{wrdataobjattr}) &&
       ($mode eq "update" || 
        $mode eq "where.update" ||   # Die where.* modes sind notwendig, damit
        $mode eq "where.insert" ||   # im SQL Replace modus auch berechnete
        $mode eq "where.delete" ||   # ID Felder korrekt verarbeitet werden
        $mode eq "insert")){
      return($self->{wrdataobjattr});
   }

   if ($mode eq "select" || $mode=~m/^where\..*/){
      if (!defined($self->{dataobjattr}) && defined($self->{container})){
         if ($mode eq "where.select"){
            return($self->Name()); 
         }
      }
      return(undef) if (!defined($self->{dataobjattr}));
      if (ref($self->{dataobjattr}) eq "ARRAY"){
         $_=$db->DriverName();
         case: {
            /^mysql$/i and do {
               return("concat(".join(",'-',",@{$self->{dataobjattr}}).")");
               return(undef); # noch todo
            };
            /^oracle$/i and do {
               my @fl=@{$self->{dataobjattr}};
               my $wcmd=$fl[0];
               if ($#fl>0){
                  my @flx=shift(@fl);
                  my @kl;
                  map({push(@flx,"'-'",$_);
                       push(@kl,"))")} @fl);
                  my $last=pop(@flx);
                  $wcmd=join(",",map({"concat($_"} @flx)).",$last".join("",@kl);
               }
               return($wcmd); 
            };
            /^odbc$/i and do {
               return(join("+'-'+",
                           map({"'\"'+rtrim(ltrim(convert(char,$_)))+'\"'"} 
                           @{$self->{dataobjattr}})));
            };
            do {
               msg(ERROR,"conversion for date on driver '$_' not ".
                         "defined ToDo!");
               return(undef);
            };
         }
      }
      if ($mode eq "select" && $self->{noselect}){
         return(undef);
      }
      if ($mode eq "select" || $mode eq "where.select"){ 
         if (defined($self->{altdataobjattr})){
            $_=$db->DriverName();
            case: {
               /^mysql$/i and do {
                  my $f="if ($self->{altdataobjattr} is null,".
                        "$self->{dataobjattr},$self->{altdataobjattr})";
                  return($f); # noch todo
               };
               do {
                  msg(ERROR,"alternate conversion for date on driver '$_' not ".
                            "defined ToDo!");
                  return(undef);
               };
            }
            
         }
      }
      return($self->{dataobjattr});
   }
   elsif ($mode eq "order"){
      my $ordername=shift;
    
      if (defined($self->{dataobjattr}) && 
          ref($self->{dataobjattr}) ne "ARRAY"){
         my $orderstring=$self->{dataobjattr};
         $orderstring=$self->{name} if ($self->{dataobjattr}=~m/^max\(.*\)$/);
         my $sqlorder="";
         if (defined($self->{sqlorder})){
            $sqlorder=$self->{sqlorder};
         }
         if ($sqlorder ne "none" && ($ordername=~m/^-/)){  # absteigend
            $sqlorder="desc";
         }
         if ($sqlorder ne "none" && ($ordername=~m/^\+/)){  # aufsteigend
            $sqlorder="asc";
         }
         $orderstring.=" ".$sqlorder;

         return(undef) if (lc($self->{sqlorder}) eq "none");
         return($orderstring);
      }
   }
   else{
      return($self->{dataobjattr});
   }
   return(undef);
}


sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;    # ATTENTION! - This is not always set! (at now 03/2013)
   my $d;

   my $tcurrent=tied(%$current);
   if (defined($tcurrent) && $tcurrent->can("STORE") && 
       $tcurrent->can("FETCH") && 
       exists($self->{default})){  # hoffe das löst das Problem mit dem
                                   # default Wert nur in Detail (eventinfo.pm)
                                   # möglicherweise wäre ein check auf
                                   # ref($self->{default}) eq "CODE" besser?!
      $current->{$self->{name}}=$tcurrent->FETCH($self->{name},$mode);
      if ((!defined($current->{$self->{name}}) ||
           $current->{$self->{name}} eq "") && exists($self->{default})){
         $d=$self->default($current,$mode);
      }
   }

   if (exists($current->{$self->Name()}) &&
       !(!defined($current->{$self->{name}}) && $self->{noUndefRawCaching})){
      $d=$current->{$self->{name}};
   }
   elsif (defined($self->{onRawValue}) && ref($self->{onRawValue}) eq "CODE"){
      $current->{$self->Name()}=&{$self->{onRawValue}}($self,$current,$mode);
      $d=$current->{$self->Name()};
   }
   elsif (defined($self->{vjointo}) && 
          $self->Self() ne "kernel::Field::FlexBox"){
      my $c=$self->getParent->Context();
      $c->{JoinData}={} if (!exists($c->{JoinData}));
      $c=$c->{JoinData};
      my $joincontext=$self->vjoinContext();
      my @view;
      if (ref($self->{vjoindisp}) eq "ARRAY"){
         @view=(@{$self->{vjoindisp}},$self->{vjoinon}->[1]);
      }
      else{
         @view=($self->{vjoindisp},$self->{vjoinon}->[1]);
      }
      if ($self->getParent->can("getCurrentView")){
         foreach my $fieldname ($self->getParent->getCurrentView()){
            my $fobj=$self->getParent->getField($fieldname);
            next if (!defined($fobj));
            if ($fobj->vjoinContext() eq $joincontext){
               if (!grep(/^$fobj->{vjoindisp}$/,@view)){
                  push(@view,$fobj->{vjoindisp});
               }
            }
         }
      }
      $joincontext.="+".join(",",sort(@view));
      $c->{$joincontext}={} if (!exists($c->{$joincontext}));
      $c=$c->{$joincontext};
      my @joinon=@{$self->{vjoinon}};
      my %flt=();
      my $joinval=0;
      if ($self->getParent->can("getField")){
         while(my $myfield=shift(@joinon)){
            my $joinfield=shift(@joinon);
            my $myfieldobj=$self->getParent->getField($myfield);
            if (defined($myfieldobj)){
               if ($myfieldobj ne $self){
                  my $myval=$myfieldobj->RawValue($current);
                  if (!ref($myval)){
                     $flt{$joinfield}=\$myval;
                  }
                  else{
                     $flt{$joinfield}=$myval;
                  }
                  $joinval=1 if (defined($myval) && $myval ne "");
               }
               else{
                  $flt{$joinfield}=\undef;
                  $joinval=1;
               }
            }
         }
      }
      my @fltlst=(\%flt);
      if (ref($self->{vjoinonfinish}) eq "CODE"){  # this allows dynamic joins
         @fltlst=&{$self->{vjoinonfinish}}($self,\%flt,$current);
      }
      my $joinkey=join(";",map({ my $k=$flt{$_};
                                 $k=$$k if (ref($k) eq "SCALAR");
                                 $k=join(";",@$k) if (ref($k) eq "ARRAY");
                                 $_."=".$k;
                               } sort(keys(%flt))));
      delete($self->{VJOINSTATE});
      delete($self->{VJOINKEY});
      delete($self->{VJOINCONTEXT});
      if (keys(%flt)>0){
         if ($#fltlst!=-1 && $joinval){ 
            if (!exists($c->{$joinkey})){
               if ($self->vjoinobj->isSuspended()){
                  return("[ERROR: information temporarily suspended]");
               }
               else{
                  $self->vjoinobj->ResetFilter();
                  if (defined($self->{vjoinbase})){
                     my $base=$self->{vjoinbase};
                     if (ref($base) eq "CODE"){
                        $base=&{$base}($self,$current);
                     }
                     if (defined($base)){
                        if (ref($base) eq "HASH"){
                           $base=[$base];
                        }
                        $self->vjoinobj->SetNamedFilter("BASE",@{$base});
                     }
                  }
                  if (defined($self->vjoinobj) && $self->vjoinobj->Ping()){
                     $self->vjoinobj->SetFilter(@fltlst);
                     $c->{$joinkey}=[$self->vjoinobj->getHashList(@view)];
                  }
                  else{
                     return("[ERROR: information temporarily unavailable]");
                  }
                  if ($#{$c->{$joinkey}}==-1){
                     if (!$self->vjoinobj->Ping()){
                       return("[ERROR: information temporarily unavailable]");
                     }
                  }
               }
               $c->{$joinkey}=ObjectRecordCodeResolver($c->{$joinkey});
              # Dumper($c->{$joinkey}); # ensure that all subs are resolved
            }
            my %u=();
            my @rawlist=();
            my $disp=$self->{vjoindisp};
            $disp=$disp->[0] if (ref($disp) eq "ARRAY");
            my $dispobjvjoinconcat=", ";
            map({
                   my %current=%{$_};
                   my $dispobj=$self->vjoinobj->getField($disp,\%current);
                   if (!defined($dispobj)){
                      die("fail to find $disp in $self");
                   }
                   if (defined($dispobj->{vjoinconcat})){
                      $dispobjvjoinconcat=$dispobj->{vjoinconcat};
                   }
                   my $bk=$dispobj->RawValue(\%current);
                   if (!$self->vjoinobj->Ping()){
                    $bk="[ERROR: information temporarily unavailable]";
                   }
                   else{
                      if (ref($bk) eq "ARRAY"){
                         $bk=join($dispobjvjoinconcat,@$bk);
                      }
                   }
                   push(@rawlist,$bk);
                   $u{$bk}=1;
                } @{$c->{$joinkey}});
            if (keys(%u)>0){
               $self->{VJOINSTATE}="ok";
               $self->{VJOINKEY}=$joinkey;
               $self->{VJOINCONTEXT}=$joincontext;
            }
            else{
               $self->{VJOINSTATE}="not found";
            }
#            if (defined($self->{vjoinconcat})){  # joinconcat shoul better
#                                                 # be realized on formated
#               $current->{$self->Name()}=        # layer
#                       join($self->{vjoinconcat},sort(keys(%u)));
#            }
#            else{
               if (keys(%u)>1){
                  if (lc($self->{sortvalue}) eq "none"){
                     $current->{$self->Name()}=[@rawlist];
                  }
                  else{
                     $current->{$self->Name()}=[sort(keys(%u))];
                  }
               }
               else{
                  if (keys(%u)==1){
                     my @l=keys(%u);
                     $current->{$self->Name()}=$l[0];
                  }
                  else{
                     $current->{$self->Name()}=undef;
                  }
               }
#            }
            $d=$current->{$self->Name()};
         }
         else{
            $d=undef;
         }
      }
      else{
         return("ERROR: can't find join target '$self->{vjoinon}->[0]'");
      }
   }
   elsif (defined($self->{container})){
      $d=$self->resolvContainerEntryFromCurrent($current);
   }
   elsif (defined($self->{alias})){
      my $fo=$self->getParent->getField($self->{alias});
      return(undef) if (!defined($fo));
      my $d=$fo->RawValue($current);
      return($d);
   }
   else{
      $d=$current->{$self->Name};
   }
   if (ref($self->{prepRawValue}) eq "CODE"){
      $d=&{$self->{prepRawValue}}($self,$d,$current);
   }
   # attention - default values are NOT cached in record - multi calles posible!
   if (exists($self->{default}) && (!defined($d) || $d eq "")){
      $d=$self->default($current,$mode); #allow code pointers for default values
   }
   return($d);
}

sub resolvContainerEntryFromCurrent
{
   my $self=shift;
   my $current=shift;
   my $d;

   my $container=$self->getParent->getField($self->{container});
   if (!defined($container)){ # if the container comes from the parrent
                              # DataObj (if i be a SubDataObj)
      my $parentofparent=$self->getParent->getParent();
      $container=$parentofparent->getField($self->{container});
   }
   my $containerdata=$container->RawValue($current);
   my $centryname=$self->Name;
   if (defined($self->{containergroup})){
      $centryname=$self->{containergroup}.".".$centryname;
   }
   if (wantarray()){
      if (ref($containerdata->{$centryname}) eq "ARRAY"){
         return(@{$containerdata->{$centryname}});
      }
      return($containerdata->{$centryname});
   }
   if (ref($containerdata->{$centryname}) eq "ARRAY" &&
       $#{$containerdata->{$centryname}}<=0){
      $d=$containerdata->{$centryname}->[0];
   }
   else{
      $d=$containerdata->{$centryname};
   }
   return($d);
}

sub getLastVjoinRec          # to use the last joined record
{
   my $self=shift;
   my $joinkey=$self->{VJOINKEY};
   my $joincontext=$self->{VJOINCONTEXT};
   my $c=$self->getParent->Context();

   if (defined($joinkey) && defined($joincontext) &&
       defined($c->{JoinData}->{$joincontext}) && 
       defined($c->{JoinData}->{$joincontext}->{$joinkey})){
      return($c->{JoinData}->{$joincontext}->{$joinkey});
   }

   return(undef);

}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (defined($self->{onFinishWrite}) && 
       ref($self->{onFinishWrite}) eq "CODE"){   
      return(&{$self->{onFinishWrite}}($self,$oldrec,$newrec));
   }
   return(undef);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   if (defined($self->{onFinishDelete}) && 
       ref($self->{onFinishDelete}) eq "CODE"){   
      return(&{$self->{onFinishDelete}}($self,$oldrec));
   }
   return(undef);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->FormatedDetail($current,$FormatAs);
   return($d);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current,$FormatAs);
   $d=$self->FormatedDetailDereferncer($current,$FormatAs,$d);
   if ($FormatAs eq "SOAP"){
      if (!ref($d)){
         $d=quoteSOAP($d);
      }
      elsif (ref($d) eq "ARRAY"){
         $d=[map({quoteSOAP($_)} @{$d})];
      }
   }
   return($d);
}

sub FormatedDetailDereferncer
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=shift;

   if (ref($d) && ($FormatAs ne "JSON" && $FormatAs ne "SOAP")){
      if (ref($self->{dereference}) eq "CODE"){
         my @result=&{$self->{dereference}}($self,$current,$FormatAs,$d);
         return(@result);
      }
      if (ref($d) eq "ARRAY"){
         if (exists($self->{vjoinconcat}) && $self->{vjoinconcat} ne ""){
            if (($FormatAs=~m/^Html/) && ($self->{vjoinconcat}=~m/\n/)){
               my $j=$self->{vjoinconcat};
               $j=~s/\n/<br>\n/g;
               return(join($j,@$d));
            }
            return(join($self->{vjoinconcat},@$d));
            
         }
         return(join("; ",@$d));
      }
      elsif (ref($d) eq "HASH"){
         if (exists($d->{$FormatAs})){
            $d=$d->{$FormatAs};
         }
         elsif (exists($d->{'RawValue'})){
            $d=$d->{'RawValue'};
         }
         if (($FormatAs=~m/^Html/)){
            my $htmlD=Dumper($d);
            $htmlD=~s/^\$VAR1\s*=\s*{/{/s;
            $htmlD=~s/;\s*$//s;
            $d="<xmp>".$htmlD."</xmp>";;
         }
      }
   }
   return($d);
}

sub FormatedSearch
{
   my $self=shift;

   my $name=$self->{name};
   my $label=$self->Label;
   my $curval=Query->Param($name);
   if (!defined($curval)){
      $curval=Query->Param("search_".$name);
   }
   $curval=~s/"/&quot;/g;
   my $d="<table style=\"table-layout:fixed;width:100%\" ".
         "border=0 cellspacing=0 cellpadding=0 aria-hidden=\"true\"  >\n";
   $d.="<tr><td>". # for min width, add an empty image with 50px width
       "<img width=50 border=0 height=1 alt=\"\" aria-hidden=\"true\" ".
       "src=\"../../../public/base/load/empty.gif\">";
   if (exists($self->{selectsearch})){
      my $options=$self->{selectsearch};
      $options=[&$options($self)] if (ref($options) eq "CODE");
      $d.="<select name=\"search_$name\" style=\"min-width:50px;width:100%\">";
      foreach my $opt (@$options){
         my $valopt=$opt;
         my $dispopt=$opt;
         if (ref($opt) eq "ARRAY"){
            $valopt=$opt->[0];
            $dispopt=$opt->[1];
         }
         $dispopt=~s/>/&gt;/g;
         $dispopt=~s/</&lt;/g;
         if ($valopt=~m/\s/ && !($valopt=~m/^"/)){
            $valopt="\"$valopt\"";
         }
         $valopt=~s/"/&quot;/g;
         $d.="<option value=\"$valopt\">".$dispopt."</option>";
      }
      $d.="</select>";
   }
   else{
      my $searchfieldprefix=$self->getParent->T("Search field");
      $d.="<input type=text  name=\"search_$name\" ".
          "aria-label=\"$searchfieldprefix : $label - help shortcut F1\" ".
          "class=finput style=\"min-width:50px\" value=\"$curval\">";
   }
   $d.="</td>";
   my $FieldHelpUrl=$self->getFieldHelpUrl();
   if (defined($FieldHelpUrl)){
      $d.="<td width=10 valign=top align=right>";
      $d.="<img class=hideOnMobile ".
          "style=\"cursor:pointer;cursor:hand;float:right;\" ".
          "onClick=\"FieldHelp_On_$name()\" align=right ".
          "alt=\"Field-Help\" ".
          "src=\"../../../public/base/load/questionmark.gif\" ".
          "border=0>";
      $d.="</td>";
      my $q=kernel::cgi::Hash2QueryString(
            focus=>"1",
            field=>"search_$name",
            TITLE=>$self->getParent->T("field search help"),
            label=>$label);
      $q=~s/%/\\%/g;
      $d.=<<EOF;
<script langauge="JavaScript">
var ifld=document.getElementsByName('search_$name');
if (ifld){
   for(var c=0;c<ifld.length;c++){
      var sfld=ifld[c];
      sfld.addEventListener('keydown',function(e){ 
         if (e.keyCode === 112) {  // F1 Key redirects to HelpOnField
           FieldHelp_On_$name();
           e.preventDefault(); 
         } 
      });
   }
}

function FieldHelp_On_$name()
{
   showPopWin('$FieldHelpUrl?$q',500,200,function(){
      var ifld=document.getElementsByName('search_$name');
      if (ifld && ifld[0]){
         window.setTimeout(function(){
            ifld[0].focus();
         },500);
      }
   });
}
</script>
EOF
   }
   $d.="</td></tr></table>\n";
   return($d);
}


sub BackgroundColorHandling
{
   my $self=shift;
   my $FormatAs=shift;
   my $current=shift;
   my $d=shift;

   my $bg=$self->background($FormatAs,$current);
   if ($bg ne ""){
      if ($FormatAs eq "HtmlDetail"){
         if ($bg eq "red" || $bg eq "green" ||
             $bg eq "yellow" || $bg eq "grey" || $bg eq "blue"){
            $d="<div ".
               "style='padding-top:2px;padding-bottom:2px;".
               "padding-left:2px;background-image:".
               "url(../../base/load/cellbg_$bg.jpg)'>".
               $d.
               "</div>";
         }
         else{
            $d="<div ".
               "style='padding-top:2px;padding-bottom:2px;".
               "padding-left:2px;background-color:".
               "$bg'>".
               $d.
               "</div>";
         }
      }
      elsif ($FormatAs eq "HtmlV01"){  # background-color geht hier nicht
         if ($bg eq "red" || $bg eq "green" ||
             $bg eq "yellow" || $bg eq "grey" || $bg eq "blue"){
            $d.="<img height=10 width=10 src='../../base/load/cellbg_$bg.jpg'>";
         }
      }
   }
   
   return($d);
}




sub getFieldHelpUrl
{
   my $self=shift;

   my $type=$self->Type();
   if (defined($self->{FieldHelp})){
      if (ref($self->{FieldHelp}) eq "CODE"){
         return(&{$self->{FieldHelp}}($self));
      }
      if ($self->{FieldHelp}=~m/\//){ # FieldHelp seems to be a URL
         return($self->{FieldHelp});
      }
      else{
         $type=$self->{FieldHelp};
      }
   }
   if (exists($self->{FieldHelpType}) && $self->{FieldHelpType} ne ""){
      $type=$self->{FieldHelpType};
   }
   if ($type eq "GenericConstant"){
      return("../../base/load/tmpl/FieldHelp.GenericConstant");
   }
   if ($type=~m/Date$/){
      return("../../base/load/tmpl/FieldHelp.Date");
   }
   if ($type=~m/SubList$/){
      return("../../base/load/tmpl/FieldHelp.SubList");
   }
   if ($self->{FieldHelp} ne "0"){
      return("../../base/load/tmpl/FieldHelp.Default");
   }
   return(undef);
}

#
# vor history displaying in Workflow Mode
#
sub FormatedStoredWorkspace
{
   my $self=shift;
   my $name=$self->{name};
   my $d="";

   my @curval=Query->Param("Formated_".$name);
   my $disp="";
   my $var=$name;
   if (defined($self->{vjointo})){
      $var=$self->{vjoinon}->[0];
   }
   if ($#curval>0){
      $disp.=$self->FormatedResult({$var=>\@curval},"HtmlDetail");
   }
   else{
      $disp.=$self->FormatedResult({$var=>$curval[0]},"HtmlDetail");
   }
   foreach my $var (@curval){
      $var=~s/"/&quot;/g;
      $d.="<input type=hidden name=Formated_$name value=\"$var\">";
   }
   $d=$disp.$d;
   return($d);
}

sub getXLSformatname
{
   my $self=shift;
   my $xlscolor=$self->xlscolor;
   my $xlsbgcolor=$self->xlsbgcolor;
   my $xlsbcolor=$self->xlsbcolor;
   my $xlsnumformat=$self->xlsnumformat;
   my $f="default";
   my $colset=0;
   if (defined($xlscolor)){
      $f.=".color=\"".$xlscolor."\"";
   }
   if (defined($xlsbgcolor)){
      $f.=".bgcolor=\"".$xlsbgcolor."\"";
      $colset++;
   }
   if ($colset || defined($xlsbcolor)){
      if (!defined($xlsbcolor)){
         $xlsbcolor="#8A8383";
      }
      $f.=".bcolor=\"".$xlsbcolor."\"";
   }
   if (defined($xlsnumformat)){
      $f.=".numformat=\"".$xlsnumformat."\"";
   }
   return($f);
}

sub WSDLfieldType
{
   my $self=shift;
   my $ns=shift;
   my $mode=shift;
   if (exists($self->{WSDLfieldType})){
      if (!($self->{WSDLfieldType}=~m/:/)){
         return($ns.":".$self->{WSDLfieldType});
      }
      return($self->{WSDLfieldType});
   }
   return("xsd:string");
}


sub AsyncFieldPlaceholder
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();

   my $d;

   my $idfield=$self->getParent->IdField();
   if (defined($idfield)){
      my $id=$idfield->RawValue($current);
      my $divid="ViewProcessor_$self->{name}";
      my $XMLUrl="";
      $XMLUrl=~s/^[a-z]+?://; # rm protocol to prevent reverse proxy issues
      $XMLUrl.="/../ViewProcessor/XML/$self->{name}/$id";
      my $d="<div id=\"$divid\"><font color=silver>init ...</font></div>";
      #
      # Weblinks can't be resolved on async fields
      # (destination field value is an async information)
      #$d=$self->addWebLinkToFacility($d,$current);
      return(<<EOF);
$d
<script language="JavaScript">
function onLoadViewProcessor_$self->{name}(timedout)
{
   var ResContainer=document.getElementById("$divid");
   if (ResContainer && timedout==1){
      ResContainer.innerHTML="ERROR: XML request timed out";
      return;
   }
   // window.setTimeout("onLoadViewProcessor_$self->{name}(1);",10000);
   // timeout handling ist noch bugy!
   var xmlhttp=getXMLHttpRequest();
   var reqTarget=document.location.pathname+"$XMLUrl";
   xmlhttp.open("POST",reqTarget,true);
   xmlhttp.onreadystatechange=function() {
      var r=document.getElementById("$divid");
      if (r){
         if (xmlhttp.readyState<4){
            var t="<font color=silver>Loading ...</font>";
            if (r.innerHTML!=t){
               r.innerHTML=t;
            }
         }
         if (xmlhttp.readyState==4 && 
             (xmlhttp.status==200||xmlhttp.status==304)){
            var xmlobject = xmlhttp.responseXML;
            var result=xmlobject.getElementsByTagName("value");
            if (result){
               r.innerHTML="";
               for(rid=0;rid<result.length;rid++){
                  if (r.innerHTML!=""){
                     r.innerHTML+=", ";
                  }
                  if (result[rid].childNodes[0]){
                     r.innerHTML+=result[rid].childNodes[0].nodeValue;
                  }
               }
            }
            else{
               r.innerHTML="ERROR: XML error";
            }
         }
      }
   };
   xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   var r=xmlhttp.send('Mode=XML');



//   ResContainer.innerHTML="<font color=silver>"+
//                          "- Informations isn't avalilable at now -"+
//                          "</font>";
}
addEvent(window,"load",onLoadViewProcessor_$self->{name});
</script>
EOF
   }
   else{
      return("- ERROR - no idfield - ");
   }
   return($d);
}


# Zugriffs funktionen

1;
