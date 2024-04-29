package base::event::w5stat;
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
use kernel::date;
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


   $self->RegisterEvent("w5stat","w5stat",timeout=>7200);
   $self->RegisterEvent("w5statrecreate","w5statrecreate",timeout=>7200);
   $self->RegisterEvent("w5stattrace","w5stattrace",timeout=>7200);
   $self->RegisterEvent("w5statsend","w5statsend");
   return(1);
}


sub w5stattrace
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $dstrange=shift;

   return($self->w5statrecreate($statstream,$module,$dstrange));
}




sub w5statrecreate
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $dstrange=shift;
   my @dstrange;

   if ($statstream eq "*" || $statstream eq "w5stat"){
      $statstream="default";
   } 
   $module="*" if (!defined($module));
   if (!defined($dstrange)){
      my ($year,$mon,$day, $hour,$min,$sec) = Today_and_Now("GMT");
      $dstrange=sprintf("%04d%02d",$year,$mon);
      push(@dstrange,$dstrange);
      my ($week,$year)=Week_of_Year($year,$mon,$day);
      my $dstrange=sprintf("%04dKW%02d",$year,$week);
      push(@dstrange,$dstrange);
   }
   else{
      push(@dstrange,$dstrange);
   }


   my $stat=getModuleObject($self->Config,"base::w5stat");
   my $res=$stat->W5ServerCall("rpcMultiCacheQuery",$ENV{REMOTE_USER});
   $res={} if (!defined($res));
   if (!$stat->ValidateMandatorCache($res->{Mandator})){
      return({
         exitcode=>10,
         exitmsg=>'can not communicate to w5server',
      });
   }
   ############################################################
   # check on trace                                           #
   ############################################################
   if ((caller(1))[3] eq "base::event::w5stat::w5stattrace"){
      $stat->setTraceFile("/tmp/w5stattrace.txt");
   }
   ############################################################

   foreach my $dstrange (@dstrange){
      $stat->Trace("start dstrange $dstrange");
      msg(INFO,"call recreateStats for Module '$module' in ".
               "dstrange '$dstrange'");
      $stat->recreateStats($statstream,"w5stat",$module,$dstrange);
   }
   $stat->Trace("start loadLateModifies");
   $stat->loadLateModifies($statstream,\@dstrange);

   return({exitcode=>0});
}

sub w5stat
{
   my $self=shift;
   my $module=shift;
   my $dstrange=shift;

   return($self->w5statrecreate("default",$module,$dstrange));
}







