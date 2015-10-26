package tsacinv::event::ImportAssetCenterCO;
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

my $TMPDIR="/tmp/accheck2";
my $TMPDIR="/tmp/aclockcheck2";

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

   $self->RegisterEvent("ImportAssetManagerCO","ImportAssetManagerCO");
   return(1);
}

sub ImportAssetManagerCO
{
   my $self=shift;

   my $co=getModuleObject($self->Config,"tsacinv::costcenter");
   my $w5co=getModuleObject($self->Config,"itil::costcenter");

   $self->{loadstart}=NowStamp("en");
   $self->{acsys}=getModuleObject($self->Config,"tsacinv::system");
   $self->{w5sys}=getModuleObject($self->Config,"itil::system");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
   $self->{user}=getModuleObject($self->Config,"base::user");
   $self->{mandator}=getModuleObject($self->Config,"base::mandator");
   my $flt=[{bc=>['AL T-COM','Notes & Collab. Ser.','AL TMO',
                  'Global CU Telco','Telekom IT']},
            {orgunit=>['DTAG']}];
   $self->{statefile}="/var/log/w5base/SystemID.noappl.log";
   #$flt->{name}=\'9100007746';
   open(F,">".$self->{statefile}); close(F);

   $co->SetFilter($flt);
   my @l=$co->getHashList(qw(name bc description sememail islocked));
   my $cocount=0;
   foreach my $rec (@l){
     msg(INFO,"co=$rec->{name}");
     next if (!$w5co->ValidateCONumber("name",$rec));
     $w5co->ResetFilter();
     $w5co->SetFilter({name=>\$rec->{name}});
     my ($w5rec,$msg)=$w5co->getOnlyFirst(qw(ALL));
     my $newrec={cistatusid=>4,
                 shortdesc=>$rec->{description},
                 comments=>"authority at AssetManager",
                 srcload=>NowStamp(),
                 name=>$rec->{name}};
     if (!defined($w5rec)){
        $w5co->ValidatedInsertRecord($newrec);
     }
     else{
        delete($newrec->{comments});
        if ($rec->{islocked}){
           if ($w5rec->{cistatusid}==4){
              $newrec->{cistatusid}=5;
           }
        }
        delete($newrec->{cistatusid}) if ($w5rec->{cistatusid}==5);
        $w5co->ValidatedUpdateRecord($w5rec,$newrec,{name=>\$rec->{name}});
     }
     $self->VerifyAssetManagerData($rec);
     #last if ($cocount++==80);
   }


   my $wf=$self->{wf};
   $wf->ResetFilter();
   $wf->SetFilter({stateid=>"<20",class=>\'base::workflow::DataIssue',
                   directlnktype=>[$self->Self],
                   srcload=>"<\"$self->{loadstart}\""});
   $wf->SetCurrentView(qw(ALL));
   $wf->ForeachFilteredRecord(sub{
       my $WfRec=$_;
       my $bk=$wf->Store($WfRec,{stateid=>25});
   });
#   $self->SendOpMsg();

   return({exitcode=>0}); 
}


