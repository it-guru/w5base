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
   if (ref($filename) eq "ARRAY" || $filename=~m/^webfs:/){
      $filename=[$filename] if (ref($filename) ne "ARRAY");
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
      delete($ENV{HTTP_ACCEPT_LANGUAGE});
      if ($self->crec('lang') ne ""){
         $ENV{HTTP_ACCEPT_LANGUAGE}=$self->crec('lang');
      }


      my $DataObj;
      my $reqDataObj=$self->crec('DataObj');
      if (ref($reqDataObj)){
         $DataObj=$reqDataObj;
      }
      else{
         $DataObj=getModuleObject($self->Config,$reqDataObj);
      }
      $DataObj->SetFilter($self->crec('filter'));
      $out->setDataObj($DataObj);
      $DataObj->SetCurrentView(@{$self->crec('view')});
      my $sqlorder=$self->crec('order');
      if ($sqlorder ne ""){
         $DataObj->SetCurrentOrder($sqlorder);
      }
      my $sheetname=$self->crec('sheet');

      my $sheetname=$self->crec('sheet');
      if ($sheetname eq ""){
         $sheetname=$DataObj->T($DataObj->Self(),$DataObj->Self());
      }
      my $line=1;
      my ($rec,$msg)=$DataObj->getFirst(unbuffered=>1);
      if (defined($rec)){
         my $reproccount=0;
         do{
            my @recordview=$DataObj->getFieldObjsByView($self->crec('view'),
                                                        current=>$rec);
            my $recordPreProcessor=$self->{crec}->{'recPreProcess'};
            my $doNext=1;
            my $res=1;
            if (ref($recordPreProcessor) eq "CODE"){
               $res=&{$recordPreProcessor}($self->getParent(),$DataObj,$rec,
                                           \@recordview,$reproccount);
               # 0 = no display
               # 1 = display
               # 2 = display and reprocess
               if ($res==2){
                  $doNext=0;
               }
            }
            if ($res){
               if ($line==1){
                  $out->addSheet($sheetname);
               }
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
            if ($doNext){
               ($rec,$msg)=$DataObj->getNext();
               $reproccount=0;
            }
            else{
               $reproccount++;
            }
         } until(!defined($rec));
      }
      if ($line>1){
         $out->ProcessBottom(undef,undef,"",{});
         $out->ProcessHead(undef,undef,"",{});
      }
   }
   $out->closeWorkbook();
   if (ref($self->{FinalFilename}) eq "ARRAY"){
      my $filename=$self->{TempFilename};
      foreach my $FinalFilename (@{$self->{FinalFilename}}){
         if (my ($f)=$FinalFilename=~m/^webfs:(.*)$/){
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
         }
         else{
            msg(ERROR,"output to multiple files in filesystem not supported");
         }
      }
      unlink($filename);
   }
   return(1);
}






1;

