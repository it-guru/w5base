package AL_TCom::event::AEG_Parser;
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
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub AEG_Parser
{
   my $self=shift;
   my $name=shift;
   if (!($name=~m/\.xls$/) || ! -f $name){
      return({exitcode=>1,msg=>msg(ERROR,"invalid filename '$name'")});
   }

   $self->{iaeg}=getModuleObject($self->Config,"inetwork::aeg");
   return({exitcode=>1,msg=>"ERROR in acsys"}) if (!defined($self->{iaeg}));

   $self->{appl}=getModuleObject($self->Config,"TS::appl");
   return({exitcode=>1,msg=>"ERROR in appl"}) if (!defined($self->{appl}));

   $self->{user}=getModuleObject($self->Config,"base::user");
   return({exitcode=>1,msg=>"ERROR in base user"}) if (!defined($self->{user}));

   $self->{wiw}=getModuleObject($self->Config,"tswiw::user");
   return({exitcode=>1,msg=>"ERROR in tswiw::user"}) if (!defined($self->{wiw}));

   $self->{applid}={};


   my $exitcode=$self->ProcessExcelExpand("/tmp/AEG.xls");

   return({exitcode=>$exitcode});
}

sub ProcessLineData
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $row=shift;
   my $data=shift;
  
   if ($row<200){
      my @targetappl;
      if ($data->[1]=~m/^\s*$/){
         if ($data->[0] ne ""){
            my $custappl=$data->[0];
            my $iaeg=$self->{iaeg};
            $iaeg->SetFilter({name=>\$custappl});
            my ($irec,$msg)=$iaeg->getOnlyFirst(qw(w5baseid smemail));
            if (defined($irec) && $irec->{w5baseid}){
               $data->[1]=$irec->{w5baseid};
            }
         }
      }
      if (!$data->[1]=~m/^\s*$/){
         my $id=join(" ",map({'"'.$_.'"'} split(/[\s;,]/,$data->[1])));
         $self->{appl}->ResetFilter();
         $self->{appl}->SetFilter({id=>$id,cistatusid=>'4'});
         my @dboss;
         my @targetappl=$self->{appl}->getHashList(qw(name id databoss));
         foreach my $arec (@targetappl){
            push(@dboss,$arec->{databoss}) if ($arec->{databoss} ne "");
         }
         $data->[2]=join("; ",@dboss);
      }
      for(my $a=0;$a<6;$a++){
         my $sncol=3+$a*5;
         my $gncol=4+$a*5;
         my $phcol=5+$a*5;
         my $idcol=6+$a*5;
         next if ($data->[$sncol] eq "" || $data->[$gncol] eq "");
         printf("check\n -surname=%s\n -givenname=%s\n -phone=%s\n",
                $data->[$sncol],
                $data->[$gncol],
                $data->[$phcol]);
         # Step 1 - check W5Base/Darwin by surname and givenname
         if ($data->[$idcol]=~m/^\s*$/){
            $self->{user}->ResetFilter();
            $self->{user}->SetFilter({surname=>\$data->[$sncol],
                                      givenname=>$data->[$gncol]});
            my @l=$self->{user}->getHashList(qw(posix));
            if ($#l==0 && $l[0]->{posix} ne ""){
               $data->[$idcol]=$l[0]->{posix};
            }
         }
         # Step 2 - fuzzy phone check
         if ($data->[$idcol]=~m/^\s*$/){
            my $tel=$data->[$phcol];
            $tel=~s/[^0-9 +]/ /g;
            my @blks=split(/\s+/,$tel);
            my $maxblk=3;
            $maxblk=$#blks if ($#blks<$maxblk);
            if ($#blks!=-1){
               for(my $chkblk=0;$chkblk<=$maxblk;$chkblk++){
                  next if (!($data->[$idcol]=~m/^\s*$/));
                  my $von=$#blks-$chkblk;
                  my $bis=$#blks;
                  my @v;
                  push(@v,'*'.join("",@blks[$von..$bis]).'*');
                  push(@v,'*'.join("-",@blks[$von..$bis]).'*');
                  push(@v,'"*'.join(" ",@blks[$von..$bis]).'*"');
                  $self->{user}->ResetFilter();
                  $self->{user}->SetFilter({allphones=>join(" ",@v)});
                  my @l=$self->{user}->getHashList(qw(posix email));
                  if ($#l==0){
                     if ($l[0]->{posix} ne ""){
                        $data->[$idcol]=$l[0]->{posix};
                     }
                     else{
                        $data->[$idcol]=$l[0]->{email};
                     }
                  }
                  next if (!($data->[$idcol]=~m/^\s*$/));
                  my @v;
                  push(@v,'*'.join("",@blks[$von..$bis]));
                  push(@v,'*'.join("-",@blks[$von..$bis]));
                  push(@v,'"*'.join(" ",@blks[$von..$bis]).'"');

                  $self->{wiw}->ResetFilter();
                  $self->{wiw}->SetFilter({office_mobile=>join(" ",@v)});
                  my @l=$self->{wiw}->getHashList(qw(email));
                  if ($#l==0){
                     $data->[$idcol]=lc($l[0]->{email});
                  }
                  next if (!($data->[$idcol]=~m/^\s*$/));
                  $self->{wiw}->ResetFilter();
                  $self->{wiw}->SetFilter({office_phone=>join(" ",@v)});
                  my @l=$self->{wiw}->getHashList(qw(email));
                  if ($#l==0){
                     $data->[$idcol]=lc($l[0]->{email});
                  }
               }
            }

            
            printf("blocks=%s\n",join("|",@blks));
            
         }
         # Last Step: Set result to ? if nothing could be unique identified
         if ($data->[$idcol]=~m/^\s*$/){
            $data->[$idcol]="???";
         }
         else{
            if ($data->[$idcol] ne "INVALID"){
               my $uid=$self->{wiw}->GetW5BaseUserID($data->[$idcol]);
               if ($uid ne ""){
                  $self->{user}->ResetFilter();
                  $self->{user}->SetFilter({userid=>\$uid});
                  my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(posix email));
                  if ($urec->{posix} ne ""){
                     $data->[$idcol]=$urec->{posix};
                  }
                  else{
                     $data->[$idcol]=$urec->{email};
                  }
               }
            }
            else{
               $data->[$idcol]="???";
            }
         }
      }
      my @ids=split(/[,;\s]+/,$data->[1]);
      @ids=grep(!/^\s*$/,@ids);
      if ($#ids==-1 && $data->[0] ne ""){
         die("missing mapping for  $data->[0]");
      }
      else{
         @targetappl=();
         foreach my $applid (@ids){
            if (exists($self->{applid}->{$applid})){
               die("doublicate mapping for $applid");
            }
            $self->{applid}->{$applid}++;
            $self->{appl}->ResetFilter();
            $self->{appl}->SetFilter({id=>\$applid,cistatusid=>\'4'});
            my ($arec,$msg)=$self->{appl}->getOnlyFirst(qw(id name 
                                                           applmgrid
                                                           applmgr
                                                           contacts 
                                                           technicalaeg
                                                           databossid));
            if (!defined($arec)){
               die("invalid applid $applid found");
            }
            else{
               push(@targetappl,$arec);
            }
         }
      }
      # OK, now processint @targetappl

      foreach my $arec (@targetappl){
         my $infomail;
         my %emailcc=('11920906020009'=>1,'13033697790001'=>1,
                      '11634955470001'=>1,'12762475160001'=>1);
         msg(INFO,"Processing Appl: $arec->{name}");
         foreach my $cn (@{$arec->{contacts}}){
             my $roles=$cn->{roles};
             $roles=[$roles] if (ref($roles) ne "ARRAY");
             if (in_array($roles,"write")){
                if ($cn->{target} eq "base::user"){
                   $emailcc{$cn->{targetid}}++;
                }
                if ($cn->{target} eq "base::grp"){
                   my @l=$self->{appl}->getMembersOf($cn->{targetid},
                                                     'RMember','direct');
                   foreach my $uid (@l){
                      $emailcc{$uid}++;
                   }
                }
             }
         }
         my $aeg=$arec->{technicalaeg};
         #
         # Application Manager Check
         #
         my $uid=$self->{wiw}->GetW5BaseUserID($data->[6]);
         if ($uid ne ""){
            $self->{user}->ResetFilter();
            $self->{user}->SetFilter({userid=>\$uid});
            my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(fullname ));
            if ($arec->{applmgrid} eq ""){  # kein ApplicationManager
               msg(INFO," - kein Application Manager erfasst");
               if ($self->{appl}->ValidatedUpdateRecord($arec,
                      {applmgrid=>$uid},{id=>\$arec->{id}})){
                  
                  $infomail.="Der <b>Application Manager</b> wurde ".
                             "auf <b>'$urec->{fullname}'</b> gesetzt. ".
                             "Da diese Änderung über eine zentrale ".
                             "Einspielung erfolgt ist, prüfen Sie bitte ob ".
                             "diese Zuordnung plausiebel ist. Falls dies ".
                             "nicht der Fall ist, klären Sie bitte wer der ".
                             "korrekte Application Manager ist und tragen ".
                             "dies entsprechend ein.\n\n";
               }
            }
            if ($arec->{applmgrid} ne $uid){
               $infomail.="Laut zentral erarbeiteter AEG Liste ist der ".
                          "<b>Application Manager</b> für '$arec->{name}' ".
                          "nicht '$arec->{applmgr}', sondern ".
                          "<b>'$urec->{fullname}'</b>. ".
                          "Bitte prüfen Sie, ob dies plausiebel ist und ".
                          "passen Sie dann mit hoher Dringlichkeit die ".
                          "Configdaten entsprechend an!\n\n";
            }
         }
         #
         # Technical Solution Manager Check
         #
         my $uid=$self->{wiw}->GetW5BaseUserID($data->[11]);
         if ($uid ne ""){
            $self->{user}->ResetFilter();
            $self->{user}->SetFilter({userid=>\$uid});
            my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(fullname ));
            if ($arec->{tsmid} eq ""){  # kein TSM
               msg(INFO," - kein TSM erfasst");
               if ($self->{appl}->ValidatedUpdateRecord($arec,
                      {tsmid=>$uid},{id=>\$arec->{id}})){
                  
                  $infomail.="Der <b>TSM</b> (Technical Solution Manager) ".
                             "wurde auf <b>'$urec->{fullname}'</b> gesetzt. ".
                             "Da diese Änderung über eine zentrale ".
                             "Einspielung erfolgt ist, prüfen Sie bitte ob ".
                             "diese Zuordnung plausiebel ist. Falls dies ".
                             "nicht der Fall ist, klären Sie bitte wer der ".
                             "korrekte TSM ist und tragen ".
                             "dies entsprechend ein.\n\n";
               }
            }
            if ($arec->{tsmid} ne $uid){
               $infomail.="Laut zentral erarbeiteter AEG Liste ist der ".
                          "<b>TSM</b> (Technical Solution Manager) ".
                          " für '$arec->{name}' nicht ".
                          "'$arec->{applmgr}', sondern ".
                          "<b>'$urec->{fullname}'</b>. ".
                          "Bitte prüfen Sie, ob dies plausiebel ist und ".
                          "passen Sie dann mit hoher Dringlichkeit die ".
                          "Configdaten entsprechend an!\n\n";
            }
         }
         #
         # Database Administrator Check
         #
         if ($#{$aeg->{dba_userid}}==-1){
            msg(INFO,"no DBAs found");
            $infomail.="Es konnte kein <b>DBA</b> (Datenbank Administrator) ".
                       "in W5Base/Darwin identifiziert werden. ".
                       "Bitte setzen Sie sich dringend mit ".
                       "der zuständigen Datenbankbetreuung in Verbindung ".
                       "und weisen Sie diese darauf hin, das alle ".
                       "Datenbank-Instanzen für '$arec->{name}' als ".
                       "Software-Instanzen korrekt zu erfassen sind! Im ".
                       "speziellen muß der Instanz-Administrator bei diesen ".
                       "Datenbank-Instanzen korrekt erfasst sein.\n\n";
         }
         else{
            my $uid=$self->{wiw}->GetW5BaseUserID($data->[16]);
            if ($uid ne ""){
               $self->{user}->ResetFilter();
               $self->{user}->SetFilter({userid=>\$uid});
               my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(fullname ));
               if (!in_array($aeg->{dba_userid},$uid)){
                  $infomail.="Laut zentraler AEG Erfassung, sollte ".
                             "<b>'$urec->{fullname}'</b> der <b>DBA</b> ".
                             "für '$arec->{name}' ".
                             "sein. Offensichtlich wurde dieser aber ".
                             "in W5Base/Darwin nicht korrekt erfasst. ".
                             "Bitte setzten Sie sich mit '$urec->{fullname}' ".
                             "in Verbindung, damit dieser alle relevanten ".
                             "Datenbank-Instanzen für '$arec->{name}' ".
                             "korrekt als Software-Instanzen in W5Base/Darwin ".
                             "erfasst! Im Speziellen ist der Eintrag des ".
                             "richtigen Instanz-Administrator von Nöten.\n\n";
               }
            }
         }
         #
         # Operations Manager Check
         #
         my $uid=$self->{wiw}->GetW5BaseUserID($data->[21]);
         if ($uid ne ""){
            $self->{user}->ResetFilter();
            $self->{user}->SetFilter({userid=>\$uid});
            my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(fullname ));
            if ($arec->{opmid} eq ""){  # kein OPM
               msg(INFO," - kein OPM erfasst");
               if ($self->{appl}->ValidatedUpdateRecord($arec,
                      {opmid=>$uid},{id=>\$arec->{id}})){
                  
                  $infomail.="Der <b>OPM</b> (Operations Manager) wurde ".
                             "auf <b>'$urec->{fullname}'</b> gesetzt. ".
                             "Da diese Änderung über eine zentrale ".
                             "Einspielung erfolgt ist, prüfen Sie bitte ob ".
                             "diese Zuordnung plausiebel ist. Falls dies ".
                             "nicht der Fall ist, klären Sie bitte wer der ".
                             "korrekte OPM ist und tragen ".
                             "dies entsprechend ein.\n\n";
               }
            }
            if ($arec->{opmid} ne $uid){
               $infomail.="Laut zentral erarbeiteter AEG Liste ist der ".
                          "<b>OPM</b> (Operations Manager) ".
                          " für '$arec->{name}' nicht ".
                          "'$arec->{applmgr}', sondern ".
                          "<b>'$urec->{fullname}'</b>. ".
                          "Bitte prüfen Sie, ob dies plausiebel ist und ".
                          "passen Sie dann mit hoher Dringlichkeit die ".
                          "Configdaten entsprechend an!\n\n";
            }
         }
         #
         # Projektmanager Entwicklung Check (contact role pmdev)
         #
         my $cinfomail;
         my $uid=$self->{wiw}->GetW5BaseUserID($data->[26]);
         if ($uid ne ""){
            $self->{user}->ResetFilter();
            $self->{user}->SetFilter({userid=>\$uid});
            my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(fullname ));
            my $lnkrec;
            foreach my $cn (@{$arec->{contacts}}){
                if ($cn->{target} eq "base::user" &&
                    $cn->{targetid} eq $uid){
                   $lnkrec=$cn->{id};
                }
            }
            if (!defined($lnkrec)){
               my $o=getModuleObject($self->Config,"base::lnkcontact");
               my $lnkid=$o->ValidatedInsertRecord({target=>'base::user',
                                                    targetid=>$uid,
                                                    refid=>$arec->{id},
                                                    parentobj=>'itil::appl'});
               $cinfomail.="Es wurde der Kontakt ".
                           "'$urec->{fullname}' zur ".
                           "Anwendung hinzugefügt.";
               $lnkrec=$lnkid;
            }
            if ($lnkrec ne ""){
               my $o=getModuleObject($self->Config,"base::lnkcontact");
               $o->SetFilter({id=>\$lnkrec});
               my ($lrec,$msg)=$o->getOnlyFirst(qw(ALL));
               $lnkrec=$lrec;
               if (defined($lnkrec->{roles})){
                  $lnkrec->{roles}=[$lnkrec->{roles}] if (ref($lnkrec->{roles})
                                                          ne "ARRAY");
               }
               else{
                  $lnkrec->{roles}=[];
               }
               my @l=(@{$lnkrec->{roles}});
               $lnkrec->{roles}=\@l;
            }
            if (defined($lnkrec)){
               my $roles=$lnkrec->{roles};
               if (!in_array($roles,"pmdev")){
                  my $o=getModuleObject($self->Config,"base::lnkcontact");
                  my @newroles=@$roles;
                  push(@newroles,"pmdev");
                  $o->ValidatedUpdateRecord($lnkrec,{roles=>\@newroles},
                                            {id=>\$lnkrec->{id}});
                  $cinfomail.="Für den Kontakt <b>'$urec->{fullname}'</b> ".
                              "wurde die Rolle ".
                              "<b>'Projektmanager Entwicklung'</b> ".
                              "vergeben.\n\n";
               }
            }
         }

         #
         # Projektmanager IT-System (contact role projectmanager)
         #
         my $uid=$self->{wiw}->GetW5BaseUserID($data->[31]);
         if ($uid ne ""){
            $self->{user}->ResetFilter();
            $self->{user}->SetFilter({userid=>\$uid});
            my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(fullname ));
            my $lnkrec;
            foreach my $cn (@{$arec->{contacts}}){
                if ($cn->{target} eq "base::user" &&
                    $cn->{targetid} eq $uid){
                   $lnkrec=$cn->{id};
                }
            }
            if (!defined($lnkrec)){
               my $o=getModuleObject($self->Config,"base::lnkcontact");
               my $lnkid=$o->ValidatedInsertRecord({target=>'base::user',
                                                    targetid=>$uid,
                                                    refid=>$arec->{id},
                                                    parentobj=>'itil::appl'});
               $cinfomail.="Es wurde der Kontakt ".
                           "'$urec->{fullname}' zur ".
                           "Anwendung hinzugefügt.";
               $lnkrec=$lnkid;
            }
            if ($lnkrec ne ""){
               my $o=getModuleObject($self->Config,"base::lnkcontact");
               $o->SetFilter({id=>\$lnkrec});
               my ($lrec,$msg)=$o->getOnlyFirst(qw(ALL));
               $lnkrec=$lrec;
               if (defined($lnkrec->{roles})){
                  $lnkrec->{roles}=[$lnkrec->{roles}] if (ref($lnkrec->{roles})
                                                          ne "ARRAY");
               }
               else{
                  $lnkrec->{roles}=[];
               }
               my @l=(@{$lnkrec->{roles}});
               $lnkrec->{roles}=\@l;
            }
            if (defined($lnkrec)){
               my $roles=$lnkrec->{roles};
               if (!in_array($roles,"projectmanager")){
                  my $o=getModuleObject($self->Config,"base::lnkcontact");
                  my @newroles=@$roles;
                  push(@newroles,"projectmanager");
                  $o->ValidatedUpdateRecord($lnkrec,{roles=>\@newroles},
                                            {id=>\$lnkrec->{id}});
                  $cinfomail.="Für den Kontakt <b>'$urec->{fullname}'</b> ".
                              "wurde die Rolle <b>'Projektmanager'</b> ".
                              "vergeben.\n\n";
               }
            }
         }
         ####################################################################
         if ($cinfomail ne ""){
            $infomail.="An den Kontakten der Anwendung '$arec->{name}' ".
                       "wurden aufgrund der zentral ermittelten AEG Liste ".
                       "Anpassungen vorgenommen. $cinfomail".
                       "Bitte überprüfen Sie diese Anpassungen in den ".
                       "Kontakten auf Plausibilität. Bei etwaigen Fehlern ".
                       "korrigieren Sie diese bitte zeitnah!\n\n";
         }
         if ($infomail ne ""){
            $infomail.="\nSollten Sie bei diesen zentral initieren ".
                       "Anpassungen Fehler erkannt und korrigiert haben, so ".
                       "kommunizieren Sie diese bitte auch an ".
                       "Hr. Lange/Hr. Ehlschleger.\n".
                       "Auch bei Fragen zu diesen einmailigen zentralen ".
                       "Einspielungsprozess, wenden Sie sich bitte an ".
                       "Hr. Lange bzw. Hr. Ehlschleger.\n\n".
                       "<b>Achtung:</b> Dies ist eine einmalige ".
                       "Einspielung, d.h. für die weitere Pflege der ".
                       "u.U. korrigieren Daten sind SIE als ".
                       "Datenverantwortlicher gemäß des normalen ".
                       "Config-Pflegeprozesses verantwortlich!";
            $infomail="Sehr geehrter Datenverantwortlicher,\n\n".
                      "für die <b>AEG (Application Expert Group)</b> wurde ".
                      "zentral eine Ermittlung der notwendigen Kontaktdaten ".
                      "durchgeführt. Auf Basis dieser Ermitlung ".
                      "(<b>Ansprechpartner sind Hr. Lange bzw. ".
                      "Hr. Ehlschleger</b>) ".
                      "wurde erkannt, das die Config-Daten der von Ihnen ".
                      "Datenverantworteten Anwendung '$arec->{name}' ".
                      "aktualisiert werden mußten.\n\n".$infomail;
            my $act=getModuleObject($self->Config,"base::workflowaction");

            $act->Notify('','Application Expert Group - Anpassungen '.
                         $arec->{name},$infomail,
                         emailfrom=>'"AEG Import-Testlauf" <>',
                         emailto=>[$arec->{databossid}],
                         emailcc=>[keys(%emailcc)],
                         adminbcc=>1,
                        );

         }
      } 
   }
}


