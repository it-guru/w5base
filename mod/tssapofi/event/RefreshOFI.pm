package tssapofi::event::RefreshOFI;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use UUID::Tiny ':std';
use File::Path qw(remove_tree);
@ISA=qw(kernel::Event);

my %SapHierMap;
my %errmap;


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

   $self->RegisterEvent("RefreshOFI","RefreshOFI",timeout=>21600); # =6h
   return(1);
}



sub RefreshOFI
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
   $sftpsource=$sftpsource->{'RefreshOFI'} if (ref($sftpsource) eq "HASH");

   if ($sftpsource eq ""){
      my $msg="Event RefreshOFI not processable without SFTP Connect\n".
              "Parameter in DATAOBJCONNECT[RefreshOFI] Config";
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
      if ($file=~m/^DE_YT5A_DTIT/i){
         $self->loadKostFile(File::Spec->catfile($tempdir,$file),$file);
      }
      elsif ($file=~m/^DE_KOST_\d+_Import/i){
         # kann ignoriert werden
      }
      elsif ($file=~m/^DE_WBS_\d+_Import/i){
         $self->loadWbsFile(File::Spec->catfile($tempdir,$file),$file);
      }
   }
   if (open(my $err,">OFI_Import_error.log")){
      print $err join("",sort(values(%errmap)));
      close($err);
   }
   if (defined($loaderror)){
      return({exitcode=>1,msg=>'ERROR:'.$loaderror});
   }

   return({
      exitcode=>0,
      msg=>'ok '.($#procfiles+1)." files processed $reccnt records"
   });
}



sub parseCsvLine
{
   my $fh=shift;
   my $line=shift;
   my @l;

   $line=~s/\s*$//;
   $line=~s/\xff/ /;

   my @raw=split(/;/,$line);
   @l=@raw;

   return(\@l);
}

