package SMNow::event::SMNowGroupMig;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use Time::HiRes qw(usleep);
use kernel;
use kernel::Event;
use kernel::QRule;
@ISA=qw(kernel::Event);



sub Init
{
   my $self=shift;


   $self->RegisterEvent("SMNowGroupMig","SMNowGroupMig",timeout=>7200);
   return(1);
}


sub SMNowGroupMig
{
   my $self=shift;

   my $sngrpmig=getModuleObject($self->Config,"SMNow::grpmig");
   my $user=getModuleObject($self->Config,"base::user");
   my $metagrp=getModuleObject($self->Config,"tsgrpmgmt::grp");

   return({}) if ($sngrpmig->isSuspended());
   # if ping failed ...
   if (!$sngrpmig->Ping()){
      # check if there are lastmsgs
      # if there, send a message to interface partners
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      return({}) if ($infoObj->NotifyInterfaceContacts($sngrpmig));
      msg(ERROR,"no ping posible to ".$sngrpmig->Self());
      return({});
   }


   my $doNotify=1;
   my $doChange=1;

   if ($#_!=-1){   # if any is specified, not the default handling process
      $doNotify=0; # is done
      $doChange=0;
   }
   while(my $p=shift){
      if ($p eq "NOTIFY"){
         $doNotify=1;
         if ($_[0]=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/){
            $doNotify=shift;
         }
         elsif($_[0]="CHANGE"){
            $doNotify="1";
         }
         else{
            return({exitcode=>1,exitmsg=>'invalid parameter order after NOTIFY'});
         }
      }
      elsif ($p eq "CHANGE"){
         $doChange=1;
         if ($_[0]=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/){
            $doChange=shift;
         }
         elsif($_[0]="NOTIFY"){
            $doChange="1";
         }
         else{
            return({exitcode=>1,exitmsg=>'invalid parameter order after CHANGE'});
         }
      }
      else{
            return({exitcode=>1,exitmsg=>'invalid parameter '.$p});
      }
   }
   if ($doNotify eq "1"){
      my $dst=$sngrpmig->ExpandTimeExpression("now+15d","en");
      $dst=~s/\s.*//;
      $doNotify=$dst;
   }
   if ($doChange eq "1"){
      my $dst=$sngrpmig->ExpandTimeExpression("now+1d","en");
      $dst=~s/\s.*//;
      $doChange=$dst;
   }
   if ($doNotify){
      msg(INFO,"process doNotify for $doNotify");
      my $bk=$self->handleTimeStamp("prewarning",
                                    $user,$metagrp,$sngrpmig,
                                    $doNotify);
      return($bk) if ($bk);
   }
   if ($doChange){
      msg(INFO,"process doChange for $doChange");
      my $bk=$self->handleTimeStamp("postmodify",
                                    $user,$metagrp,$sngrpmig,
                                    $doChange);
      return($bk) if ($bk);
   }
   return({exitcode=>0});
}

