package kernel::Field::DataMaintContacts;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
   $self{readonly}=1                     if (!exists($self{readonly}));
#   $self{'vjointo'}="base::lnkcontact"   if (!defined($self{'vjointo'}));
#   $self{'vjoinon'}=['id'=>'refid']      if (!defined($self{'vjoinon'}));
   $self{'uploadable'}=0                 if (!defined($self{'uploadable'}));
   $self{'allowcleanup'}=1               if (!defined($self{'allowcleanup'}));
   $self{'forwardSearch'}=1              if (!defined($self{'forwardSearch'}));
   $self{'htmldetail'}=1                 if (!defined($self{'htmldetail'}));
   $self{'limit'}=5                      if (!defined($self{'limit'}));
   $self{'label'}='Data maintenences contacts'   if (!defined($self{'label'}));
   $self{'name'}='datamaintcontacts'     if (!defined($self{'name'}));
   
   my $self=bless($type->SUPER::new(%self),$type);
   $self->{searchable}=0;

   if (!exists($self->{depend})){
      $self->{depend}=[];
   }
   $self->{depend}=[$self->{depend}] if (ref($self->{depend}) ne "ARRAY");
   if (!in_array($self->{depend},"databossid")){
      push(@{$self->{depend}},"databossid");
   }
   if (!in_array($self->{depend},"contacts")){
      push(@{$self->{depend}},"contacts");
   }

   return($self);
}


sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;    # ATTENTION! - This is not always set! (at now 03/2013)

   my $o;
   my @cur;
   
   if ($self->{vjointo} ne ""){
      if (ref($self->{vjoinon}) ne "ARRAY" ||
          $#{$self->{vjoinon}}!=1){
         msg(ERROR,"invalid vjoinon in $self");
         return(undef);
      }
      $o=$self->vjoinobj();
      my @view=@{$self->{depend}};
      my $idfld=$o->IdField();
      if (defined($idfld)){
         my $idname=$idfld->Name();
         if (!in_array(\@view,$idname)){
            push(@view,$idname);
         }
      }
      my $myval;
      my $myfieldobj=$self->getParent->getField($self->{vjoinon}->[0]);
      if (defined($myfieldobj)){
         if ($myfieldobj ne $self){
            my $_myval=$myfieldobj->RawValue($current);
            if (!ref($_myval)){
               if ($_myval ne ""){
                  $myval=\$_myval;
               }
            }
            else{
               $myval=$_myval;
            }
         }
      }
      if (!defined($myval)){
         return(undef);
      }
      $o->SetFilter({$self->{vjoinon}->[1]=>$myval});
      @cur=$o->getHashList(@view);
   }
   else{
      @cur=($current);
      $o=$self->getParent->Clone();
   }


   my %uid;

   foreach my $cur (@cur){
      $o->getWriteAuthorizedContacts($cur,$self->{depend},100,\%uid);
   }
   return([sort({
      $a->{responselevel}<=>$b->{responselevel} ||
      $a->{fullname} cmp $b->{fullname} 
   } values(%uid))]);
}

sub  addUid
{
   my $self=shift;
   my $uid=shift;
   my $id=shift;
   my $responselevel=shift;

   if (!exists($uid->{$id})){
      $uid->{$id}={
         responselevel=>$responselevel
      };
   }
   else{
      if ($uid->{$id}->{responselevel}>$responselevel){
         $uid->{$id}->{responselevel}=$responselevel;
      }
   }
}

#sub FormatedDetail
#{
#   my $self=shift;
#   my $current=shift;
#   my $mode=shift;
#   my $name=$self->Name();
#
#
#
#
#
#   return($d);
#}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();

   my @res;
   if (defined($d)){
      my @showlist;
      if (($mode=~m/^Html/) && $#{$d}>$self->{limit}){
         @showlist=(splice(@$d,0,$self->{limit}),
                    {userid=>undef,fullname=>'further',responselevel=>99});
      }
      else{
         @showlist=@$d;
      }
      foreach my $crec (@showlist){
         my $formpref;
         my $formpost;
         my $fullname=$crec->{fullname};
         if (!defined($crec->{userid})){
            $fullname="+".$self->getParent->T($fullname,
                          "kernel::Field::DataMaintContacts");

         }
         
         if ($mode=~m/^Html/){
            if ($crec->{responselevel}==1){
               $formpref="<b>";
               $formpost="</b>";
            }
            if ($crec->{responselevel}>50){
               $formpref="<font color=gray>";
               $formpost="</font>";
            }
         }
         if ($mode eq "HtmlDetail"){
            push(@res,$formpref.$fullname.$formpost);
         }
         if ($mode eq "HtmlV01"){
            push(@res,$formpref.$fullname.$formpost);
         }
      }
   }
   if ($mode=~m/^Html/){
      return(join("; ",@res));
   }
   return("ERROR - data not exportabel");
   return(\@res);
}












1;
