package tswiw::ext::userImport;
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
   return(2000);
}


sub getImportIDFieldHelp
{
   my $self=shift;

   my $o=getModuleObject($self->getParent->Config,'tswiw::user');
   my $txt='WhoIsWho: ';
   $txt.=$o->getField('uid')->Label();

   return($txt);
}


sub processImport
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;
   my $param=shift;

   return(undef) if (!$name);

   my $wiw=getModuleObject($self->getParent->Config,"tswiw::user");

   my $flt; 

   if ($useAs eq "dsid"){
      $flt={uid=>\$name};
   }
   if ($useAs eq "email"){
      $flt={email=>\$name};
   }
   if (!defined($flt)){
      $self->getParent->LastMsg(ERROR,"no acceptable filter");
      return(undef);
   }
   $wiw->SetFilter($flt);
   my @l=grep($_->{surname}!~m/_duplicate_/i,
              $wiw->getHashList(qw(uid surname givenname email)));
   if ($#l==-1){
      if (!$param->{quiet}){
         $wiw->LastMsg(ERROR,"contact '$name' not found in ".
                              "wiw while Import");
      }
      return(undef);
   }

   my $imprec=$l[0];

   my $user=getModuleObject($self->getParent->Config,"base::user");
   $user->SetFilter([{'email'=>$imprec->{email}},{dsid=>$imprec->{uid}}]);
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
      $identifyby=$user->ValidatedInsertRecord({
         cistatusid=>4,
         usertyp=>'extern',
         allowifupdate=>1,
         surname=>$imprec->{surname},
         givenname=>$imprec->{givenname},
         dsid=>$imprec->{uid},
         email=>$imprec->{email}
      });
      return($identifyby);
   }

   return(0);
}



1;
