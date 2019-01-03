package TS::event::NotifyChange;
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


   $self->RegisterEvent("NotifyChange","NotifyChange");
   return(1);
}

sub NotifyChange
{
   my $self=shift;
   my %param=@_;
   if ($param{id}=~m/^\d{10,20}$/){
      my $wf=getModuleObject($self->Config,"base::workflow");
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      $wf->SetFilter({id=>\$param{id}});
      my ($wfrec,$msg)=$wf->getOnlyFirst(qw(ALL));
      if (defined($wfrec)){
         my $fo=$wf->getField("headref");
         my $headref=$fo->RawValue($wfrec);
         my $essentialdatahash=$headref->{essentialdatahash}->[0];
         $wfa->ResetFilter();
         $wfa->SetFilter({wfheadid=>\$wfrec->{id}});
         
         my $actions=$wfrec->{shortactionlog};
         my $sendfound=0;
         foreach my $act ($wfa->getHashList(qw(id cdate id actionref))){
            if (ref($act->{actionref}) eq "HASH"){
               if (exists($act->{actionref}->{'autonotify.essential'})){
                  my $es=$act->{actionref}->{'autonotify.essential'};
                  if (ref($es) eq "ARRAY" &&
                      $es->[0] eq $essentialdatahash){
                     $sendfound++;
                  }
                  last;
               }
            }
         }

         my $fo=$wf->getField("additional");
         my $additional=$fo->RawValue($wfrec);
         my $scstate=lc($additional->{ServiceCenterState}->[0]);


         if ($sendfound){
            return({exitcode=>0,msg=>'no essentials changed'});
         }
         my $srcid=$wfrec->{srcid};
         my $aid=$wfrec->{affectedapplicationid};
         my %emailto;
         if (defined($aid)){
            $aid=[$aid] if (!ref($aid));
            my $appl=getModuleObject($self->Config,"itil::appl");
            my $user=getModuleObject($self->Config,"base::user");
            my $grp=getModuleObject($self->Config,"base::grp");
            my $sigiapps="BL-T(P)   DoCoMue(P)  Messsystem_90_Wirk(P)".
                         "QMDB  RM_Archivierung   RM_Archivierung_T/A  ".
                         "RM_Datensicherung    RM_Datensicherung_T/A ".
                         "SchaKaL_(P/S)  SchaKaL_(T/A)  SIT4_BL-T   ".
                         "SKS_ES   SKS_ES_R  uCMDB  T-STORE";

            $appl->SetFilter({id=>$aid,name=>'SIT* W5* '.$sigiapps}); # first test only for sit
            $aid=[];
            foreach my $arec ($appl->getHashList(qw(contacts name id))){
               msg(INFO,"check application $arec->{name}");
               push(@$aid,$arec->{id});
               if (ref($arec->{contacts}) eq "ARRAY"){
                  foreach my $crec (@{$arec->{contacts}}){
                     my $r=$crec->{roles};
                     $r=[$r] if (ref($r) ne "ARRAY");
                     if ($crec->{target} eq "base::user" &&
                         grep(/^infocontact$/,@$r)){
                        $user->ResetFilter();
                        $user->SetFilter({userid=>\$crec->{targetid},
                                          cistatusid=>\'4'});
                        my ($urec,$msg)=$user->getOnlyFirst(qw(email));
                        if (defined($urec)){
                           $emailto{$urec->{email}}++;
                        }
                     }
                  }
               }
            }
         }
         return({exitcode=>0,msg=>'ok'}) if (!defined($aid) || $#{$aid}==-1);
         my $ia=getModuleObject($self->Config,"base::infoabo");
         $ia->LoadTargets(\%emailto,'*::appl',\'changenotify',$aid);
        # $ia->LoadTargets($emailto,'base::staticinfoabo',
        #                           \'STEVchangeinfobyfunction',
        #                           '100000004',\@tobyfunc,default=>1);
        # $ia->LoadTargets($emailcc,'base::staticinfoabo',\'STEVchangeinfobydepfunc',
        #                           '100000005',\@ccbyfunc,default=>1);

         my $emailto=[keys(%emailto)];

         return({exitcode=>0,msg=>'ok'}) if ($#{$emailto}==-1);

         if (!($self->Config->Param("W5BaseOperationMode") eq "normal"||
               $self->Config->Param("W5BaseOperationMode") eq "online")){
            return({exitcode=>0,msg=>'Notify only in normal Online mode'});
         }

         my $desc=$wfrec->{changedescription};
         $desc=~s/^AG\s+.*$//m;
         $desc=trim($desc);


         my @dispfields=qw(
                           wffields.changestart
                           wffields.changeend
                           wffields.changedescription
                           affectedapplication 
                          );

         my @eventlist=($scstate);

         foreach my $curscstate (@eventlist){
            next if ($curscstate eq "");
            my @emailtext;
            my @emailsubheader;
            my @emailprefix;
            my @emailsep;
            my %notiy;
            $notiy{emaillang}="en,de";
           
            foreach my $lang (split(/,/,$notiy{emaillang})){
               $ENV{HTTP_FORCE_LANGUAGE}=$lang; 
               $ENV{HTTP_FORCE_TZ}="CET" if ($lang eq "en");
               $ENV{HTTP_FORCE_TZ}="CET" if ($lang eq "de");
               if ($#emailsep==-1){
                  push(@emailsep,0);
               }
               else{
                  push(@emailsep,"$lang:");
               }
               my $url=$self->Config->Param("EventJobBaseUrl");
               if ($url ne ""){
                  push(@emailprefix,
                       "<a title=\"click to get current ".
                                  "informations of change\" ".
                       "href=\"$url/auth/tssm/chm/ById/$srcid\">".
                       "$srcid</a>");
               }
               else{
                  push(@emailprefix,$srcid);
               }
               if ($lang eq "en"){
                  push(@emailtext,"Ladies and Gentleman,\n\n".
                                  "the Change <b>$srcid</b> state has been ".
                                  "switched to <b>$curscstate</b>\n".
                                  "This is only an information for you. ".
                                  "There are no actions need to be done.");
               }
               if ($lang eq "de"){
                  push(@emailtext,"Sehr geehrte Damen und Herren,\n\n".
                                  "der Change <b>$srcid</b> hat den Status ".
                                  "<b>$curscstate</b> erreicht.\n".
                                  "Diese Mail ist nur als Information für Sie. ".
                                  "Aufgrund dieser Mail sind keine Aktionen ".
                                  "für Sie notwendig.");
               }
               push(@emailsubheader,0);
              
               foreach my $field (@dispfields){ 
                  my $fo=$wf->getField($field,$wfrec);
                  my $d=$fo->FormatedDetail($wfrec,"HtmlMail");
                  push(@emailsep,0);
                  push(@emailprefix,$fo->Label());
                  push(@emailtext,$d);
                  push(@emailsubheader,0);
               }
               
             #  push(@emailsep,0);
             #  my $fo=$wf->getField("wffields.changedescription",$wfrec);
             #  push(@emailprefix,$fo->Label());
             #  push(@emailtext,$desc);
             #  push(@emailsubheader,0);
              
               delete($ENV{HTTP_FORCE_LANGUAGE});
               delete($ENV{HTTP_FORCE_TZ});
            }
            
           
            $notiy{emailto}=$emailto;
            $notiy{name}="$srcid: ".$wfrec->{name};
            $notiy{emailprefix}=\@emailprefix;
            my $defaultfrom=$self->Config->Param("WORKFLOWTERMINFROM");
            my $sitename=$self->Config->Param("SITENAME");
            $notiy{emailfrom}='"Change Notification: '.$sitename.'" '.
                              '<'.$defaultfrom.'>';

            $notiy{emailtext}=\@emailtext;
            $notiy{emailsep}=\@emailsep;
            #$notiy{emailtemplate}='changenotification';
            $notiy{emailsubheader}=\@emailsubheader;
            #$notiy{emailcc}=['hartmut.vogler@t-systems.com'];
            $notiy{class}='base::workflow::mailsend';
            $notiy{step}='base::workflow::mailsend::dataload';
            $notiy{directlnktype}='base::workflow';
            $notiy{directlnkmode}='WorkflowNotify';
            $notiy{directlnkid}=$wfrec->{id};
            $notiy{emailtemplate}="terminnotify";
            $notiy{terminstart}=$wfrec->{eventstart};
            $notiy{terminend}=$wfrec->{eventend};
            $notiy{terminnotify}=1440;
            $notiy{prio}=5;
            $notiy{terminlocation}="T-Systems RZ";

            if ($curscstate eq "xxxxxxxxx"){
               $wf->Action->ValidatedInsertRecord({
                  wfheadid=>$wfrec->{id},
                  name=>'note',
                  comments=>'NotifyChange Event: not sending '.
                            'information about change state '.$curscstate,
                  actionref=>{"autonotify.$curscstate"=>'ignored',
                              "autonotify.essential"=>$essentialdatahash}});
            }
            else{
               if (my $wid=$wf->Store(undef,\%notiy)){
                  my %d=(step=>'base::workflow::mailsend::waitforspool');
                  my $r=$wf->Store($wid,%d);
                  $wf->Action->ValidatedInsertRecord({
                     wfheadid=>$wfrec->{id},
                     name=>'note',
                     comments=>'NotifyChange Event: sending automatic '.
                               'change state '.$curscstate.' notification '.
                               'to all information partners in application '.
                               'contacts',
                     actionref=>{"autonotify.$curscstate"=>'send',
                                 "autonotify.essential"=>$essentialdatahash}});
               }
            }
         }
         return({exitcode=>0,msg=>'ok'});
      }
      return({exitcode=>1,msg=>'workflow not found'});
   }
   return({exitcode=>1,msg=>'invalid id'});
}





1;
