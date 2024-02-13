package W5Warehouse::event::Transfer_W5USULICMGMT_SYSTEM;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
no warnings;
use kernel;
use kernel::Event;
use kernel::QRule;
use kernel::FileTransfer;
use Crypt::GPG;
use File::Temp qw(tempdir);
@ISA=qw(kernel::Event);


sub Transfer_W5USULICMGMT_SYSTEM
{
   my $self=shift;
   my $queryparam=shift;

   my $DataObjUser=$self->Config->Param("DATAOBJUSER");
   if (ref($DataObjUser) eq "HASH" && exists($DataObjUser->{USULICMGMT})){
      $DataObjUser=$DataObjUser->{USULICMGMT};
   }
   else{
      $DataObjUser=undef;
   }

   my $DataObjPKey=$self->Config->Param("DATAOBJPKEY");
   if (ref($DataObjPKey) eq "HASH" && exists($DataObjPKey->{USULICMGMT})){
      $DataObjPKey=$DataObjPKey->{USULICMGMT};
   }
   else{
      $DataObjPKey=undef;
   }

   my $gpg=new Crypt::GPG();
   $gpg->gpgbin("/usr/bin/gpg");

   my @k=$gpg->addkey($DataObjPKey);
   $gpg->keytrust($k[0],5);
   my @kdb=$gpg->keydb();

   my $ftp=new kernel::FileTransfer($self,"USULICMGMT");
   if (!defined($ftp)){
      return({exitcode=>1,msg=>msg(ERROR,"can't create ftp object")});
   }

   if ($ftp->Connect()){
      my $dobj=getModuleObject($self->Config,
                               "W5Warehouse::W5USULICMGMT_SYSTEM");
      $dobj->SetFilter({systemid=>"S30120*"});
      $dobj->SetFilter({});
      $dobj->SetCurrentView(qw(ALL));
      my $output=new kernel::Output($dobj);
      my %param=(ignViewValid=>1);
      if (!($output->setFormat("CsvV01",%param))){
         msg(ERROR,"fail to select output format");
         return();
      }

      my @view=$dobj->GetCurrentView();
      @view=grep(!/^linenumber$/,@view);
      $dobj->SetCurrentView(@view);

      my $tempdir = tempdir(CLEANUP=>1);
      my $file=$dobj->Self();
      $file=~s/^.*:://;
      $file=~s/[^a-z0-9]/_/gi;
      $file.=".csv.gpg";
      my $filename=$tempdir."/".$file;
      my $csvfile=$output->WriteToScalar(HttpHeader=>0);
      $gpg->armor(0);
      my $target=$k[0]->{ID};
      my $encrypted = $gpg->encrypt ($csvfile,$target);
      if ($encrypted eq ""){
         my $msg="fail to encrypt data for $target";
         #msg(ERROR,$msg);
         return({exitcode=>1,exitmsg=>$msg});
      }
      if (open(F,'>'.$filename)){
         print F ($encrypted);
         close(F);
      }
      msg(INFO,"send $filename to $file");
      $ftp->Put($filename,$file);
      $ftp->Disconnect();
   }

   return({exitcode=>0,exitmsg=>'OK'});
}


1;
