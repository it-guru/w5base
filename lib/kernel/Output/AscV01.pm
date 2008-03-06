package kernel::Output::AscV01;
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
use kernel::Formater;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   return(1);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_asctab.gif");
}
sub Label
{
   return("Output to Text");
}
sub Description
{
   return("Format is a nice table only based on ASCII-characters");
}

sub MimeType
{
   return("text/plain");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".txt");
}


sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:".$self->MimeType().";charset=ISO-8895-1\n\n";

   return($d);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my $app=$self->getParent->getParent();
   my @maxlist=();
   my $headlines=1;

   for(my $c=0;$c<=$#{$self->{fieldobjects}};$c++){
      my $fo=$self->{fieldobjects}->[$c];
      my $label=$fo->Label();
      if (defined($fo->unit)){
         $label.=" (".$fo->unit.")";
      }
      my @lines=split(/\n/,$label);
      $headlines=$#lines+1 if ($headlines<$#lines+1);
      my $s=$fo->Size();
      if (defined($s)){
         $maxlist[$c]=$s;
      }
      foreach my $d (@lines){
         $d=~s/\t/   /g;
         trim(\$d);
         if ($maxlist[$c]<length($d)){
            $maxlist[$c]=length($d);
         }
      }
   }
   for(my $c=0;$c<=$#{$self->{recordlist}};$c++){
      for(my $cc;$cc<=$#{$self->{recordlist}->[$c]};$cc++){
         my $fulldata=$self->{recordlist}->[$c]->[$cc];
         #if ($self->getParent->getParent->Config->Param("UseUTF8")){
         #   $fulldata=utf8($fulldata);
         #   $fulldata=$fulldata->latin1();
         #}
         my @lines=split(/\n/,$fulldata);
         foreach my $d (@lines){
            $d=~s/\t/   /g;
            rtrim(\$d);
            if ($maxlist[$cc]<length($d)){
               $maxlist[$cc]=length($d);
            }
         }
      }
   }
   for(my $c=0;$c<=$#{$self->{fieldobjects}};$c++){
      my $format=sprintf('+-%%-%ds-',$maxlist[$c]);
      my $f=sprintf($format,' ');
      $f=~s/\s/-/g;
      $d.=$f;
   }
   $d.="+\r\n" if ($#{$self->{fieldobjects}}!=-1);
   for(my $hl=0;$hl<$headlines;$hl++){
      for(my $c=0;$c<=$#{$self->{fieldobjects}};$c++){
         my $format=sprintf('| %%-%ds ',$maxlist[$c]);
         my $headtxt=$self->{fieldobjects}->[$c]->Label();
         if (defined($self->{fieldobjects}->[$c]->unit)){
            $headtxt.=" (".$self->{fieldobjects}->[$c]->unit.")";
         }
         my @lines=split(/\n/,$headtxt);
         my $f=sprintf($format,$lines[$hl]);
         $d.=$f;
      }
      $d.="|\r\n" if ($#{$self->{fieldobjects}}!=-1);
   }

   for(my $c=0;$c<=$#{$self->{fieldobjects}};$c++){
      my $format=sprintf('+-%%%ds-',$maxlist[$c]);
      if ($c==0){
         $format=sprintf('|-%%%ds-',$maxlist[$c]);
      }
      my $f=sprintf($format,' ');
      $f=~s/\s/-/g;
      $d.=$f;
   }
   $d.="|\r\n" if ($#{$self->{fieldobjects}}!=-1);

   for(my $c=0;$c<=$#{$self->{recordlist}};$c++){
      my $subline=0;
      my $havenextline=0;
      do{
         $havenextline=0;
         for(my $cc=0;$cc<=$#{$self->{fieldobjects}};$cc++){
            my $align=$self->{fieldobjects}->[$cc]->align();
            $align="-" if (!defined($align));
            $align="-" if ($align eq "left");
            $align=""  if ($align eq "right");
            my $fulldata=$self->{recordlist}->[$c]->[$cc];
            #if ($self->getParent->getParent->Config->Param("UseUTF8")){
            #   $fulldata=utf8($fulldata);
            #   $fulldata=$fulldata->latin1();
            #}
            my @l=split(/\n/,$fulldata);
            my $format=sprintf('| %%%s%ds ',$align,$maxlist[$cc]);
            $l[$subline]=~s/\t/   /g;
            $l[$subline]=~s/\s*$//;
            my $f=sprintf($format,substr($l[$subline],0,$maxlist[$cc]));
            $d.=$f;
            $havenextline=1 if ($#l>$subline);
         }
         $d.="|\r\n" if ($#{$self->{fieldobjects}}!=-1);
         $subline++;
      }while($havenextline);
   }
   for(my $c=0;$c<=$#{$self->{fieldobjects}};$c++){
      my $format=sprintf('+-%%-%ds-',$maxlist[$c]);
      my $f=sprintf($format,' ');
      $f=~s/\s/-/g;
      $d.=$f;
   }
   $d.="+\r\n" if ($#{$self->{fieldobjects}}!=-1);
   return($d);
}

1;
