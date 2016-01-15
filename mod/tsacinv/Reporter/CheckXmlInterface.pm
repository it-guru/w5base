package tsacinv::Reporter::CheckXmlInterface;
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
use strict;
use vars qw(@ISA);
use kernel;
use kernel::Reporter;
use File::Temp qw(tempfile);

@ISA=qw(kernel::Reporter);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{name}="Check Log-Files of XML Interface";
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(60,['6:19']);
}


sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;

   my ($fh, $filename);

   if (!(($fh, $filename) = tempfile())){
      print STDERR ("ERROR: can not create temp file\n");
      return(1);
   }

   my $ftp=new kernel::FileTransfer($self,"tsacftp");
   if (!defined($ftp)){
      print STDERR ("ERROR: can not create file transfer endpoint\n");
      return(1);
   }
   if (!$ftp->Connect()){
      print STDERR ("ERROR: connect to tsacftp endpoint failed\n");
      return(1);
   }
   if ($ftp->Get("appl/log/application_log.xml",$filename)){
      eval("use XML::Parser;");
      if ($@ ne ""){
         print STDERR ("ERROR: fail to load XML::Parser\n");
         return(1);
      }
      my $p;
      eval('$p=new XML::Parser();');
      if (!defined($p)){
         print STDERR ("ERROR: fail to create XML::Parser object\n");
         return(1);
      }
      $p->setHandlers(getHandlers());
      $p->parsefile($filename);
   }
   else{
      printf STDERR ("ERROR: can not load xml file %s\n",$ftp->errstr());
      return(1); 
   }
   unlink($filename);

   return(0);
}

sub getHandlers
{
   my $curTag;
   my $buf;
   my $rec;

   return(
   Start=>sub{
      my ($p,$tag,%attr)=@_;
      $curTag=join('.',$p->context(),$tag);
      $buf=undef;
      $rec=undef if ($tag eq "Response");
   },
   End=>sub{
      my ($p,$tag,%attr)=@_;
      if ($curTag eq "XMLInterface.Response.Error_Desc"){
         if ($buf=~m/Incident assignment.*cannot be empty/i){
            $buf="missing incident assignmentgroup";
         }
         elsif($buf=~m/You do not have 'update' right on field 'Deleted/i){
            $buf="can not undelete";
         }
         elsif ($buf=~m/You don\'t have the right.*this rec/i){
            $buf="write denied";
         }
         else{
            $buf=~s/\n/ /g;
            $buf=~s/;/ /g;
            if (length($buf)>255){
               $buf=substr($buf,0,255)."...";
            }
         }
      }
      $rec->{$curTag}=$buf;
      if ($tag eq "Response" &&
          defined($rec)){ # print record buf
         printf("%s;%s\n",
            $rec->{'XMLInterface.Response.EventID'},
            $rec->{'XMLInterface.Response.Error_Desc'});
      }
   },
   Char=>sub {
      my ($p,$s)=@_;
      $buf.=$s;
   });
}




1;
