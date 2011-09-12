package AL_TCom::event::putoqb;
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
use kernel::FTP;

use File::Temp qw(tempfile);
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("putoqb","PutOQB");
   return(1);
}


sub PutOQB
{
   my $self=shift;
   my @appid=@_;

   my $elements=0;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $mandators=['GCU Telco'];
   $wf->SetFilter({mdate=>">now-2d AND <now",
                   class=>'*::workflow::problem'});
   $wf->SetCurrentView(qw(name mandator eventstart eventend srcid id
                          detaildescription
                          additional.ServiceCenterCreator));

   my (%fh,%filename);
   my $ftp=new kernel::FTP($self,"oqbftp");
   if (defined($ftp)){
      if (!($ftp->Connect())){
         return({exitcode=>1,msg=>msg(ERROR,"can't connect to ftp server ".
                "- login fails")});
      }
      $self->{ftp}=$ftp;
   }
   else{
      return({exitcode=>1,msg=>msg(ERROR,"can't create ftp object")});
   }
   ($fh{problem},     $filename{problem}          )=$self->InitTransfer();
   return($ftp) if (ref($ftp) eq "HASH" || !defined($ftp)); # on errors

  

   my ($rec,$msg)=$wf->getFirst();
   $self->{jobstart}=NowStamp();
   my %grpnotfound;
   if (defined($rec)){
      do{
         if (ref($rec->{mandator}) eq "ARRAY"){
            my $found=0;
            foreach my $qmandator (map({quotemeta($_)} @$mandators)){
               $found++ if (grep(/^$qmandator$/,@{$rec->{mandator}}));
            }
            if ($found){
               msg(INFO,"dump=%s",Dumper($rec));
               my %tmprec=%{$rec};
               my %trec=(record=>\%tmprec);
               my $f=$fh{problem};
               print $f hash2xml(\%trec,{header=>0});
            }
         }
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   my $back=$self->TransferFile($fh{problem},$filename{problem},
                                $ftp,"problem");
   return($back);
}


sub InitTransfer
{
   my $self=shift;
   my $fh;
   my $filename;

   if (!(($fh, $filename) = tempfile())){
      return({msg=>$self->msg(ERROR,'can\'t open tempfile'),exitcode=>1});
   }
   print $fh ("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n\n");
   print $fh ("<XMLInterface>\n");

   return($fh,$filename);
}

sub TransferFile
{
   my $self=shift;
   my $fh=shift;
   my $filename=shift;
   my $ftp=shift;
   my $object=shift;

   print $fh ("</XMLInterface>\n");
   close($fh);

   if (open(FI,"<$filename") && open(FO,">/tmp/last.putoqb.$object.xml")){
      printf FO ("%s",join("",<FI>));
      close(FO);
      close(FI);
   }
   if ($ftp->Connect()){
      msg(INFO,"Connect to FTP Server OK");
      my $jobname="DARWIN.".$self->{jobstart}.".xml";
      my $jobfile="$jobname";
      msg(INFO,"Processing  job : '%s'",$jobfile);
      msg(INFO,"Processing  file: '%s'",$filename);
      if (1){
         if (!$ftp->Put($filename,$jobfile)){
            msg(ERROR,"File $filename to $jobfile could not be transfered");
         }
      }
      unlink($filename);
      $ftp->Disconnect();
   }
   else{
      return({msg=>$self->msg(ERROR,'can\'t connect to ftp srv'),exitcode=>1});
   }

   return({exitcode=>0,msg=>'OK'});
}


1;
