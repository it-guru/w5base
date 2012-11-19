package kernel::Field::JoinUniqMerge;
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
   my $self={@_};
   $self->{value}=[0,1]            if (!defined($self->{value}));
   $self->{transprefix}="boolean." if (!defined($self->{transprefix}));
   $self->{master}="1"             if (!defined($self->{master}));
   $self->{default}="0"            if (!defined($self->{default}));
   $self->{uploadable}="0"         if (!defined($self->{uploadable}));
   $self->{readonly}='1'           if (!defined($self->{htmleditwidth}));
   $self->{WSDLfieldType}="xsd:string" if (!defined($self->{WSDLfieldType}));
   $self=bless($type->SUPER::new(%{$self}),$type);
   $self->{vjoinconcat}=undef;
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->SUPER::RawValue($current);

   $d=[$d] if (ref($d) ne "ARRAY");
   @$d=grep(!/^$/,@$d);
   if ($#{$d}==-1){
      $d=[$self->{default}];
   }
   my %out;
   my %chk;
   foreach my $v (@{$d}){
      $chk{$v}++;
   }
   if ($mode=~m/Html/){
      foreach my $v (@{$d}){
         my $o=$self->getParent->T($self->{transprefix}.$v,
                                   $self->{translation});
         if ($v eq $self->{master} && keys(%chk)>1){
            $o="<u><b>$o</b></u>";
         }
         $out{$o}++;
      }
   }
   else{
      foreach my $v (@$d){
         my $o=$self->getParent->T($self->{transprefix}.$v,
                                   $self->{translation});
         $out{$o}++;
      }
   }
   my $res=join("; ",sort(keys(%out)));
   return($res);
}

sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $d;

   my $d=$self->SUPER::RawValue($current);

   $d=[$d] if (ref($d) ne "ARRAY");
   @$d=grep(!/^$/,@$d);
   if ($#{$d}==-1){
      $d=[$self->{default}];
   }
   my %out;
   my %chk;
   foreach my $v (@{$d}){
      $chk{$v}++;
   }
   if (keys(%chk)==0){ 
      return($self->{default});
   }
   if (keys(%chk)==1){
      foreach my $v (@{$d}){
         return($v);
      }
   }
   else{
      foreach my $v (@{$d}){
         if ($v eq $self->{master}){
            return($v);
         }
      }
      foreach my $v (@{$d}){
         return($v);
      }
   }

}


1;
