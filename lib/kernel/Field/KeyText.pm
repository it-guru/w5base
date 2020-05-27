package kernel::Field::KeyText;
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
   $param{vjoinconcat}=", " if (!defined($param{vjoinconcat}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{multiple}=1       if (!defined($self->{multiple}));
   $self->{conjunction}="or" if (!defined($self->{conjunction}));
   $self->{WSDLfieldType}="ArrayOfStringItems" if (!defined($self->{WSDLfieldType}));
   return($self);
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $changed=0;

   if (defined($hflt->{$self->{name}}) &&
       $hflt->{$self->{name}} ne ""){
      my $name=$self->Name();
      my $keyfield=$self->getParent->getField($self->{keyhandler});
      my $idfield=$self->getParent->IdField()->Name();

      $keyfield->Initialize();
      my $db=$keyfield->{db};
      my $keytab=$keyfield->{tablename};
      my %res=();
      my $cmd="select name,id from $keytab";
      my $str=$hflt->{$self->{name}};
      $str=trim($str);
      my @words=parse_line('[,;]{0,1}\s+',0,$str);
      if (lc($self->{conjunction}) eq "or"){
         my $where="";
         my %sqlparam=(sqldbh=>$db);
         my $bk=$self->getParent->Data2SQLwhere(\$where,"fval",
                                     $hflt->{$self->{name}},%sqlparam);
         return(undef) if (!$bk);
         my %sqlparam=(sqldbh=>$db,listmode=>0,wildcards=>0);
         my $bk=$self->getParent->Data2SQLwhere(\$where,"name",
                                     $name,%sqlparam);
         return(undef) if (!$bk);
         my @useindex;
         if (defined($keyfield->{extselect})){
            foreach my $sfld (keys(%{$keyfield->{extselect}}),$idfield){
               my $fo=$self->getParent->getField($sfld);
               my $type=$fo->Type();
               my $sqltype="STRING";
               $sqltype="DATE" if ($type=~m/Date$/); 
               if (exists($hflt->{$sfld})){
                  if ($sfld eq "trange"){
                     my $trangetab=$keyfield->{extselect}->{$sfld};
                     my $range=$hflt->{$sfld};

                     my $res=$self->getParent->ExpandTRangeExpression($range,
                        undef,undef,undef,
                        {
                           align=>'day'
                        }
                     );
                     my $s=$self->getParent->ExpandTimeExpression(
                           $res->[0],"en"
                     );
                     my $e=$self->getParent->ExpandTimeExpression(
                           $res->[1],"en"
                     );
                     $where="($where) and (" if ($where ne "");
                     $where.="$trangetab.s<='$e'";
                     $where.=" or ";
                     $where.=" ($trangetab.m<='$e' and $trangetab.m>='$s') ";
                     $where.=" or ";
                     $where.="$trangetab.e>='$s'";
                     $where.=")";
                     $cmd="select $keytab.name,$keytab.id ".
                          "from $trangetab join $keytab on ".
                          "$keytab.id=$trangetab.wfheadid";
                  }
                  else{
                     my %sqlparam=(sqldbh=>$db,datatype=>$sqltype);
                     my $searchfield;
                     if ($sfld eq $idfield){
                        $searchfield=$keytab.".id";
                     }
                     else{
                        $searchfield=$keytab.".".
                                     $keyfield->{extselect}->{$sfld};
                     }
                     my $bk=$self->getParent->Data2SQLwhere(\$where,
                                        $searchfield,
                                        $hflt->{$sfld},%sqlparam);
                     return(undef) if (!$bk);
                  }
               }
            }
         }
         if ($#useindex!=-1){
            $cmd.=" use index(".join(",",@useindex).")";
         }
         my $subcmd="$cmd where $where";
         #msg(INFO,"key searchcmd or=%s",$subcmd);
         $self->getParent->Log(INFO,"sqlread",$subcmd.
                               " (KeyText subcmd OR)");
         foreach my $rec ($db->getHashList($subcmd)){
            $res{$rec->{id}}++;
         }
      }
      else{
         foreach my $word (@words){
            my $sword=$word;
            $sword=~s/\*/%/g;
            my $op="like";
            $op="=" if (($sword=~m/^\d+$/));
            my $subcmd="$cmd where fval $op '$sword' and name='$name'";
            #msg(INFO,"key searchcmd and=%s",$subcmd);
            $self->getParent->Log(INFO,"sqlread",$subcmd.
                                  " (KeyText subcmd AND)");
            foreach my $rec ($db->getHashList($subcmd)){
               $res{$rec->{id}}++;
            }
         }
      }
      my @residlist=();
      foreach my $id (keys(%res)){
         # >= search needed for wildcard AND searches!
         if ($res{$id}>=$#words+1 || lc($self->{conjunction}) eq "or"){
            push(@residlist,$id);
         }
      }
      push(@residlist,"none") if ($#residlist==-1);
      if (lc($self->{conjunction}) eq "or"){
         my $oldflt=$self->getParent->GetNamedFilter(
                                         "KeyFilter:".$self->{name});
         if (defined($oldflt)){
            $oldflt=$oldflt->[0] if (ref($oldflt) eq "ARRAY");
            if (ref($oldflt->{$idfield}) eq "ARRAY"){
               foreach my $existid (@{$oldflt->{$idfield}}){
                  push(@residlist,$existid);
               }
            }
         }
      }
      $self->getParent->SetNamedFilter("KeyFilter:".$self->{name},
                                       {$idfield=>\@residlist});
      delete($hflt->{$self->{name}});
   }
   return($changed);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record
   my $name=$self->Name();

   if (exists($newrec->{$name})){
      my $khrec={}; 
      my $keyname=$self->keyName();
      if (defined($currentstate->{$self->{keyhandler}})){
         $khrec=$currentstate->{$self->{keyhandler}};
      }
      my @d;
      if ($self->{multiple}){
         if (ref($newrec->{$self->Name()}) eq "ARRAY"){
            @d=@{$newrec->{$self->Name()}};
         }
         else{
            @d=parse_line('[,;]{0,1}\s+',0,$newrec->{$self->Name()});
         }
      }
      else{
         if (ref($newrec->{$self->Name()}) eq "ARRAY"){
            if (defined($newrec->{$self->Name()}->[0])){
               @d=$newrec->{$self->Name()}->[0];
            }
         }
         else{
            @d=($newrec->{$self->Name()});
         }
      }
      if (defined($self->{vjointo})){   # input handling in workflow init
         my $newval=$newrec->{$name};
         my $elementcount=1;
         my $filter;
         if (ref($newval) eq "ARRAY"){
            $filter={$self->{vjoindisp}=>$newval};
            $elementcount=$#{$newval}+1;
         }
         else{
            $newval=trim($newval);
         }
         $filter={$self->{vjoindisp}=>'"'.$newval.'"'};


         $self->FieldCache->{LastDrop}=undef;

         if (defined($self->{vjoinbase})){
            $self->vjoinobj->SetNamedFilter("BASE",$self->{vjoinbase});
         }
         if (defined($self->{vjoineditbase})){
            $self->vjoinobj->SetNamedFilter("EDITBASE",$self->{vjoineditbase});
         }
         $self->vjoinobj->SetFilter($filter);
         my %param=(AllowEmpty=>1);
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
            if (ref($newval) ne "ARRAY"){
               $filter={$self->{vjoindisp}=>'"*'.$newval.'*"'};
            }
            else{
               $filter={$self->{vjoindisp}=>$newval};
            }
            $self->vjoinobj->ResetFilter();
            if (defined($self->{vjoineditbase})){
               $self->vjoinobj->SetNamedFilter("EDITBASE",
                                               $self->{vjoineditbase});
            }
            $self->vjoinobj->SetFilter($filter);
            ($dropbox,$keylist,$vallist)=$self->vjoinobj->getHtmlSelect(
                                                     "Formated_$name",
                                                     $self->{vjoindisp},
                                                  [$self->{vjoindisp}],%param);
         }
         my $srcval;
         my $dstkey;
         if (ref($newval) ne "ARRAY"){
            if ($#{$keylist}>0){
               $self->FieldCache->{LastDrop}=$dropbox;
               $self->getParent->LastMsg(ERROR,"'%s' value '%s' is not unique",
                                                $self->Label,$newval);
               return(undef);
            }
            if ($#{$keylist}<0 && $newrec->{$name} eq "" && $fromquery eq ""){
               $dstkey=undef;
               $srcval=undef;
            }
            else{
               if ($#{$keylist}<0 && ((defined($fromquery) 
                                       && $fromquery ne "") ||
                                      (defined($newrec->{$name}) && 
                                       $newrec->{$name} ne $oldrec->{$name}))){
                  $self->getParent->LastMsg(ERROR,"'%s' value '%s' not found",
                                            $self->Label,$newval);
                  return(undef);
               }
               $dstkey=$self->vjoinobj->getVal($self->vjoinobj->IdField->Name(),
                          $filter);
               $srcval=$vallist->[0];
            }
            
         }
         else{
            my @dstkey=$self->vjoinobj->getVal($self->vjoinobj->IdField->Name(),
                       $filter);
            $dstkey=\@dstkey;
            $srcval=$newval;
         }

         if (ref($newval) ne "ARRAY"){
            Query->Param("Formated_".$name=>$srcval);
         }
         if ($self->{vjoinon}->[0] ne $name){
            Query->Param("Formated_".$self->{vjoinon}->[0]=>$dstkey);
         }
         $khrec->{$keyname}=$srcval;
         $khrec->{$self->{vjoinon}->[0]}=$dstkey;
         
         if (!defined($self->{container})){
            delete($newrec->{$keyname});
            return({$self->{keyhandler}=>$khrec});
         }
         else{
            return({%$khrec,
                    $self->{keyhandler}=>$khrec});
         }
         return(undef);
      }
      $khrec->{$keyname}=\@d;
      if (!defined($self->{container})){
         delete($newrec->{$keyname});
         return({$self->{keyhandler}=>$khrec});
      }
      return({$keyname=>$newrec->{$keyname},
              $self->{keyhandler}=>$khrec});
   }
   return({});
}


