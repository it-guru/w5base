package kernel::XLSReport;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (it@guru.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;
use File::Temp;
use kernel::Output::XlsV01;

@ISA=qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $parent=shift;
   my $filename=shift;
   my $self=bless({@_},$type);
   $self->{out}=new kernel::Output::XlsV01();
   $self->setParent($parent);
   if ($filename ne ""){
      $self->setFilename($filename);
   }

   return($self);
}

sub Config
{
   my $self=shift;
   return($self->getParent->Config());
}

sub setFilename
{
   my $self=shift;
   my $filename=shift;
   if ($filename=~m/^webfs:/){
      my $fh=new File::Temp();
      $self->{FinalFilename}=$filename;
      $self->{fh}=$fh; 
      $filename=$fh->filename;
      msg(DEBUG,"use TempFilename=$filename");
      $self->{TempFilename}=$filename;
   }
   return($self->{out}->setFilename($filename));
}

sub initWorkbook
{
   my $self=shift;
   return($self->{out}->initWorkbook());
}

sub setDataObj
{
   my $self=shift;
   my $DataObj=shift;
   $self->{out}->setParent($DataObj);
   return($self->{out}->setDataObj($DataObj));
}

sub crec
{
   my $self=shift;
   if (ref($self->{crec}->{$_[0]}) eq "CODE"){
      return(&{$self->{crec}->{$_[0]}});
   }
   return($self->{crec}->{$_[0]});
}

sub Process
{
   my $self=shift;

   my $out=$self->{out};
   foreach my $cr (@_){
      $self->{'crec'}=$cr;

      my $DataObj=getModuleObject($self->Config,$self->crec('DataObj'));
      $DataObj->SetFilter($self->crec('filter'));
      $out->setDataObj($DataObj);
      my $sheetname=$self->crec('sheet');
      $sheetname=$DataObj->T($DataObj->Self(),$DataObj->Self()) if ($sheetname eq "");
      my $line=1;
      foreach my $rec ($DataObj->getHashList(@{$self->crec('view')})){
         if ($line==1){
            $out->addSheet($sheetname);
         }
         my @recordview=$DataObj->getFieldObjsByView($self->crec('view'),
                                                 current=>$rec);
         my $fieldbase={};
         map({$fieldbase->{$_->Name()}=$_} @recordview);
         $out->{fieldkeys}={};
         $out->{fieldobjects}=[];
         foreach my $fo (@recordview){
            my $name=$fo->Name();
            if (!defined($out->{fieldkeys}->{$name})){
               push(@{$out->{fieldobjects}},$fo);
               $out->{fieldkeys}->{$name}=$#{$out->{fieldobjects}};
            }
         }
         $out->ProcessLine(undef,["ALL"],$rec,\@recordview,
                           $fieldbase,$line++,undef);
      }
      if ($line>1){
         $out->ProcessBottom(undef,undef,"",{});
         $out->ProcessHead(undef,undef,"",{});
      }
   }
   $out->closeWorkbook();
   if (my ($f)=$self->{FinalFilename}=~m/^webfs:(.*)$/){
      my $filename=$self->{TempFilename};
      close($self->{fh});
      if (my ($dir,$dstfile)=$f=~m/^(.*)\/([^\/]+)$/){
         $dir=~s/^\///;
         my $file=getModuleObject($self->Config,"base::filemgmt");
         msg(DEBUG,"temp name=$filename");
         msg(DEBUG,"webfs dir=$dir file=$file");
         if (open(F,"<$filename")){
            if (!($file->ValidatedInsertOrUpdateRecord(
                         {name=>$dstfile, parent=>$dir,file=>\*F},
                         {name=>\$dstfile,parent=>\$dir}))){
               msg(ERROR,"fail to store $self->{FinalFilename}");
            }
            close(F);
         }
         else{
            msg(ERROR,"fail to open temp file $filename");
         }
      }
      unlink($filename);
   }
   return(1);
}






1;