sub VerifyAssetManagerData
{
   my $self=shift;
   my $corec=shift;
   my $conumber=$corec->{name};
   my $altbc=$corec->{bc};
   my $islocked=$corec->{islocked};

   open(FO,">>".$self->{statefile}); 


   if ($altbc eq "AL T-COM"){
      my $wf=$self->{wf};
      my $acsys=$self->{acsys};
      my $w5sys=$self->{w5sys};
      $acsys->ResetFilter();
      $acsys->SetFilter({conumber=>\$conumber});
      my @syslist=$acsys->getHashList(qw(systemid systemname applications
                                         assignmentgroup systemola
                                         assignmentgroupsupervisoremail
                                         type usage priority));
      if ($#syslist!=-1){
         foreach my $sysrec (@syslist){
            if ($islocked){
              $self->OpMsg($sysrec->{assignmentgroupsupervisoremail},
                   "SystemID:$sysrec->{systemid}",
                   "Das System mit der SystemID '$sysrec->{systemid}' ".
                   "ist in AssetManager der AssignmentGroup ".
                   "'$sysrec->{assignmentgroup}' für die Sie als ".
                   "Leiter eingetragen sind. Die CO-Nummer '$conumber', ".
                   "die bei diesem System eingetragen ist, ist aktuell ".
                   "gesperrt. Der letzte bekannte ServiceManager für ".
                   "diese CO-Nummer war '$corec->{sememail}'.\n".
                   "Bitte sorgen Sie dafür, dass bei dem System eine ".
                   "gültige CO-Nummer eingetragen wird. Falls das ".
                   "System aktuell nicht mehr existiert, dann sorgen ".
                   "Sie bitte umgehend für eine entsprechende ".
                   "Datenbereinigung!");
               printf FO ("%s;%s;%s;%s;%s;%s;%s;%s\n",
                          $sysrec->{systemid},
                          $sysrec->{type},
                          $sysrec->{usage},
                          $sysrec->{priority},
                          $sysrec->{assignmentgroup},
                          $sysrec->{systemola},
                          $conumber,
                          "co-number is locked");
            }
            else{
               if (!defined($sysrec->{applications}) ||
                   ref($sysrec->{applications}) ne "ARRAY" ||
                   $#{$sysrec->{applications}}==-1){
                  if (!defined($self->{configmgr}->{$altbc})){
                     $self->{user}->SetFilter({posix=>\'hmerx'});
                     my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(userid));
                     $self->{configmgr}->{$altbc}=$urec->{userid};
                  }
                  my $desc="[W5TRANSLATIONBASE=".$self->Self."]\n";
                  $desc.="There are no application relations in AssetManager\n"; 
           
                  $w5sys->ResetFilter();
                  $w5sys->SetFilter({systemid=>\$sysrec->{systemid},
                                     cistatusid=>"<=5"});
                  my ($w5sysrec,$msg)=$w5sys->getOnlyFirst(qw(id applications
                                                              cistatusid));
                  if (!defined($w5sysrec)){
                     $desc.="- SystemID not found in W5Base/Darwin\n";
              #       $self->OpMsg($corec->{sememail},
              #            "SystemID:$sysrec->{systemid}",
              #            "Die SystemID '$sysrec->{systemid}' ".
              #            "(Systemname laut AssetManager: $sysrec->{systemname}) ".
              #            "ist in W5Base/Darwin nicht definiert.\n".
              #            "Das System mit der SystemID '$sysrec->{systemid}' ".
              #            "ist in AssetManager der CO-Nummer '$corec->{name}' ".
              #            "(CO Bezeichnung: $corec->{description}) ".
              #            "zugeordnet, für die Sie SeM sind. ".
              #            "Tragen Sie das System mit der SystemID ".
              #            "'$sysrec->{systemid}' entsprechend den ".
              #            "Config-Management Regeln der AL DTAG in ".
              #            "W5Base/Darwin ein! (bzw. tragen Sie die SystemID ".
              #            "ein, falls Sie diese beim entsprechenden System ".
              #            "vergessen haben)");
                     printf FO ("%s;%s;%s;%s;%s;%s;%s;%s\n",
                                $sysrec->{systemid},
                                $sysrec->{type},
                                $sysrec->{usage},
                                $sysrec->{priority},
                                $sysrec->{assignmentgroup},
                                $sysrec->{systemola},
                                $conumber,
                                "systemid not in W5Base/Darwin registered");
                  }
                  else{
                     if (!defined($w5sysrec->{applications}) ||
                         ref($w5sysrec->{applications}) ne "ARRAY" ||
                         $#{$w5sysrec->{applications}}==-1){
                        $desc.="- no application relations found in ".
                               "W5Base/Darwin\n";
              #          $self->OpMsg($corec->{sememail},
              #               "SystemID:$sysrec->{systemid}",
              #               "Das System '$w5sysrec->{systemname}' mit der ".
              #               "SystemID '$sysrec->{systemid}' ist in ".
              #               "W5Base/Darwin erzeugt, aber keiner Anwendung ".
              #               "zugeordnet. Sie sind als SeM für die CO-Nummer ".
              #               "'$corec->{name}' des Systems in AssetManager ".
              #               "erfasst. Die Zuordnung eines Systems zu ".
              #               "einer Anwendung ist nach den Config-Management ".
              #               "Regeln der AL DTAG zwingend. Sorgen Sie dafür, ".
              #               "dass die korrekte Zuordnung zu einer Anwendung ".
              #               "in W5Base/Darwin eingetragen wird.");
                        printf FO ("%s;%s;%s;%s;%s;%s;%s;%s\n",
                                   $sysrec->{systemid},
                                   $sysrec->{type},
                                   $sysrec->{usage},
                                   $sysrec->{priority},
                                   $sysrec->{assignmentgroup},
                                   $sysrec->{systemola},
                                   $conumber,
                                   "no application relations in W5Base/Darwin");
                     }
                  }
           
           
                  #############################################################
                  # Issue Create
                  #
                  my $issue={name=>"DataIssue: AssetManager: no applications ".
                                   "on systemid \"$sysrec->{systemid}\" ".
                                   "($sysrec->{systemname})",
                             class=>'base::workflow::DataIssue',
                             step=>'base::workflow::DataIssue::dataload',
                             eventstart=>NowStamp("en"),
                             srcload=>NowStamp("en"),
                             directlnktype=>$self->Self,
                             directlnkid=>'0',
                             altaffectedobjectname=>$sysrec->{systemid},
                             mandatorid=>['200'],
                             mandator=>['AL DTAG'],
                             directlnkmode=>$sysrec->{systemid},
                             detaildescription=>$desc};
                  if (defined($self->{configmgr}->{$altbc})){
                     $issue->{openusername}="Config Manager";
                     $issue->{openuser}=$self->{configmgr}->{$altbc};
                     $issue->{fwdtargetid}=$self->{configmgr}->{$altbc};
                     $issue->{fwdtarget}="base::user";
                  }
                  $wf->ResetFilter();
                  $wf->SetFilter({stateid=>"<20",class=>\$issue->{class},
                                  directlnktype=>\$issue->{directlnktype},
                                  directlnkid=>\$issue->{directlnkid},
                                  directlnkmode=>\$issue->{directlnkmode}});
                  my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
                  $W5V2::OperationContext="QualityCheck";
                  #
                  # Da die Issues nicht bearbeiter werden, entferne ich diese
                  # Prüfung (vogler 26.05.)
                  #
           #       if (!defined($WfRec)){
           #          my $bk=$wf->Store(undef,$issue);
           #       }
           #       else{
           #          map({delete($issue->{$_})} qw(eventstart class step));
           #          my $bk=$wf->Store($WfRec,$issue);
           #       }
                  #############################################################
               #exit(1) if ($sysrec->{systemid} eq "S01312120");
           
               }
            }
         }
      }
   }
   close(FO);
}

