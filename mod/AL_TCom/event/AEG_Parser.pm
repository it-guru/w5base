package AL_TCom::event::AEG_Parser;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub AEG_Parser
{
   my $self=shift;

   $self->{iaeg}=getModuleObject($self->Config,"inetwork::aeg");
   return({exitcode=>1,msg=>"ERROR in acsys"}) if (!defined($self->{iaeg}));

   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   return({exitcode=>1,msg=>"ERROR in appl"}) if (!defined($self->{appl}));

   $self->{user}=getModuleObject($self->Config,"base::user");
   return({exitcode=>1,msg=>"ERROR in base user"}) if (!defined($self->{user}));

   $self->{wiw}=getModuleObject($self->Config,"tswiw::user");
   return({exitcode=>1,msg=>"ERROR in tswiw::user"}) if (!defined($self->{wiw}));

   my $exitcode=$self->ProcessExcelExpand("/tmp/AEG.xls");

   return({exitcode=>$exitcode});
}

sub ProcessLineData
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $row=shift;
   my $data=shift;
  
   if ($row>0 && $row<1000){
      if ($data->[0] ne ""){
         my $custappl=$data->[0];
         my $iaeg=$self->{iaeg};
         $iaeg->SetFilter({name=>\$custappl});
         my ($irec,$msg)=$iaeg->getOnlyFirst(qw(w5baseid smemail));
         if (defined($irec) && $irec->{w5baseid}){
            $data->[1]=$irec->{w5baseid};
         }
      }
      if (!$data->[1]=~m/^\s*$/){
         my $id=join(" ",map({'"'.$_.'"'} split(/[\s;,]/,$data->[1])));
         $self->{appl}->ResetFilter();
         $self->{appl}->SetFilter({id=>$id,cistatusid=>'4'});
         my @dboss;
         foreach my $arec ($self->{appl}->getHashList("databoss")){
            push(@dboss,$arec->{databoss}) if ($arec->{databoss} ne "");
         }
         $data->[2]=join("; ",@dboss);
      }
      for(my $a=0;$a<6;$a++){
         my $sncol=3+$a*5;
         my $gncol=4+$a*5;
         my $phcol=5+$a*5;
         my $idcol=6+$a*5;
         next if ($data->[$sncol] eq "" || $data->[$gncol] eq "");
         printf("check\n -surname=%s\n -givenname=%s\n -phone=%s\n",
                $data->[$sncol],
                $data->[$gncol],
                $data->[$phcol]);
         # Step 1 - check W5Base/Darwin by surname and givenname
         if ($data->[$idcol]=~m/^\s*$/){
            $self->{user}->ResetFilter();
            $self->{user}->SetFilter({surname=>\$data->[$sncol],
                                      givenname=>$data->[$gncol]});
            my @l=$self->{user}->getHashList(qw(posix));
            if ($#l==0 && $l[0]->{posix} ne ""){
               $data->[$idcol]=$l[0]->{posix};
            }
         }
         # Step 2 - fuzzy phone check
         if ($data->[$idcol]=~m/^\s*$/){
            my $tel=$data->[$phcol];
            $tel=~s/[^0-9 +]/ /g;
            my @blks=split(/\s+/,$tel);
            my $maxblk=3;
            $maxblk=$#blks if ($#blks<$maxblk);
            if ($#blks!=-1){
               for(my $chkblk=0;$chkblk<=$maxblk;$chkblk++){
                  next if (!($data->[$idcol]=~m/^\s*$/));
                  my $von=$#blks-$chkblk;
                  my $bis=$#blks;
                  my @v;
                  push(@v,'*'.join("",@blks[$von..$bis]).'*');
                  push(@v,'*'.join("-",@blks[$von..$bis]).'*');
                  push(@v,'"*'.join(" ",@blks[$von..$bis]).'*"');
                  $self->{user}->ResetFilter();
                  $self->{user}->SetFilter({allphones=>join(" ",@v)});
                  my @l=$self->{user}->getHashList(qw(posix email));
                  if ($#==0){
                     if ($l[0]->{posix} ne ""){
                        $data->[$idcol]=$l[0]->{posix};
                     }
                     else{
                        $data->[$idcol]=$l[0]->{email};
                     }
                  }
                  next if (!($data->[$idcol]=~m/^\s*$/));
                  my @v;
                  push(@v,'*'.join("",@blks[$von..$bis]));
                  push(@v,'*'.join("-",@blks[$von..$bis]));
                  push(@v,'"*'.join(" ",@blks[$von..$bis]).'"');

                  $self->{wiw}->ResetFilter();
                  $self->{wiw}->SetFilter({office_mobile=>join(" ",@v)});
                  my @l=$self->{wiw}->getHashList(qw(email));
                  if ($#==0){
                     $data->[$idcol]=$l[0]->{email};
                  }
                  next if (!($data->[$idcol]=~m/^\s*$/));
                  $self->{wiw}->ResetFilter();
                  $self->{wiw}->SetFilter({office_phone=>join(" ",@v)});
                  my @l=$self->{wiw}->getHashList(qw(email));
                  if ($#==0){
                     $data->[$idcol]=$l[0]->{email};
                  }
               }
            }

            
            printf("blocks=%s\n",join("|",@blks));
            
         }
         # Last Step: Set result to ? if nothing could be unique identified
         if ($data->[$idcol]=~m/^\s*$/){
            $data->[$idcol]="???";
         }
  
      }
      return();
   }

}


