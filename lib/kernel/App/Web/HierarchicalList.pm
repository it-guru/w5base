package kernel::App::Web::HierarchicalList;
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
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   #
   # name und fullname sind zwingend
   # fullname muss ein unique key sein und parentid muss den 
   # Verweis auf den Eltern-Datensatz enthalten
   #
   $self->{PathSeperator}="." if (!defined($self->{PathSeperator}));
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $parentid;
   if (defined($oldrec)){
      $parentid=$oldrec->{parentid};
      if (!defined($newrec->{name})){
         $newrec->{name}=$oldrec->{name};
      }
   }
   if (defined($newrec->{parentid})){
      $parentid=$newrec->{parentid};
   }
   if (!defined($parentid)){
      $newrec->{fullname}=$newrec->{name};
      $origrec->{fullname}=$newrec->{name};
   }
   else{
      #load parents fullname
      my $idname=$self->IdField->Name;
      my $pname="";
      if ($parentid ne ""){
         $pname=$self->getVal("fullname",{$idname=>$parentid});
      }
      if ($pname ne ""){
         $newrec->{fullname}=$pname.$self->{PathSeperator}.$newrec->{name};
         $origrec->{fullname}=$pname.$self->{PathSeperator}.$newrec->{name};
      }
      else{
         $newrec->{fullname}=$newrec->{name};
         $origrec->{fullname}=$newrec->{name};
      }
   }
   my $fn=effVal($oldrec,$newrec,"fullname");
   if (length($fn)>250){
      $self->LastMsg(ERROR,"resulting fullname to long '$fn'");
      return(0);
   }
   if (defined($oldrec) && effChanged($oldrec,$newrec,"parentid")){
      # tree validierung
      msg(INFO,"new parentid needs tree validierung");
      my $parentid=effVal($oldrec,$newrec,"parentid");
      my $idname=$self->IdField->Name;
      my %ring=(effVal($oldrec,$newrec,$idname)=>1);
      while($parentid ne ""){
         if (exists($ring{$parentid})){
            $self->LastMsg(ERROR,"result entry will create a loop pointer");
            return(0);
         }
         else{
            $ring{$parentid}++;
         }
         $parentid=$self->getVal("parentid",{$idname=>$parentid});
         msg(INFO,"check $parentid");
      }
   }
   return(1);
}

sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;
   my $idfield=$self->IdField()->Name();

   return(undef) if (!defined($oldrec) || $#filter!=0 ||
                     keys(%{$filter[0]})!=1 ||
                     !defined($filter[0]->{$idfield}));
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my @updfields=keys(%{$newrec});
   if (!grep(/^fullname$/,@updfields) &&
       !grep(/^name$/,@updfields) &&
       !grep(/^parent$/,@updfields) &&
       !grep(/^parentid$/,@updfields) ){ # just make it simple
      return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
   }
   my $subchanges=0;
   msg(INFO,"data change check for '".effVal($oldrec,$newrec,"fullname")."'");
   foreach my $v (qw(fullname name parent parentid)){
      if (exists($newrec->{$v}) && 
          $oldrec->{$v} ne $newrec->{$v}){
         $subchanges++;
         msg(INFO,"data changed in field '".$v."'");
      }
      else{
         #msg(INFO,"no data change found in field '".$v."'");
      }
   }
   if (!$subchanges){
      msg(INFO,"no data changes found");
      return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
   }

   my $lockFail=$self->lockWorktable();
   if (!defined($lockFail)){
      my @dep=(\%{$oldrec});
      my @loadlist=($oldrec->{$idfield});
      my @fieldlist=qw(fullname parentid name);
      if ($self->getField("cistatusid")){
         push(@fieldlist,"cistatusid");
      }
      while($#loadlist!=-1){
         $self->SetFilter({parentid=>\@loadlist});
         my @d=$self->getHashList(@fieldlist);
         @loadlist=();
         foreach my $rec (@d){  # load recursive the full dependency
            push(@loadlist,$rec->{$idfield});
            push(@dep,$rec); 
         }
      }
      my $bak=1;
      my $writefailon=undef;
      for(my $c=0;$c<=$#dep;$c++){
         my $writerec=$dep[$c];
         $writerec=$newrec if ($c==0);
         my $bak=$self->SUPER::ValidatedUpdateRecord($dep[$c],$writerec,
                                            {$idfield=>$dep[$c]->{$idfield}});
         if (!$bak){
            if ($c==0){
               $self->unlockWorktable();
               return($bak);
            }
            $writefailon=$c;
            last;
         }
      }
      if (defined($writefailon) && $writefailon>0){  #undo 
         for(my $c=0;$c<=$#dep;$c++){
            my $writerec=$dep[$c];
            $self->SUPER::ValidatedUpdateRecord($dep[$c],$writerec,
                                            {$idfield=>$dep[$c]->{$idfield}});
         }
         $self->unlockWorktable();
         return(undef);
      }
      $self->unlockWorktable();
     
      return($bak);
   }
   $self->LastMsg(ERROR,"can't lock tables: ".$lockFail);
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   my $idobj=$self->IdField();
   if (!defined($idobj)){
      return(0);
   }
   my $g=$self->Clone();
   my $grpid=$rec->{$idobj->Name()};
   $g->SetFilter({"parentid"=>\$grpid});
   if ($g->CountRecords()>0){
      return(0);
   }
   return(1);
}




1;