sub SendOpMsg()
{
   my $self=shift;

   my $user=$self->{user};
   my $wf=$self->{wf};
   $user->ResetFilter();
   $user->SetFilter({posix=>['hvogler','hmerx']});
   my @cc=map({$_->{email}} $user->getHashList(qw(email))); 


   foreach my $msgfile (glob($TMPDIR."/*.txt")){
      if (my ($email)=$msgfile=~m/\/([^\/]+\@.+)\.txt$/){
         msg(INFO,"send $msgfile");
         msg(INFO,"to=$email cc=%s",join(", ",@cc));
         my $msg;
         my $curcount;
         if (open(F,"<$msgfile")){
            my @l=<F>;
            my @sep=grep(/^---\s*$/,@l);
            $curcount=$#sep+1;
            $msg=join("",@l);
            close(F);
         }
         my $newmsgfile=$msgfile;
         $newmsgfile=~s/\.txt$/.old/g;
         my $postfix;
         if (open(F,"<$newmsgfile")){
            my @l=<F>;
            my @sep=grep(/^---\s*$/,@l);
            my $lastcount=$#sep+1;
            if ($lastcount==$curcount){
               $postfix="keine Verbesserung";
            }
            if ($lastcount<$curcount){
               $postfix="Verschlechterung um ".($curcount-$lastcount);
            }
            if ($lastcount>$curcount){
               $postfix="Verbesserung um ".($lastcount-$curcount);
            }
            $postfix=" ($postfix)";
         }
         $postfix=" - $curcount Probleme $postfix";
         rename($msgfile,$newmsgfile);
         if ($msg ne ""){
            my %notiy;
            $notiy{name}="Mangelhafte Datenpflege".$postfix;
            $notiy{emailtext}=$msg."\n\n\n".
                              "Bei Fragen wenden Sie sich bitte an den ".
                              "\nConfig-Manager der ".
                              "AL DTAG Hr. Merx Hans-Peter.";
            $notiy{emailto}=$email;
            $notiy{emailcc}=\@cc;
            $notiy{class}='base::workflow::mailsend';
            $notiy{step}='base::workflow::mailsend::dataload';
            if (my $id=$wf->Store(undef,\%notiy)){
               my %d=(step=>'base::workflow::mailsend::waitforspool');
               my $r=$wf->Store($id,%d);
            }
         }
      }
   }
}


sub OpMsg
{
   my $self=shift;
   my $email=shift;
   my $target=shift;
   my $msg=shift;

   my $tmpdir=$TMPDIR."/";

   if ($email ne ""){
      if (!-d $tmpdir){
         mkdir($tmpdir);
      }
      if (open(F,">>$tmpdir/$email.txt")){
         printf F ("%s\n---\n\n",$msg);
         close(F);
      }
   }
}



1;
