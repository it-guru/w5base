package tssapp01::event::RefreshSAP;
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
use kernel::Event;
use File::Temp;
use File::Path qw(remove_tree);
@ISA=qw(kernel::Event);

# mapping

#WBS-Number-TOP          = not mapped
#WBS-Number              = name         = Name                   = varchar(30) P
#description             = description  = Description            = textarea
#company code            = not mapped
#legal unit              = not mapped
#lock group              = not mapped     
#delete                  = isdeleted    = is marked as delete    = int(1)
#status                  = status       = Status                 = varchar(10)
#supervisor              = not mapped     
#supervisor_wiw          = databosswiw  = Databoss WIW ID        = varchar(8)
#start                   = not mapped
#end                     = not mapped
#customer ID             = not mapped     
#customer                = sapcustomer  = SAP Customer name      = varchar(40)
#application ID          = not mapped
#application             = not mapped
#service manager         = smwiw        = ServiceManager WIW ID  = varchar(8)
#delivery manager        = delmwiw      = DeliveryManager WIW ID = varchar(8)
#hierarchy TSI ID        = saphier1     = SAP Hier 1             = varchar(10)
#hierarchy TSI           = not mapped
#hierarchy ESS/BSS ID    = saphier2     = SAP Hier 2             = varchar(10)
#hierarchy ESS/BSS       = not mapped
#hierarchy ITO/SSM ID    = saphier3     = SAP Hier 3             = varchar(10)
#hierarchy ITO/SSM       = not mapped
#hierarchy BB-1          = saphier4     = SAP Hier 4             = varchar(10)
#hierarchy BB-1          = not mapped
#business center ID      = saphier5     = SAP Hier 5             = varchar(10)
#business center         = not mapped
#customer center ID      = saphier6     = SAP Hier 6             = varchar(10)
#customer center         = not mapped
#customer team ID        = saphier7     = SAP Hier 7             = varchar(10)
#customer team           = not mapped
#customer office ID      = saphier8     = SAP Hier 8             = varchar(10)
#customer office         = not mapped
#hierarchy 9 ID          = saphier9     = SAP Hier 9             = varchar(10)
#hierarchy 9             = not mapped
#hierarchy 10 ID         = saphier10    = SAP Hier 10            = varchar(10)
#hierarchy 10            = not mapped
#hierarchy SL/AL         = not mapped
#parent Co-Number        = pconumber    = Parent CO-Numer        = varchar(20)
#customer link           = not mapped
#description industry    = not mapped
#strategic partner name  = not mapped
#NOR-solution model      = normodel     = NOR Solution Model     = varchar(5)
#NOR-n                   = norn         = NOR Exclude            = varchar(30)
#Business_Prozess_Info   = bpmark       = Bussiness Process      = varchar(20)
#ICTO-Nummer             = ictono       = ICTO-ID                = varchar(20)



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


   $self->RegisterEvent("RefreshSAP",
                        "RefreshSAP",timeout=>27000); # =7h
   return(1);
}



