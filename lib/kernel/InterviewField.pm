package kernel::InterviewField;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use kernel;
use strict;
use Text::ParseWhere;

sub getTotalActiveQuestions
{
   my $self=shift;
   my $parentobj=shift;
   my $idname=shift;
   my $id=shift;
   my $answered=shift;
   my %contextCache;
   my $lang=$self->getParent->Lang();
   my $userid=$self->getParent->getCurrentUserId();



   my $p=getModuleObject($self->getParent->Config,$parentobj);
   $p->ResetFilter();
   $p->SetFilter({$idname=>\$id});
   my ($rec,$msg)=$p->getOnlyFirst(qw(ALL));

   if (exists($rec->{mandatorid}) && $rec->{mandatorid} ne ""){
      my $lq=getModuleObject($self->getParent->Config,"base::lnkqrulemandator");
      my $parentflt=$parentobj;
      $parentflt=~s/^.*::/*::/;
      $lq->SetFilter({mandatorid=>\$rec->{mandatorid},dataobj=>$parentflt,
                      cistatusid=>\'4'});
      my @l=$lq->getHashList(qw(dataobj mandatorid));
      my %tparent;
      foreach my $lqrec (@l){
         if ($lqrec->{dataobj} ne "" &&  $lqrec->{mandatorid} ne "" &&
             $lqrec->{mandatorid} ne "0"){
            $tparent{$lqrec->{dataobj}}++;
         }
      }
      my @keytparent=keys(%tparent);
      if ($#keytparent==0){
         msg(INFO,"interview parent transformation from $parentobj to ".
                  $keytparent[0]."::".$id);
         $p=getModuleObject($self->getParent->Config,$keytparent[0]);
         $p->ResetFilter();
         $p->SetFilter({$idname=>\$id});
         ($rec,$msg)=$p->getOnlyFirst(qw(ALL));
      }
      elsif ($#keytparent==-1){
         msg(INFO,"no qrules for interview parent transformation ".
                  "${parentobj}::".$id);
      } 
      else{
         msg(ERROR,"not unique interview parent transformation ".
                  "${parentobj}::".$id);
      }
   }

   #my $ic=getModuleObject($self->getParent->Config,"base::interviewcat");
   #$ic->SetCurrentView(qw(id fulllabel));
   #my $icat=$ic->getHashIndexed(qw(id));  # cache categorie labels

   my $i=getModuleObject($self->getParent->Config,"base::interview");
   $i->SetFilter([
     {parentobj=>\$parentobj,cistatusid=>[3,4],ifrom=>"[EMPTY]",ito=>"[EMPTY]"},
     {parentobj=>\$parentobj,cistatusid=>[3,4],
                         ifrom=>"<now",ito=>"[EMPTY]"},
     {parentobj=>\$parentobj,cistatusid=>[3,4],
                         ifrom=>"[EMPTY]",ito=>">now"},
     {parentobj=>\$parentobj,cistatusid=>[3,4],
                         ifrom=>"<now",ito=>">now"}
   ]);
   my $pwrite=$i->checkParentWrite($p,$rec);
   my @viewlist=$i->getParentViewgroups($p,$rec);
   my %boundpviewgroupAcl=$p->InterviewPartners($rec);
   
   my @l;
   foreach my $irec ($i->getHashList(qw(queryblock questclust interviewcattree
                                        qtag id name qname prio
                                        boundpviewgroup addquestdata
                                        interviewcatid contactid contact2id
                                        boundpcontact necessverifyinterv
                                        questtyp restriction
                                        allownotrelevant))){
      my $restok=1;
      if ($irec->{restriction} ne ""){
         $restok=0;
         my $p=new Text::ParseWhere();
         my $pcode=$p->compileExpression($irec->{restriction});
         if (defined($pcode) && &{$pcode}($rec)){
            $restok=1;
         }
      }
      if ($restok){
         my $write=$i->checkAnserWrite($pwrite,$irec,$p,$rec,\%contextCache);
         if (!$write){
            my $tag=$irec->{boundpcontact}."";
            if (exists($boundpviewgroupAcl{$tag}) &&
                in_array($boundpviewgroupAcl{$tag},$userid)){
               $write++;
            }
         }

         my ($HTMLanswer,$HTMLrelevant,$HTMLcomments,$HTMLVerifyButton,$HTMLjs)=
            $i->getHtmlEditElements($write,$irec,
                         $answered->{interviewid}->{$irec->{id}},$p,$rec);
         $irec->{'HTMLanswer'}=$HTMLanswer;
         $irec->{'HTMLverify'}=$HTMLVerifyButton;
         $irec->{'HTMLrelevant'}=$HTMLrelevant;
         $irec->{'HTMLcomments'}=$HTMLcomments;
         $irec->{'HTMLjs'}=$HTMLjs;
         $irec->{'AnswerViewable'}=1;
         if ($irec->{boundpviewgroup} ne ""){
            my $q=quotemeta($irec->{boundpviewgroup});
            if (!grep(/^($q|ALL)$/,@viewlist)){
               $irec->{'AnswerViewable'}=0;
               $irec->{'HTMLanswer'}="-";
               $irec->{'HTMLverify'}="-";
               $irec->{'HTMLrelevant'}="-";
               $irec->{'HTMLcomments'}="-";
               $irec->{'HTMLjs'}="";
            }
         }
         if ($irec->{name} eq ""){
            $irec->{name}="no question text";
         }
         $irec->{questclust}=extractLangEntry($irec->{questclust},$lang,80,0);
         push(@l,$irec);
      }
   }
   return(\@l);
}


sub getAnsweredQuestions
{
   my $self=shift;
   my $parentobj=shift;
   my $idname=shift;
   my $id=shift;

   my $i=getModuleObject($self->getParent->Config,"base::interanswer");
   $i->SetFilter({parentobj=>\$parentobj,
                  parentid=>\$id});
   $i->SetCurrentView(qw(interviewid answer relevant archiv comments
                         lastverify needverify answerlevel));

   my $ial=$i->getHashIndexed(qw(interviewid));

   return($ial);
}

sub buildHtmlEditEntry
{
   my $self=shift;
   my $mode=shift;

}


package kernel::InterviewField::qStat;

use strict;
use vars qw(@ISA);
use kernel;
use Tie::Hash;

@ISA=qw(Tie::Hash);

sub TIEHASH
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}



1;
