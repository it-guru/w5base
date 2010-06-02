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
use MIME::Base64;
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
      my $errormsg;
      while(my $n=read(STDIN, $data, 1024)){
         print $fh $data;
      }

      seek($fh,0,0) || die ("error");
      while(my $line=<$fh>){
         if (my ($v)=$line=~m/^Subject:\s*(.*)\s*$/){
            ($targetobj,$user,$targetname,$label)=
                         $v=~m/^\s*\((.+)\)\s*(\S+)\@(\S+):(.+)\s*$/;
            $label=~s/\\/\//g;
            if (!($label=~m/\/[a-z0-9\/\._-]+$/i)){
               $errormsg="invalid label specified";
            }
         }
         if ($line=~m/^\s*$/){
            last;
         }
      }
      #printf STDERR ("Signed PUT to '%s' identified by '%s' from '%s'\n",
      #               $targetobj,$targetname,$user);
      #printf STDERR ("Signed PUT label '%s'\n",
      #               $label);

      #
      # Step 0: extract attached keyfile
      #
      my $pkcs7="";
      if ($errormsg eq ""){
         seek($fh,0,0) || die ("error");
         open(F,"openssl smime -pk7out -in $filename|".
                "openssl pkcs7 -print_certs|");
         while(<F>){
            $pkcs7.=$_;
         }
         $pkcs7=trim($pkcs7);
      }

      #
      # Step 1: check if pkcs7 is not empty - if yes, send error to client
      #
      if ($errormsg eq ""){
         if ($pkcs7 eq ""){
            $errormsg="no pkcs7 key found in request";
         }
      }

      #
      # Step 2: check if $targetobj,$targetname,$user are empty if yes,
      #         then send error to client
      #
      if ($errormsg eq ""){
         if ($errormsg eq "" && !($targetobj=~m/^\S+::\S+.*$/)){
            $errormsg="no target object specified";
         }

      }

      #
      # Step 3: load  with $targetobj,$targetname,$user the known pkcs7
      #         key from database. If key not exists, create a new
      #         key record in cistatus "requested" - send a aprove message
      #         to databoss
      #
      my $filesig;
      my $sigrec;
      if ($errormsg eq ""){
         $filesig=getModuleObject($self->Config,"base::filesig");
         $filesig->SetFilter({parentobj=>\$targetobj,
                              name=>\$targetname,
                              username=>\$user});
         my $msg;
         ($sigrec,$msg)=$filesig->getOnlyFirst(qw(ALL)); 
         if (!defined($sigrec)){
            $sigrec={
                     parentobj=>$targetobj,
                     name=>$targetname,
                     cistatusid=>'2',
                     username=>$user,
                     pk7=>$pkcs7};
            $filesig->ValidatedInsertRecord($sigrec);
            $errormsg="used signatur is new recored";
         }
         else{
            if ($errormsg eq "" && $sigrec->{cistatusid}!=4){
               $errormsg="used signatur is not activated";
            }
            if ($pkcs7 ne $sigrec->{pk7}){
               $errormsg="invalid signature attached";
            }
         }
      }

      #
      # Step 4: verfify the new data against the known key. Store the
      #         result, if verification is success.
      #
      if ($errormsg eq ""){
         my ($certfh, $certfile) = tempfile();
         print $certfh $sigrec->{pk7};
         close($certfh); 
         my $chkcmd="openssl smime -verify -in $filename -CAfile $certfile";
         open(F,"$chkcmd 2>&1|");
         my $fileok=0;
         my $fb64;
         while(<F>){
            if ($_=~m/Verification successful/){
               $fileok=1;
            }
            else{
               $fb64.=$_;
            }
         }
         if ($fileok){
            my $nativfile=decode_base64($fb64);
            #
            # Verify the first line of payload - if structure is not correct
            # produce an error and send it to client
            #
            {  # first quick hack
               $nativfile=~s/^.*?\n//m;
            }
            #printf STDERR ("OK verified:\n%s\n",$nativfile);
            if ($errormsg eq ""){
               #
               # Store file at label
               #
               my $to=getModuleObject($self->Config,$targetobj);
               if (!defined($to)){
                  $errormsg="invalid target object specifed";
               }
            
               if ($errormsg eq ""){
                  my $fo=$to->getField("signedfiletransfername");
                  if (!defined($fo)){
                     $errormsg="target object could not recive signed file";
                  }
               }
               my ($parentid,$mandatorid);
               if ($errormsg eq ""){
                  my $id=$to->IdField()->Name();
                  $to->SetFilter({signedfiletransfername=>\$targetname});
                  my ($trec,$msg)=$to->getOnlyFirst($id,"mandatorid"); 
                  if ($trec->{$id} eq ""){
                     $errormsg="could not detect id in parent object";
                  }
                  $parentid=$trec->{$id};
                  $mandatorid=$trec->{mandatorid};
               }
               if ($errormsg eq ""){
                  my $sf=getModuleObject($self->Config,"base::signedfile");
                  #
                  # check if a file with the requested label already exists
                  #
                  $sf->SetFilter({label=>\$label,
                                  isnewest=>\'1',
                                  parentid=>\$parentid,
                                  parentobj=>\$targetobj});
                  my ($oldrec,$msg)=$sf->getOnlyFirst("id"); 
                  if (defined($oldrec)){
                     #
                     # if a file already exists, mark it as "old"
                     #
                     $sf->ValidatedUpdateRecord($oldrec,{isnewest=>undef},
                                                {id=>\$oldrec->{id}});
                  }
                  $sf->ValidatedInsertRecord({label=>$label,
                                              filesig=>$sigrec->{id},
                                              parentid=>$parentid,
                                              mandatorid=>$mandatorid,
                                              parentobj=>$targetobj,
                                              datafile=>$nativfile});
                  if ($self->LastMsg()!=0){
                     $errormsg=join(";",$self->LastMsg()); 
                     $errormsg=~s/\n/ /g;
                     $self->LastMsg("");
                  }
               }
            }
         }
         else{
            $errormsg="signature not correct";
         }
         unlink($certfile); 
      }

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

      close(F);
      close($fh);
      unlink($filename);
      
  
      if ($errormsg eq ""){
         print $self->HttpHeader("text/plain");
         print "RESPONSE:\nOK\n";
      }
      else{
         print $self->HttpHeader("text/plain");
         if (!($errormsg=~m/ERROR/)){
            $errormsg="ERROR: $errormsg";
         }
         print "RESPONSE:\n$errormsg\n";
      }

   }
   return;
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),"store");
}





1;
