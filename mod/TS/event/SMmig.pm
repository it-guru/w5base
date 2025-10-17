package TS::event::SMmig;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use finance::costcenter;
@ISA=qw(kernel::Event);

our %src;
our %dst;
our $DATE="06.06.2015";
our $WELLE="Welle3";
our $CHANGE=0;


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

   $self->RegisterEvent("SMmigAppl","SMmigAppl");
   $self->RegisterEvent("SMmigSwi","SMmigSwi");
   $self->RegisterEvent("SMcleanup","SMcleanup");
   return(1);
}

sub SMcleanup
{
   my $self=shift;

   my $wf=getModuleObject($self->getParent->Config,"base::workflow");
   my $wfop=getModuleObject($self->getParent->Config,"base::workflow");



   $wf->SetFilter({class=>['itil::workflow::change','itil::workflow::incident'],
                   mdate=>"<now-365d"});
   $wf->SetCurrentView(qw(ALL));
   $wf->SetCurrentOrder(qw(NONE));
   $wf->Limit(10000);
   my $c=0;

   my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(INFO,"process $rec->{id} class=$rec->{class}");
         $wfop->ValidatedDeleteRecord($rec);
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }

}


sub SMmigSwi
{
   my $self=shift;
   my $filename=shift;
   if ($filename eq "1" || $filename eq "0"){
      $CHANGE=$filename;
      $filename=shift;
   }
   my $atdate=shift;
   $self->{MAP}={};
   $self->{errMAP}=[];
   open(LOG,">SMmig.log");

   printf LOG ("\n\n%s\n","-" x 70);
   printf LOG ("%s",msg(INFO,"Starting migration process at %s",NowStamp("en")));
   printf LOG ("%s",msg(INFO,"try to open file '$filename'"));
   $ENV{REMOTE_USER}="service/ServiceManagerMig";
   my $bak=$self->ProcessExcelImport($filename);

   if ($bak->{exitcode} eq "0"){
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      my @migrec;
      my $swi=getModuleObject($self->Config,"TS::swinstance");
      $swi->SetFilter({cistatusid=>"<6"});
      my @mapfld=qw(acinmassingmentgroup scapprgroup);
      
      foreach my $rec ($swi->getHashList(qw(databossid 
                                            fullname 
                                            urlofcurrentrec
                                            id),@mapfld)){
         #last if ($#migrec==20);
         my $eff=0;
         foreach my $f (@mapfld){
            if (($rec->{$f} ne "" &&
                 exists($self->{MAP}->{$rec->{$f}}))){
               $eff++;
               printf LOG ("%s",msg(INFO,"for %s at %s exists map ent",
                                         $rec->{fullname},$f));
            }
         }
         if ($eff){
            my $d=Dumper($rec);
            push(@migrec,$rec);
         }
      }
      printf LOG ("%s",msg(INFO,"found %d potential affected instances ".
                                "records",$#migrec+1));
      my @newrec;
      foreach my $rec (@migrec){  # check target process
         my $changechount=0;
         my $errcount=0;
         my $newrec={id=>$rec->{id},
                     fullname=>$rec->{fullname},
                     databossid=>$rec->{databossid}};
         foreach my $f (@mapfld){
            if (exists($self->{MAP}->{$rec->{$f}})){
               my $fld=$swi->getField($f);
               my $vjoinobj=$fld->vjoinobj->Clone(); 
               if (defined($fld->{vjoinbase})){
                  $vjoinobj->SetNamedFilter("BASE",$fld->{vjoinbase});
               }
               if (defined($fld->{vjoineditbase})){
                  $vjoinobj->SetNamedFilter("EDITBASE",$fld->{vjoineditbase});
               }
               $vjoinobj->SetFilter({
                  $fld->{vjoindisp}=>$self->{MAP}->{$rec->{$f}}
               });
               my @d=$vjoinobj->getHashList($fld->{vjoindisp});
               if ($#d!=0){
                  my $mis=$self->{MAP}->{$rec->{$f}};
                  push(@{$self->{errMAP}},
                       msg(ERROR,"miss $mis for $f in $rec->{fullname}"));
                  $errcount++;
               }
               else{
                  $newrec->{$f}=$self->{MAP}->{$rec->{$f}};
               }
               $changechount++;
            }
         }
         if ($changechount==0 || $errcount!=0){
            printf LOG ("%s",msg(INFO,"mapping error for instance '%s'",
                                      $rec->{fullname}));
         }
         else{
            push(@newrec,$newrec);
         }
      }
      if ($#{$self->{errMAP}}!=-1){
         printf LOG ("%s",join("",@{$self->{errMAP}}));
      }
      printf LOG ("%s",msg(INFO,"%d applications are final affected ",
                                $#newrec+1));
      if ($#{$self->{errMAP}}!=-1){
         printf LOG ("%s",msg(ERROR,
                              "break migration process due mapping errors"));
      #   return({exitcode=>1,exitmsg=>'ERROR in mapping'});  
      }
      # now we have a working @newrec list!

      my $olddataboossid=undef;
      my @msgbuffer;

      foreach my $rec (@newrec){
         if ($olddataboossid ne $rec->{databossid} &&
             $#msgbuffer!=-1){
            $self->NotifyMsgBuffer($CHANGE,\@msgbuffer);
         }
         $olddataboossid=$rec->{databossid};

         my %to=();
         my %bcc=('11634953080001'=>1, # Vogler
         );
         my %cc=('13916949570000'=>1, # Pfisterer
                 '12023707570001'=>1, # Chirstman);
         );
         $swi->SetFilter({id=>\$rec->{id}});
         my @oldrec=$swi->getHashList(qw(ALL));
         if ($#oldrec==0){
            my $oldrec=ObjectRecordCodeResolver($oldrec[0]);
            my $fnewrec={};
            foreach my $f (@mapfld){
               if (exists($rec->{$f})){
                  $fnewrec->{$f}="<b>".$rec->{$f}."</b>";
               }
               else{
                  $fnewrec->{$f}="- not changed -";
               }
            }
            if ($CHANGE){
               my %msg=(%$oldrec,fnewrec=>$fnewrec);
               if ($swi->ValidatedUpdateRecord($oldrec[0],$rec,
                                               {id=>\$rec->{id}})){
                  printf LOG ("%s",msg(INFO,"sucess '%s' (W5BaseID %s)",
                                   $rec->{name},$rec->{id}));
                  push(@msgbuffer,\%msg);
               }
            }
            else{
               my %msg=(%$oldrec,fnewrec=>$fnewrec);
               push(@msgbuffer,\%msg);
            }
         }
      }
      if ($#msgbuffer!=-1){
         $self->NotifyMsgBuffer($CHANGE,\@msgbuffer);
      }
   }
   return($bak);
}


sub NotifyMsgBuffer
{
   my $self=shift;
   my $ischangemode=shift;
   my $msgbuffer=shift;

   my $lang="de";

   my $databossid=$msgbuffer->[0]->{databossid};


   if ($databossid ne ""){
      my $user=getModuleObject($self->Config,"base::user");
      $user->ResetFilter();
      $user->SetFilter({userid=>\$databossid});
      my ($urec,$msg)=$user->getOnlyFirst(qw(fullname talklang));
      $lang=$urec->{talklang};
   }

   my $map="";
   foreach my $swi (@$msgbuffer){
      $map.=sprintf("%s\n%s\n",
                    $swi->{fullname},
                    $swi->{urlofcurrentrec});
      foreach my $k (sort(keys(%{$swi->{fnewrec}}))){
         if ($swi->{$k} ne ""){
            my $label="";
            if ($k eq "acinmassingmentgroup"){
              $label=" <font color=darkblue>Incident-Assignmentgroup:</font>\n";
            }
            if ($k eq "scapprgroup"){
              $label=" <font color=darkblue>Change Approvergroup:</font>\n";
            }
            $map.=sprintf("%s  %s -&gt; %s\n",
                          $label,$swi->{$k},$swi->{fnewrec}->{$k});
         }
      }
      $map.="\n";
   }
   
   my $text;
   my $subject;

   if ($ischangemode){
      $subject="Changes made by ServiceCenter to ServiceManager Migration";
      $text=$self->getMailtextSwi($lang,$map);
   }
   else{
      $subject="Announcement Migration ServiceCenter to ServiceManager";
      $text=$self->getPreMailtextSwi($lang,$map);
   }
   my %to=();
   if ($databossid ne ""){
      $to{$databossid}=1;
   }
   my %bcc=('11634953080001'=>1, # Vogler
   );
   my %cc=('13916949570000'=>1, # Pfisterer
           '12023707570001'=>1, # Chirstman);
   );

   my $wfa=getModuleObject($self->Config,"base::workflowaction");
   $wfa->Notify("INFO", $subject, $text,
                emailto=>[keys(%to)],
                emailbcc=>[keys(%bcc)],
                emailcc=>[keys(%cc)]);

   @{$msgbuffer}=();
}



sub SMmigAppl
{
   my $self=shift;
   my $filename=shift;
   if ($filename eq "1" || $filename eq "0"){
      $CHANGE=$filename;
      $filename=shift;
   }
   my $atdate=shift;

   $self->{MAP}={};
   $self->{errMAP}=[];
   open(LOG,">SMmig.log");

   printf LOG ("\n\n%s\n","-" x 70);
   printf LOG ("%s",msg(INFO,"Starting migration process at %s",NowStamp("en")));
   printf LOG ("%s",msg(INFO,"try to open file '$filename'"));
   $ENV{REMOTE_USER}="service/ServiceManagerMig";
   my $bak=$self->ProcessExcelImport($filename);

   if ($bak->{exitcode} eq "0"){
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      my $user=getModuleObject($self->Config,"base::user");
      my @migrec;
      my $appl=getModuleObject($self->Config,"TS::appl");
      $appl->SetFilter({cistatusid=>"<6"});
      my @mapfld=qw(acinmassingmentgroup scapprgroup scapprgroup2);
      
      foreach my $rec ($appl->getHashList(qw(name
                                             scapprgroup id
                                             scapprgroup2
                                             acinmassingmentgroup))){
         #last if ($#migrec==10);
         my $eff=0;
         foreach my $f (@mapfld){
            if (($rec->{$f} ne "" &&
                 exists($self->{MAP}->{$rec->{$f}}))){
               $eff++;
               printf LOG ("%s",msg(INFO,"for %s in feld %s exists map entry",
                                         $rec->{name},$f));
            }
         }
         if ($eff){
            my $d=Dumper($rec);
            push(@migrec,$rec);
         }
      }
      printf LOG ("%s",msg(INFO,"found %d potential affected application ".
                                "records",$#migrec+1));
      my @newrec;
      foreach my $rec (@migrec){  # check target process
         my $changechount=0;
         my $errcount=0;
         my $newrec={id=>$rec->{id},name=>$rec->{name}};
         foreach my $f (@mapfld){
            if (exists($self->{MAP}->{$rec->{$f}})){
               my $fld=$appl->getField($f);
               my $vjoinobj=$fld->vjoinobj->Clone(); 
               if (defined($fld->{vjoinbase})){
                  $vjoinobj->SetNamedFilter("BASE",$fld->{vjoinbase});
               }
               if (defined($fld->{vjoineditbase})){
                  $vjoinobj->SetNamedFilter("EDITBASE",$fld->{vjoineditbase});
               }
               $vjoinobj->SetFilter({
                  $fld->{vjoindisp}=>$self->{MAP}->{$rec->{$f}}
               });
               my @d=$vjoinobj->getHashList($fld->{vjoindisp});
               if ($#d!=0){
                  my $mis=$self->{MAP}->{$rec->{$f}};
                  push(@{$self->{errMAP}},
                       msg(ERROR,"miss $mis for $f in $rec->{name}"));
                  $errcount++;
               }
               else{
                  $newrec->{$f}=$self->{MAP}->{$rec->{$f}};
               }
               $changechount++;
            }
         }
         if ($changechount==0 || $errcount!=0){
            printf LOG ("%s",msg(INFO,"mapping error for application '%s'",
                                      $rec->{name}));
         }
         else{
            push(@newrec,$newrec);
         }
      }
      if ($#{$self->{errMAP}}!=-1){
         printf LOG ("%s",join("",@{$self->{errMAP}}));
      }
      printf LOG ("%s",msg(INFO,"%d applications are final affected ",
                                $#newrec+1));
      if ($#{$self->{errMAP}}!=-1){
         printf LOG ("%s",msg(ERROR,"break migration process due mapping errors"));
      #   return({exitcode=>1,exitmsg=>'ERROR in mapping'});  
      }
      # now we have a working @newrec list!
      foreach my $rec (@newrec){
         my %to=();
         my %bcc=('11634953080001'=>1, # Vogler
         );
         my %cc=('13916949570000'=>1, # Pfisterer
                 '12023707570001'=>1, # Chirstman);
         );
         $appl->SetFilter({id=>\$rec->{id}});
         my @oldrec=$appl->getHashList(qw(ALL));
         if ($#oldrec==0){
            $user->ResetFilter();
            $user->SetFilter({userid=>\$oldrec[0]->{databossid}});
            my $lang=$user->getVal("talklang");
            printf LOG ("%s",msg(INFO,"using $lang to talk to $oldrec[0]->{databoss}"));
            my $fnewrec={};
            foreach my $f (@mapfld){
               if (exists($rec->{$f})){
                  $fnewrec->{$f}="<b>".$rec->{$f}."</b>";
               }
               else{
                  $fnewrec->{$f}="- not changed -";
               }
            }
            
            my @mapfld=qw(acinmassingmentgroup scapprgroup scapprgroup2);
           
            $to{$oldrec[0]->{databossid}}++;
            #%cc=();
            #%to=();
            if ($CHANGE){
               my $orgold=ObjectRecordCodeResolver($oldrec[0]);
               if ($appl->ValidatedUpdateRecord($oldrec[0],$rec,{id=>\$rec->{id}})){
                  printf LOG ("%s",msg(INFO,"sucess '%s' (W5BaseID %s)",$rec->{name},$rec->{id}));
                  my $txt=$self->getMailtextAppl($lang,$orgold,$rec,$fnewrec);
                  $wfa->Notify("INFO",
                               'Changes made by Migration ServiceCenter to ServiceManager '.$WELLE,
                               $txt,
                               emailto=>[keys(%to)],
                               emailbcc=>[keys(%bcc)],
                               emailcc=>[keys(%cc)]);

               }
               else{
                  printf LOG ("%s",msg(INFO,"fail '%s' (W5BaseID %s)",$rec->{name},$rec->{id}));
                  printf LOG ("%s",msg(ERROR,$self->LastMsg()));
               }
            }
            else{ # pre handling
               my $pretxt=$self->getPreMailtextAppl($lang,$oldrec[0],$rec,$fnewrec);
               $wfa->Notify("INFO",
                            'Announcement Migration ServiceCenter to ServiceManager '.$WELLE,
                            $pretxt,
                            emailto=>[keys(%to)],
                            emailbcc=>[keys(%bcc)],
                            emailcc=>[keys(%cc)]);

            }
         }
      }
   }
   return($bak);
}

sub getMailtextSwi
{
   my $self=shift;
   my $lang=shift;
   my $map=shift;


   if ($lang eq "de"){
      my $d=<<EOF;
Sehr geehrter Datenverantwortlicher,

bei Ihren Software-Instanzen wurden die folgenden Änderungen
an den Assignmentgroups vorgenommen:

$map

Falls Sie Fragen zu dieser Migration haben, wenden Sie sich bitte
an die betreffenden Ansprechpartner aus dem Migrationsprojekt:

<b>Panschow, Jürgen</b>     https://darwin.telekom.de/darwin/auth/base/user/ById/11695234600001

Pfisterer, Wolfgang  https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000
Christmann, Tobias   https://darwin.telekom.de/darwin/auth/base/user/ById/12023707570001


oder das Projekt-Funktionspostfach 
mailto:FMB_SCC2SM9_Rollout\@t-systems.com



Mit freundlichem Gruss

W5Base/Darwin Administration

EOF
      return($d);
   }
   else{
      my $d=<<EOF;
Dear databoss,

the following changes on your software-instances have been done:

$map

If you got questions for this migration, please contact one of
the following contacts from the migration project:

<b>Panschow, Jürgen</b>     https://darwin.telekom.de/darwin/auth/base/user/ById/11695234600001

Pfisterer, Wolfgang  https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000
Christmann, Tobias   https://darwin.telekom.de/darwin/auth/base/user/ById/12023707570001


or the Function-Mailbox
mailto:FMB_SCC2SM9_Rollout\@t-systems.com



Kind regards

W5Base/Darwin Administration

EOF
      return($d);
   }
   return(undef);
}


sub getPreMailtextSwi
{
   my $self=shift;
   my $lang=shift;
   my $map=shift;


   if ($lang eq "de"){
      my $d=<<EOF;
Sehr geehrter Datenverantwortlicher,

aufgrund der ServiceCenter nach ServiceManager Migration müssen bei
Software-Instanzen die von Ihnen datenverantwortet werden, 
Assignmentgroups korrigiert werden.
Wenn Sie nicht bis zum <b>10.07.2015 14:00 CET</b> selbst eine Umstellung auf
die neuen SM9 Assignmentgroups vornehmen, wird zentrall die Umstellung 
nach folgender Mapping Tabelle vorgenommen:

$map
Falls Sie Fragen zu dieser Migration haben, wenden Sie sich bitte
an die betreffenden Ansprechpartner aus dem Migrationsprojekt:

<b>Panschow, Jürgen</b>     https://darwin.telekom.de/darwin/auth/base/user/ById/11695234600001

Pfisterer, Wolfgang  https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000
Christmann, Tobias   https://darwin.telekom.de/darwin/auth/base/user/ById/12023707570001


oder das Projekt-Funktionspostfach 
mailto:FMB_SCC2SM9_Rollout\@t-systems.com



Mit freundlichem Gruss

W5Base/Darwin Administration

EOF
      return($d);
   }
   else{
      my $d=<<EOF;
Dear databoss,

reasoned on the ServiceCenter to ServiceManager migration the 
Assignmentgroups in your Software-Instances needs to be changed.
If you do not have changed to the new SM9 groups 
since <b>10.07.2015 14:00 CET</b>, the migration will be done by a
central job based on the following mapping table:

$map
If you got questions for this migration, please contact one of
the following contacts from the migration project:

<b>Panschow, Jürgen</b>     https://darwin.telekom.de/darwin/auth/base/user/ById/11695234600001

Pfisterer, Wolfgang  https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000
Christmann, Tobias   https://darwin.telekom.de/darwin/auth/base/user/ById/12023707570001


or the Function-Mailbox
mailto:FMB_SCC2SM9_Rollout\@t-systems.com



Kind regards

W5Base/Darwin Administration

EOF
      return($d);
   }
   return(undef);
}


sub getMailtextAppl
{
   my $self=shift;
   my $lang=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $fnewrec=shift;


   if ($lang eq "de"){
      my $d=<<EOF;
Sehr geehrter Datenverantwortlicher,

ihre Anwendung '<b>$oldrec->{name}</b>' ...
$oldrec->{urlofcurrentrec}
... war von der ServiceCenter nach ServiceManager Migration betroffen.

Es wurden die folgende Änderungen zentral an dem genannten
Anwendungs Config-Item durchgeführt:

Incident-Assignmentgroup    : $oldrec->{acinmassingmentgroup} -> 
                              $fnewrec->{acinmassingmentgroup}

Change Approvergroup tech.  : $oldrec->{scapprgroup} -> 
                              $fnewrec->{scapprgroup}

Change Approvergroup fachl. : $oldrec->{scapprgroup2} ->
                              $fnewrec->{scapprgroup2}

Falls Sie Fragen zu dieser Migration haben, wenden Sie sich bitte
an die betreffenden Ansprechpartner aus dem Migrationsprojekt:

<b>Panschow, Jürgen</b>     https://darwin.telekom.de/darwin/auth/base/user/ById/11695234600001

Pfisterer, Wolfgang  https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000
Christmann, Tobias   https://darwin.telekom.de/darwin/auth/base/user/ById/12023707570001


oder das Projekt-Funktionspostfach 
mailto:FMB_SCC2SM9_Rollout\@t-systems.com



Mit freundlichem Gruss

W5Base/Darwin Administration

EOF
      return($d);
   }
   if ($lang eq "en"){
      my $d=<<EOF;
Dear databoss,

the application '<b>$oldrec->{name}</b>' ...
$oldrec->{urlofcurrentrec}
... was affected by the ServiceCenter to ServiceManager Migration.

The following changes are done by an central
process on the application config-item:

Incident-Assignmentgroup    : $oldrec->{acinmassingmentgroup} -> 
                              $fnewrec->{acinmassingmentgroup}

Change Approvergroup tech.  : $oldrec->{scapprgroup} -> 
                              $fnewrec->{scapprgroup}

Change Approvergroup fachl. : $oldrec->{scapprgroup2} ->
                              $fnewrec->{scapprgroup2}

If you got questions for this migration, please contact one of
the following contacts from the migration project:

<b>Panschow, Jürgen</b>     https://darwin.telekom.de/darwin/auth/base/user/ById/11695234600001

Pfisterer, Wolfgang  https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000
Christmann, Tobias   https://darwin.telekom.de/darwin/auth/base/user/ById/12023707570001


or the Function-Mailbox
mailto:FMB_SCC2SM9_Rollout\@t-systems.com



Kind regards

W5Base/Darwin Administration

EOF
      return($d);
   }
   return(undef);
}


sub getPreMailtextAppl
{
   my $self=shift;
   my $lang=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $fnewrec=shift;


   if ($lang eq "de"){
      my $d=<<EOF;
Sehr geehrter Datenverantwortlicher,

ihre Anwendung '<b>$oldrec->{name}</b>' ...
$oldrec->{urlofcurrentrec}
... ist von der ServiceCenter nach ServiceManager Migration betroffen.

Zum $DATE ($WELLE) werden folgende Änderungen zentral an dem genanntem
Anwendungs Config-Item durchgeführt:

Incident-Assignmentgroup    : $oldrec->{acinmassingmentgroup} -> 
                              $fnewrec->{acinmassingmentgroup}

Change Approvergroup tech.  : $oldrec->{scapprgroup} -> 
                              $fnewrec->{scapprgroup}

Change Approvergroup fachl. : $oldrec->{scapprgroup2} ->
                              $fnewrec->{scapprgroup2}

Falls Sie Fragen zu dieser Migration haben, wenden Sie sich bitte
an die betreffenden Ansprechpartner aus dem Migrationsprojekt:

<b>Panschow, Jürgen</b>     https://darwin.telekom.de/darwin/auth/base/user/ById/11695234600001

Pfisterer, Wolfgang  https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000
Christmann, Tobias   https://darwin.telekom.de/darwin/auth/base/user/ById/12023707570001


oder das Projekt-Funktionspostfach 
mailto:FMB_SCC2SM9_Rollout\@t-systems.com



Mit freundlichem Gruss

W5Base/Darwin Administration

EOF
      return($d);
   }
   if ($lang eq "en"){
      my $d=<<EOF;
Dear databoss,

the application '<b>$oldrec->{name}</b>' ...
$oldrec->{urlofcurrentrec}
... is affected by the ServiceCenter to ServiceManager Migration.

At $CHANGE ($WELLE) the following changes are made by an central
process on the application config-item:

Incident-Assignmentgroup    : $oldrec->{acinmassingmentgroup} -> 
                              $fnewrec->{acinmassingmentgroup}

Change Approvergroup tech.  : $oldrec->{scapprgroup} -> 
                              $fnewrec->{scapprgroup}

Change Approvergroup fachl. : $oldrec->{scapprgroup2} ->
                              $fnewrec->{scapprgroup2}

If you got questions for this migration, please contact one of
the following contacts from the migration project:

<b>Panschow, Jürgen</b>     https://darwin.telekom.de/darwin/auth/base/user/ById/11695234600001

Pfisterer, Wolfgang  https://darwin.telekom.de/darwin/auth/base/user/ById/13916949570000
Christmann, Tobias   https://darwin.telekom.de/darwin/auth/base/user/ById/12023707570001


or the Function-Mailbox
mailto:FMB_SCC2SM9_Rollout\@t-systems.com



Kind regards

W5Base/Darwin Administration

EOF
      return($d);
   }
   return(undef);
}


##########################################################################
##########################################################################
##########################################################################
##########################################################################




sub ProcessExcelImport
{
   my $self=shift;
   my $inpfile=shift;

   if (! -r $inpfile ){
      printf STDERR ("ERROR: can't open '$inpfile'\n");
      printf STDERR ("ERROR: errstr=$!\n");
      exit(1);
   }
   else{
      printf ("INFO:  opening $inpfile\n");
   }

   my $oExcel;
   eval('use Spreadsheet::ParseExcel;'.
        '$oExcel=Spreadsheet::ParseExcel::Workbook->Parse($inpfile)');
   if ($@ ne "" || !defined($oExcel)){
      msg(ERROR,"%s",$@);
      return(2);
   }
   my  $oBook=$oExcel->Parse($inpfile);
   if (!$oBook ){
      printf STDERR ("ERROR: can't parse '$inpfile'\n");
      exit(1);
   }
   for(my $iSheet=0; $iSheet < $oBook->{SheetCount} ; $iSheet++) {
      my $oWkS = $oBook->{Worksheet}[$iSheet];
      for(my $row=0;$row<=$oWkS->{MaxRow};$row++){
         if ($oWkS->{'Cells'}[$row][0]){
            my $scag=$oWkS->{'Cells'}[$row][0]->Value();
            my $smag=$oWkS->{'Cells'}[$row][1]->Value();
            next if ($row==0);
            next if ($scag eq "" || $smag eq "");
            printf("INFO:  Prozess: '%s'\n",$scag."->".$smag);
            $self->{MAP}->{$scag}=$smag;
         }
      }
   }
   return({exitcode=>0});
}


1;
