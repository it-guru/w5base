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


sub Init
{
   my $self=shift;


   $self->RegisterEvent("SIMonRefresh","SIMonRefresh");
   $self->RegisterEvent("SIMonNotify","SIMonNotify");
   return(1);
}




sub SIMonNotify
{
   my $self=shift;
   my %param=@_;

   my $wfa=getModuleObject($self->Config,"base::workflowaction");
   my $user=getModuleObject($self->Config,"base::user");

   my $StreamDataobj="SIMon::lnkmonpkgrec";
   my $datastream=getModuleObject($self->Config,$StreamDataobj);
   my $opobj=$datastream->Clone();

   if (exists($param{debug})){
      $datastream->SetFilter({
         system=>$param{debug},
         reqtarget=>['RECO','MAND'],
         curinststate=>\'NOTFOUND',
         exceptreqtxt=>'',     # noch keine Ausnahme beantragt
         needrefresh=>\'0'     # notwendig falls die rules angepasst wurden
      });

   }
   else{
      $datastream->SetFilter({
         cistatusid=>[3,4],
         systemidate=>"<now-28d",  # send mails at earliest after 4 weeks
         reqtarget=>['RECO','MAND'],
         curinststate=>\'NOTFOUND',
         exceptreqtxt=>'',     # noch keine Ausnahme beantragt
         needrefresh=>\'0',    # notwendig falls die rules angepasst wurden
         notifydate=>\undef
      });
   }




   $datastream->SetCurrentView("ALL");
   $datastream->SetCurrentOrder("systemidate");
   my ($rec,$msg)=$datastream->getFirst();
   my $c=0;
   if (defined($rec)){
      NREADLOOP: do{
         $c++;
         my %notifyparam;
         msg(INFO,"($c) ipkg:".$rec->{monpkgid}.
                  " on sys:".$rec->{system}." req=".$rec->{reqtarget}.
                  " curstate=".$rec->{curinststate});
         my %emailto; 
         my %emailcc; 

         my %tsm;
         my %tsm2;
         my %applmgr;

         my %applid;
         my $las=$datastream->getPersistentModuleObject("itil::lnkapplsystem");
         $las->SetFilter({systemid=>$rec->{systemid},applcistatusid=>"<6"});
         my @l=$las->getHashList(qw(applid));
         foreach my $r (@l){
            $applid{$r->{applid}}++ if ($r->{applid} ne "");
         }
         my $apo=$datastream->getPersistentModuleObject("itil::appl");
         $apo->SetFilter({id=>[keys(%applid)],cistatusid=>"<6"});
         my @l=$apo->getHashList(qw(tsmid tsm2id applmgrid));
         foreach my $r (@l){
            $tsm{$r->{tsmid}}++ if ($r->{tsmid} ne "");
            $tsm2{$r->{tsm2id}}++ if ($r->{tsm2id} ne "");
            $tsm2{$r->{applmgrid}}++ if ($r->{applmgrid} ne "");
         }
         if (keys(%tsm)){   # known - so we addres him at first
            foreach my $tsmid (keys(%tsm)){
               $emailto{$tsmid}++ if ($tsmid ne "");
            }
            $emailcc{$rec->{databossid}}++ if ($rec->{databossid} ne "");
            $emailcc{$rec->{adm2id}}++ if ($rec->{adm2id} ne "");
            $emailcc{$rec->{admid}}++ if ($rec->{admid} ne "");
         }
         else{              # alternativ process without tsm
            if ($rec->{admid} ne ""){
               $emailto{$rec->{admid}}++;
               $emailcc{$rec->{adm2id}}++ if ($rec->{adm2id} ne "");
               $emailcc{$rec->{databossid}}++ if ($rec->{databossid} ne "");
            }
            else{
               $emailto{$rec->{databossid}}++ if ($rec->{databossid} ne "");
               $emailcc{$rec->{adm2id}}++ if ($rec->{adm2id} ne "");
               $emailcc{$rec->{admid}}++ if ($rec->{admid} ne "");
            }
         }
         foreach my $tsm2id (keys(%tsm2)){
            $emailcc{$tsm2id}++ if ($tsm2id ne "");
         }
         foreach my $applmgrid (keys(%applmgr)){
            $emailcc{$applmgrid}++ if ($applmgrid ne "");
         }

         my @emailto=keys(%emailto);
         my @emailcc;

         foreach my $userid (keys(%emailcc)){
            push(@emailcc,$userid) if (!in_array($userid,\@emailto));
         }
         $user->ResetFilter();
         $user->SetFilter({userid=>\@emailto});
         my ($urec,$msg)=$user->getOnlyFirst(qw(fullname talklang));
         if (defined($urec)){
            $notifyparam{emailto}=\@emailto;
            $notifyparam{emailcc}=\@emailcc;
            $notifyparam{emailbcc}=[qw(11634953080001)];
            my $lastlang;
            if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
               $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
            }
            if ($urec->{talklang} ne ""){
               $ENV{HTTP_FORCE_LANGUAGE}=$urec->{talklang};
            }
            my $subject=$rec->{monpkg};
            $subject.=" ";
            $subject.=$opobj->T("on");
            $subject.=" ";
            $subject.=$rec->{system};
            $subject.=" ";
            if ($rec->{reqtarget} eq "MAND"){
               $subject.=$opobj->T("mandatory");
            }
            else{
               $subject.=$opobj->T("recommended");
            }

            my $text="";

            $text.=$opobj->T("The installation package");
            $text.="...\n\n   ";
            $text.="<b>";
            $text.=$rec->{monpkg};
            $text.="</b>\n";
            $text.="   ".$rec->{urlofcurrentrec}."\n";
            $text.="\n.... ";
            if ($rec->{monpkgrestrictarget} eq "MAND"){
               $text.=$opobj->T("needs to be installed");
               $text.="<b>(mandatory)</b>";
            }
            else{
               $text.=$opobj->T("should be installed");
               $text.="<b>(recommended)</b>";
            }
            $text.=".\n\n";
            $text.=$opobj->T("Target");
            $text.=" ";
            $text.=$opobj->T("on logical system");
            $text.=" ";
            $text.="<b>".$rec->{system}."</b>.\n\n";
            if ($rec->{reqtarget} eq "MAND"){
               $text.=$opobj->T("If there are reasons, why the software ".
                                "can not be installed or you would not ".
                                "install the software, you can write a ".
                                "exception justification at");
               $text.="\n";
               $text.=$rec->{urlofcurrentrec}."\n";
               $text.="\n";
            }
            my $notifycomments=extractLangEntry($rec->{notifycomments},
                                                $urec->{talklang},
                                                100000,1);
            if ($notifycomments ne ""){
               $text.="\n";
               $text.="<b><u>".$opobj->T("Installation-Hints").":</u></b>\n";
               $text.=$notifycomments."\n\n";
            }
            my $mode="INFO";
            if ($rec->{reqtarget} eq "MAND"){
               $mode="WARN";
            } 
            $notifyparam{emailcategory}=['SIMon','InstallRequestHint'];
            $wfa->Notify($mode,$subject,$text,%notifyparam); 
           
           
            my $bk=$opobj->ValidatedUpdateRecord($rec,{
               mdate=>$rec->{mdate},
               notifydate=>NowStamp("en")
            },{id=>\$rec->{id}});

            if (defined($lastlang)){
               $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
            }
            else{
               delete($ENV{HTTP_FORCE_LANGUAGE});
            }
         }


         ($rec,$msg)=$datastream->getNext();
         if (defined($msg)){
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>1,msg=>$msg});
         }
      }until(!defined($rec) || $c>5000);
   }
   return({exitcode=>0,exitmsg=>'ok'});
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
   my $notifyResetCount=0;


   $datastream->ResetFilter();
   $datastream->SetFilter({neednotifyreset=>\'1'});
   my @l=$datastream->getHashList(qw(ALL));
   msg(INFO,"need reset of ".($#l+1)." notification records");
   foreach my $rec (@l){
      my $bk=$opobj->ValidatedUpdateRecord($rec,{
         notifydate=>undef,
         mdate=>NowStamp("en")
      },{id=>\$rec->{id}});
      msg(INFO,"reset for $rec->{system} bk=$bk");
      $notifyResetCount++;
   }

   if (exists($param{debug}) &&
       $param{debug} ne ""){
      $datastream->ResetFilter();
      $datastream->SetFilter([
        {id=>$param{debug}},
        {system=>$param{debug}}
      ]);

   }
   else{
      $datastream->ResetFilter();
      $datastream->SetFilter([
        {
           systemcistatusid=>[3,4],
           id=>\undef,
           systemidate=>"<now-14d" # create mon rec after 2 weeks
        },  
        {
           systemcistatusid=>[3,4],
           needrefresh=>\'1'
        },
        {  # add an automatic recalculation for active systems once a month 
           systemcistatusid=>[3,4],
           mdate=>'<now-1M'
        }
      ]);
   }

   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   $datastream->SetCurrentView(@datastreamview);
   $datastream->SetCurrentOrder("systemid");
   my ($rec,$msg)=$datastream->getFirst();
   my $refreshCount=0;
   if (defined($rec)){
      READLOOP: do{
         $refreshCount++;
         if ($opmode eq "dev"){
            msg(INFO,sprintf("%6d",$refreshCount)." processing ".$rec->{system}.
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

         ($rec,$msg)=$datastream->getNext();
         if (defined($msg)){
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>1,msg=>$msg});
         }
      }until(!defined($rec)||$refreshCount>1999);
           # max. 2000 recalculations per hour(run)
   }

   return({
      exitcode=>0,
      exitmsg=>"ok; ".
               "notifyResetCount=$notifyResetCount; ".
               "refreshCount=$refreshCount"
   });
}


1;
