package kernel::DataObj::Static;
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
use kernel::DataObj;
use Text::ParseWords;

@ISA = qw(kernel::DataObj);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub data
{
   my $self=shift;
   my $filterset=shift;
   if (ref($self->{data}) eq "CODE"){
      return(&{$self->{data}}($self,$filterset));
   }
   return($self->{data});
}

sub Initialize
{
   my $self=shift;
   return(1);
}

sub Fields
{
   my $self=shift;
   return(@{$self->{'FieldOrder'}});
}


sub resolvField
{
   my $self=shift;
   my $field=shift;
   my $rec=shift;
   return(undef);
}

sub tieRec
{
   my $self=shift;

   if (defined($self->{CurrentData}->[$self->{'Pointer'}])){
      my %rec;
      my $rec=$self->{CurrentData}->[$self->{'Pointer'}];
      my $view=[$self->getFieldObjsByView([$self->getCurrentView()],
                                          current=>$rec)];
      tie(%rec,'kernel::DataObj::Static::rec',$self,$rec,$view);
      return(\%rec);
   }
   return(undef);

}

sub getOnlyFirst
{
   my $self=shift;
   if (ref($_[0]) eq "HASH"){
      $self->SetFilter($_[0]);
      shift;
   }
   my @view=@_;
   $self->SetCurrentView(@view);
   $self->Limit(1,1);
   my @res=$self->getFirst();
   return(@res);
}


