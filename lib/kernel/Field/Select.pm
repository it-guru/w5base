package kernel::Field::Select;
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
use Text::ParseWords;

@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{vjoinconcat}=", " if (!exists($param{vjoinconcat}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{_permitted}->{jsonchanged}=1;      # On Changed Handling
   $self->{_permitted}->{jsoninit}=1;      # On Init Handling
   $self->{allownative}=undef if (!exists($self->{allownative}));
   $self->{allowfree}=undef   if (!exists($self->{allowfree}));
   $self->{useNullEmpty}=0    if (!exists($self->{allownative}));
   return($self);
}

sub getPostibleValues
{
   my $self=shift;
   my $current=shift;
   my $newrec=shift;
   my $mode=shift;
 
   if (defined($self->{getPostibleValues}) &&
       ref($self->{getPostibleValues}) eq "CODE"){
      my $f=$self->{getPostibleValues};
      my @l=&$f($self,$current,$newrec);
      return(&$f($self,$current,$newrec));
   }

   if (defined($self->{value}) && ref($self->{value}) eq "ARRAY"){
      my @l=();
      map({
             my $kval=$_;
             my $dispname=$kval;
             if (defined($self->{transprefix})){
                my $tdispname=$self->{transprefix}.$kval;
                my $tr=$self->{translation};
                $tr=$self->getParent->Self() if (!defined($tr));
                my $newdisp=$self->getParent->T($tdispname,$tr);
                if ($tdispname ne $newdisp){
                   $dispname=$newdisp;
                }
             }
             push(@l,$kval,$dispname);
          } @{$self->{value}});
#      map({push(@l,$_,$_);} @{$self->{value}}); # altes Verfahren - macht
      if ($self->{allowempty}==1){               # Probleme beim XLS Upload!
         unshift(@l,"","");
      }
      return(@l);
   }
   if (defined($self->{vjointo})){
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
      if ($mode eq "edit"){
         if (defined($self->{vjoineditbase})){
            my $base=$self->{vjoineditbase};
            if (ref($base) eq "CODE"){
               $base=&{$base}($self,$current);
            }
            $self->vjoinobj->SetNamedFilter("editbase",$base);
         }
      }
      #$self->vjoinobj->SetFilter({$self->{vjoinon}->[1]=>
      #                           [$joinonval]});
     # my $joinidfield=$self->vjoinobj->IdField->Name();
      my $joinidfieldobj=$self->vjoinobj->getField($self->{vjoinon}->[1]);
      if (!defined($joinidfieldobj)){
         msg(ERROR,"program bug - can not find field ".$self->{vjoinon}->[1]);
         exit(1);
      }
      my $joinidfield=$joinidfieldobj->Name();
      my @res=(); 
      my @view=($self->{vjoindisp},$joinidfield);

      if ($self->{vjoinon}->[1] eq $self->{vjoindisp}){
         @view=("VDISTINCT",$self->{vjoindisp});
      }
      my @l=$self->vjoinobj->getHashList(@view); 
      if ($self->{vjoinon}->[1] eq $self->{vjoindisp}){
         map({push(@res,$_->{$self->{vjoindisp}},$_->{$self->{vjoindisp}})} @l);
      }
      else{
         map({push(@res,$_->{$joinidfield},$_->{$self->{vjoindisp}})} @l);
      }
      if ($self->{allowempty}==1){
         unshift(@res,"",$self->getEmptyFrontendValue());
      }
      return(@res);
   }
   return();
}

sub ViewProcessor                           # same handling as in
{                                           # TextDrop fields!!!
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
               my $d=$self->SUPER::FormatedResult($rec,$mode);
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



sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   if (ref($self->{vjoinon}) eq "ARRAY"){
      my $onfield=$self->{vjoinon}->[0];
      my $onfld=$self->getParent->getField($onfield);
      return($onfld->RawValue($oldrec));
   }
   return($self->RawValue($oldrec));
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();
   if ($self->{async} && $mode eq "HtmlDetail"){
      return($self->AsyncFieldPlaceholder($current,$mode));
   }
   my $d=$self->RawValue($current,$mode);
   $d=[$d] if (ref($d) ne "ARRAY");
   my $readonly=$self->readonly($current);
   if (($mode eq "workflow" || $mode eq "edit" ) 
       && !($readonly)){
      my @fromquery=Query->Param("Formated_$name");
      if (defined($current) &&
          defined($self->{vjointo}) && defined($self->{vjoinon})){
         $d=$current->{$self->{vjoinon}->[0]};
      }
      $d=[$d] if (ref($d) ne "ARRAY");
      if ($#fromquery!=-1){  # defined ist not allowed
         $d=\@fromquery;
      }
      if (($#{$d}==-1 && defined($self->{default}))||
          ($#{$d}==0 && !defined($d->[0]))){
         $d=[$self->default($current,$mode)];
      }
      my $width="100%";
      $width=$self->{htmleditwidth} if (defined($self->{htmleditwidth}));
      my $disabled="";

      my $arialable=$self->Label();
      $arialable=~s/"//g;

      my $s="<select aria-label=\"$arialable\" id=\"$name\" ".
            "name=\"Formated_$name\"";
      if ($self->{multisize}>0){
         $s.=" multiple";
         $s.=" size=\"$self->{multisize}\"";
      }
      my $onchange="";
      if ($self->{allowfree} eq "1"){
         $onchange.=";" if ($onchange ne "");
         $onchange.="select_allow_free_$name(this);";
      }
      if (defined($self->{jsonchanged})){
         $onchange.=";" if ($onchange ne "");
         $onchange.="jsonchanged_$name('onchange');";
      }
      if ($onchange ne ""){
         $s.=" onchange=\"$onchange\"";
      }
      $s.=" class=\"finput\" style=\"width:$width\">";
      my @options=$self->getPostibleValues($current,undef,"edit");
      if ($self->{allowfree} eq "1"){
         push(@options,"");
         push(@options,
              $self->getParent->T("- other -","kernel::Field::Select"));
      }

      while($#options!=-1){
         my $key=shift(@options);
         my $val=shift(@options);
         $s.="<option value=\"$key\"";
         my $qkey=quotemeta($key);
         my $qval=quotemeta($val);
         $s.=" selected" if (($qkey ne "" && grep(/^$qkey$/,@{$d})) || 
                             ($qval ne "" && grep(/^$qval$/,@{$d})));
         $s.=">".$val."</option>";
      }

      $s.="</select>";
      if (defined($self->{jsonchanged})){
         $s.="<script language=\"JavaScript\">".
             "function jsonchanged_$name(mode){".
             $self->jsonchanged."}".  
             "</script>";
      }
      if ($self->{allowfree} eq "1"){
         $s.="<script language=\"JavaScript\">".
             "function select_allow_free_$name(e){".
             "if (e.options[e.selectedIndex].value==''){".
             "var newObject = document.createElement('input');".
             "newObject.type='text';".
             "newObject.name=e.name;".
             "newObject.style=e.style;".
             "newObject.id=e.id;".
             "e.parentNode.replaceChild(newObject,e);".
             "addEvent(newObject,'keydown',function(e){".
             "return(EnterSubmitEvtHandler(e,document.forms[0],DetailEditSave)".
             ");});".
             "newObject.focus();".
             "}".  
             "}".  
             "</script>";
      }
      return($s);
   }
   my $res=$self->FormatedResult($current,$mode);
   $res=[$res] if (ref($res) ne "ARRAY");
   if ($mode eq "HtmlDetail"){
      if (!(ref($d) eq "ARRAY" && $#{$d}==0 && !defined($d->[0]))){
         $res=[map({$self->addWebLinkToFacility($_,$current)} @{$res})];
      }
   }
   $res=join($self->{vjoinconcat},@$res);
   if ($mode eq "HtmlDetail"){
      if (defined($self->{unit})) {
         $res.=" ".$self->getParent->T($self->{unit},$self->{translation});
      }
   }

   return($res);
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $fobj=$self;
   my $field=$self->Name();
   my $changed=0;
   my $err;

   if (defined($self->{onPreProcessFilter}) &&
       ref($self->{onPreProcessFilter}) eq "CODE"){
      return(&{$self->{onPreProcessFilter}}($self,$hflt));
   }

   if (!defined($self->{vjointo})){
      my $oldval=$hflt->{$field};
      my @options=$fobj->getPostibleValues(undef,undef);
      my %tr=();
      my %raw=();
      my @to=@options;
      while($#to>0){
         my $key=shift(@to);
         my $val=shift(@to);
         $raw{$val}=$key;
         my $trval=$val;
         if (defined($self->{transprefix})){
            $trval=$self->{transprefix}.$trval;
         }
         my $tropt=$self->getParent->T($trval,$fobj->{translation});
         my $tropt=$val;
         $tr{$tropt}=$key;
      }
      my @newsearch=();
      if (ref($oldval) eq "ARRAY"){
         foreach my $chk (@{$oldval}){ 
            if (defined($chk)){
               foreach my $v (keys(%tr)){
                  push(@newsearch,$tr{$v}) if ($v eq $chk ||
                                               $tr{$v} eq $chk);
               }
            }
            else{
               push(@newsearch,undef);
            }
         }
      }
      elsif (ref($oldval) eq "SCALAR"){
         if (keys(%tr)!=0){
            foreach my $v (keys(%tr)){
               push(@newsearch,$tr{$v}) if ($v eq ${$oldval} ||
                                            $tr{$v} eq ${$oldval});
            }
         }
         else{
            push(@newsearch,${$oldval});
         }
      }
      else{
         my $procoldval=trim($oldval);
         my @chklist=parse_line(',{0,1}\s+',0,$procoldval);
         foreach my $chk (@chklist){
            my $neg=0;
            if ($chk=~m/^!/){
               $neg++;
               $chk=~s/^!//;
            }
            if ($neg && exists($self->{container})){
               $err=$self->getParent->T("negations not allowed on ".
                                        "container based fields",$self->Self());
               last;
            }
            my $qchk='^'.quotemeta($chk).'$';
            $qchk=~s/\\\*/\.*/g;
            $qchk=~s/\\\?/\./g;
            if ($chk eq "[LEER]" || $chk eq "[EMPTY]" ){
               if ($neg){
                  push(@newsearch,keys(%tr),keys(%raw));
               }
               else{
                  push(@newsearch,undef);
               }
            }
            else{
               if ($neg){
                  if (grep(/^$qchk$/i,keys(%tr))){ # check if neg is translated
                     push(@newsearch,grep(!/^$qchk$/i,keys(%tr)));
                     $changed++;
                  }
                  elsif (grep(/^$qchk$/i,keys(%raw))){ # check if neg is on raw
                     push(@newsearch,grep(!/^$qchk$/i,keys(%raw)));
                  }
               }
               else{
                  foreach my $v (keys(%tr)){
                     if ($v=~m/$qchk/i || $tr{$v} eq $chk){
                        if (!grep(/^$tr{$v}$/,@newsearch)){
                           push(@newsearch,$tr{$v});
                        }
                     }
                  }
                  foreach my $v (keys(%raw)){
                     if ($v=~m/$qchk/i || $tr{$v} eq $chk){
                        if (!grep(/^$raw{$v}$/,@newsearch)){
                           push(@newsearch,$raw{$v});
                        }
                     }
                  }
               }
            }
         }
      }
      $hflt->{$field}=\@newsearch;
   }
   my ($subchanged,$suberr)=$self->SUPER::preProcessFilter($hflt);
   return($subchanged+$changed,$err);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;
   my $name=$self->{name};


   if (exists($newrec->{$name})){
      my $val=$newrec->{$name};
      if (($val eq "" || (ref($val) eq "ARRAY" && $#{$val}==-1)) 
          && $self->{allowempty}==1){
         if ($self->{useNullEmpty}){
            if (defined($self->{vjointo}) &&
                defined($self->{vjoinon}) &&
                ref($self->{vjoinon}) eq "ARRAY"){
               return({$self->{vjoinon}->[0]=>undef});
            }

            return({$self->Name()=>undef});
         }
         return({$self->Name()=>$val});
     
      }
      else{
         my @options=$self->getPostibleValues($oldrec,$newrec,"edit");
         my @nativ=@options;
         my %backmap=();
         while($#options!=-1){
            my $key=shift(@options);
            my $val=shift(@options);
            $backmap{$val}=$key;
         }
         my $failfound=0;
         my $chkval=$val;
         my $chkval=[$chkval] if (ref($chkval) ne "ARRAY");
         if (ref($self->{allownative}) eq "ARRAY"){
            push(@nativ,@{$self->{allownative}});
         }
         foreach my $v (@$chkval){
            my $qv=quotemeta($v);
            if (!grep(/^$qv$/,@nativ)){
               $failfound++;
               last;
            }
         }
         if ($self->{allownative} eq "1" || $self->{allowfree} eq "1"){
            $failfound=0;
         }
         if (!$failfound){
            if (defined($self->{dataobjattr}) || defined($self->{container}) ||
                defined($self->{onFinishWrite})){
               return({$self->Name()=>$val});
            }
            else{
               if (defined($self->{vjointo}) &&
                   defined($self->{vjoinon}) &&
                   ref($self->{vjoinon}) eq "ARRAY"){
                  if (exists($backmap{$val})){ # store value is the string
                     return({$self->{vjoinon}->[0]=>$backmap{$val}});
                  }
                  else{  # field has already the id value
                     return({});
                  }
               }
               $self->getParent->LastMsg(ERROR,"invalid write request ".
                                               "to Select field '$name'");
               return(undef); 
            }
         }
         else{
            $self->getParent->LastMsg(ERROR,
             sprintf($self->getParent->T("invalid native value ".
                                         "'%s' in %s"),$val,$name));
         }
         return(undef);
      }
   }
   return({});
}


sub getEmptyFrontendValue
{
   my $self=shift;

   my $t;

   my $tr=$self->{translation};
   $tr=$self->getParent->Self() if (!defined($tr));

   if (exists($self->{emptyvalue})){
      my $eval=$self->{emptyvalue};
      if (exists($self->{transprefix})){
         $eval=$self->{transprefix}.$eval;
      }
      my $translation=
      $t=$self->getParent->T($eval,$tr);
   }
   else{
      $t="[".$self->getParent->T("none")."]";
   }
   return($t);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);

   if (!defined($d) && $self->{allowempty}==1 && ($FormatAs=~m/^Html/)){
      return($self->getEmptyFrontendValue());
   }
   if (!defined($d)){
      if (defined($self->{value}) && in_array($self->{value},undef)){
         $d=[undef];
      }
      else{
         $d=[];
      }
   }

   $d=[$d] if (ref($d) ne "ARRAY");
 
   my $res;
   if (defined($self->{getPostibleValues}) &&
       ref($self->{getPostibleValues}) eq "CODE"){
      my @opt=&{$self->{getPostibleValues}}($self,$current,undef);
      my @res;
      my %p;
      map({$p{$_}++} @{$d});
      
      while(defined(my $k=shift(@opt))){
         my $v=shift(@opt);
         if (exists($p{$k})){
            push(@res,$v);
            delete($p{$k});
         }
      }
      foreach my $k (keys(%p)){
         push(@res,"?-$k");
      }



      $res=join($self->vjoinconcat,@res);
   }
   else{
       $res=join($self->vjoinconcat,map({
           my $tval=$self->getParent->T(
                            $self->{transprefix}.$_,$self->{translation});
           if ($tval eq $self->{transprefix}.$_){
              $tval=$_;
           }
           $tval; } @{$d}));
   }



   if ($FormatAs=~m/^Html/){
      $res=~s/</&lt;/g;
      $res=~s/>/&gt;/g;
      $res=~s/\n/<br>\n/g;
   }
   if ($FormatAs eq "SOAP"){
      if (!ref($res)){
         $res=quoteSOAP($res);
      }
      elsif (ref($d) eq "ARRAY"){
         $res=[map({quoteSOAP($_)} @{$res})];
      }
   }


   return($res);
}


sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;
   my $r={};
   $formated=[$formated] if (ref($formated) ne "ARRAY");
   if (defined($formated)){
      if (defined($self->{container}) || defined($self->{dataobjattr})){
         return($self->SUPER::Unformat($formated,$rec));
      }
      elsif (defined($self->{vjoinon})){
         delete($rec->{$self->{name}}); # prevent log of old name in select
         if ($self->{multisize}>0){
            $r->{$self->{vjoinon}->[0]}=$formated;
         }
         else{
            $r->{$self->{vjoinon}->[0]}=$formated->[0];
            if ($self->{allowempty}==1 && $self->{useNullEmpty}==1 &&
                $formated->[0] eq ""){
               $r->{$self->{vjoinon}->[0]}=undef;
            }
         }
      }
      else{
         $r->{$self->Name()}=$formated;
      }
      if ($self->{allowempty}==1 && !defined($self->{vjointo})){
         $r->{$self->Name()}=undef if ($r->{$self->Name()} eq "");
      }
   }
   return($r);
}

sub prepUploadRecord   # prepair one record on upload
{
   my $self=shift;
   my $newrec=shift;
   my $oldrec=shift;
   my $name=$self->Name();
   if (defined($newrec->{$name})){
      my $reqval=$newrec->{$name};
      my $newkey;
      my @options=$self->getPostibleValues($oldrec,$newrec,"edit");
      my @o=@options;
      if ($self->{multisize}>0){  # multivalue selects
         if (ref($reqval) ne "ARRAY"){
            my $joinconcat=$self->vjoinconcat;
            my $sep;
            if ($joinconcat=~m/,/){
               $sep='[,]\s+';
               $reqval=~s/[,\s\n]*$//s;
            }
            elsif ($joinconcat=~m/;/){
               $sep='[;]\s+';
               $reqval=~s/[;\s\n]*$//s;
            }
            else{
               $sep='[,;]\s+';
            }
            $reqval=[grep(!/^\s*$/,split(/$sep/,$reqval))];
         }
         $newkey=[];
         if ($#{$reqval}!=-1){
            foreach my $strval (@$reqval){
               my @o=@options;
               my $kval;
               while($#o!=-1){   # pass 1 check if value  matches
                  my $key=shift(@o);
                  my $val=shift(@o);
                  if ($val eq $strval){
                     $kval=$key;
                     last;
                  }
               }
               if (!defined($kval)){
                  print msg(ERROR,
                          $self->getParent->T("no matching value '\%s' ".
                                              "in field '\%s'"),
                        $strval,$name);
                  return(0);
               }
               push(@$newkey,$kval);
            }
         }
      }
      else{
         if (!$self->{allowfree}){
            while($#o!=-1){   # pass 1 check if value  matches
               my $key=shift(@o);
               my $val=shift(@o);
               if ($val eq $reqval){
                  $newkey=$key;
                  last;
               }
            }
            if (!defined($newkey)){
               my @o=@options;
               while($#o!=-1){  # pass 1 check if value (translated) matches
                  my $key=shift(@o);
                  my $val=shift(@o);
                  if ($self->getParent->T($self->{transprefix}.$val,
                        $self->{translation}) eq $reqval){
                     $newkey=$key;
                     last;
                  }
               }
               if (!defined($newkey)){
                  my @o=@options;
                  while($#o!=-1){  # pass 1 check if key direct matches
                     my $key=shift(@o);
                     my $val=shift(@o);
                     if ($key eq $reqval){
                        $newkey=$key;
                        last;
                     }
                  }
               }
            }
         }
         else{
            $newkey=$reqval;
         }
      }
      if (!defined($newkey)){
         print msg(ERROR,
                 $self->getParent->T("no matching value '\%s' in field '\%s'"),
               $reqval,$name);
         return(0);
      }
      else{
         if (defined($self->{vjoinon})){
            delete($newrec->{$name});
            $newrec->{$self->{vjoinon}->[0]}=$newkey;
         }
         else{
            $newrec->{$name}=$newkey;
         }
      }
   }
   return(1);
}




1;