sub keyName
{
   my $self=shift;

   if (!defined($self->{keyalias})){
      return($self->Name());
   }
   return($self->{keyalias});
}




sub RawValue
{
   my $self=shift;
   my $current=shift;

   if (exists($current->{$self->Name()})){
      return($current->{$self->Name()});
   }
   if (defined($self->{container})){
      my $keyfield=$self->getParent->getField($self->{container});
      my $keyval=$keyfield->RawValue($current);

      if (ref($keyval->{$self->{name}}) eq "ARRAY" &&
          $#{$keyval->{$self->{name}}}>0) {
         my @l=sort(@{$keyval->{$self->{name}}});
         return(\@l);
      }

      return($keyval->{$self->{name}});
   }
   my $keyfield=$self->getParent->getField($self->{keyhandler});
   my $keyval=$keyfield->RawValue($current);
   my $d=$keyval->{$self->{name}};
   if (ref($keyval->{$self->{name}}) eq "ARRAY"){
      my @l=@{$keyval->{$self->{name}}};
      $d=\@l;
   }
   $current->{$self->Name()}=$d;
   
   return($d);
}

sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;
   my $r={};
   if (defined($formated)){
      if ($self->{multiple}){
         $r->{$self->{name}}=[split(/[,;]{0,1}\s+/,$formated->[0])];
      }
      else{
         $r->{$self->{name}}=[$formated->[0]];
      }
      if ($#{$r->{$self->{name}}}==0){
         $r->{$self->{name}}=$r->{$self->{name}}->[0];
      }
   }
   return($r);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();

   if ($mode eq "storedworkspace"){
      return($self->FormatedStoredWorkspace());
   }

   if (($mode eq "edit" || $mode eq "workflow")){
      $d=join($self->{vjoinconcat},@$d) if (ref($d) eq "ARRAY");
      my $readonly=0;
      if ($self->readonly($current)){
         $readonly=1;
      }
      if ($self->frontreadonly($current)){
         $readonly=1;
      }
      if ($mode eq "workflow"){ # if the developer has request an element
         $readonly=0;           # in workflow edit mode, then readonly makes
      }                         # no sense
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      if ($self->FieldCache->{LastDrop}){
         return($self->FieldCache->{LastDrop});
      }
      return($self->getSimpleInputField($d,$readonly));
   }
   $d=[$d] if (ref($d) ne "ARRAY");
   if ($mode eq "HtmlDetail"){
      $d=[map({$self->addWebLinkToFacility(quoteHtml($_),$current)} @{$d})];
   }
   if ($mode eq "SOAP"){
      $d=[map({quoteSOAP($_)} @{$d})];
      return($d);
   }
   if ($mode eq "HtmlV01"){
      $d=[map({quoteHtml($_)} @{$d})];
   }
   my $vjoinconcat=$self->{vjoinconcat};
   $vjoinconcat="; " if (!defined($vjoinconcat));
   $d=join($vjoinconcat,@$d);
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
      $var=quoteHtml($var);
      $d.="<input type=hidden name=Formated_$name value=\"$var\">";
   }
   $d=$disp.$d;
   my $dstkey=$self->{vjoinon}->[0];
   my @curval=Query->Param("Formated_".$dstkey);
   foreach my $var (@curval){
      $var=quoteHtml($var);
      $d.="<input type=hidden name=Formated_$dstkey value=\"$var\">";
   }

   return($d);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $myname=$self->Name();
   my $oldval=$oldrec->{$myname} if (defined($oldrec) &&
                                     exists($oldrec->{$myname}));
   my $newval=$newrec->{$myname} if (defined($newrec) &&
                                     exists($newrec->{$myname}));

   my $keyname=$self->keyName();
   if (defined($newval)){
      my $khrec={}; 
      if (defined($newrec->{$self->{keyhandler}})){
         $khrec=$newrec->{$self->{keyhandler}};
      }
      $khrec->{$keyname}=$newval;
      $newrec->{$self->{keyhandler}}=$khrec;
   }
}








1;