sub loadWbsFile
{
   my $self=shift;
   my $file=shift;
   my $shortname=shift;

   my $tabname="OFI_wbs_import";
   msg(DEBUG,"process WbsFile '$shortname'");
   my $db=$self->getNativOracleDBIConnectionHandle("w5warehouse");
   msg(DEBUG,"Oracle Database handle '$db'");
   my $n=0;
   if (open(my $fh,"<:encoding(Latin1)",$file)){   # structure check
      $db->begin_work();
      $db->do("update OFI_wbs_import set deleted=1");
      my %colmap;
      while(my $l=<$fh>){
          $n++;
          #next if ($n>100);
          my $rec=parseCsvLine($fh,$l);
          if ($n==1){
             for(my $col=0;$col<$#{$rec};$col++){
                $colmap{$rec->[$col]}=$col;
             }
          }
          else{
             my %r;
             foreach my $k (sort(keys(%colmap))){
                $r{$k}=$rec->[$colmap{$k}];
             }

             my %frec;
             #print Dumper(\%r);
             my $hierlink=trim($r{'hierarchy SL/AL'});
             my @fullname=grep(/$hierlink$/,keys(%SapHierMap));


             if ($hierlink eq ""){
                #$errmap{"empty".$r{'WBS-Number'}}=
                #   msg(ERROR,"emtpy 'hierarchy SL/AL' for WBS-Number '".
                #             $r{'WBS-Number'}."' at line $n");
             } 
             elsif ($hierlink eq "0"){
                #$errmap{"empty".$r{'WBS-Number'}}=
                #   msg(ERROR,"zero 'hierarchy SL/AL' for WBS-Number '".
                #             $r{'WBS-Number'}."' at line $n");
             } 
             elsif ($#fullname==-1){
                #$errmap{"inval".$r{'WBS-Number'}}=
                #   msg(ERROR,"not usable 'hierarchy SL/AL'='$hierlink' ".
                #             "in WBS-Number '".
                #             "$r{'WBS-Number'}' not found at line $n");
             } 
             elsif ($#fullname>0){
                $errmap{"notuniq".$r{'WBS-Number'}}=
                   msg(ERROR,"not usable 'hierarchy SL/AL'='$hierlink' ".
                             "in WBS-Number '".
                             "$r{'WBS-Number'}' not unique at line $n");
             } 
             else{
                my $saphier=$fullname[0];
                my $saphierobjectid=$SapHierMap{$saphier};
                my $oid=uuid_to_string(create_uuid(UUID_V5,$r{'WBS-Number'}));


                if ($r{'delete'} ne "1"){
                   my %rec=(
                      objectid=>$oid,
                      name=>$r{'WBS-Number'},
                      saphierid=>$saphierobjectid,
                      description=>$r{'description'},
                      supervisor_ciamid=>$r{'supervisor'},
                      servicemgr_ciamid=>$r{'service manager'},
                      delivermgr_ciamid=>$r{'delivery manager'},
                      company_code=>$r{'company code'},
                      customer_link=>$r{'customer link'}
                   );
                   foreach my $k (keys(%rec)){
                      $rec{$k}=undef if ($rec{$k} eq "");
                   }
                   {# handle import
                      my @fld=keys(%rec);
print STDERR Dumper(\%rec);

                      my $lev0upd="update $tabname ".
                                  "set dsrcload=current_date,deleted=0 ".
                                  "where ".join(" and ",map({"$_=?"} @fld)); 
                      printf STDERR ("lev0upd=%s\n",$lev0upd);
                      printf STDERR ("param=%s\n",join(", ",map({$rec{$_}} @fld)));
                      my $rv=$db->do($lev0upd,{},map({$rec{$_}} @fld));
                      printf STDERR ("rv=$rv\n\n");
                      if ($rv eq "0E0"){  # nothing effected
                         $rv=$db->do("update $tabname ".
                                     "set ".join(",",map({"$_=?"} @fld)).
                                     ",dmodifydate=current_date".
                                     ",dsrcload=current_date,deleted=0 ".
                                     "where objectid=?",{},
                                     map({$rec{$_}} @fld),
                                     $rec{objectid});
                         if ($rv eq "0E0"){  # nothing effected
                            $rv=$db->do("insert into $tabname ".
                                        "(".join(",",@fld).",".
                                        "dsrcload,dcreatedate,dmodifydate) ".
                                        "values(".join(",",map({"?"} @fld)).
                                        ",current_date,current_date,".
                                        "current_date) ",{},
                                        map({$rec{$_}} @fld));
                         }
                      }
                      if ($rv ne "1"){
                         msg(ERROR,"fatal error while handling import");
                         return(0);
                      }
                   }
                }
             }
          }
      }
      $db->commit();
      close($fh);
   }
   return(0);
}