##########################################################################
##########################################################################
##########################################################################
##########################################################################




sub ProcessExcelExpand
{
   my $self=shift;
   my $inpfile=shift;
   my $outfile=shift;

   if (!defined($outfile)){
      $outfile=$inpfile;
      $outfile=~s/\.xls$/_new.xls/i;
   }
   if (! -r $inpfile ){
      printf STDERR ("ERROR: can't open '$inpfile'\n");
      printf STDERR ("ERROR: errstr=$!\n");
      exit(1);
   }
   else{
      printf ("INFO:  opening $inpfile\n");
   }
   my $oExcel;
   eval('use Spreadsheet::ParseExcel::SaveParser;'.
        'use Spreadsheet::ParseExcel::Workbook;'.
        '$oExcel=new Spreadsheet::ParseExcel::SaveParser;');
   if ($@ ne "" || !defined($oExcel)){
      msg(ERROR,"%s",$@);
      return(2);
   }
   my  $oBook=$oExcel->Parse($inpfile);
   if (!$oBook ){
      printf STDERR ("ERROR: can't parse '$inpfile'\n");
      exit(1);
   }
   for(my $iSheet=0; $iSheet < $oBook->{SheetCount} ; $iSheet++) {
      my $oWkS = $oBook->{Worksheet}[$iSheet];
      for(my $row=0;$row<=$oWkS->{MaxRow};$row++){
         if ($oWkS->{'Cells'}[$row][0]){
            my $keyval=$oWkS->{'Cells'}[$row][0]->Value();
            next if ($keyval eq "");
            printf("INFO:  Prozess: '%s'\n",$keyval);
            $self->ProcessExcelExpandLevel1($oExcel,$oBook,$oWkS,$iSheet,$row);
         }
      }
   }
   printf("INFO:  saving '%s'\n","$outfile");
   $oExcel->SaveAs($oBook,$outfile);
}


sub ProcessExcelExpandLevel1
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $row=shift;
   my @data=();
   my @orgdata=();

   for(my $col=0;$col<=$oWkS->{MaxCol};$col++){
      next if (!($oWkS->{'Cells'}[$row][$col]));
      next if ($oWkS->{'Cells'}[$row][$col]->Value() eq "");
      $data[$col]=$oWkS->{'Cells'}[$row][$col]->Value();
   }
   @orgdata=@data;
   $self->ProcessLineData($oExcel,$oBook,$oWkS,$iSheet,$row,\@data);
   for(my $col=0;$col<=$#data;$col++){
      if ($data[$col] ne $orgdata[$col]){
         $oBook->AddCell($iSheet,$row,$col,$data[$col],0);
      }
   }
}





1;
