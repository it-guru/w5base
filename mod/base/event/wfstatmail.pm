package base::event::wfstatmail;
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


   $self->RegisterEvent("wfstatmail","SendMyJobs");
   $self->RegisterEvent("wfstatsend","SendMyJobs");
   return(1);
}

sub SendMyJobs
{
   my $self=shift;
   my @target=@_;

   my $ia=getModuleObject($self->Config,"base::infoabo");
   my $user=getModuleObject($self->Config,"base::user");
   my @flt;
   $flt[0]={usertyp=>\'user',cistatusid=>\'4'};
   #$flt->{fullname}="vogl* bichler* *hanno.ernst*";
   #$flt->{fullname}="ladegast* ernst*";
   if ($#target==-1){
      $flt[0]->{groups}=["DTAG.TSI.ES.ITO.CSS.T-Com.ST.DB",
                         "DTAG.TSI.ES.ITO.CSS.T-Com.ST.DeM",
                         "DTAG.TSI.ES.ITO.CSS.T-Com.PMAQ.QSO",
                         "DTAG.TSI.ES.ITO.CSS.T-Com.GHS-TSI.GT2",
                         "DTAG.TSI.ES.ITO.CSS.OSS.OCTC.T-Com.C3",
                         "DTAG.TSI.ES.ITO.CSS.T-Com.ST.WINDOWS",
                         "DTAG.TSI.ES.ITO.CSS.T-Com.PMAQ.QSC"];
   }
   else{
      my %f=%{$flt[0]};
      $flt[1]=\%f;
      $flt[0]->{groups}=\@target;
      $flt[1]->{email}=\@target;
   }
   $user->SetFilter(\@flt);
   $user->SetCurrentView(qw(userid fullname email accounts lang lastlang));
   my $wf=getModuleObject($self->Config,"base::MyW5Base::wfmyjobs");
   $wf->setParent($self);

   my $now=NowStamp("en");
   my $baseurl=$self->Config->Param("EventJobBaseUrl");
   my ($urec,$msg)=$user->getFirst();
   if (defined($urec)){
      do{
         #######################################################################
         my $userlang="";
         if ($urec->{lastlang} ne ""){
            $userlang=$urec->{lastlang};
         }
         if ($userlang eq ""){
            $userlang=$urec->{lang};
         }
         $userlang eq "en" if ($userlang eq "");
         #######################################################################

         my $emailto={};
         $ia->LoadTargets($emailto,'base::staticinfoabo',\'STEVwfstatsendWeek',
                                   '110000003',[$urec->{userid}],default=>1);
         if (ref($urec->{accounts}) eq "ARRAY" &&
             $#{$urec->{accounts}}>-1 && keys(%{$emailto})>0){
            $ENV{HTTP_FORCE_LANGUAGE}=$userlang;
            my $accounts=join(", ",map({$_->{account}} @{$urec->{accounts}}));
            $wf->ResetFilter();
            $wf->SetFilter({userid=>$urec->{userid}});
            my @l=$wf->getHashList(qw(mdate id name nature stateid));
            my @emailtext;
            my @emailpostfix;
            my @emailprefix;
            my $wfcount=0;
            foreach my $wfrec (@l){
               my $imgtitle=$wfrec->{name};
               my $wfheadid=$wfrec->{id};
               my $dur=CalcDateDuration($wfrec->{mdate},$now,"GMT");
               my $emailprefix;
               my $color="black";
               my $bold1="";
               my $bold0="";
               if ($dur->{days}>1 && $wfrec->{stateid}!=5){ # list no defereds
                  $wfcount++;                             
                  if ($wfcount<50){
                     if ($wfrec->{stateid}<17){
                        if ( ($wfrec->{prio}<3 && $dur->{days}>3) ||
                             ($wfrec->{prio}<6 && $dur->{days}>14) ||
                             ($dur->{days}>30)){
                           $color="red";
                        }
                        if ($dur->{days}>60){
                           $bold1="<b>";
                           $bold0="</b>";
                        }
                     }
                     my $msg=$self->T("unprocessed\nsince \%d days");
                     $msg=~s/\n/<br>/g;
                          
                     $emailprefix=
                         sprintf("<div style=\"padding:2px;color:$color\">".
                                  "$bold1$msg$bold0</div>",$dur->{days});
                     push(@emailprefix,$emailprefix);
                     if ($baseurl ne ""){
                        my $lang="?HTTP_ACCEPT_LANGUAGE=$userlang";
                        my $imgtitle="current state of workflow";
                        my $emailpostfix=
                               "<img title=\"$imgtitle\" class=status border=0 ".
                               "src=\"$baseurl/public/base/workflow/ShowState/".
                               "$wfheadid$lang\">";
                        push(@emailpostfix,$emailpostfix);
                     }
                     my $wfname=$wfrec->{name};
                     if ($baseurl ne ""){
                        $wfname.="\n".$baseurl."/auth/base/workflow/ById/".
                                 $wfheadid;
                     }
                     push(@emailtext,$wfname);
                  }
                  elsif($wfcount==50){
                    push(@emailtext,"...");
                    push(@emailpostfix,"");
                    push(@emailprefix,"");
                  }
               }
            }
            if ($#wfcount>0){
               my $infoabo=join(",",map({@{$_}} values(%{$emailto})));
               if ($baseurl ne ""){
                  $self->sendNotify(emailtext=>\@emailtext,
                                    emailpostfix=>\@emailpostfix,
                                    emailprefix=>\@emailprefix,
                                    additional=>{contact=>$urec->{fullname},
                                                 wfcount=>$wfcount,
                                                 accounts=>$accounts,
                                                 baseurl=>$baseurl,
                                                 infoabo=>$infoabo,
                                                },
                                    emailfrom=>[keys(%{$emailto})],
                                    emailto=>[keys(%{$emailto})]);
               }
            }
         }
         delete($ENV{HTTP_FORCE_LANGUAGE});
         ($urec,$msg)=$user->getNext();
      }until(!defined($urec));
   }

   return({msg=>'OK',exitcode=>0});
}


sub sendNotify
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my %rec=@_;
   my $sitename=$wf->Config->Param("SITENAME");

   $rec{class}='base::workflow::mailsend';
   $rec{step}='base::workflow::mailsend::dataload';
   $rec{name}=$self->T('weekly report current jobs');
   if ($sitename ne ""){
      $rec{name}=$sitename.": ".$rec{name};
   }
   if (defined($rec{additional}->{wfcount})){
      $rec{name}.=" (".$rec{additional}->{wfcount}.")";
   }
   $rec{emailtemplate}='wfstatmail';
   #$rec{emailcc}=['hartmut.vogler@t-systems.com'];
   #       emaillang     =>$lang,

   if (my $id=$wf->Store(undef,\%rec)){
      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
  }


}

1;
