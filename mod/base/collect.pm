package base::collect;
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
use kernel::App::Web;
use kernel::App::Web::HierarchicalList;
use kernel::DataObj::DB;
use kernel::Field;
use File::Temp qw(tempfile);
use Fcntl qw(SEEK_SET);
use File::Temp(qw(tmpfile));
@ISA=qw(kernel::App::Web::HierarchicalList kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(       name       =>'fid',
                                   label      =>'W5BaseID',
                                   size       =>'10',
                                   dataobjattr=>'collect.fid'),
   );
   $self->setWorktable("collect");
   $self->setDefaultView(qw(fullname contentsize parentobj entrytyp editor));
   $self->{PathSeperator}="/";
   $self->{locktables}="collect write,fileacl write,contact write";
   return($self);
}


sub store
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   if ($ENV{REQUEST_METHOD} eq "PUT"){
      my $data;
      my ($fh, $filename) = tempfile();
      my $targetobj;
      my $targetname;
      my $user;
      my $label;
      while(my $n=read(STDIN, $data, 1024)){
         print $fh $data;
      }

      seek($fh,0,0) || die ("error");
      while(my $line=<$fh>){
         if (my ($v)=$line=~m/^Subject:\s*(.*)\s*$/){
            ($targetobj,$user,$targetname,$label)=
                         $v=~m/^\s*\((.+)\)\s*(\S+)\@(\S+):(.+)\s*$/;
            printf STDERR ("fifi target subject $v\n");
         }
         if ($line=~m/^\s*$/){
            last;
         }
      }
      printf STDERR ("Signed PUT to '%s' identified by '%s' from '%s'\n",
                     $targetobj,$targetname,$user);
      printf STDERR ("Signed PUT label '%s'\n",
                     $label);

      seek($fh,0,0) || die ("error");
      open(F,"openssl smime -pk7out -in $filename|");
      my $pkcs7="";
      while(<F>){
         $pkcs7.=$_;
      }

      #
      # Step 1: check if pkcs7 is not empty - if yes, send error to client
      #

      #
      # Step 2: check if $targetobj,$targetname,$user are empty if yes,
      #         then send error to client
      #

      #
      # Step 3: load  with $targetobj,$targetname,$user the known pkcs7
      #         key from database. If key not exists, create a new
      #         key record in cistatus "requested" - send a aprove message
      #         to databoss
      #

      #
      # Step 4: verfify the new data against the known key. Store the
      #         result, if verification is success.
      #

      #
      # Step 5: send result of operation to client.
      #





      my $cert="";
      seek($fh,0,0) || die ("error");
      open(F,"openssl smime -pk7out -in $filename| ".
             "openssl pkcs7 -print_certs -noout|");
      my $cert="";
      while(<F>){
         $cert.=$_;
      }


      print STDERR ("file:$filename\n");
      print STDERR ("cert:$cert\n");
      close(F);
      close($fh);
#      unlink($filename);
      
  
      print $self->HttpHeader("text/plain");
      print "RESPONSE: OK\n";

   }
   return;
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),"store");
}





1;