sub processRelevantCIs
{
   my $self=shift;
   my $metagrp=shift;
   my $mode=shift;
   my $migstate=shift;
   my $ag=shift;
   my $newag=shift;

   my %l;

   foreach my $dataobjname (qw(TS::appl TS::system TS::asset TS::swinstance)){
      foreach my $prc (qw(INM CHM)){
         if ($prc eq "CHM" && $dataobjname eq "TS::appl"){
            $metagrp->ResetFilter();
            $metagrp->SetFilter({fullname=>\$newag,
                                 ischmapprov=>1,cistatusid=>4}); 
            my @chk=$metagrp->getHashList(qw(id));
            #printf STDERR ("fifi chk=%s\n",Dumper(\@chk));
            if ($#chk==0 || $migstate eq "omitted"){
               my $o=getModuleObject($self->Config,$dataobjname);
               $o->SetFilter([
                     {chmapprgroups=>\$ag,cistatusid=>"<6"},
                     {chmapprgroups=>\$ag,cistatusid=>"6",mdate=>'>now-90d'}
                                                                   
               ]);
               foreach my $rec ($o->getHashList(qw(ALL))){
                 my $name=$rec->{name};
                 my $lrec={
                    urlofcurrentrec=>$rec->{urlofcurrentrec},
                    name=>$name,
                    databossid=>$rec->{databossid}
                 };
                 if ($mode eq "postmodify"){
                    if ($migstate eq "migrated" || $migstate eq "merge"){
                       my $op=getModuleObject($self->Config,
                                              "TS::lnkapplchmapprgrp");
                       foreach my $lnkrec (@{$rec->{chmapprgroups}}){
                          if (lc($ag) eq lc($lnkrec->{group})){
                             my $bk=$op->ValidatedUpdateRecord(
                                 $lnkrec,
                                 {group=>$newag},
                                 {id=>\$lnkrec->{id}}
                             );
                          }
                       }
                       usleep(200); # prevent to many mods in one sec.
                       push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                       push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                    }
                    if ($migstate eq "omitted"){
                       my $op=$o->Clone();
                       my $op=getModuleObject($self->Config,
                                              "TS::lnkapplchmapprgrp");
                       foreach my $lnkrec (@{$rec->{chmapprgroups}}){
                          if (lc($ag) eq lc($lnkrec->{group})){
                             $op->ValidatedDeleteRecord($lnkrec);
                          }
                       }
                       usleep(200); # prevent to many mods in one sec.
                       push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                       push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                    }
                 }
                 else{
                    push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                    push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                 }
               }
            }
         }
         if ($prc eq "CHM" && $dataobjname eq "TS::swinstance"){
            $metagrp->ResetFilter();
            $metagrp->SetFilter({fullname=>\$newag,
                                 ischmapprov=>1,cistatusid=>4}); 
            my @chk=$metagrp->getHashList(qw(id));
            #printf STDERR ("fifi chk=%s\n",Dumper(\@chk));
            if ($#chk==0 || $migstate eq "omitted"){
               my $o=getModuleObject($self->Config,$dataobjname);
               $o->SetFilter([
                     {scapprgroup=>\$ag,cistatusid=>"<6"},
                     {scapprgroup=>\$ag,cistatusid=>"6",mdate=>'>now-90d'}
                                                                   
               ]);
               foreach my $rec ($o->getHashList(qw(ALL))){
                 my $name=$rec->{name};
                 my $lrec={
                    urlofcurrentrec=>$rec->{urlofcurrentrec},
                    name=>$name,
                    databossid=>$rec->{databossid}
                 };
                 if ($mode eq "postmodify"){
                    if ($migstate eq "migrated" || $migstate eq "merge"){
                       my $op=$o->Clone();
                       my $bk=$op->ValidatedUpdateRecord(
                           $rec,
                           {scapprgroup=>$newag},
                           {id=>\$rec->{id}}
                       );
                       usleep(200); # prevent to many mods in one sec.
                       #printf STDERR ("migrated $ag to $newag bk=$bk\n");
                       push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                       push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                    }
                    if ($migstate eq "omitted"){
                       my $op=$o->Clone();
                       my $bk=$op->ValidatedUpdateRecord(
                           $rec,
                           {scapprgroup=>undef},
                           {id=>\$rec->{id}}
                       );
                       usleep(200);  # prevent to many mods in one sec.
                       #printf STDERR ("omitted $ag bk=$bk\n");
                       push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                       push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                    }
                 }
                 else{
                    push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                    push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                 }
               }
            }
         }
         if ($prc eq "INM"){
            $metagrp->ResetFilter();
            $metagrp->SetFilter({fullname=>\$newag,
                                 isinmassign=>1,cistatusid=>4}); 
            my @chk=$metagrp->getHashList(qw(id));
            if ($#chk==0 || $migstate eq "omitted"){
               my $o=getModuleObject($self->Config,$dataobjname);
               $o->SetFilter([
                     {acinmassingmentgroup=>\$ag,cistatusid=>"<6"},
                     {acinmassingmentgroup=>\$ag,cistatusid=>"6",
                      mdate=>'>now-90d'}
               ]);
               foreach my $rec ($o->getHashList(qw(ALL))){
                 my $name=$rec->{name};
                 if ($dataobjname=~m/::system$/){
                    if ($rec->{shortdesc} ne ""){
                       $name.=": ".$rec->{shortdesc};
                    }
                 }
                 my $lrec={
                    urlofcurrentrec=>$rec->{urlofcurrentrec},
                    name=>$name,
                    databossid=>$rec->{databossid}
                 };
                 if ($mode eq "postmodify"){
                    if ($migstate eq "migrated" || $migstate eq "merge"){
                       my $op=$o->Clone();
                       my $bk=$op->ValidatedUpdateRecord(
                           $rec,
                           {acinmassingmentgroup=>$newag},
                           {id=>\$rec->{id}}
                       );
                       usleep(200); # prevent to many mods in one sec.
                       #printf STDERR ("migrated $ag to $newag bk=$bk\n");
                       push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                       push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                    }
                    if ($migstate eq "omitted"){
                       my $op=$o->Clone();
                       my $bk=$op->ValidatedUpdateRecord(
                           $rec,
                           {acinmassingmentgroup=>undef},
                           {id=>\$rec->{id}}
                       );
                       usleep(200);  # prevent to many mods in one sec.
                       #printf STDERR ("omitted $ag bk=$bk\n");
                       push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                       push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                    }
                 }
                 else{
                    push(@{$l{databossid}->{$rec->{databossid}}},$lrec);
                    push(@{$l{dataobjname}->{$dataobjname}},$lrec);
                 }
               }
            }
         }
      }
   }
   return(%l);
}

