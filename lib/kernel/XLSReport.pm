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
use File::Temp qw(tempfile);
use kernel::Output::XlsV01;

@ISA=qw(kernel::Universal);

sub new              # filename AND FinalFilename can be specified at new!
{
   my $type=shift;
   my $parent=shift;
   my $filename=shift;
   my $self=bless({@_},$type);
   $self->{out}=new kernel::Output::XlsV01();
   $self->{out}->setParent($self);
   $self->setParent($parent);
   $self->{filename}=$filename;
   if ($filename ne "" && $filename ne ">&STDOUT"){
      $self->setFilename($filename);
   }
   else{
      my ($fh, $filename) = tempfile();
      $self->setFilename($filename);
   }

   return($self);
}

sub Config
{
   my $self=shift;
   return($self->getParent->Config());
}

sub getDownloadFilename   # this callback is needed for &STDOUT 
{
   my $self=shift;
   return($self->{FinalFilename}) if ($self->{FinalFilename} ne "");

   return(undef);
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
      $self->FullContextReset();
      $self->Context->{Linenumber}=0;
      $out->{fieldkeys}={};
      $out->{fieldobjects}=[];
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
      if ($sheetname eq ""){
         $sheetname=$DataObj->T($DataObj->Self(),$DataObj->Self());
      }
      $self->Context->{Linenumber}=0;
      $self->Context->{Recordnumber}=0;

      my $line=1;
      my $unbuffered=$self->crec('unbuffered');
      $unbuffered=1 if (!defined($unbuffered));
      my ($rec,$msg)=$DataObj->getFirst(unbuffered=>$unbuffered);
      if (defined($rec)){
         my $reproccount=0;
         do{
            $self->Context->{Linenumber}++;
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
               if ($self->Context->{Linenumber}==1){
                  $out->addSheet($sheetname);
               }
               my $fieldbase={};
               map({$fieldbase->{$_->Name()}=$_} @recordview);
               foreach my $fo (@recordview){
                  my $name=$fo->Name();
                  if (!defined($out->{fieldkeys}->{$name})){
                     push(@{$out->{fieldobjects}},$fo);
                     $out->{fieldkeys}->{$name}=$#{$out->{fieldobjects}};
                  }
               }
               $out->ProcessLine(undef,["ALL"],$rec,\@recordview,
                                 $fieldbase,$self->Context->{Recordnumber},
                                 undef);
               $self->Context->{Recordnumber}++;
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
      if ($self->Context->{Linenumber}>1){
         $out->ProcessBottom(undef,undef,"",{});
         $out->ProcessHead(undef,undef,"",{});
      }
   }
   $out->closeWorkbook();
   if ($self->{filename} eq ">&STDOUT"){
      print STDOUT ($out->DownloadHeader().
                    $out->getHttpHeader());
      $out->Finish();
   }
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
            if (open(OUT,">$FinalFilename")){
               if (open(IN,"<$filename")){
                  my $sblk=1024;
                  my $blk;
                  while(my $r=sysread(IN,$blk,$sblk)){
                     my $w=syswrite(OUT,$blk);
                     if ($r!=$w){
                        msg(ERROR,"fail to write output to '%s'",
                                  $FinalFilename);
                        delete($ENV{HTTP_ACCEPT_LANGUAGE});
                        return(undef);
                     }
                  }
               }
               close(OUT);
            }
            else{
               msg(ERROR,"fail to open '%s'",$FinalFilename);
            }
         }
      }
      unlink($filename);
      delete($ENV{HTTP_ACCEPT_LANGUAGE});
   }
   return(1);
}

sub StdReportParamHandling
{
   my $self=shift;
   my %param=@_;

   my $eventend="currentmonth";
   if ($param{month} ne ""){
      $eventend="$param{month}";
   }
   my $origeventend=$param{month};
   my $eventendfilename;
   $eventend=$self->getParent->PreParseTimeExpression($eventend,"GMT",
                                               \$eventendfilename);
   if ($eventendfilename eq ""){
      return({exitcode=>1,msg=>"no eventendfilename can be builded"});
   }
   my $pref=$param{'defaultFilenamePrefix'};
   $pref="Report" if ($pref eq "");
   if ($param{'filename'} eq "" || $param{'filename'}=~m/\/$/){
      my $names=$param{customer};
      $names=substr($names,0,40)."___" if (length($names)>40);
      my $tstr=$eventendfilename;
      $tstr=~s/</less_/gi;
      $tstr=~s/>/more_/gi;
      $tstr=~s/[^a-z0-9]/_/gi;
      $names=~s/[^a-z0-9]/_/gi;
      $names=~s/_$//;
      $names=~s/^_//;
      $tstr=~s/_$//;
      $tstr=~s/^_//;
      my $dir="./";
      if ($pref=~m/^webfs:.*/){
         $dir="";
      }
      if ($param{'filename'}=~m/\/$/){
         $dir=$param{'filename'};
      }
      if ($param{month} eq ""){
         $param{'filename'}=["${dir}${pref}${names}_${tstr}.xls",
                             "${dir}${pref}${names}_current.xls"];
      }
      else{
         $param{'filename'}=["${dir}${pref}${names}_${tstr}.xls"];
      }
   }
   if ($origeventend eq "" && $param{'defaultEventend'} ne ""){
      $eventend=$param{'defaultEventend'};
   }
   $param{'eventend'}=$eventend;
   return(%param);
}






1;

