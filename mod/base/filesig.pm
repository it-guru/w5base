package base::filesig;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::DB;
use kernel::Field;
use File::Temp qw(tempfile);
use Fcntl qw(SEEK_SET);
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'filesig.keyid'),
                                                  
      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0 AND <7"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'filesig.cistatus'),

      new kernel::Field::Text(
                name          =>'labelpath',
                group         =>'sig',
                label         =>'path/usage',
                dataobjattr   =>'filesig.labelpath'),

      new kernel::Field::Text(
                name          =>'parentobj',
                group         =>'sig',
                label         =>'Parentobj',
                dataobjattr   =>'filesig.parentobj'),

      new kernel::Field::Text(
                name          =>'parentid',
                group         =>'sig',
                label         =>'Parentrefid',
                dataobjattr   =>'filesig.parentid'),

      new kernel::Field::Text(
                name          =>'name',
                group         =>'sig',
                label         =>'systemname',
                dataobjattr   =>'filesig.name'),

      new kernel::Field::Text(
                name          =>'username',
                group         =>'sig',
                label         =>'given used identity',
                dataobjattr   =>'filesig.username'),

      new kernel::Field::Textarea(
                name          =>'pk7',
                group         =>'sig',
                label         =>'PK7 Key',
                dataobjattr   =>'filesig.pemkey'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'filesig.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'filesig.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'filesig.modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'filesig.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'filesig.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'filesig.realeditor')

   );
   $self->setDefaultView(qw(linenumber parentobj username name 
                            labelpath cistatus cdate mdate));
   $self->setWorktable("filesig");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $parentobj=trim(effVal($oldrec,$newrec,"parentobj"));
   if ($parentobj ne "itil::system"){
      $self->LastMsg(ERROR,"used parentobject is not suppored");
      return(undef);
   }
   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","sig","soure");
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return();
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
      my $labelpath;
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
            if (!($label=~m/\/[a-z0-9\/\._-]+$/i) &&
                $label ne "CFMACCMGR"){
               $errormsg="invalid label specified";
            }
            else{
               $labelpath=$label;
               if ($label=~m/^\//){
                  $labelpath=~s/[^\/]*$//;
               }
            }
         }
         if ($line=~m/^\s*$/){
            last;
         }
      }
      print $self->HttpHeader("text/plain");
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
      if ($errormsg eq ""){
         if ($errormsg eq "" && ($targetname=~m/^\s*$/)){
            $errormsg="no target name specified";
         }
      }
      my $to;
      if ($errormsg eq ""){
         $to=getModuleObject($self->Config,$targetobj);
         if (!defined($to)){
            $errormsg="invalid target object specifed";
         }
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
         my $flt={signedfiletransfername=>\$targetname};
         if (defined($to->getField("cistatusid"))){
            $flt->{cistatusid}="<6";
         }
         $to->SetFilter($flt);
         $to->SetCurrentOrder(qw(NONE));
         my ($trec,$msg)=$to->getOnlyFirst($id,"mandatorid"); 
         if ($trec->{$id} eq ""){
            $errormsg="could not detect id in parent object";
         }
         $parentid=$trec->{$id};
         $mandatorid=$trec->{mandatorid};
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
                              labelpath=>\$labelpath,
                              username=>\$user});
         my $msg;
         $filesig->SetCurrentOrder(qw(NONE));
         ($sigrec,$msg)=$filesig->getOnlyFirst(qw(ALL)); 
         if (!defined($sigrec)){
            $sigrec={
                     labelpath=>$labelpath,
                     parentobj=>$targetobj,
                     parentid=>$parentid,
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
            elsif ($_=~m/certificate has expired/){
               $errormsg="ERROR: your client certificate has expired";
               $fileok=0;
               last;
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
               if ($errormsg eq ""){

                  if ($labelpath eq "CFMACCMGR"){
                     #
                     # process singed data query for account management
                     #
                     my $u=getModuleObject($self->Config,"base::user");
                     printf STDERR ("CFMACCMGR request=%s\n",$nativfile);
                     my @flt=$u->StringToFilter($nativfile,nofieldcheck=>1);
                     if ($#flt==0 && exists($flt[0]->{appl})){
                        my $appl=getModuleObject($self->Config,"itil::appl");
                        if (defined($appl)){
                           $appl->SetFilter({cistatusid=>'<=5',
                                             name=>$flt[0]->{appl}});
                           foreach my $ar ($appl->getHashList("businessteam")){
                              if (!exists($flt[0]->{groups})){
                                 $flt[0]->{groups}="";
                              }
                              if ($ar->{businessteam} ne ""){
                                 if ($flt[0]->{groups} ne ""){
                                    $flt[0]->{groups}.=" ";
                                 }
                                 $flt[0]->{groups}.=$ar->{businessteam};
                              }
                           }
                        }
                        else{
                           $flt[0]->{userid}=\'-1';
                        }
                        delete($flt[0]->{appl});
                     }
                     printf STDERR ("CFMACCMGR filter=%s\n",Dumper(\@flt));
                     foreach my $f (@flt){
                        $f->{cistatusid}="4";
                        if (!exists($f->{usertyp})){
                           $f->{usertyp}="user";
                        }
                     }
                     if ($u->LastMsg()==0){
                        $u->SetFilter(\@flt);
                        my @l=$u->getHashList(qw(userid posix 
                                          email ssh1publickey ssh2publickey));
                        if ($#l>100){
                           $errormsg="too many accounts selected";
                        }
                        else{
                           foreach my $urec (@l){
                              my $ssh1publickey=$urec->{ssh1publickey};
                              my $ssh2publickey=$urec->{ssh2publickey};
                              $ssh1publickey=~s/[\n:]//g;
                              $ssh2publickey=~s/[\n:]//g;
                              if ($urec->{posix} ne ""){ 
                                 printf("ACC:%s:%s:%s:%s:%s\n",
                                        $urec->{posix},$urec->{userid},
                                        $urec->{email},
                                        $urec->{ssh1publickey},
                                        $urec->{ssh2publickey});
                              }
                           }
                        }
                     }
                     else{
                        $errormsg=join("\n",$self->LastMsg());
                     }
                  }
                  else{
                     #
                     # process singed file transfer to datastore
                     #
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
         }
         else{
            $errormsg="signature not correct" if ($errormsg eq "");
         }
         unlink($certfile); 
      }

      #
      # Step 5: send result of operation to client.
      #

      
  
      if ($errormsg eq ""){
         print "RESPONSE:OK\n";
      }
      else{
         if (!($errormsg=~m/ERROR/)){
            $errormsg="ERROR: $errormsg\n";
         }
         print "RESPONSE:$errormsg\n";
      }
      unlink($filename);

   }
   return;
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),"store");
}








1;