sub w5statsend
{
   my $self=shift;
   my $force=shift;

   my ($year,$mon,$day, $hour,$min,$sec)=Today_and_Now("GMT");
   



   my $month=sprintf("%04d%02d",$year,$mon);
   my $forcesend=0;
   {
      my ($year1,$mon1,$day1, $hour1,$min1,$sec1)=
              Add_Delta_YMD("GMT",$year,$mon,$day,0,0,7);
      if ($mon!=$mon1){
         $forcesend=1;
      }
   }
   if (lc($force) eq "force" ||
       lc($force) eq "-force"){
      $forcesend=1;
   }

   my $w5stat=getModuleObject($self->Config,"base::w5stat");
   my $user=getModuleObject($self->Config,"base::user");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $ia=getModuleObject($self->Config,"base::infoabo");
   my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
   my $lnkrole=getModuleObject($self->Config,"base::lnkgrpuserrole");
   $grp->SetFilter({cistatusid=>[3,4]});
   my ($send,$notsend,$notneeded)=(0,0,0);
   my $MinReportUserGroupCount=$self->Config->Param("MinReportUserGroupCount");
   $MinReportUserGroupCount=int($MinReportUserGroupCount);
   #$grp->SetFilter({cistatusid=>[3,4],fullname=>"*t-com.st"});
   #$grp->SetFilter({cistatusid=>[3,4],fullname=>"*.ST.DB"});
   #$grp->SetFilter({cistatusid=>[3,4],fullname=>"DTAG.TSI.Prod.CS.SAPS.EG.TelCo2.CF"});
   #$grp->SetFilter({cistatusid=>[3,4],fullname=>"DTAG.GHQ.VTS.TSI.TI.E-TSO.AO"});
   #$grp->SetFilter({cistatusid=>[3,4],fullname=>"DTAG.GHQ.VTI.DTIT.E-DTO.E-DTOPT.E-DTOPT02"});
   $grp->SetCurrentView(qw(grpid fullname description));
   my ($rec,$msg)=$grp->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         my $emailto={};
         msg(INFO,"start processing group $rec->{fullname}");
         $lnkgrp->ResetFilter();
         $lnkgrp->SetFilter({grpid=>\$rec->{grpid}});
         my @RBoss;
         my @tempRBoss;
         my @RReportReceive;
         foreach my $lnkrec ($lnkgrp->getHashList(qw(userid lnkgrpuserid))){
            $lnkrole->ResetFilter();
            $lnkrole->SetFilter({lnkgrpuserid=>\$lnkrec->{lnkgrpuserid}});
            foreach my $lnkrolerec ($lnkrole->getHashList("role")){
               if ($lnkrolerec->{role} eq "RBoss"){
                  push(@tempRBoss,$lnkrec->{userid});
               }
               if ($lnkrolerec->{role} eq "RReportReceive"){
                  push(@RReportReceive,$lnkrec->{userid});
               }
            }
         }
         # extract active Bosses
         $user->SetFilter({userid=>\@tempRBoss,cistatusid=>'<=4'});
         foreach my $urec ($user->getHashList("userid")){
            push(@RBoss,$urec->{userid});
         }

         if ($#RReportReceive==-1){
            $ia->LoadTargets($emailto,'base::staticinfoabo',\'STEVqreportbyorg',
                                      '110000002',\@RBoss,default=>1);
         }
         $user->ResetFilter();
         $user->SetFilter({userid=>\@RReportReceive,cistatusid=>'<=4'});
         foreach my $urec ($user->getHashList("email")){
            if ($urec->{email} ne ""){
               $emailto->{$urec->{email}}++;
            }
         }
         if (keys(%$emailto)){
            my @emailto=keys(%$emailto);
            msg(INFO,"process group $rec->{fullname}($rec->{grpid})");
            
            $w5stat->ResetFilter();
            $w5stat->SetFilter([{dstrange=>\$month,
                                 nameid=>\$rec->{grpid},
                                 statstream=>\'default',
                                 sgroup=>\'Group'},
                                {dstrange=>\$month,
                                 fullname=>\$rec->{fullname},
                                 statstream=>\'default',
                                 sgroup=>\'Group'}]);
            my ($chkrec,$msg)=$w5stat->getOnlyFirst(qw(id));
            if (defined($chkrec)){
               msg(INFO,"chk record found - now try to find id $chkrec->{id}");
               my ($primrec,$hist)=$w5stat->LoadStatSet(id=>$chkrec->{id});
               if (defined($primrec) &&
                   defined($w5stat->{w5stat}->{'base::w5stat::overview'})){
                  my $ucnt=0;
                  $ucnt=$primrec->{stats}->{User} if (ref($primrec) eq "HASH" &&
                                              ref($primrec->{stats}) eq "HASH");
                  $ucnt=$ucnt->[0] if (ref($ucnt) eq "ARRAY");
                  $ucnt=int($ucnt);
                  if ($ucnt<$MinReportUserGroupCount &&
                      $primrec->{nameid}>=2){
                     $notsend++;
                  }
                  else{
                     msg(INFO,"primrec ok and stat processor found");
                     my $obj=$w5stat->{w5stat}->{'base::w5stat::overview'};
                     my %P=$obj->getPresenter();
                     if (defined($P{'overview'}) &&
                         defined($P{'overview'}->{opcode})){
                        msg(INFO,"overview tag handler found");
                        foreach my $emailto (@emailto){
                           my $lang="";
                           $user->ResetFilter();
                           $user->SetFilter({email=>\$emailto});
                           my ($urec,$msg)=$user->getOnlyFirst(qw(lastlang 
                                                                  lang));
                           if (defined($urec)){
                              if ($urec->{lastlang} ne ""){
                                 $lang=$urec->{lastlang};
                              }
                              if ($lang eq ""){
                                 $lang=$urec->{lang};
                              }
                              $lang eq "en" if ($lang eq "");

              
                              $ENV{HTTP_FORCE_LANGUAGE}=$lang;
                              my ($d,$ovdata)=
                                   &{$P{overview}->{opcode}}($obj,
                                                               $primrec,$hist);
                              my $needsend=$forcesend;
                              foreach my $ovrec (@$ovdata){
                                 if (defined($ovrec->[2]) && 
                                     $ovrec->[2] eq "red"){
                                    $needsend=1;last;
                                 }
                              }
                              my $extdesc=$rec->{description};
                              my $extfullname=$primrec->{fullname};
                              my $fullname=$primrec->{fullname};
                              if (($extdesc=~m/http[s]{0,1}:/i)){
                                 $extdesc=undef;
                              }
                              my $desc=$extdesc;
                              if ($extdesc ne ""){
                                 $extdesc=~s/&/&amp;/g;
                                 $extdesc=~s/>/&gt;/g;
                                 $extdesc=~s/</&lt;/g;
                                 if ((length($extfullname)+
                                      length($extdesc))>75){
                                    if (length($extfullname)>45){
                                       $extfullname=TextShorter($extfullname,45,"DOTHIER");
                                    }
                                    if ((length($extfullname)+
                                         length($extdesc))>75){
                                       $extdesc=TextShorter($extdesc,30,"INDICATED");
                                    }
                                 }
                                 $extdesc="($extdesc)";
                              }
                              #msg(INFO,"target=$emailto lang=$lang ".
                              #         "needsend=$needsend");
                              #msg(INFO,"extdesc=$extdesc");
                              if ($needsend && 1){
                                 $send++;
                                 $self->sendOverviewData(
                                    $emailto,
                                    $lang,
                                    $primrec,
                                    $hist,
                                    $d,
                                    $ovdata,
                                    $fullname,
                                    $extfullname,
                                    $desc,
                                    $extdesc
                                 );
                              }
                              else{
                                 $notneeded++;
                              }
                              delete($ENV{HTTP_FORCE_LANGUAGE});
                           }
                        }
                     }
                     else{
                        msg(ERROR,"can not find w5stat overview handler");
                     }
                  }
               }
            }
         }
         ($rec,$msg)=$grp->getNext();
      }until(!defined($rec));
   }
   return({exitcode=>0,
           msg=>"send=>$send,notsend=>$notsend,notneeded=>$notneeded ".
                "MinReportUserGroupCount=$MinReportUserGroupCount"});
}