sub RefreshSAP
{
   my $self=shift;
   my $reqType=shift;
   my @filter=@_;
   my $loaderror;
   my @loadfiles;
   my @procfiles;

   my $sftpsource=$self->Config->Param("DATAOBJCONNECT");
   $sftpsource=$sftpsource->{'RefreshSAPP01'} if (ref($sftpsource) eq "HASH");

   if ($sftpsource eq ""){
      my $msg="Event RefreshSAPP01 not processable without SFTP Connect\n".
              "Parameter in DATAOBJCONNECT[RefreshSAPP01] Config";
      msg(ERROR,$msg);
      return({exitcode=>1,msg=>$msg});

   }

   if ($reqType eq ""){
      my $msg="no type (costcenter or psp) specified";
      msg(ERROR,$msg);
      return({exitcode=>1,msg=>$msg});
   }

   #######################################################################
   # transfer files from SFTP Server
   my $tempdir=File::Temp::tempdir(CLEANUP=>1);
   $SIG{INT} = sub { eval('remove_tree($tempdir);exit(1);') if (-d $tempdir);};
   msg(DEBUG,"Starting Refresh on $tempdir");
   my $res=`echo 'lcd \"$tempdir\"\nget *.csv' | 
            sftp -b - \"$sftpsource\" 2>&1`;
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
   #######################################################################
   # after this, all useable files are in @loadfiles
   my $reccnt=0;
   foreach my $file (sort(@loadfiles)){
      my $label=$file;
      $label=~s/_.*//;
      my $type;
      if ($reqType eq "costcenter"){
         $type="costcenter" if ($file=~m/_kostl_h_/);
      }
      if ($reqType eq "psp"){
         $type="psp" if ($file=~m/_order_hier_/);
      }
      next if (!defined($type));
      next if (!($file=~m/\.csv$/i));
      if ($#filter !=-1){
         my $found=0;
         foreach my $prefix (@filter){
            my $qprefix=quotemeta($prefix);
            $found++ if ($file=~m/^$qprefix/);
         }
         next if (!$found);
      }
      if ($self->processFile(File::Spec->catfile($tempdir,$file),$label,$type,\$reccnt)){
         push(@procfiles,$file);
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
   

   if (defined($loaderror)){
      return({exitcode=>1,msg=>'ERROR:'.$loaderror});
   }

   return({exitcode=>0,msg=>'ok '.($#procfiles+1)." files processed $reccnt records"});
}



sub processFile
{
   my $self=shift;
   my $file=shift;
   my $label=shift;
   my $type=shift;
   my $reccnt=shift;

   my $obj; # target object
   my %m;   # mapping
   my $start=NowStamp("en");
   if ($type eq "psp"){
      $obj="tssapp01::psp";
      %m=(
          'WBS-Number'                    =>'name',
          'description'                   =>'description',
          'company code'                  =>'accarea',
          'delete'                        =>'isdeleted',
          'status'                        =>'status',
          'Business_Prozess_Information'  =>'bpmark',
          'ICTO-Nummer'                   =>'ictono',
          'supervisor_wiw'                =>'databosswiw',
          'customer'                      =>'sapcustomer',
          'service manager'               =>'smwiw',
          'delivery manager'              =>'delmwiw',
          'hierarchy TSI ID'              =>'saphier1',
          'hierarchy ESS/BSS ID'          =>'saphier2',
          'hierarchy ITO/SSM ID'          =>'saphier3',
          'hierarchy BB-1 ID'             =>'saphier4',
          'business center ID'            =>'saphier5',
          'customer center ID'            =>'saphier6',
          'customer team ID'              =>'saphier7',
          'customer office ID'            =>'saphier8',
          'hierarchy 9 ID'                =>'saphier9',
          'hierarchy 10 ID'               =>'saphier10',
          'parent Co-Number'              =>'pconumber',
          'NOR-solution model'            =>'normodel',
          'NOR-n'                         =>'norn',
          'PSP_Element_OFI'               =>'rawofientity'
      );
   }
   if ($type eq "costcenter"){
      $obj="tssapp01::costcenter";
      %m=(
          'cost center'                   =>'name',
          'description'                   =>'description',
          'company code'                  =>'accarea',
          'cost center type'              =>'etype',
          'supervisor'                    =>'responsiblewiw',
          'hierarchy TSI ID'              =>'saphier1',
          'hierarchy ESS/BSS ID'          =>'saphier2',
          'hierarchy ITO/SSM ID'          =>'saphier3',
          'hierarchy SL/IL ID'            =>'saphier4',
          'business center ID'            =>'saphier5',
          'customer center ID'            =>'saphier6',
          'customer team ID'              =>'saphier7',
          'customer office ID'            =>'saphier8',
          'hierarchy 9 ID'                =>'saphier9',
          'hierarchy 10 ID'               =>'saphier10'
      );
   }
   
   my $if=getModuleObject($self->Config,$obj);

   msg(DEBUG,"process '$file'");
   my $csv=Text::CSV_XS->new({
      binary  =>1,
      escape_char=>'',
      quote_char=>'',
      sep_char=>';'
   });
   my %k;
   my $srcsys=$label;


   if (open(my $fh,"<:encoding(Latin1)",$file)){
      $csv->column_names ($csv->getline($fh)); # use first line as fieldnames
      my $line=0;
      while(my $rec=$csv->getline_hr ($fh)){
         $line++;
         my $wrrec={}; 
         foreach my $k (keys(%m)){
            my $target=$m{$k};
            $wrrec->{$target}=undef;
            if ($rec->{$k} ne "" && $rec->{$k} ne "nn"){
               $wrrec->{$target}=trim($rec->{$k});
            }
         }
         $wrrec->{srcsys}=$srcsys;
         $wrrec->{srcid}=$wrrec->{name};
         $wrrec->{srcload}=NowStamp("en");
         $wrrec->{isdeleted}="0" if ($wrrec->{isdeleted} eq "");
         next if ($wrrec->{name} eq "9900591950 1000SI"); # wrong entries
         next if ($wrrec->{name} eq "9900591950 8109SI");
         next if ($wrrec->{name} eq "9900592970 1000SI");
         next if ($wrrec->{name} eq "9900592970 8109SI");
         next if ($wrrec->{name} eq "9910014071 1000SI");
         next if ($wrrec->{name} eq "9910014071 8109SI");

         if (($wrrec->{name}=~m/^\s*$/) ||
             ($wrrec->{name}=~m/\s/)){
            #msg(ERROR,"RefreshSAPP01: ".
            #          "invalid record without or invalid ".
            #          "WBS-Number '".$wrrec->{name}."' at line $line");
         }
         else{
         #   $if->ResetFilter();
         #   $if->SetFilter({'name'=>\$wrrec->{'name'}});
         #   my ($oldrec)=$if->getOnlyFirst(qw(name id));
            # validate against postible existing record
            $wrrec->{'name'}=~s/^0+//; # remove leading 0 s
            if (exists($k{$wrrec->{'name'}})){
               # doublicate (known) entry
               next if ($wrrec->{'name'} eq "X-BCM98-1000");
               next if ($wrrec->{'name'} eq "R-9910044497");
               next if ($wrrec->{'name'} eq "R-9910044497-1000");
               ###############################################################
               printf STDERR ("ERROR: dublicate entry '%s' - ignoring it\n",
                              $wrrec->{'name'});
               next;
            }
            #   print Dumper($wrrec);
            $k{$wrrec->{'name'}}++;
            if (defined($wrrec->{'rawofientity'})){
               $wrrec->{'ofientity'}=$wrrec->{'rawofientity'};
               my $ofi=$wrrec->{'ofientity'};
               if (my (@ofi)=$ofi=~
                   m/^([A-Z])([0-9A-Z]{3})([0-9A-Z]{9})([0-9]{2})([0-9]{4})$/i){
                  $wrrec->{'ofientity'}=join("-",@ofi);
               }
               elsif (my (@ofi)=$ofi=~
                   m/^([A-Z])([0-9A-Z]{3})([0-9A-Z]{9})([0-9]{2})$/i){
                  $wrrec->{'ofientity'}=join("-",@ofi);
               }
               elsif (my (@ofi)=$ofi=~
                   m/^([A-Z])([0-9A-Z]{3})([0-9A-Z]{9})$/i){
                  $wrrec->{'ofientity'}=join("-",@ofi);
               }
            }
           
            # take remote record 
            $if->ValidatedInsertOrUpdateRecord($wrrec,
                                               {'name'=>\$wrrec->{'name'},
                                                'srcsys'=>\$srcsys});
            $$reccnt++;
            #exit() if ($wrrec->{'name'} eq "E-900328595O-1000IT");
            #print Dumper($wrrec);
         }
      } 
      $csv->eof or $csv->error_diag ();
      #printf STDERR ("fifi $line processed\n");
   }
   # ToDo: Bulk Delete old records
   $if->BulkDeleteRecord({'srcload'=>"<$start",
                          'srcsys'=>$srcsys});

   return(1); 
}

1;
