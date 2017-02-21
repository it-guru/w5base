package passx::io;
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
use MIME::Base64;
use Data::Dumper;
use CGI;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(GetPublicKeys SendCryptedData ChangePassword TechMenu));
}

sub TechMenu
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   my $format=Query->Param("format");
   my @fl=qw(xml fvwm perl enlightenment sshmenu);
   $p=~s/\///g; 

   $format="xml" if (!grep(/^$format$/,@fl));
   my $user=$self->getPersistentModuleObject("base::user");
   $user->SetFilter({posix=>\$p});
   my ($urec,$msg)=$user->getOnlyFirst(qw(userid));
   if (defined($urec)){ 
      my $userid=$urec->{userid};
      my $ent=$self->getPersistentModuleObject("passx::entry");
      if ($format eq "xml"){
         print $self->HttpHeader("text/xml");
         print $ent->generateMenuTree($format,$userid,"","");
      }
      if ($format eq "sshmenu"){
         print $self->HttpHeader("text/plain");
         print $ent->generateMenuTree($format,$userid,"","");
      }
      if ($format eq "fvwm"){
         print $self->HttpHeader("text/plain");
         print $ent->generateMenuTree($format,$userid,"","");
      }
      if ($format eq "enlightenment"){
         print $self->HttpHeader("text/plain");
         print $ent->generateMenuTree($format,$userid,"","");
      }
   }
}

sub LoadTarget
{
   my $self=shift;
   my $host=shift;
   my $account=shift;
   my $entrytypeid=shift;
   my $Rerec=shift;
   my $Rdest=shift;

   $host=~s/[\*\s\?]//g;
   $account=~s/[\*\s\?]//g;

   if ($host eq ""){
      printf("ERROR: invalid or incomplete host specification\n");
      return;
   }
   if ($account eq ""){
      printf("ERROR: invalid or incomplete account specification\n");
      return;
   }
   my $ent=$self->getPersistentModuleObject("passx::entry");
   my $mgr=$self->getPersistentModuleObject("passx::mgr");
   $host=lc($host);
   $ent->SetFilter({name=>\$host,account=>\$account,
                    entrytypeid=>\$entrytypeid});
   my ($erec,$msg)=$ent->getOnlyFirst(qw(ALL));
   if (!defined($erec)){
      $ent->ResetFilter();
      $ent->SetFilter({name=>"$host.*",account=>\$account,
                       entrytypeid=>\$entrytypeid});
      my @l=$ent->getHashList(qw(ALL));
      if ($#l==0){
         $erec=$l[0];
      }
   }
   if (!defined($erec)){
      printf("ERROR: no distribution entry for host '%s' and account '%s'\n",
             $host,$account);
      return;
   }
   my @dest=$mgr->GetDestPublicKeys($erec);

   @$Rdest=@dest;
   $$Rerec=$erec;
   return(1);
}

sub GetPublicKeys
{
   my ($self)=@_;
   my $host=Query->Param("host");
   my $account=Query->Param("account");
   my $entrytypeid=Query->Param("entrytypeid");
   $entrytypeid=1 if ($entrytypeid eq "");

   my ($erec,@dest);
   print $self->HttpHeader("text/plain");
   return() if (!$self->LoadTarget($host,$account,$entrytypeid,\$erec,
                                   \@dest));
   if ($erec->{scriptkey} eq ""){
      my $newkey=generateToken(80);
      printf("KEY:%s\n",$newkey);
      my $ent=$self->getPersistentModuleObject("passx::entry");
      $erec->{scriptkey}=$newkey;
      $ent->ValidatedUpdateRecord($erec,{scriptkey=>$erec->{scriptkey},
                                         mdate=>$erec->{mdate},
                                         realeditor=>$erec->{realeditor},
                                         editor=>$erec->{editor}},
                                  {id=>\$erec->{id}});
   }
   foreach my $dest (@dest){
      printf("UID:%s\n",$dest->{userid});
      my $n=$dest->{n};
      $n=~s/[\r\n]//gm;
      my @n=grep(!/^\s*$/,split(/(..)/,$n));
      my $keylen=($#n+1)*8;
      my @pref;
      if ($keylen==256){
         @pref=qw(30 3c 30 0d 06 09 2a 86 48 86 f7 0d 01 01 01 05 
                  00 03 2b 00 30 28 02 21 00);
      }
      if ($keylen==512){
         @pref=qw(30 5C 30 0D 06 09 2A 86 48 86 F7 0D 01 01 01 05 
                  00 03 4B 00 30 48 02 41 00);
      }
      if ($keylen==1024){
         @pref=qw(30 81 9F 30 0D 06 09 2A 86 48 86 F7 0D 01 01 01
                  05 00 03 81 8D 00 30 81 89 02 81 81 00 );
      }
      my @exp=qw(02 03 01 00 01);
      my @asn1data=(@pref,@n,@exp);
      my $asn1=encode_base64(pack("H*",join("",@asn1data)));
      printf("-----BEGIN PUBLIC KEY-----\n");
      printf("%s",$asn1);
      printf("-----END PUBLIC KEY-----\n");

   }
   printf("OK\n");
}


sub SendCryptedData
{
   my ($self)=@_;
   my $host=Query->Param("host");
   my $account=Query->Param("account");
   my $entrytypeid=Query->Param("entrytypeid");
   my $scriptkey=Query->Param("scriptkey");
   $entrytypeid=1 if ($entrytypeid eq "");
   my $cryptdata=Query->Param("cryptdata");
   

   my ($erec,@dest);
   print $self->HttpHeader("text/plain");
   return() if (!$self->LoadTarget($host,$account,$entrytypeid,\$erec,\@dest));
   if (defined($erec->{scriptkey}) && $erec->{scriptkey} ne $scriptkey){
      print("invalid scriptkey or old ChangePassword version\n");
      return();
   }

   my $mgr=$self->getPersistentModuleObject("passx::mgr");
   my $passxlog=$self->getPersistentModuleObject("passx::log");

   $passxlog->ValidatedInsertRecord({name=>'ChangePassword of '.
                                           $erec->{account}.'@'.
                                           $erec->{name}.' from '.
                                           getClientAddrIdString(),
                                     entryid=>$erec->{id}});
   $mgr->StoreCryptData($erec->{id},$cryptdata,\@dest);



#   printf("fifi host=$host\n");
#   printf("fifi account=$account\n");
#   printf("crypt:\n$cryptdata\n");
   print("OK\n");
}

sub ChangePassword
{
   my ($self)=@_;
   my $instdir=$self->Config->Param("INSTDIR");

   print $self->HttpHeader("text/x-perl");
   if (open(F,"$instdir/contrib/passx/ChangePassword")){
      print(join("",<F>));
      close(F);
   }
}

1;