sub sendOverviewData
{
   my $self=shift;
   my $emailto=shift;
   my $lang=shift;
   my $primrec=shift;
   my $hist=shift;
   my $d=shift;
   my $ovdata=shift;
   my $fullname=shift;
   my $extfullname=shift;
   my $desc=shift;
   my $extdesc=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $sitename=$wf->Config->Param("SITENAME");
   my $joburl=$wf->Config->Param("EventJobBaseUrl");
   my @emailtext;
   foreach my $ovrec (@$ovdata){
      if ($#{$ovrec}==0){
         push(@emailtext,"---\n".$ovrec->[0]);
      }
      else{
         push(@emailtext,$ovrec->[0].": ".$ovrec->[1]);
      }
   }
   my $month=$primrec->{dstrange};
   my ($Y,$M)=$month=~m/^(\d{4})(\d{2})$/;
   my $month=sprintf("%02d/%04d",$M,$Y);
 
   if (my $id=$wf->Store(undef,{
          class    =>'base::workflow::mailsend',
          step     =>'base::workflow::mailsend::dataload',
          name     =>$sitename.": ".'QualityReport '.
                     $month." ".$primrec->{fullname},
          emailtemplate =>'w5stat',
          emaillang     =>$lang,
          emailfrom     =>$emailto,
          emailtext     =>\@emailtext,
          emailcategory =>['W5Base','QualityReport','Reporting','KPI'],
          emailto       =>$emailto,
          emailfrom     =>'"'.$sitename.'"'." <>",
          additional    =>{
             htmldata=>$d,month=>$month, 
             directlink=>$joburl."/auth/base/menu/msel/Reporting?search_id=".
                         $primrec->{id},
             fullname=>$primrec->{fullname},
             extfullname=>$extfullname,
             desc=>$desc,
             extdesc=>$extdesc
          },
         })){
      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
      return({msg=>'versandt'});
   }
}

1;