##########################################################################
##########################################################################
##########################################################################
##########################################################################




sub ProcessExcelExpand
{
   my $self=shift;
   my $inpfile=shift;
   my $outfile=shift;

   if (!defined($outfile)){
      $outfile=$inpfile;
      $outfile=~s/\.xls$/_new.xls/i;
   }
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
        'use Spreadsheet::ParseExcel::SaveParser;'.
        '$oExcel=new Spreadsheet::ParseExcel::SaveParser;');
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
            my $keyval=$oWkS->{'Cells'}[$row][0]->Value();
            next if ($keyval eq "");
            printf("INFO:  Prozess: '%s'\n",$keyval);
            $self->ProcessExcelExpandLevel1($oExcel,$oBook,$oWkS,$iSheet,$row);
         }
      }
   }
   printf("INFO:  saving '%s'\n","$outfile");
   $oExcel->SaveAs($oBook,$outfile);
   return(0);
}


sub ProcessExcelExpandLevel1
{
   my $self=shift;
   my $oExcel=shift;
   my $oBook=shift;
   my $oWkS=shift;
   my $iSheet=shift;
   my $row=shift;
   my @data=();
   my @orgdata=();

   for(my $col=0;$col<=$oWkS->{MaxCol};$col++){
      next if (!($oWkS->{'Cells'}[$row][$col]));
      next if ($oWkS->{'Cells'}[$row][$col]->Value() eq "");
      $data[$col]=$oWkS->{'Cells'}[$row][$col]->Value();
   }
   @orgdata=@data;
   $self->ProcessLineData($oExcel,$oBook,$oWkS,$iSheet,$row,\@data);
   for(my $col=0;$col<=$#data;$col++){
      if ($data[$col] ne $orgdata[$col]){
         $oBook->AddCell($iSheet,$row,$col,$data[$col],0);
      }
   }
}





1;
