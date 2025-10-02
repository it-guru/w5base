package kernel::Input::XlsV01;

use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;
use Fcntl 'SEEK_SET';
use File::Temp(qw(tempfile));

@ISA=qw(kernel::Universal);
   
sub new
{  
   my $type=shift;
   my $parent=shift;
   my $self=bless({@_},$type);

   $self->setParent($parent);

   return($self);
}


sub getIconName
{
   my $self=shift;
   return("icon_xls");
}


sub SetInput
{
   my $self=shift;
   my $file=shift;

   my $buffer;
   eval("use Spreadsheet::ParseExcel;".
        "use Spreadsheet::ParseExcel::Utility qw(ExcelFmt);");
   return(undef) if ($@ ne "");
   if (sysread($file,$buffer,8)){
      if (uc(unpack("H*",$buffer)) ne "D0CF11E0A1B11AE1"){
         return(undef);
      }
      sysseek($file,0,SEEK_SET);
      print msg(INFO,"MS-Office Document detected");
      my ($fh,$filename)=tempfile();
      my $size;
      my $blk=1024;
      my $max=2048000;
      if ($self->getParent->getParent->IsMemberOf("admin")){
         $max=$max*10;
      }
      my ($w,$r);
      while($r=sysread($file,$buffer,$blk)){
         my $w=syswrite($fh,$buffer,$r);
         if ($r!=$w){
            $size=0;
            last;
         }
         else{
            $size+=$w;
            last if ($size>$max);
         }
      }
      close($fh);
      if ($size>$max){
         print msg(ERROR,"file larger then the xls limit %d bytes",$max);
         unlink($filename) if ($filename ne "");
         return(undef);
      }
      if ($size==0){
         print msg(ERROR,"can't create tempfile");
         unlink($filename) if ($filename ne "");
         return(undef);
      }
      print msg(INFO,"Microsoft Office Document with a size of %d transfered",
                      $size);
      my $oBook=undef;
      $self->{'oBook'}=undef;
      $self->{'oWkS'}=undef;
      eval('$oBook=Spreadsheet::ParseExcel::Workbook->Parse($filename)');
      if ($@ ne "" || !defined($oBook)){
         print msg(ERROR,"can't parse Excel Spreadsheet");
         unlink($filename) if ($filename ne "");
         return(undef);
      }
      unlink($filename) if ($filename ne "");
      $self->{'oBook'}=$oBook;
      $self->{'oWkS'}=${$self->{'oBook'}->{'Worksheet'}}[0];
      if (!defined($self->{'oWkS'})){
         print msg(ERROR,"can't find the first Worksheet");
         return(undef);
      }
      my @fieldnames=();
      for(my $col=0;$col<=$self->{'oWkS'}->{MaxCol};$col++){
         last if (!defined($self->{'oWkS'}->{'Cells'}[0][$col]));
         last if ($self->{'oWkS'}->{'Cells'}[0][$col]->Value() eq "");
         push(@fieldnames,$self->{'oWkS'}->{'Cells'}[0][$col]->Value());
      }
      if ($self->{debug}){
         print msg(INFO,"original field names = %s",join(", ",@fieldnames));
      }
      my @trfieldnames=$self->getParent->getParent->
                        CachedTranslateUploadFieldnames(@fieldnames);
      if ($self->{debug}){
         print msg(INFO,"translated field names = %s",join(", ",@trfieldnames));
      }
      my $ok=1;
      for(my $col=0;$col<=$#fieldnames;$col++){
         if ($fieldnames[$col] eq "#UPLOAD_COMMENT_COLUMN#"){
            $trfieldnames[$col]=$fieldnames[$col];
         }
         if ($fieldnames[$col] ne "" && $trfieldnames[$col] eq ""){
            print msg(ERROR,"can't associate column name '%s'",
                      $fieldnames[$col]);
            $ok=0;
         }
      }
      return(undef) if (!$ok);
      $self->{Fields}=\@trfieldnames;


      return(1);
   }
   return(undef);
}
   

sub SetCallback
{
   my $self=shift;
   my $callback=shift;

   $self->{Callback}=$callback;
}

sub Process
{
   my $self=shift;
   if (!defined($self->{'oWkS'})){
      return(undef);
   }
   my $recno=0;
   for(my $row=1;$row<=$self->{'oWkS'}->{MaxRow}+1;$row++){
      my $isempty=1;
      my %rec=();
      for(my $col=0;$col<=$self->{'oWkS'}->{MaxCol};$col++){
         my $cell=$self->{'oWkS'}->{Cells}[$row][$col];
         my $v="";
         if (defined($cell)){
            $v=$cell->value();
            $v=$cell->{Val} if ($v eq "");
            if ($cell->{Type} eq "Date" && $v ne ""){
               $v=ExcelFmt("dd.mm.yyyy hh:mm:ss",$cell->{Val});
            }
            if (my ($d,$m,$y,$H,$M,$S)=$v=~
                m/^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})\s
                   ([0-9]{2}):([0-9]{2}):([0-9]{2})$/x){
               $v=$y."-".$m."-".$d." ".$H.":".$M.":".$S;
            }

            $isempty=0 if (!($v=~m/^\s*$/));
            if ($v=~m/^'.*[^']$/){  # this indicates a text field formater
               $v=~s/^'//;
            }
         }
         print msg(INFO,"cell (c=$col/r=$row)='%s'",$v) if ($self->{debug});
         if (!defined($self->{Fields}->[$col]) ||
              $self->{Fields}->[$col] eq ""){
            if ($v ne ""){
               print(msg(ERROR,
                         "data without header colum in col '%d'",$col));
            }
            else{
               print(msg(WARN,
                         "data without header colum in col '%d'",$col));
            }
         }
         else{
            $rec{$self->{Fields}->[$col]}=$v;
         }
      }
      next if ($isempty);
      $recno++;
      delete($rec{'#UPLOAD_COMMENT_COLUMN#'});
      print msg(INFO,"[start record %d starting at line %d ".
                     "with %d vars for '%s']",
                $recno,$row,
                scalar(keys(%rec)),
                $ENV{REMOTE_USER});
      $self->getParent->getParent->setTimePerEditStamp();
      &{$self->{Callback}}(\%rec,undef);
   }

   #eval("\$self->{Parser}->parse(\$self->{File});");
}



   