sub getFirst
{
   my $self=shift;
   $self->{'Pointer'}=undef;

   $self->{CurrentData}=$self->data($self->{FilterSet});
   if (defined($self->{CurrentData}) && ref($self->{CurrentData}) eq "ARRAY" &&
       $self->{InternExternRemapping}>0){
      my @l=map({$self->remapExtern2Intern($_)} @{$self->{CurrentData}});
      $self->{CurrentData}=\@l;
   }

   if (!defined($self->{CurrentData}) || ref($self->{CurrentData}) ne "ARRAY"){
      my @lastmsg=$self->LastMsg();
      return(undef,@lastmsg) if ($#lastmsg!=-1);
      return(undef,"DataCollectError");
   }

#
#   ## hier muss bei Gelegenheit mal ein Order Verfahren rein!

   my @l=0..$#{$self->{CurrentData}};


   my @o=$self->GetCurrentOrder();
   if (!($#o==0 && uc($o[0]) eq "NONE")){
      if ($#o==-1 || ($#o==0 && $o[0] eq "")){
         @o=$self->getCurrentView(1);
      }
   }
   @o=grep(!/^linenumber$/,@o);
   map({$_=~s/^\+//; $_} @o);

   if (grep(/^-/,@o)){
      $self->LastMsg(WARN,"requested descending (desc) order not suppored ".
                          "and will be ignored");
      map({$_=~s/^\-//; $_} @o);
   }

   my @orderbuf;
   for(my $c=0;$c<=$#{$self->{CurrentData}};$c++){
      push(@orderbuf,{
         id=>$c,
         ostring=>substr(join(";",map({
            my $d=$self->{CurrentData}->[$c]->{$_};
            $d=join("|",sort(@$d)) if (ref($d) eq "ARRAY");
            $d;
         } @o)),0,80),
      });
   }
   $self->{'Index'}=[map({$_->{id}}
                     sort({lc($a->{ostring}) cmp lc($b->{ostring})} @orderbuf)
                     )];


   my $LimitStart=$self->{_LimitStart};
   $LimitStart=0 if ($LimitStart eq "");
   $LimitStart=1 if ($LimitStart<1);
   
   $self->{resultRecCnt}=1;

   # LimitStart=1 means starting with 1st record


   $self->{'Pointer'}=shift(@{$self->{'Index'}});
   return(undef) if (!defined($self->{'Pointer'}));

   my $cdata=$self->{CurrentData};

   while(!($self->CheckFilter()) && 
         defined($cdata->[$self->{'Index'}->[$self->{'Pointer'}]])){ 
      $self->{'Pointer'}=shift(@{$self->{'Index'}});
      return(undef) if (!defined($self->{'Pointer'}));
   }
   while($LimitStart>1){
      $self->{'Pointer'}=shift(@{$self->{'Index'}});
      return(undef) if (!defined($self->{'Pointer'}));
      while(!($self->CheckFilter()) && 
            defined($cdata->[$self->{'Index'}->[$self->{'Pointer'}]])){ 
         $self->{'Pointer'}=shift(@{$self->{'Index'}});
         return(undef) if (!defined($self->{'Pointer'}));
      }
      $LimitStart--;
   }

   $self->{resultRecCnt}++;
   return(undef) if (!defined($self->{'Pointer'}));
   return($self->tieRec());
}

sub getNext
{
   my $self=shift;
   return(undef) if ($self->{_Limit}>0 && 
                     $self->{resultRecCnt}>$self->{_Limit});
   $self->{resultRecCnt}++;
   $self->{'Pointer'}=shift(@{$self->{'Index'}});
   return(undef) if (!defined($self->{'Pointer'}));

   while(!($self->CheckFilter()) && 
         defined($self->{CurrentData}->[$self->{'Index'}->[$self->{'Pointer'}]])){ 
      $self->{'Pointer'}=shift(@{$self->{'Index'}});
      return(undef) if (!defined($self->{'Pointer'}));
   }
   return($self->tieRec());
}

sub Rows
{
   my $self=shift;

   $self->{resultRecCnt}=0;

   my $cdata=$self->{CurrentData};
   for(my $c=0;$c<=$#{$cdata};$c++){
      $self->{'Pointer'}=$c;
      if ($self->CheckFilter()){
         $self->{resultRecCnt}++;
      }
   }
   return($self->{resultRecCnt});
}

sub CheckFilter
{
   my $self=shift;
   my $rec=$self->tieRec();
   my @flt=$self->getFilterSet();
   return(1) if (!defined($rec));
   return(1) if ($#flt==-1);
   my $failcount=0;
   my $okcount=0;
   CHK: foreach my $filter (@flt){
      foreach my $k (keys(%{$filter})){
         my $fld=$self->getField($k);
         next if (exists($fld->{RestSoftFilter}) && !$fld->{RestSoftFilter});
         if (exists($filter->{$k}) && !defined($filter->{$k})){ # compare on 
            if (!(!defined($rec->{$k}) && exists($rec->{$k}))){ # null entrys
               $failcount=1;
               last CHK;
            }
         }
         elsif (ref($filter->{$k}) eq "SCALAR"){
            if ($rec->{$k} ne ${$filter->{$k}}){
               $failcount=1;
               last CHK;
            }
         }
         elsif (ref($filter->{$k}) eq "ARRAY"){
            my $subcheck=0;
            FLTCHK: foreach my $v (@{$filter->{$k}}){
               if (ref($rec->{$k}) eq "ARRAY"){
                  foreach my $subval (@{$rec->{$k}}){
                     if ($v eq $subval){
                        $subcheck=1;
                        last FLTCHK;
                     }
                  }
               }
               elsif (ref($rec->{$k}) eq "HASH"){
                  foreach my $subval (values(%{$rec->{$k}})){
                     if ($v eq $subval){
                        $subcheck=1;
                        last FLTCHK;
                     }
                  }
               }
               else{
                  if ($v eq $rec->{$k}){
                     $subcheck=1;
                     last FLTCHK;
                  }
               }
            }
            if ($subcheck==0){
               $failcount=1;
               last CHK;
            }
         }
         else{
            my $chk=$filter->{$k};
            my @words=parse_line('[,;]{0,1}\s+',0,$chk);
            if (!($chk=~m/^\s*$/) && $#words==-1){  # maybe an invalid " struct
               $failcount=1;
               last CHK;
            }
            else{
               my $wordschkok=0;
               my $conjunction; # AND relation

               my @dataval=($rec->{$k});
               if (ref($rec->{$k}) eq "ARRAY"){
                  @dataval=@{$rec->{$k}};
                  @dataval=(undef) if ($#dataval==-1);
               }
               if (ref($rec->{$k}) eq "HASH"){
                  @dataval=values(%{$rec->{$k}});
                  @dataval=(undef) if ($#dataval==-1);
               }

               for (my $i=0;$i<=$#words;$i++) {
                  my $chk=$words[$i];

                  $conjunction=0; # default
                  if ($i<$#words && $words[$i+1] eq 'AND') {
                     $conjunction=1; # relation to next word is AND
                  }

                  my $recok;
                  DATACHK: foreach my $dataval (@dataval){
                     if ($chk=~m/^>/){
                        $chk=~s/^>//;
                        if (!($dataval>$chk)){
                           $recok=0 if (!defined($recok));
                           if ($conjunction) {
                              # skip all words with AND relation
                              while ($i<$#words && $words[$i+1] eq 'AND') {
                                 $i+=2;
                              }
                           }
                        }
                        elsif ($conjunction) {
                           $recok=0 if (!defined($recok));
                           $i+=1; # skip next word. It's AND
                        }
                     }
                     elsif ($chk=~m/^</){
                        $chk=~s/^<//;
                        if (!($dataval<$chk)){
                           $recok=0 if (!defined($recok));
                           if ($conjunction) {
                              while ($i<$#words && $words[$i+1] eq 'AND') {
                                 $i+=2;
                              }
                           }
                        }
                        elsif ($conjunction) {
                           $recok=0 if (!defined($recok));
                           $i+=1;
                        }
                     }
                     elsif ($chk=~m/^!/){
                        $chk=~s/^!//;
                        $chk=~s/\?/\./g;
                        $chk=~s/\*/\.*/g;
                        if (($dataval=~m/^$chk$/i)){
                           $recok=0 if (!defined($recok));
                           if ($conjunction) {
                              while ($i<$#words && $words[$i+1] eq 'AND') {
                                 $i+=2;
                              }
                           }
                        }
                        elsif ($conjunction) {
                           $recok=0 if (!defined($recok));
                           $i+=1;
                        }
                     }
                     else{
                        $chk=~s/\./\\./g;
                        $chk=~s/\?/\./g;
                        $chk=~s/\*/\.*/g;
                        if (!($dataval=~m/^$chk$/i)){
                           $recok=0 if (!defined($recok));
                           if ($conjunction) {
                              while ($i<$#words && $words[$i+1] eq 'AND') {
                                 $i+=2;
                              }
                           }
                        }
                        else{
                           if ($conjunction) {
                              $recok=0 if (!defined($recok));
                              $i+=1;
                           }
                           else {
                              $recok++;
                           }
                        }
                     }
                  }
                  if (defined($recok) && $recok>0){
                     $okcount++;
                  }
                  if (!(defined($recok) && $recok==0)){
                     $wordschkok++;
                  }
                   
               }
               if ($wordschkok==0 && $#words!=-1){
                  $failcount++;
                  last CHK;
               }
            }
         } 
      }
   }
   return(0) if ($failcount); 
   return(1);
}

sub remapExtern2Intern
{
   my $self=shift;
   my $rec=shift;
   my %int;

   if ($self->{InternExternRemapping}>0){
      my @fieldlist=$self->getFieldList();
      foreach my $field (@fieldlist){
         my $fo=$self->getField($field);
         if (defined($fo)){
            my $fieldname=$field;
            if (exists($fo->{dataobjattr})){
               $fieldname=$fo->{dataobjattr};
            }
            if (exists($rec->{$fieldname})){
               $int{$field}=$rec->{$fieldname};
            }
         }
      }
   }
   else{
      return($rec);
   }
   return(\%int); 
}





########################################################################



package kernel::DataObj::Static::rec;
use strict;
use vars qw(@ISA);
use Tie::Hash;

@ISA=qw(Tie::Hash);

sub getParent
{
   return($_[0]->{Parent});
}

sub TIEHASH
{
   my $type=shift;
   my $parent=shift;
   my $rec=shift;
   my $view=shift;
   my %HashView;
   map({$HashView{$_->Name()}=$_} @{$view});
   return(bless({ Parent=>$parent, Rec=>$rec, View=>\%HashView },$type));
}

sub FIRSTKEY
{
   my $self=shift;

   my %k=();
   map({$k{$_}=1;} keys(%{$self->{View}}));
   $self->{'keylist'}=[keys(%k)];

   return(shift(@{$self->{'keylist'}}));
}



sub EXISTS
{
   my $self=shift;
   my $key=shift;

   return(grep(/^$key$/,keys(%{$self->{View}}),keys(%{$self->{Rec}})) ? 1:0);
}

sub NEXTKEY
{
   my $self=shift;
   return(shift(@{$self->{'keylist'}}));
}

sub FETCH
{  
   my $self=shift;
   my $key=shift;
   my $mode=shift;
   return($self->{Rec}->{$key}) if (exists($self->{Rec}->{$key}));
   my $p=$self->getParent;
   if (defined($p)){
      my $fobj;
      if (!defined($self->{View}->{$key})){
         $fobj=$p->getField($key,$self->{Rec});
      }
      else{
         $fobj=$self->{View}->{$key};
      }
      return($p->RawValue($key,$self->{Rec},$fobj,$mode));
   }
   return("- unknown parent for '$key' -");
}


sub STORE
{
   my $self=shift;
   my $key=shift;
   my $val=shift;

   $self->{View}->{$key}=undef if (!exists($self->{View}->{$key}));
   $self->{Rec}->{$key}=$val;
}

sub DELETE
{
   my $self=shift;
   my $key=shift;

   delete($self->{View}->{$key});
   delete($self->{Rec}->{$key});
}






1;
