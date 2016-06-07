package tshpsa::event::RefreshHPSA;
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

## Der Code sollte entsorgt werden, wenn die Schulte-Bunnert HPSA
## Lösung beendet wird.




use strict;
use vars qw(@ISA);
use kernel;
use kernel::Event;
use File::Temp;
use File::Path qw(remove_tree);
@ISA=qw(kernel::Event);




sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   eval('   use Text::CSV_XS;');

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("RefreshHPSA",
                        "RefreshHPSA",timeout=>21600); # =6h
   return(1);
}



sub RefreshHPSA
{
   my $self=shift;
   my $reqType=shift;
   my @filter=@_;
   my $loaderror;
   my @loadfiles;
   my @procfiles;
   my @skipfiles;
   my @failfiles;

   my $sftpsource=$self->Config->Param("DATAOBJCONNECT");
   $sftpsource=$sftpsource->{'RefreshHPSA'} if (ref($sftpsource) eq "HASH");

   if ($sftpsource eq ""){
      my $msg="Event RefreshHPSA not processable without SFTP Connect\n".
              "Parameter in DATAOBJCONNECT[RefreshHPSA] Config";
      msg(ERROR,$msg);
      return({exitcode=>1,msg=>$msg});

   }

   #######################################################################
   # transfer files from SFTP Server
   my $tempdir=File::Temp::tempdir(CLEANUP=>1);
   $SIG{INT} = sub { eval('remove_tree($tempdir);exit(1);') if (-d $tempdir);};
   msg(DEBUG,"Starting Refresh on $tempdir");
   my $res=`echo 'lcd \"$tempdir\"\nget *.csv' | 
            sftp -b - \"$sftpsource\" 2>&1 >/dev/null `;
   if ($?!=0){
      $loaderror=$res;
   }
   #######################################################################
   # after this, all fields in $tempdir

   if (!defined($loaderror)){
      my $dh;
      if (opendir($dh,$tempdir)){
         @loadfiles=grep({ -f "$tempdir/$_" &&
                           !($_=~m/^\./) } readdir($dh));
         if ($#loadfiles==-1){
            $loaderror="error - no files transfered from '$sftpsource'";
         }
      }
      else{
         $loaderror="fail to open dir '$tempdir': $?";
      }
   }
   #print STDERR Dumper(\@loadfiles);

   #######################################################################
   # after this, all useable files are in @loadfiles
   my $reccnt=0;
   my $filecnt=0;
   foreach my $file (reverse(sort(@loadfiles))){
      my $label=$file;
      next if (!($file=~m/\.csv$/i));
      msg(INFO,"found file=$file");
      if ($filecnt==0){
         if (my $st=$self->processFile(
                File::Spec->catfile($tempdir,$file),\$reccnt)){
            if ($st==1){
               push(@procfiles,$file);
            }
            if ($st==2){
               push(@failfiles,$file);
            }
            $filecnt++;
         }
      }
      else{
         push(@skipfiles,$file);
      }
   }

   # cleanup FTP Server
   foreach my $file (@procfiles){
      msg(DEBUG,"cleanup '$file'");
      my $res=`echo 'rename \"$file\" \"$file.processed\"' |\
               sftp -b - \"$sftpsource\" 2>&1`;
      if ($?!=0){
         $loaderror.=$res;
      }
   }
   foreach my $file (@skipfiles){
      msg(WARN,"skiped file '$file' due multiple input files");
      my $res=`echo 'rename \"$file\" \"$file.skiped\"' |\
               sftp -b - \"$sftpsource\" 2>&1`;
      if ($?!=0){
         $loaderror.=$res;
      }
   }
   foreach my $file (@failfiles){
      msg(WARN,"fail to process file '$file' due structure problems");
      my $res=`echo 'rename \"$file\" \"$file.fail\"' |\
               sftp -b - \"$sftpsource\" 2>&1`;
      if ($?!=0){
         $loaderror.=$res;
      }
   }
   if ($filecnt==0){
      msg(WARN,"no valid import file found/received");
   }
   if ($filecnt>1){
      msg(WARN,"multiple files received");
   }

   if (defined($loaderror)){
      return({exitcode=>1,msg=>'ERROR:'.$loaderror});
   }

   return({
      exitcode=>0,
      msg=>'ok '.($#procfiles+1)." files processed $reccnt records"
   });
}




sub processFile
{
   my $self=shift;
   my $file=shift;
   my $reccnt=shift;

   msg(DEBUG,"process '$file'");
   my $db=$self->getNativOracleDBIConnectionHandle("w5warehouse");
   msg(DEBUG,"Oracle Database handle '$db'");
   my @structHead=();
   my @structContent=qw(class version path uname scandate);

   my $structError=0;
   my $recno=0;
   ####################################################################
   sub recordUnpack
   {
      my $recbuf=shift;
      my $recno=shift;
      my %rec;

      print STDERR Dumper($recbuf);
      if ($#{$recbuf}<1){
         return(undef);
      }
      $$recno++;
      if ($$recno==1){    # 1= Header
         my @l1=split(/;/,$recbuf->[0]);
         shift(@l1); # @@@Next@@@ entfernen
         @structHead=map({$_=~s/^<(.*)>$/$1/;$_} @l1);
      }
      else{
         my @l1=split(/;/,$recbuf->[0]);
         shift(@l1); # @@@Next@@@ entfernen
         for(my $c=0;$c<=$#structHead;$c++){
            $rec{$structHead[$c]}=$l1[$c];
         }
         my @content;
         for(my $row=1;$row<=$#{$recbuf};$row++){
            if ($recbuf->[$row] ne "NV"){
               my @c=split(/;/,$recbuf->[$row]);
               my %crec;
               for(my $c=0;$c<=$#structContent;$c++){
                  $crec{$structContent[$c]}=$c[$c]; 
               }
               push(@content,\%crec);
            }
         }
         $rec{content}=\@content;
      }
      print STDERR "recno=$recno\n";
      print STDERR Dumper(\%rec);
      return(\%rec);
   }

   sub recordValidate
   {
      my $rec=shift;
      my $recno=shift;
      if ($$recno>=2){  # recno==1 = Header
         if ($rec->{'SystemID'} eq "" || 
             $rec->{'Server Identifier'} eq ""){
            return(0);
         }
      }
      $rec->{'Hostname'}=lc($rec->{'Hostname'});
      foreach my $crec (@{$rec->{content}}){
         $crec->{objectid}=$rec->{'Server Identifier'};
      }
      return(1);
   }
   sub recordProcess
   {
      my $rec=shift;
      my $recno=shift;

      {# handle HPSA_system_import
         my @fldmap=(
            'objectid'=>'Server Identifier',
            'systemid'=>'SystemID',
            'hostname'=>'Hostname',
            'agentip'=>'PrimaryIP',
            'managementip'=>'ManagamentIP',
         );
         my %fldmap=@fldmap;
         my @fld=keys(%fldmap);

         my $rv=$db->do("update HPSA_system_import ".
                        "set ".join(",",map({"$_=?"} @fld)).
                        ",dmodifydate=current_date,deleted=0 ".
                        "where ".$fldmap[0]."=?",{},
                        map({$rec->{$fldmap{$_}}} @fld),
                        $rec->{$fldmap[1]});
         if ($rv eq "0E0"){  # nothing effected
            $rv=$db->do("insert into HPSA_system_import ".
                        "(".join(",",@fld).",dmodifydate) ".
                        "values(".join(",",map({"?"} @fld)).",current_date) ",
                        {},
                        map({$rec->{$fldmap{$_}}} @fld));
         }
         if ($rv ne "1"){
            msg(ERROR,"fatal error while handling HPSA_system_import");
            return(0);
         }
      }
      {# handle W5I_HPSA_lnkswp_import
         my @fldmap=(
            'objectid'=>'objectid',
            'class'=>'class',
            'version'=>'version',
            'path'=>'path',
            'uname'=>'uname',
            'scandate'=>'scandate',
         );
         my %fldmap=@fldmap;
         my @fld=keys(%fldmap);

         foreach my $crec (@{$rec->{content}}){
            my $rv=$db->do("insert into HPSA_lnkswp_import ".
                           "(".join(",",@fld).",dmodifydate) ".
                           "values(".join(",",map({"?"} @fld)).
                           ",current_date) ",
                           {},
                           map({$crec->{$fldmap{$_}}} @fld));
            if ($rv ne "1"){
               msg(ERROR,"fatal error while handling W5I_HPSA_lnkswp_import");
               return(0);
            }
         }
      }
      return(1);
   }
   sub parseFile
   {
      my $filename=shift;
      my $mode=shift;

      if (open(my $fh,"<:encoding(Latin1)",$file)){   # structure check
         my $n=0;
         my $lastline;
         my @recbuf;
         while(my $l=<$fh>){
            $n++;
            $l=~s/\s*$//;
            if ($n==1){
               if (!($l=~m/^Export started at .*$/)){
                  msg(ERROR,"Structure error in file $file - ".
                            "start not correct");
                  return(2);
               }
               else{
                  next;
               }
            }
            $lastline=$l;
            if ($n>2 && $l=~m/^\@\@\@Next\@\@\@;/){
               my $rec=recordUnpack(\@recbuf,\$recno);
               if (!defined($rec)){
                  msg(ERROR,"struture error in line $n");
                  return(2);
               }
               if (!recordValidate($rec,\$recno)){
                  msg(ERROR,"fatal value error in line $n");
                  return(2);
               }
               if ($mode eq "final" && $recno>1){  # dont insert header
                  if (!recordProcess($rec,\$recno)){
                     msg(ERROR,"fatal process error in line $n");
                     return(2);
                  }
               }
               @recbuf=();
            }
            push(@recbuf,$l);
            #printf("l%04d '%s'\n",$n,$l);
         }
         if (!($lastline=~m/^Export finished at .*$/)){
            msg(ERROR,"Structure error in file $file - end not correct");
            return(2);
         }
         else{
            pop(@recbuf);
            my $rec=recordUnpack(\@recbuf,\$recno);
            if (!defined($rec)){
               msg(ERROR,"struture error in line $n");
               return(2);
            }
            if (!recordValidate($rec,\$recno)){
               msg(ERROR,"fatal value error in line $n");
               return(2);
            }
            if ($mode eq "final"){
               if (!recordProcess($rec,\$recno)){
                  msg(ERROR,"fatal process error in line $n");
                  return(2);
               }
            }
         }
         close($fh);
      }
      return(1);
   }

   my $bk=parseFile($file,"preview");
   return($bk) if ($bk!=1);

   $recno=0;
   if ($db->begin_work()){
      $db->do("update HPSA_system_import set deleted=1");
      $db->do("update HPSA_lnkswp_import set deleted=1");
      my $bk=parseFile($file,"final");
      $db->do("delete from HPSA_system_import ".
              "where deleted=1");
      $db->do("delete HPSA_lnkswp_import ".
              "where deleted=1");
      if ($db->commit()){
         $$reccnt=$recno;
         return($bk);
      }
      else{
         die('commit for $file failed');
      }
   }
   else{
      die('begin_work for $file failed');
   }
   return(0); 
}

#
# Connect to replication target oracle DB via DBI
#
sub getNativOracleDBIConnectionHandle
{
   my $self=shift;
   my $dbname=shift;

   my $dbconnect=$self->Config->Param("DATAOBJCONNECT");
   my $dbuser=$self->Config->Param("DATAOBJUSER");
   my $dbpass=$self->Config->Param("DATAOBJPASS");

   if (ref($dbconnect) ne "HASH" ||
       ref($dbuser) ne "HASH" ||
       ref($dbpass) ne "HASH"){
      msg(ERROR,"fatal error - not enough connection informations");
      exit(255);
   } 
   $dbconnect=$dbconnect->{$dbname};
   $dbuser=$dbuser->{$dbname};
   $dbpass=$dbpass->{$dbname};
   
   msg(INFO,"try ora connect='$dbconnect' user='$dbuser'");

   if ($dbconnect eq "" || $dbuser eq "" || $dbpass eq ""){
      msg(ERROR,"fatal error - not enough connection informations");
      exit(255);
   }
   my $dst=DBI->connect($dbconnect,$dbuser,$dbpass,{
    #  AutoCommit=>0,
      FetchHashKeyName=>'NAME_lc',
   });
   if (!defined($dst)){
      msg(ERROR,$DBI::errstr);
      sleep(20);
      exit(100);
   }
   $dst->{'LongTruncOk'} = 1;
   $dst->{'LongReadLen'} = 128000;
   $dst->do("alter session set NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'");
   $dst->do("alter session set NLS_NUMERIC_CHARACTERS='. '");
   $dst->do("alter session set TIME_ZONE='GMT'");
   # set session TIME_ZONE to GMT to ensure to get a GMT timestamp
   # while using CURRENT_DATE. Note: There is not way to ensure to get
   # a GMT timestamp in SYSDATE on session level (SYSDATE timezone can
   # only be set from system root! (not the DBA!))
   msg(INFO,"connect to replication target '$dbconnect' successfull");
   return($dst);
}



1;
