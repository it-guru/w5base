package base::w5stat::wfrepjob;
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
use kernel::Universal;
use kernel::date;
use File::Temp;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}



sub processDataInit
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my $count;

   return() if ($statstream ne "default");

   msg(INFO,"processDataInit in $self");
   my $wfrepjob=getModuleObject(
                $self->getParent->Config,"base::workflowrepjob");
   $wfrepjob->SetFilter({cistatusid=>\'4'});
   $self->{RJ}=[];
   foreach my $repjob ($wfrepjob->getHashList(qw(ALL))){
      my %d=%{$repjob};
      #printf STDERR ("d=%s\n",Dumper(\%d));
      push(@{$self->{RJ}},\%d);
   }
   if (!defined($self->{SSTORE})){
      eval("use Spreadsheet::WriteExcel::Big;");
      if ($@ eq ""){
         $self->{SSTORE}={};
      }
   }
}


sub processData
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my $count;

   return() if ($statstream ne "default");

   #######################################################################
   if ($param{currentmonth} eq $dstrange){
      my $wf=getModuleObject($self->getParent->Config,"base::workflow");
      my $wfrec=$wf->Clone();
      $param{DataObj}=$wfrec;
      my $wfw=$wf->Clone();
      msg(INFO,"starting collect of base::workflow set0 ".
               "- all modified $dstrange");
      $wf->SetFilter({mdate=>">monthbase-1M-2d AND <now",
                      isdeleted=>\'0'});
   #   $wf->SetFilter({id=>"12312433930002"});
   #   $wf->Limit(15500);
      $wf->SetCurrentView(qw(ALL));
      $wf->SetCurrentOrder("NONE");
     
      msg(INFO,"getFirst of base::workflow set0");$count=0;
      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            $self->getParent->processRecord($statstream,'base::workflow::stat',
                                            $dstrange,$rec,%param);
            $count++;
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
      msg(INFO,"FINE of base::workflow set0 $count records");
   }
}

sub processRecord
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;
   my %param=@_;

   return() if ($statstream ne "default");

   if ($module eq "base::workflow::stat"){
      return(undef) if (!exists($self->{SSTORE}));
      msg(INFO,"workflow id=$rec->{id} month=$month");
#      msg(INFO,"         class=$rec->{class}");
      foreach my $repjob (@{$self->{RJ}}){
         if ($self->matchJob($repjob,$rec,\%param)){
            my $reftime=$rec->{eventend};
            #############################################################
            #
            # Period berechnen
            if ($reftime ne ""){
               my ($Y,$M,$D)=$self->getParent->ExpandTimeExpression(
                                   "$reftime-$repjob->{mday}d-1s",
                                   undef,"GMT",$repjob->{tz});
               my $period=sprintf("%04d%02d",$Y,$M);
               ($Y,$M,$D)=Add_Delta_YMD($repjob->{tz},$Y,$M,1,0,1,0);
               my $period1=sprintf("%04d%02d",$Y,$M);
              
               if ($period eq $param{currentmonth}||
                   $period1 eq $param{currentmonth}){
                  $self->storeWorkflow($repjob,$rec,$period,\%param);
               }
            }
         }
      }
   }
}

