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


   $self->RegisterEvent("wfstatmail","SendMyJobs",timeout=>14400);
   $self->RegisterEvent("wfstatsend","SendMyJobs",timeout=>14400);
   return(1);
}

sub SendMyJobs
{
   my $self=shift;
   my @target=@_;
   my $sendcount=0;

   my $ia=getModuleObject($self->Config,"base::infoabo");
   my $user=getModuleObject($self->Config,"base::user");
   my @flt;
   $flt[0]={usertyp=>['user','service'],cistatusid=>\'4'};
   #$flt[0]->{fullname}="vogl* bichler* *hanno.ernst*";
   #$flt->{fullname}="ladegast* ernst*";
   #$flt[0]->{userid}=12260596620002;
   if ($#target==-1){
      #
      # basierend auf der Entscheidung des MC AL DTAG werden die
      # reports über anstehende Aufgaben jetzt an alle Darwin Nutzer erstellt.
      #
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
   my $instdir=$self->Config->Param("INSTDIR");
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
         #$userlang="en";
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
            my @emailsubtitle;
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
                     if ($wfcount==1){
                       push(@emailsubtitle,
                            "<table cellspacing=5 border=0><tr><td><b><u>".
                            $user->T("Current pending workflows:").
                            "</b></u></td></tr></table>");
                     }
                     else{
                       push(@emailsubtitle,"");
                     }
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
                         sprintf("<div style=\"margin:5px;color:$color\">".
                                  "$bold1$msg$bold0</div>",$dur->{days});
                     push(@emailprefix,$emailprefix);
                     if ($baseurl ne ""){
                        my $lang="/$userlang";
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
                    push(@emailsubtitle,"");
                  }
               }
            }
            my $totaljobs=$wfcount;
            my $adcount=0;

            ##################################################################
            # check autodiscovery data
            if ( -f "${instdir}/mod/itil/autodiscrec.pm"){
               my $autodiscreco=getModuleObject($self->Config,
                                                "itil::autodiscrec");
               if (defined($autodiscreco)){
                  my $userid=$urec->{userid};
                  my @flt=(
                     { 
                       sec_sys_databossid=>\$userid, 
                       sec_sys_cistatusid=>"<6",
                       state=>\'1',
                       processable=>\'1' 
                     },
                     { 
                       sec_swi_databossid=>\$userid, 
                       sec_swi_cistatusid=>"<6",
                       state=>\'1',
                       processable=>\'1' 
                     }
                  );
                  $autodiscreco->SetFilter(\@flt);
                  $autodiscreco->SetCurrentView(qw(id));
                  my @cnt=$autodiscreco->getHashList(qw(id));
                  if ($#cnt!=-1){
                     $adcount=$#cnt+1;
                     $totaljobs+=($#cnt+1);
                  }
               }
            }
            my $openInterviews=0;

            my $itodo=getModuleObject($self->Config,"base::interviewtodocache");
            $itodo->SetFilter({userid=>$urec->{userid}});
            $itodo->SetCurrentView(qw(dataobject dataobjectid));
            my $itodos=$itodo->getHashIndexed("dataobject");
            foreach my $objname  (keys(%{$itodos->{dataobject}})){
               my $o=getModuleObject($self->Config,$objname);
               my $idfield=$o->IdField();
               my $itodosList=$itodos->{dataobject}->{$objname};
               $itodosList=[$itodosList] if (ref($itodosList) ne "ARRAY");
               foreach my $todorec (@{$itodosList}){
                  $o->SetFilter({$idfield->Name()=>$todorec->{dataobjectid}});
                  foreach my $cirec ($o->getHashList(qw(ALL))){
                  #   if ($cirec->{interviewst}->{todo}>0 ||
                  #       $cirec->{interviewst}->{outdated}>0){
                      if (1){  # answer direct from cache
                        if ($openInterviews==0){
                           push(@emailsubtitle,
                               "<table cellspacing=5 border=0><tr><td><b><u>".
                               $user->T("Current Config-Items with ".
                                        "open or oudated answers:").
                               "</b></u></td></tr></table>");
                        }
                        else{
                           push(@emailsubtitle,"");
                        }
                        $openInterviews++;
                        push(@emailtext,"$cirec->{name}\n".
                                        "$cirec->{urlofcurrentrec}/Interview");
                        push(@emailpostfix,"");
                        push(@emailprefix,"");
                     }
                  }
               }
            }
            $totaljobs+=$openInterviews;



            ##################################################################
            if ($totaljobs>0){
               my $infoabo=join(",",map({@{$_}} values(%{$emailto})));
               if ($baseurl ne ""){
                  my $detailcnt="";
                  my $howToFind="";
                  if ($wfcount>0){
                     $detailcnt.="<li><b>$wfcount ".
                                 $user->T("Workflow(s)").
                                 "</b></li>";
                     $howToFind.=
                        "<p class=header>".
                        $user->T("The current list of your pending ".
                                 "workflows can be found online at:").
                        "\n<a target=W5Base href=\"${baseurl}".
                        "/auth/base/menu/msel/MyW5Base?".
                        "MyW5BaseSUBMOD=base::MyW5Base::wfmyjobs\">".
                        "<br>MyW5Base => ".
                        $user->T("base::MyW5Base::wfmyjobs",
                                 "base::MyW5Base::wfmyjobs").
                        "</a><br><br></p>\n";
                  }
                  if ($adcount>0){
                     $detailcnt.="<li><b>$adcount ".
                                 $user->T("unprocessed AutoDiscovery Records").
                                 "</b></li>";
                     $howToFind.=
                        "<p class=header>".
                        $user->T("The list of current pending ".
                                 "AutoDiscovery records can be ".
                                 "found at:").
                        "\n<a target=W5Base href=\"${baseurl}".
                        "/auth/base/menu/msel/MyW5Base?".
                        "MyW5BaseSUBMOD=itil::MyW5Base::myautodiscrec\">".
                        "<br>MyW5Base => ".
                        $user->T("itil::MyW5Base::myautodiscrec",
                                 "itil::MyW5Base::myautodiscrec").
                        "</a><br><br></p>\n";
                  }
                  if ($openInterviews>0){
                     $detailcnt.="<li><b>$openInterviews ".
                        $user->T(
                        "Config-Item Interviews with open or outdated answers").
                                 "</b></li>";

                  }

                  $sendcount++;
                  $self->sendNotify(emailtext=>\@emailtext,
                                    emailpostfix=>\@emailpostfix,
                                    emailprefix=>\@emailprefix,
                                    emailsubtitle=>\@emailsubtitle,
                                    emailcategory =>['W5Base',
                                                     'WorkflowStatus'],
                                    additional=>{contact=>$urec->{fullname},
                                                 wfcount=>$wfcount,
                                                 totaljobs=>$totaljobs,
                                                 howToFind=>$howToFind,
                                                 detailcnt=>$detailcnt,
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

   return({msg=>"OK - send $sendcount notifcations",exitcode=>0});
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
      $rec{name}.=" (".$rec{additional}->{totaljobs}.")";
   }
   $rec{emailtemplate}='wfstatmail';
   $rec{emailcategory}=['WorkflowStatus'];
   #$rec{emailcc}=['hartmut.vogler@t-systems.com'];
   #       emaillang     =>$lang,

   if (my $id=$wf->Store(undef,\%rec)){
      my $r=$wf->Store($id,step=>'base::workflow::mailsend::waitforspool');
  }


}

1;
