package tsciam::ext::userImport;
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
use strict;
use vars qw(@ISA);
use kernel;
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getQuality
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;
   my $param=shift;
   return(1000);
}


sub getImportIDFieldHelp
{
   my $self=shift;

   my $o=getModuleObject($self->getParent->Config,'tsciam::user');
   my $txt='CIAM: ';
   $txt.=$o->getField('tcid')->Label();
   $txt.='|';
   $txt.=$o->getField('wiwid')->Label();

   return($txt);
}


sub processImport
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;
   my $param=shift;

   return(undef) if (!$name);
   my $ciam=getModuleObject($self->getParent->Config,"tsciam::user");

   my $flt; 

   if ($useAs eq "dsid"){
      if (trim($name)=~m/^\d+$/) {
         $flt={tcid=>\$name,active=>"true"};
      }
      else {
         $flt={wiwid=>\$name,active=>"true"};
      }
   }
   if ($useAs eq "posix"){
      $flt={wiwid=>\$name,active=>"true"};
   }
   if ($useAs eq "email"){
      $flt={email=>\$name,active=>"true",primary=>"true"};
   }
   if (!defined($flt)){
      $self->getParent->LastMsg(ERROR,"no acceptable filter $name/$useAs");
      return(undef);
   }
   $ciam->SetFilter($flt);
   my @l=$ciam->getHashList(qw(tcid surname givenname email));
   if ($#l==-1){
      if (!$param->{quiet}){
         $ciam->LastMsg(ERROR,"contact '$name' not found in ".
                              "CIAM while Import");
      }
      return(undef);
   }
   #if ($#l>0){
   #   if (!$param->{quiet}){
   #      $self->LastMsg(ERROR,"contact not unique in CIAM");
   #   }
   #   return(undef);
   #}


   my $imprec=$l[0];

   #if ($wiwrec->{surname}=~m/_duplicate_/i){
   #   if (!$param->{quiet}){
   #      $self->LastMsg(ERROR,
   #            "_duplicate_ are not allowed to import from WhoIsWho");
   #   }
   #   return(undef);
   #}
   my $user=getModuleObject($self->getParent->Config,"base::user");
   $user->SetFilter([
      {
         'email'=>$imprec->{email}
      },
      {
         dsid=>"tCID:".$imprec->{tcid}
      }
   ]);
   my ($userrec,$msg)=$user->getOnlyFirst(qw(ALL));
   my $identifyby=undef;
   if (defined($userrec)){
      if ($userrec->{cistatusid}==4){
         return($userrec->{userid});
      }
      $identifyby=$user->ValidatedUpdateRecord($userrec,{cistatusid=>4},
                                               {userid=>\$userrec->{userid}});
   }
   else{
      my $uidlist=$imprec->{tcid};
      $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
      my @tcid=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
      my $tcid=$tcid[0];
      $identifyby=$user->ValidatedInsertRecord({
         cistatusid=>4,
         usertyp=>'extern',
         allowifupdate=>1,
         surname=>$imprec->{surname},
         givenname=>$imprec->{givenname},
         dsid=>"tCID:".$tcid,
         email=>$imprec->{email}
      });
      return($identifyby);
   }

   return(0);
}




1;
