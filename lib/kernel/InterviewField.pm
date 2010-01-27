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
   my $p=getModuleObject($self->getParent->Config,$parentobj);
   $p->SetFilter({$idname=>\$id});
   my ($rec,$msg)=$p->getOnlyFirst(qw(ALL));

   my $i=getModuleObject($self->getParent->Config,"base::interview");
   $i->SetFilter({parentobj=>\$parentobj,
                  cistatusid=>[3,4]});
   my $pwrite=$i->checkParentWrite($p,$rec);
   my @l;
   foreach my $irec ($i->getHashList(qw(queryblock questclust 
                                        qtag id name qname prio
                                        questtyp restriction))){
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
         my $write=$i->checkAnserWrite($pwrite,$irec,$p,$rec);
         my ($HTMLanswer,$HTMLrelevant,$HTMLcomments)=
            $i->getHtmlEditElements($write,$irec,
                         $answered->{interviewid}->{$irec->{id}},$p,$rec);
         $irec->{HTMLanswer}=$HTMLanswer;
         $irec->{HTMLrelevant}=$HTMLrelevant;
         $irec->{HTMLcomments}=$HTMLcomments;
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
   $i->SetCurrentView(qw(interviewid answer relevant archiv comments));

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
