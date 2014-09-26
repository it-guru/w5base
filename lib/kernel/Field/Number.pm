package kernel::Field::Number;
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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{editrange}=1;
   $self->{_permitted}->{precision}=1;
   $self->{_permitted}->{minprecision}=1; # kann definiert werden, wenn 
                                          # nullen am Ende auf die minimale
                                          # anzahl von stellen entfernt werden
                                          # sollen (nur in der HTML Oberfläche)
   $self->{_permitted}->{decimaldot}=1;
   $self->{decimaldot}="," if (!defined($self->{decimaldot}));

   return($self);
}

sub RawValue
{
   my $self=shift;
   my $d=$self->SUPER::RawValue(@_);
   if (defined($d)){    # normalisierung, damit die Daten intern immer
      $d=~s/,/./g;      # mit . als dezimaltrenner behandelt werden
   }
   return($d);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current,$mode);
   my $name=$self->Name();
   if ($mode eq "HtmlSubList" || $mode eq "HtmlV01" || 
       $mode eq "HtmlDetail" || $mode eq "HtmlChart"){
      if (defined($d) && $d ne ""){
         my $format=sprintf("%%.%df",$self->{precision});
         $d=sprintf($format,$d);
         $d=~s/\./$self->{decimaldot}/g;
         $d=[$d] if (ref($d) ne "ARRAY");
         if ($mode eq "HtmlDetail"){
            $d=[map({$self->addWebLinkToFacility(quoteHtml($_),$current)} 
                    @{$d})];
         }
         if ($mode eq "HtmlV01"){
            $d=[map({quoteHtml($_)} @{$d})];
         }
         if ($mode ne "XMLV01"){
            my $vjoinconcat=$self->{vjoinconcat};
            $vjoinconcat="; " if (!defined($vjoinconcat));
            $d=join($vjoinconcat,@$d);
         }
         if (defined($self->{unit})){
            if ($d ne "" && $mode eq "HtmlDetail"){
               $d.=" ".$self->unit($mode,$d,$current);
            }
         }
         if (exists($self->{background})){
            $d=$self->BackgroundColorHandling($mode,$current,$d);
         }
      }

      return($d);
   }
   if (($mode eq "edit" || $mode eq "workflow") && 
       !defined($self->{vjointo})){
      my $readonly=0;
      if ($self->readonly($current)){
         $readonly=1;
      }
      if (defined($d) && $d ne ""){
         my $format=sprintf("%%.%df",$self->{precision});
         $d=sprintf($format,$d);
         $d=~s/\./,/g;
      }
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      return($self->getSimpleInputField($d,$readonly));
   }
   return($d);
}



sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;
   if (defined($formated)){
      return(undef) if (!defined($formated->[0]));
      $formated=trim($formated->[0]) if (ref($formated) eq "ARRAY");
      return({$self->Name()=>undef}) if ($formated eq "");
      my $d=$formated;
      my $precision=$self->precision;
      $precision=0 if (!defined($precision));
      if ($d=~m/\.\d+,/){  # german notation with . as thausend sep
         $d=~s/\.//g;
      }
      if ($d=~m/,\d+\./){  # english notation with , as thausend sep
         $d=~s/,//g;
      }
      if (!($d=~s/(-?)(\d+)[,\.]{0,1}([0-9]{0,$precision})[0-9]*$/$1$2\.$3/)){
         $self->getParent->LastMsg(ERROR,
             sprintf(
                $self->getParent->T("invalid number format '%s' in field '%s'",
                   $self->Self),$d,$self->Label()));
         printf STDERR ("error\n");
         return(undef);
      }
      $d=~s/\.$//;
     # if ($formated ne "" && $d eq ""){
     #    return(undef);
     # }

      return({$self->Name()=>$d});
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




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return({}) if (!exists($newrec->{$self->Name()}));
   if (defined($newrec->{$self->Name()})){
      if (ref($self->{editrange}) eq "ARRAY"){
         my $d=$newrec->{$self->Name()};
         if (!($d>=$self->{editrange}->[0] && $d<=$self->{editrange}->[1])){
            $self->getParent->LastMsg(ERROR,
                sprintf(
                   $self->getParent->T(
                     "value '%s' not in allowed range '%s-%s' for '%s'",
                      $self->Self),$d,
                     $self->{editrange}->[0],$self->{editrange}->[1],
                     $self->Label()));
            return(undef);
         }
      }
   }
   return($self->SUPER::Validate($oldrec,$newrec));
}




sub getXLSformatname
{
   my $self=shift;
   my $data=shift;

   my $f=$self->SUPER::getXLSformatname;

   if ( defined($self->precision) &&
       !defined($self->xlsnumformat)) {
      my $p="number.".$self->precision();
      $f=~s/^\w+?(\.|$)/$p$1/;
   }

   return $f;
}











1;
