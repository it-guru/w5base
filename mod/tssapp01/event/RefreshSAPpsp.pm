package tssapp01::event::RefreshSAPpsp;
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


   $self->RegisterEvent("RefreshSAPpsp","RefreshSAPpsp",timeout=>14400);
   return(1);
}


sub RefreshSAPpsp
{
   my $self=shift;
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

   #######################################################################
   # transfer files from SFTP Server
   my $tempdir=File::Temp::tempdir(CLEANUP=>1);
   $SIG{INT} = sub { eval('remove_tree($tempdir);exit(1);') if (-d $tempdir);};
   msg(DEBUG,"Starting Refresh on $tempdir");
   my $res=`echo 'lcd \"$tempdir\"\nget *' | 
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
   foreach my $file (@loadfiles){
      my $label=$file;
      $label=~s/_.*//;
      my $type;
      $type="psp" if ($file=~m/_order_hier_/);
      next if (!defined($type));
      next if (!($file=~m/\.csv$/i));
      next if ($#filter!=-1 && !in_array(\@filter,$label));

      if ($self->processFile(File::Spec->catfile($tempdir,$file),$label)){
         push(@procfiles,$file);
         # ToDo: Bulk Delete old records


      }
   }

   # cleanup FTP Server
   foreach my $file (@procfiles){
      msg(DEBUG,"cleanup '$file'");
      my $res=`echo 'rm \"$file\"' | sftp -b - \"$sftpsource\" 2>&1`;
      if ($?!=0){
         $loaderror.=$res;
      }
   }
   

   if (defined($loaderror)){
      return({exitcode=>1,msg=>'ERROR:'.$loaderror});
   }

   return({exitcode=>0,msg=>'ok '.($#procfiles+1)." processed"});
}

sub processFile
{
   my $self=shift;
   my $file=shift;
   my $label=shift;

   my $if=getModuleObject($self->Config,"tssapp01::psp");

   msg(DEBUG,"process '$file'");
   my $csv=Text::CSV_XS->new({
      binary  =>1,
      escape_char=>'',
      quote_char=>'',
      sep_char=>';'
   });
   my %k;
   my $srcsys=$label;

   my %m=(
      'WBS-Number'             =>'name',
      'description'            =>'description',
      'delete'                 =>'isdeleted',
      'status'                 =>'status',
      'supervisor_wiw'         =>'databosswiw',
      'customer'               =>'sapcustomer',
      'service manager'        =>'smwiw',
      'delivery manager'       =>'delmwiw',
      'hierarchy TSI ID'       =>'saphier1',
      'hierarchy ESS/BSS ID'   =>'saphier2',
      'hierarchy ITO/SSM ID'   =>'saphier3',
      'hierarchy BB-1'         =>'saphier4',
      'business center ID'     =>'saphier5',
      'customer center ID'     =>'saphier6',
      'customer team ID'       =>'saphier7',
      'customer office ID'     =>'saphier8',
      'hierarchy 9 ID'         =>'saphier9',
      'hierarchy 10 ID'        =>'saphier10',
      'parent Co-Number'       =>'pconumber',
      'NOR-solution model'     =>'normodel',
      'NOR-n'                  =>'norn');
   
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
               $wrrec->{$target}=$rec->{$k};
            }
         }
         $wrrec->{srcsys}=$srcsys;
         $wrrec->{srcid}=$wrrec->{name};
         $wrrec->{srcload}=NowStamp("en");
         if (($wrrec->{name}=~m/^\s*$/) ||
             ($wrrec->{name}=~m/\s/)){
            msg(ERROR,"RefreshSAPP01: ".
                      "invalid record without or invalid ".
                      "WBS-Number '".$wrrec->{name}."' at line $line");
         }
         else{
            $if->ResetFilter();
            $if->SetFilter({'name'=>\$wrrec->{'name'}});
            my ($oldrec)=$if->getOnlyFirst(qw(name id));
            # validate against postible existing record
            if (exists($k{$wrrec->{'name'}})){
               print STDERR Dumper($wrrec);
               exit(1);
            }
            #   print Dumper($wrrec);
            $k{$wrrec->{'name'}}++;
           
            # take remote record 
            $if->ValidatedInsertOrUpdateRecord($wrrec,
                                               {'name'=>\$wrrec->{'name'},
                                                'srcsys'=>\$srcsys});
            #print Dumper($wrrec);
         }
      } 
      $csv->eof or $csv->error_diag ();
      #printf STDERR ("fifi $line processed\n");
   }

   return(1); 
}

1;
