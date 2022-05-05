package SIMon::event::SIMonRefresh;
#  W5Base Framework
#  Copyright (C) 2022  Markus Zeis (w5base@zeis.email)
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

   return($self);
}


sub SIMonRefresh
{
   my $self=shift;
   my %param=@_;
   my %exprCode;

   my $StreamDataobj="SIMon::lnkmonpkgrec";
   my @datastreamview=qw(id systemid monpkgid system monpkg rawreqtarget
                         monpkgrestriction
                         monpkgrestrictarget);

   my $system=getModuleObject($self->Config,"itil::system");
   my $datastream=getModuleObject($self->Config,$StreamDataobj);
   my $opobj=$datastream->Clone();

   if (exists($param{debug}) &&
       $param{debug} ne ""){
      $datastream->SetFilter([
        {id=>$param{debug}},
        {system=>$param{debug}}
      ]);

   }
   else{
      $datastream->SetFilter([
        {id=>\undef},
        {needrefresh=>\'1'}
      ]);
   }

   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   $datastream->SetCurrentView(@datastreamview);
   $datastream->SetCurrentOrder("systemid");
   my ($rec,$msg)=$datastream->getFirst();
   my $c=0;
   if (defined($rec)){
      READLOOP: do{
         $c++;
         if ($opmode eq "dev"){
            msg(INFO,sprintf("%6d",$c)." processing ".$rec->{system}.
                     " in pkg ".$rec->{monpkg});
         }
         my $newtarget=$rec->{monpkgrestrictarget};
         if ($rec->{monpkgrestriction} ne ""){
            $newtarget="NEDL";
            $system->ResetFilter();
            $system->SetFilter({id=>\$rec->{systemid}});
            my ($sysrec)=$system->getOnlyFirst(qw(ALL));
            if (!exists($exprCode{$rec->{monpkgid}})){
               my $p=new Text::ParseWhere();
               if (my $pcode=$p->compileExpression($rec->{monpkgrestriction})){
                  $exprCode{$rec->{monpkgid}}=$pcode;
               }
            }
            if (exists($exprCode{$rec->{monpkgid}})){
               if (&{$exprCode{$rec->{monpkgid}}}($sysrec)){
                  $newtarget=$rec->{monpkgrestrictarget};
               }
            }
         }

         if ($rec->{id} eq ""){
            my $bk=$opobj->ValidatedInsertRecord({
               monpkgid=>$rec->{monpkgid},
               systemid=>$rec->{systemid},
               rawreqtarget=>$newtarget
            });
         }
         else{
            my $bk=$opobj->ValidatedUpdateRecord($rec,{
               rawreqtarget=>$newtarget,
               mdate=>NowStamp("en")
            },{id=>\$rec->{id}});
         }

         if ($c>5000){
            last;
         }

         ($rec,$msg)=$datastream->getNext();
         if (defined($msg)){
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>1,msg=>$msg});
         }
      }until(!defined($rec));
   }





   return({exitcode=>0,exitmsg=>'ok'});
}


1;