sub loadKostFile
{
   my $self=shift;
   my $file=shift;
   my $shortname=shift;

   msg(DEBUG,"process KostFile '$shortname'");
   my $db=$self->getNativOracleDBIConnectionHandle("w5warehouse");
   msg(DEBUG,"Oracle Database handle '$db'");
   my $n=0;
   if (open(my $fh,"<:encoding(Latin1)",$file)){   # structure check
      $db->begin_work();
      $db->do("update OFI_kost_import set deleted=1");
      $db->do("update OFI_saphier_import set deleted=1");
      my %colmap;
      my %DirectSapHierMap;
      while(my $l=<$fh>){
          $n++;
          my $rec=parseCsvLine($fh,$l);
          if ($n==1){
             for(my $col=0;$col<=$#{$rec};$col++){
                $colmap{$rec->[$col]}=$col;
             }
          }
          else{
             my %r;
             foreach my $k (sort(keys(%colmap))){
                $r{$k}=$rec->[$colmap{$k}];
             }
             my @hier;
             for(my $c=1;$c<=15;$c++){
                my $key=sprintf("Set Stufe %d",$c);
                my $v=$r{$key};
                $v="" if ($v eq "#");
                push(@hier,$v);
             }
             for(my $c=$#hier;$c>1;$c--){
                if ($hier[$c] eq ""){
                   pop(@hier);
                }
                else{
                   last;
                }
             }
             $r{saphierlist}=\@hier;
             $r{saphier}=join(".",@hier);
             $r{saphierid}=uuid_to_string(create_uuid(UUID_V5,$r{saphier}));
             if (length($r{saphier})>2){ 
                $DirectSapHierMap{$r{saphier}}=\%r;
                my $tabname="OFI_kost_import";
                if ($r{Kostenstelle} ne ""){
                   my $id=uuid_to_string(create_uuid(UUID_V5,$r{Kostenstelle}));
                   my %rec=(
                      objectid=>$id,
                      name=>$r{Kostenstelle},
                      saphierid=>$r{saphierid},
                      description=>$r{'KOST Bezeichnung'},
                      company_code=>'8111'
                   );
                   {# handle import
                      my @fld=keys(%rec);
                      my $lev0upd="update $tabname ".
                                  "set dsrcload=current_date,deleted=0 ".
                                  "where ".join(" and ",map({"$_=?"} @fld));
                      my $rv=$db->do($lev0upd,{},map({$rec{$_}} @fld));
                      if ($rv eq "0E0"){  # nothing effected
                            $rv=$db->do("update $tabname ".
                                        "set ".join(",",map({"$_=?"} @fld)).
                                        ",dmodifydate=current_date,".
                                        "dsrcload=current_date,deleted=0 ".
                                        "where objectid=?",{},
                                        map({$rec{$_}} @fld),
                                        $rec{objectid});
                         if ($rv eq "0E0"){  # nothing effected
                            $rv=$db->do("insert into $tabname ".
                                        "(".join(",",@fld).",".
                                        "dsrcload,dcreatedate,dmodifydate) ".
                                        "values(".join(",",map({"?"} @fld)).
                                        ",current_date,current_date,".
                                        "current_date) ",{},
                                        map({$rec{$_}} @fld));
                         }
                      }
                      if ($rv ne "1"){
                         msg(ERROR,"fatal error while handling import");
                         return(0);
                      }
                   }
                }
             }
          }
      }
      { # now create virual nodes in hierarchie, for elements which are
        # not in costcenter list
         foreach my $r (values(%DirectSapHierMap)){
            my @hier=@{$r->{saphierlist}};
            do{
               my $checksaphier=join(".",@hier);
               next if ($checksaphier eq "");
               if (!exists($DirectSapHierMap{$checksaphier})){
                  my %r=(
                     saphierid=>uuid_to_string(create_uuid(UUID_V5,
                                                           $checksaphier)),
                     'Set Stufe LH'=>$hier[$#hier],
                     fullname=>$checksaphier,
                     saphier=>$checksaphier
                  );
                  #print STDERR "add=".Dumper(\%r);
                  $DirectSapHierMap{$checksaphier}=\%r;
               }
            }while(pop(@hier));
         }
      }
     

      foreach my $r (values(%DirectSapHierMap)){
         my %r=%{$r};
         my $tabname="OFI_saphier_import";
         my $lastname=$r{'Set Stufe LH'};
         if (!exists($SapHierMap{$lastname})){
            if ($r{saphier} ne ""){
               my %rec=(
                  objectid=>$r{saphierid},
                  name=>$lastname,
                  fullname=>$r{saphier}
               );
               $SapHierMap{$lastname}=$r{saphierid};
               {# handle import
                  my @fld=keys(%rec);
                  my $lev0upd="update $tabname ".
                              "set dsrcload=current_date,deleted=0 ".
                              "where ".join(" and ",map({"$_=?"} @fld)); 
                  my $rv=$db->do($lev0upd,{},map({$rec{$_}} @fld));
                  if ($rv eq "0E0"){  # nothing effected
                     $rv=$db->do("update $tabname ".
                                 "set ".join(",",map({"$_=?"} @fld)).
                                 ",dmodifydate=current_date,".
                                 "dsrcload=current_date,deleted=0 ".
                                 "where objectid=?",{},
                                 map({$rec{$_}} @fld),
                                 $rec{objectid});
                     if ($rv eq "0E0"){  # nothing effected
                        $rv=$db->do("insert into $tabname ".
                                    "(".join(",",@fld).",".
                                    "dsrcload,dcreatedate,dmodifydate) ".
                                    "values(".join(",",map({"?"} @fld)).
                                    ",current_date,current_date,current_date) ",
                                    {},map({$rec{$_}} @fld));
                     }
                  }
                  if ($rv ne "1"){
                     msg(ERROR,"fatal error while handling import");
                     return(0);
                  }
               }
            }
         }
      }

      $db->commit();
      close($fh);
   }
   #print Dumper(\%SapHierMap);
   return(0);
}




#sub loadHierFile
#{
#   my $self=shift;
#   my $file=shift;
#   my $shortname=shift;
#
#   my $tabname="OFI_saphier_import";
#   msg(DEBUG,"process HierFile '$shortname'");
#   my $db=$self->getNativOracleDBIConnectionHandle("w5warehouse");
#   msg(DEBUG,"Oracle Database handle '$db'");
#   my $n=0;
#   if (open(my $fh,"<:encoding(Latin1)",$file)){   # structure check
#      my @tree;
#      $db->begin_work();
#      $db->do("update $tabname set deleted=1");
#      while(my $l=<$fh>){
#          $n++;
#          my $label;
#          my $lastname;
#          my $rec=parseCsvLine($fh,$l);
#          if ($n==1 && $rec->[0] eq ""){
#             msg(ERROR,"structure error first level missing in $shortname");
#             return(0);
#          }
#          my $level=0;
#          for(my $col=0;$col<=$#{$rec} || $col<=$#tree ;$col++){
#             $level++ if ($level==0 && $rec->[$col] ne "" );
#             $level++ if ($level==1 && $rec->[$col] eq "" );
#             $level++ if ($level==2 && $rec->[$col] ne "" );
#             $level++ if ($level==3 && $rec->[$col] eq "" );
#             $tree[$col]=$rec->[$col] if ($level==1);
#             $tree[$col]=""           if ($level>=2);
#             $label=$rec->[$col]      if ($level==3);
#          }
#          for(my $col=$#tree;$col>=0;$col--){
#             if ($tree[$col] eq ""){
#                pop(@tree);
#             }
#             else{
#                $lastname=$tree[$col];
#                last;
#             }
#          }
#          @tree=grep(!/^\s*$/,@tree);    # compress path
#          my $id=uuid_to_string(create_uuid(UUID_V5, join(".",@tree)));
#          if ($label ne ""){
#             my %rec=(
#                objectid=>$id,
#                name=>$lastname,
#                fullname=>join(".",@tree),
#                description=>$label
#             );
#             $SapHierMap{$lastname}=$id;
#             {# handle import
#                my @fld=keys(%rec);
#                my $rv=$db->do("update $tabname ".
#                               "set ".join(",",map({"$_=?"} @fld)).
#                               ",dsrcload=current_date,deleted=0 ".
#                               "where objectid=?",{},
#                               map({$rec{$_}} @fld),
#                               $rec{objectid});
#                if ($rv eq "0E0"){  # nothing effected
#                   $rv=$db->do("insert into $tabname ".
#                               "(".join(",",@fld).",dsrcload,dcreatedate) ".
#                               "values(".join(",",map({"?"} @fld)).
#                               ",current_date,current_date) ",{},
#                               map({$rec{$_}} @fld));
#                }
#                if ($rv ne "1"){
#                   msg(ERROR,"fatal error while handling HPSA_system_import");
#                   return(0);
#                }
#             }
#          }
#      }
#      $db->commit();
#      close($fh);
#   }
#   return(0);
#}









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