sub matchAttribute
{
   my $repjob=shift;
   my $WfRec=shift;
   my $param=shift;
   my $flt=shift;
   my $attr=shift;

   if ($repjob->{$flt} ne ""){
      if (!($repjob->{$flt}=~m#^/#)){
         return(0) if ($repjob->{$flt} ne $WfRec->{$attr});
      }
      else{
         my $orgflt=$repjob->{$flt};
         my $flt=$orgflt;
         $flt=~s/^\///;
         $flt=~s/\/[i]{0,1}$//;
         #$flt=quotemeta($flt);
         my $fldobj=$param->{DataObj}->getField($attr,$WfRec);
         return(0) if (!defined($fldobj));
         my $d=$fldobj->RawValue($WfRec);
         return(0) if (!defined($d) || $d eq "");
         if ($orgflt=~m/i$/){
            if (ref($d) eq "ARRAY"){
               return(0) if (!grep(/$flt/i,@$d));
            }
            else{
               return(0) if (!($d=~m/$flt/i));
            }
         }
         else{
            if (ref($d) eq "ARRAY"){
               return(0) if (!grep(/$flt/,@$d));
            }
            else{
               return(0) if (!($d=~m/$flt/));
            }
         }
      }
   }
   return(1);
}


sub matchJob
{
   my $self=shift;
   my $repjob=shift;
   my $WfRec=shift;
   my $param=shift;

   return(0) if (!matchAttribute($repjob,$WfRec,$param,'fltclass','class'));
   return(0) if (!matchAttribute($repjob,$WfRec,$param,'fltstep','step'));
   return(0) if (!matchAttribute($repjob,$WfRec,$param,'fltname','name'));
   return(0) if (!matchAttribute($repjob,$WfRec,$param,'fltdesc',
                                                       'detaildescription'));
   foreach my $fltnum (qw(flt1 flt2 flt3)){
      if ($repjob->{$fltnum.'name'} ne ""){
         if (!matchAttribute($repjob,$WfRec,$param,$fltnum.'value',
                                                   $repjob->{$fltnum.'name'})){
            return(0);
         }
      }
   }

   return(1);
}

sub storeWorkflow
{
   my $self=shift;
   my $repjob=shift;
   my $WfRec=shift;
   my $period=shift;
   my $param=shift;
   my $ss=$self->{SSTORE};
   return(undef) if (!defined($self->{SSTORE}));

   my $wbslot=$repjob->{targetfile};
   my $sheetn=$repjob->{name};

   my $slot;
   if (!exists($ss->{$period}->{$wbslot})){
      $ss->{$period}->{$wbslot}={}; 
      $slot=$ss->{$period}->{$wbslot}; 
      my $fh=new File::Temp();
      $slot->{fh}=$fh;
      $slot->{'workbook'}->{o}=Spreadsheet::WriteExcel::Big->new($fh->filename);
      $slot->{'workbook'}->{targetfile}=$repjob->{targetfile};
   }
   $slot=$ss->{$period}->{$wbslot};
#      printf STDERR ("fifi workbook=$slot->{'workbook'}\n");
   if (!exists($slot->{sheet}->{$sheetn." Detail"})){
      $slot->{sheet}->{$sheetn." Detail"}->{o}=
                      $slot->{'workbook'}->{o}->addworksheet($sheetn." Detail");
      $slot->{sheet}->{$sheetn." Detail"}->{line}=1;
   }
   my $sheet=$slot->{sheet}->{$sheetn." Detail"};

   my $fields=[split(/\s*[;,]\s*/,$repjob->{repfields})];

   for(my $col=0;$col<=$#{$fields};$col++){
      $ENV{HTTP_FORCE_LANGUAGE}="de";
      my $fieldname=$fields->[$col];
      my $fobj=$param->{DataObj}->getField($fieldname,$WfRec);
      if (defined($fobj)){
         my $data=$fobj->FormatedResult($WfRec,"XlsV01");
         my $format=$fobj->getXLSformatname($data);
       
         if (!exists($sheet->{col}->{$col})){
            my $xlswidth;
            if (defined($fobj->htmlwidth())){
               $xlswidth=$fobj->htmlwidth()*0.4;
            }
            if (defined($fobj->xlswidth())){
               $xlswidth=$fobj->xlswidth();
            }
            $xlswidth=15 if (defined($xlswidth) && $xlswidth<15);
       
            $sheet->{col}->{$col}={};
            $sheet->{col}->{$col}->{label}=$fobj->Label();
            $sheet->{col}->{$col}->{width}=$xlswidth;
         }
         if ($format=~m/^date\./){
            $sheet->{'o'}->write_date_time($sheet->{line},$col,$data,
                                                  $self->Format($slot,$format));
         }
         else{
            $data="'".$data if ($data=~m/^=/);
            $sheet->{'o'}->write($sheet->{line},$col,$data,
                                        $self->Format($slot,$format));
         }
      }
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
   foreach my $fentry (@{$repjob->{funccode}}){
      if (ref($fentry->{store}) eq "CODE"){
         &{$fentry->{store}}($self,$param->{DataObj},$fentry,$repjob,
                             $slot,$param,$period,$WfRec,$sheet);
      }
   }
   $sheet->{line}++;
   



   msg(INFO,"store $WfRec->{id}:'$WfRec->{name}'");

   return(1);
}


sub Format
{
   my $self=shift;
   my $slot=shift;
   my $name=shift;
   my $wb=$slot->{workbook};
   return($wb->{format}->{$name}) if (exists($wb->{format}->{$name}));

   my $format;
   if ($name eq "default"){
      $format=$wb->{o}->addformat(text_wrap=>1,align=>'top');
   }
   elsif ($name eq "date.de"){
      $format=$wb->{o}->addformat(align=>'top',
                                          num_format => 'dd.mm.yyyy HH:MM:SS');
   }
   elsif ($name eq "date.en"){
      $format=$wb->{o}->addformat(align=>'top',
                                          num_format => 'yyyy-mm-dd HH:MM:SS');
   }
   elsif ($name eq "longint"){
      $format=$wb->{o}->addformat(align=>'top',num_format => '#');
   }
   elsif ($name eq "header"){
      $format=$wb->{o}->addformat();
      $format->copy($self->Format($slot,"default"));
      $format->set_bold();
   }
   elsif (my ($precsision)=$name=~m/^number\.(\d+)$/){
      $format=$wb->{o}->addformat();
      $format->copy($self->Format($slot,"default"));
      my $xf="#";
      if ($precsision>0){
         $xf="0.";
         for(my $c=1;$c<=$precsision;$c++){$xf.="0";};
      }
      $format->set_num_format($xf);
   }
   if (defined($format)){
      $wb->{format}->{$name}=$format;
      return($wb->{format}->{$name});
   }
  # print STDERR msg(WARN,"XLS: setting format '$name' as 'default'");
   return($self->Format($slot,"default"));
}



sub processDataFinish
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my $count;

   return() if ($statstream ne "default");

   my $ss=$self->{SSTORE};
   return(undef) if (!defined($self->{SSTORE}));

   msg(INFO,"processDataFinish in $self");

   foreach my $period (keys(%{$ss})){
      foreach my $wbslot (keys(%{$ss->{$period}})){
         my $slot=$ss->{$period}->{$wbslot};
         foreach my $repjob (@{$self->{RJ}}){
            if ($repjob->{targetfile} eq $wbslot){
               foreach my $fentry (@{$repjob->{funccode}}){
                  if (ref($fentry->{finish}) eq "CODE"){
                     &{$fentry->{finish}}($self,$param{DataObj},$fentry,$repjob,
                                         $slot,\%param,$period);
                  }
               }
            }
         }
         foreach my $sheet (values(%{$slot->{sheet}})){
            foreach my $col (keys(%{$sheet->{col}})){
                $sheet->{'o'}->write(0,$col,$sheet->{col}->{$col}->{label},
                                     $self->Format($slot,"header"));
                $sheet->{'o'}->set_column($col,$col,
                                          $sheet->{col}->{$col}->{width});
            }
         }


         $slot->{workbook}->{o}->close();
         my $file=getModuleObject($self->getParent->Config,"base::filemgmt");
         my ($dir,$filename)=$slot->{'workbook'}->{targetfile}=~
            m/^(.*)\/([^\/]+)\.xls$/i;
         $dir=~s/^\///;
         if ($filename eq ""){
            msg(ERROR,"invalid target filename ".
                      "$slot->{'workbook'}->{targetfile}");
         }
         else{ 
            my @fl=("$filename.$period.xls");
            if ($period eq $dstrange){
               push(@fl,"$filename.current.xls");
            }
            foreach my $dstfile (@fl){
               #printf STDERR ("fifi filename=$dstfile dir=$dir\n");
               if (open(F,"<".$slot->{fh}->filename)){
                  if (!($file->ValidatedInsertOrUpdateRecord(
                               {name=>$dstfile, parent=>$dir,file=>\*F},
                               {name=>\$dstfile,parent=>\$dir}))){
                     msg(ERROR,"fail to store ".
                               "$slot->{'workbook'}->{targetfile}");
                  }
                  close(F);
               }
               else{
                  printf STDERR ("ERROR: can't open $self->{filename}\n");
               }
           
           
            }
         }
         unlink($slot->{fh}->filename);
      }
   }

   

   delete($self->{SSTORE});
}

1;
