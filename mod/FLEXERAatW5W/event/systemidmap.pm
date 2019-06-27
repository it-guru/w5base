package FLEXERAatW5W::event::systemidmap;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{fieldlist}=[qw(systemname flexerasystemid mapstate)];
   $self->{name}="Flexera SystemID Mapper";

   return($self);
}

sub Init
{
   my $self=shift;
   $self->RegisterEvent("systemidmap","systemidmap");

}


sub systemidmap 
{
   my $self=shift;

   my $rmap=getModuleObject($self->Config,"FLEXERAatW5W::rawsystemidmapof");
   my $smap=getModuleObject($self->Config,"FLEXERAatW5W::syssystemidmap");
   my $fchk=getModuleObject($self->Config,"FLEXERAatW5W::syssystemidmap");
   $smap->SetFilter({mapstate=>[undef,""]});
   my $sys=getModuleObject($self->Config,"itil::system");
   my $amsys=getModuleObject($self->Config,"tsacinv::system");
   my $mcreccnt=0;
   my $newmaprec=0;
   foreach my $mrec ($smap->getHashList(qw(ALL))){
      $mcreccnt++;
      last if ($newmaprec>1000);
      my $systemname=$mrec->{systemname};
      $systemname=~s/\*//g;
      $systemname=~s/\?//g;
      $systemname=~s/\s//g;
      my @l;
      if ($systemname ne ""){
         $sys->ResetFilter();
         $sys->SetFilter({name=>$systemname,cistatusid=>"<6"});
         @l=$sys->getHashList(qw(name systemid id));
      }
      my $mapstate="FAIL";
      my $systemid="";
      if ($#l==-1){
         my $amname=uc($systemname);
         $amsys->ResetFilter();
         $amsys->SetFilter({systemname=>\$amname,
                            status=>"\"!out of operation\""});
         @l=$amsys->getHashList(qw(systemname systemid));
      }
      if ($#l==-1){
         $mapstate="NOT FOUND";
      }
      elsif ($#l>0){
         $mapstate="NOT UNIQUE";
      }
      elsif ($#l==0){
         $mapstate="OK";
         $systemid=$l[0]->{systemid};
      }
      if ($self->Config->Param("W5BaseOperationMode") eq "online" ||
          $self->Config->Param("W5BaseOperationMode") eq "dev" ||
          $self->Config->Param("W5BaseOperationMode") eq "normal"){
         my $comment=$mrec->{cmt};
         if ($systemid ne ""){
            $rmap->ResetFilter();
            $rmap->SetFilter({id=>"!".$mrec->{id},systemid=>\$systemid});
            my ($rchkrec,$msg)=$rmap->getOnlyFirst(qw(ALL)); 
            if (defined($rchkrec)){
               msg(ERROR,"found id move from $rchkrec->{id} ".
                         "to $mrec->{id} in systemid $systemid");
               $rmap->BulkDeleteRecord({id=>\$rchkrec->{id}});
            }
            $fchk->ResetFilter();
            $fchk->SetFilter({systemid=>\$systemid});
            my ($chkrec,$msg)=$fchk->getOnlyFirst(qw(ALL)); 
            if (defined($chkrec)){
               $fchk->ValidatedUpdateRecord($chkrec,{systemid=>''},
                                            {id=>$chkrec->{id}});
               $comment.="\nReplace flexeraid=$chkrec->{id}\n";
            }
         }
         $newmaprec++;
         my $bk=$smap->ValidatedUpdateRecord($mrec,{
            systemid=>$systemid,
            mapstate=>$mapstate,
            cmt=>$comment,
            owner=>\undef
         },{id=>$mrec->{id}});
      }
   }
   $smap->ResetFilter();
   $smap->SetFilter({mapstate=>'"FAIL" "NOT FOUND" "NOT UNIQUE"'});

   my $start=NowStamp("en");
   my $o=$rmap->Clone();
   $o->BackendSessionName("DelSession-$$");
   $o->BulkDeleteRecord({mapstate=>\'NOT FOUND',mdate=>'<now-14d'});
   if ($mcreccnt>2000){
      msg(WARN,"record count=$mcreccnt");
   }
   return(0);
}





1;