sub handleTimeStamp
{
   my $self=shift;
   my $mode=shift;
   my $user=shift;
   my $metagrp=shift;
   my $o=shift;
   my $ts=shift;

   $o->SetFilter({golive=>\$ts});

   my %effGrp;

   my @d=$o->getHashList(qw(group_name sm9_name migstate sys_id));

   foreach my $rec (@d){
      next if ($rec->{migstate} eq "");
      if (exists($effGrp{$rec->{sm9_name}})){
         return({exitcode=>2,exitmsg=>'mulitple Notify records for '.
                                      $rec->{sm9_name}});
      }
      my $migstate=lc($rec->{migstate});
      my $group_name=$rec->{group_name};
      if ($migstate eq "merge"){
         $group_name=$rec->{migrate_group};
      }
      $effGrp{$rec->{sm9_name}.':'.$rec->{migstate}}={
         sys_id=>$rec->{sys_id},
         sm9_name=>$rec->{sm9_name},
         group_name=>$group_name,
         migstate=>$migstate 
      };
   }
   #printf STDERR ("fifi mig=%s\n",Dumper(\%effGrp));
   foreach my $ia (sort(keys(%effGrp))){
      my $iag=$effGrp{$ia}->{sm9_name};
      my $newgroup=$effGrp{$ia}->{group_name};
      my $sys_id=$effGrp{$ia}->{sys_id};
      my $migstate=$effGrp{$ia}->{migstate};
      next if (!in_array($migstate,[qw(merge migrated omitted)]));
      next if ($iag eq "");
      my %l=$self->processRelevantCIs($metagrp,$mode,$migstate,$iag,$newgroup);
      foreach my $databossid (sort(keys(%{$l{databossid}}))){
         msg(INFO,"databossid: $databossid do $migstate  on iag=$iag on:");
         my $is1st=1;
         my $itemlist="";
         foreach my $cirec (@{$l{databossid}->{$databossid}}){
            $itemlist.=sprintf("\n") if (!$is1st);
            $itemlist.=sprintf(" %s\n",$cirec->{name});
            $itemlist.=sprintf(" - %s\n",$cirec->{urlofcurrentrec});
            $is1st=0;
         }
         $user->ResetFilter();
         $user->SetFilter({userid=>$databossid,cistatusid=>'4'});
         my ($urec)=$user->getOnlyFirst(qw(email userid cistatusid talklang));
         if (defined($urec)){
            my $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
            $ENV{HTTP_FORCE_LANGUAGE}=$urec->{talklang};
            my $fancyTS=$ts;
            if (lc($urec->{talklang}) eq "de"){
               my ($Y,$M,$D)=$ts=~m/^([0-9]{4})-([0-9]{2})-([0-9]{2})$/;
               $fancyTS=$D.".".$M.".".$Y;
            }
            my $subject="???";
            if ($mode eq "prewarning"){
               $subject=$self->T("SM.Now planned changes for Assignmentgroup");
            }
            else{
               $subject=$self->T("SM.Now done changes for Assignmentgroup");
            }
            $subject.=" ".$iag;
            my $tmpl=$o->getParsedTemplate(
                     "tmpl/SMNow.".$mode.".".$migstate,
                     {static=>{
                        migstate=>$migstate,
                        ChangeDate=>$fancyTS,
                        oldgroup=>$iag,
                        newgroup=>$newgroup,
                        ITEMS=>$itemlist,
                     }});
            my $baseurl=$self->Config->Param("EventJobBaseUrl");
            my $directlink=$baseurl."/auth/SMNow/grpmig/Detail?".
                           "search_sys_id=$sys_id";
            my %notiy;
            my $fakeFrom="\"SM.Now - AG-Migration\" <smnow\@telekom.de>";
            $notiy{emailfrom}=$fakeFrom;
            $notiy{emailto}=$urec->{email};
            $notiy{emailcc}=[qw(12898138600000)];   # Hammel
            $notiy{emailbcc}=[qw(11634953080001)];  # HV
            $notiy{emailcategory}='SMNowGroupMigration';
            $notiy{name}=$subject;
            my $sitename=$self->Config->Param("SITENAME");
            if ($sitename ne ""){
               $notiy{name}=$sitename.": ".$notiy{name};
            }
            $tmpl.="\n\nDirectLink:\n".$directlink;

            my $wfa=getModuleObject($self->Config,"base::workflowaction");
            $wfa->Notify("INFO",$subject,$tmpl,%notiy);

            $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;;
         }
      }
      #printf STDERR ("fifi l for iag $iag=%s\n",Dumper(\%l));
   }

   
   return(0);
}


1;
