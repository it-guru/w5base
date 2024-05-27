package caiman::qrule::CaimanUser;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule syncs to CAIMAN user contacts.


=head3 IMPORTS

Synced fields ...
office_phone office_street office_zipcode office_location office_mobile 
office_costcenter office_accarea office_facsimile givenname surname
On contacts of typ function and service, there will be givenname
and surname excluded.

=head3 HINTS

[en:]

The quality rule checks whether correct data are stored in Darwin in comparison with CAIMAN. If this is not the case, a data issue is generated. 

In order to clean the data issue, correct data contained in CAIMAN must be entered manually or the field "Allow automated updates through interfaces" has to be set to "Yes" whereby the data will be automatically transferred from CAIMAN.

[de:]

Die Quality Regel pr�ft ob korrekte Daten im Vergleich mit CAIMAN in Darwin gespeichert sind. Trifft dies nicht zu, wird ein Dataissue generiert.

Um das Dataissue zu bereinigen m�ssen korrekte Daten die in CAIMAN enthalten sind manuell eingetragen werden oder man setzt das Feld "automatisierte Updates durch Schnittstellen zulassen" auf "Ja" wodurch die Daten automatisch aus CAIMAN gezogen werden.


=cut

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
use kernel;
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["base::user"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $errorlevel=0;
   my $forcedupd={};
   my $wfrequest={};
   my @qmsg;
   my @dataissue;

   if ($rec->{email} ne "" && $rec->{cistatusid}<=5){
      my $uidlist;
      my $posix;
      my $caiman=getModuleObject($self->getParent->Config(),"caiman::user");
      $caiman->SetFilter([
         {email=>\$rec->{email},active=>\'true',primary=>\'true'},
         {email2=>\$rec->{email},active=>\'true',primary=>\'true'},
         {email3=>\$rec->{email},active=>\'true',primary=>\'true'},
      ]);
      my @l=$caiman->getHashList(qw(ALL));
      if ($#l>0){
         #printf STDERR ("CAIMAN: ununique email = '%s'\n",$rec->{email});
         #printf STDERR ("fifi1 %s\n",Dumper(\@l));
         #return(3,{qmsg=>['ununique email in CAIMAN '.$rec->{email}]});
         push(@qmsg,'not unique email in CAIMAN: '.$rec->{email}); 
         $errorlevel=1 if ($errorlevel<1);
         #map({ printf STDERR ("fifi wrid=%s\n",$_->{twrid}); } @l);
         my @sorted=sort({
            $b->{twrid} <=> $a->{twrid} 
         } @l);
         @l=shift(@sorted);  # take the entry with the highest twrid
         #printf STDERR ("fifi take=$l[0]->{twrid}\n");
      }
      if ($#l==0){  # 1st try to detect uidlist
         if (defined($l[0]->{wiwid}) && $l[0]->{wiwid} ne ""){
            $uidlist=$l[0]->{wiwid};
            $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
            $uidlist=[grep(!/^\s*$/,@$uidlist)];
         }
      }

      if ($#l==-1 || ($#l==0 && !defined($uidlist))){ 
                                  # no primary workrelation found - so we will
         $caiman->ResetFilter();    # try to find  a secondary (or primary has
         $caiman->SetFilter([       # no wiwid
            {email=>\$rec->{email},active=>\'true',primary=>\'false'},
            {email2=>\$rec->{email},active=>\'true',primary=>\'false'},
            {email3=>\$rec->{email},active=>\'true',primary=>\'false'}
         ]);
         my @secl=$caiman->getHashList(qw(ALL));
         if ($#secl!=-1){
            if ($#l==-1){
               @l=@secl;
            }
            if (!defined($uidlist) || $#{$uidlist}==-1){
               foreach my $secrec (@secl){
                  if (defined($secrec->{wiwid}) && $secrec->{wiwid} ne ""){
                     $uidlist=$secrec->{wiwid};
                     $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
                     $uidlist=[grep(!/^\s*$/,@$uidlist)];
                  }
               }
            }
         }
      }
      my $msg;
      my $caimanrec=$l[0];


      my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
      $posix=$posix[0];

      if (defined($caimanrec) && $posix eq "" && $rec->{usertyp} eq "user"){  
         # user has a valid CAIMAN Record, but no WIW Account
         # (this can be happend, if user uses a wiw-account over a 
         #  PM-DUP concept)
         # now we try to find a wiw account from user used useraccounts:
         if (ref($rec->{accounts}) eq "ARRAY"){
            my @wiwaccounts=sort(
               grep(/^wiw\//,
                  map({$_->{account}} @{$rec->{accounts}})));
            if ($#wiwaccounts==0){
               my $wiwaccount=$wiwaccounts[0];
               $wiwaccount=~s/^wiw\///;
               if ($wiwaccount=~m/^[a-z0-9_]{4,8}$/){
                  $posix=$wiwaccount;
               }
            }
         }
         if ($posix ne ""){
            # check, if posix is not used by an other contact
            my $chkcontact=$dataobj->Clone();
            $chkcontact->SetFilter({posix=>\$posix,cistatusid=>"<6"});
            my ($chkrec,$msg)=$chkcontact->getOnlyFirst(qw(ALL));
            if (defined($chkrec) && $chkrec->{userid} ne $rec->{userid}){
               msg(INFO,"remove posix detected by w5-useraccounts");
               $posix=undef;
            }
         }
      }


      if (!defined($caimanrec)){
         #####################################################################
         # Change local primary email based on local known wiwid or ciamid
         my @changeOperations=(
            {
              lfld=>'posix',
              rfld=>'wiwid'
            },
            {
              lfld=>'dsid',
              rfld=>'tcid'
            }
         );
         foreach my $chop (@changeOperations){
            if ($rec->{$chop->{lfld}} ne ""){  
               $caiman->ResetFilter();
               my $chkval=$rec->{$chop->{lfld}};
               if ($chop->{rfld} eq "tcid"){
                  $chkval=~s/^tCID://;
               }
               my $flt={
                  $chop->{rfld}=>\$chkval,
                  primary=>\'true',
                  active=>\'true'
               };
               $caiman->SetFilter($flt);
               ($caimanrec,$msg)=$caiman->getOnlyFirst(qw(ALL));
               if (defined($caimanrec) && 
                   lc($caimanrec->{email}) ne "" && 
                   lc($caimanrec->{email}) ne "unknown" && 
                   lc($caimanrec->{email}) ne "unregistered"){
                  my $newemail=lc($caimanrec->{email});
                  if ($rec->{usertyp} eq "extern" || $rec->{usertyp} eq "user"){
                     my $ue=getModuleObject($self->getParent->Config(),
                                              "base::useremail");
                     $ue->SetFilter({email=>\$newemail});
                     my ($alturec,$msg)=$ue->getOnlyFirst(qw(ALL));
                     if (defined($alturec)){
                        if ($alturec->{emailtyp} eq "alternate"){
                           $ue->DeleteRecord($alturec);
                           $alturec=undef;
                        }
                        if ($alturec->{emailtyp} eq "primary"){
                           $dataobj->Log(ERROR,"basedata",
                               "Fail to move primary email '$newemail' ".
                               "from '$alturec->{contactfullname}' ".
                               "to '$rec->{fullname}' ");
                        }
                     }
                     if (!defined($alturec)){ # es ist platz bzw. es wurde
                        # Platz geschaffen, um die neue Primary E-Mail 
                        # aufnehmen zu k�nnen (doublicates d�rften nicht
                        # entstehen)
                        my $user=getModuleObject($self->getParent->Config(),
                                                 "base::user");
                        if ($user->ValidatedUpdateRecord($rec,
                            {email=>$newemail},
                            {userid=>\$rec->{userid},posix=>\$rec->{posix}})){
                          # printf STDERR ("WiwUser: ".
                          #                "address change done sucessfuly.\n");
                        }
                     }
                  }
               }
            }
            last if (defined($caimanrec));
         }
         #####################################################################

         if (!defined($caimanrec)){
            return(0,{qmsg=>['user not found']});
         }
      }
      else{
         my $lastextseen;
         if ($rec->{lastexternalseen} ne ""){
            my $nowstamp=NowStamp("en");
            my $duration=CalcDateDuration($rec->{lastexternalseen},$nowstamp);
            if (defined($duration)){
               $lastextseen=$duration->{days};
            }
         }
         if (!defined($lastextseen) || $lastextseen>3){ # update only every 3d
            if ($rec->{userid} ne ""){
               $dataobj->UpdateRecord({
                  lastexternalseen=>NowStamp("en")
               },{userid=>\$rec->{userid}});
            }
         }
         if ($posix ne ""){
            if ($rec->{posix} ne $posix ){
               my $user=getModuleObject($self->getParent->Config(),
                                        "base::user");
               $user->SetFilter({posix=>\$posix});
               my ($alturec,$msg)=$user->getOnlyFirst(qw(ALL));
               if (defined($alturec)){
                  $dataobj->Log(ERROR,"basedata",
                      "Fail to set posix identifier '$posix' ".
                      "on '$rec->{fullname}' ");
               }
               else{
                  $forcedupd->{posix}=$posix;
               }
            }
         }
         else{
            if ($rec->{posix} ne ""){
               my $o=getModuleObject($self->getParent->Config(),
                                     "caiman::user");
               if (defined($o)){
                  my $chkid=$rec->{posix};
                  $o->SetFilter({wiwid=>\$chkid});
                  my ($caimanrec,$msg)=$o->getOnlyFirst(qw(id));
                  if (defined($caimanrec)){
                     #
                     # Ein Problem, das wir erstmal ignorieren
                     #
                  }
                  else{
                     my $u=getModuleObject($self->getParent->Config(),
                                              "base::user");
                     my $orgposix=$rec->{posix};
                     if ($u->ValidatedUpdateRecord($rec,{
                           posix=>undef
                        },{userid=>$rec->{userid}})){
                        my $m="Posix Identifier '$orgposix' for ".
                              "'$rec->{fullname}' has been reset to undefined";
                        push(@qmsg,$m);
                        $dataobj->Log(ERROR,"basedata",$m);
                     }
                  }
               }
            }
         }
         my $dsid="tCID:".$caimanrec->{tcid};
         if ($dsid ne $rec->{dsid}){
            # check if dsid is NOT alread in use by an other contact
            my $u=getModuleObject($self->getParent->Config(),"base::user");
            $u->SetFilter({dsid=>\$dsid});
            my ($alturec,$msg)=$u->getOnlyFirst(qw(ALL));
            if (defined($alturec)){
               if ($alturec->{userid} ne $rec->{userid}){
                  # other contact has already requested dsid
                  if ($alturec->{cistatusid}<3 ||
                      $alturec->{cistatusid}==6){
                     $dataobj->Log(ERROR,"basedata",
                          "Delete doublicate contact ".
                          "entry '$alturec->{fullname}' to store ".
                          "$dsid for '$rec->{fullname}'");
                     $u->ValidatedDeleteRecord($alturec);
                     $alturec=undef;
                  }
                  else{
                     $dataobj->Log(ERROR,"basedata",
                          "Not correctable doublicate contact ".
                          "entry '$alturec->{fullname}' ".
                          "for '$rec->{fullname}'");
                  }
               }
               else{
                  $alturec=undef; 
               }
            }
            if (!defined($alturec)){
               $forcedupd->{dsid}=$dsid;
            }
         }
         if ($rec->{posix} eq "" && !exists($forcedupd->{posix})){
            # Mann k�nnte die Axxxxx als POSIX verwenden
            if (my ($posix)=$dsid=~m/^(A\d{5,7})\@.*$/){
               if ($rec->{posix} ne $posix){
                  $forcedupd->{posix}=lc($posix);
               }
            }
         }
         #####################################################################
         # alternate E-Mail handling
         #####################################################################
         my @emails=();
         foreach my $emailattr (qw(email email2 email3)){
            my $emailtyp="alternate";
            $emailtyp="primary" if ($emailattr eq "email");
            if ($caimanrec->{$emailattr}=~m/^.+\@.+$/){
               my $lcemail=lc($caimanrec->{$emailattr});
               if (!in_array([map({$_->{email}} @emails)],$lcemail)){
                  push(@emails,{
                     emailtyp=>$emailtyp,
                     email=>$lcemail
                  });
               }
            }
         }
         foreach my $emailrec (@emails){
            my $found=0;
            foreach my $chkrec (@{$rec->{emails}}){
               $found++ if ($chkrec->{email} eq $emailrec->{email});
            }
            if (!$found){
               my $ue=getModuleObject($self->getParent->Config(),
                                        "base::useremail");
               $ue->SetFilter({email=>\$emailrec->{email}});
               my ($alturec,$msg)=$ue->getOnlyFirst(qw(ALL));
               if (defined($alturec) && $alturec->{emailtyp} eq "alternate"){
                  # need to remove alternate email adress from outer contact
                  if ($alturec->{srcsys} ne "CAIMAN"){
                     $dataobj->Log(ERROR,"basedata",
                          "Fail to move alternate email '$emailrec->{email}' ".
                          "to '$rec->{fullname}' - admin intervention ".
                          "needed");
                  }
                  if (defined($alturec)){
                     if ($ue->DeleteRecord($alturec)){
                        $dataobj->Log(ERROR,"basedata",
                            "Transfer alternate email '$emailrec->{email}' ".
                            "from '$alturec->{user}' to '$rec->{fullname}' ".
                            "sucessfuly done");
                        $alturec=undef;
                     }
                  }
               }
               if ($emailrec->{emailtyp} eq "alternate"){
                  if (!defined($alturec)){
                     $ue->ValidatedInsertRecord({
                        cistatusid=>'4',
                        email=>$emailrec->{email},
                        srcsys=>'CAIMAN',
                        userid=>$rec->{userid}
                     });
                  }
                  elsif (defined($alturec) && $alturec->{cistatusid}==6){
                     my $u=getModuleObject($self->getParent->Config(),
                                          "base::user");
                     if ($u->ValidatedUpdateRecord($alturec,{
                           email=>$alturec->{email}."old".time()
                        },{userid=>$alturec->{userid}})){
                        $dataobj->Log(ERROR,"basedata",
                            "EMail on disposte of waste contact ".
                            "record W5BaseID='$alturec->{userid}' changed");
                        if ($ue->ValidatedInsertRecord({
                               cistatusid=>'4',
                               email=>$emailrec->{email},
                               srcsys=>'CAIMAN',
                               userid=>$rec->{userid}
                            })){
                           $dataobj->Log(ERROR,"basedata",
                               "Change alternate email fro '$rec->{fullname}' ".
                               " to '$emailrec->{email}' after ".
                               "old contact update done");
                        }
                     }
                  }
                  else{
                     $dataobj->Log(ERROR,"basedata",
                         "Fail to set alternate email '$emailrec->{email}' ".
                         "on '$rec->{fullname}'");
                  }
               }
               if ($emailrec->{emailtyp} eq "primary"){
                  if (!defined($alturec)){
                     my $u=getModuleObject($self->getParent->Config(),
                                          "base::user");
                     if ($u->ValidatedUpdateRecord($rec,{
                           email=>$emailrec->{email}
                        },{userid=>$rec->{userid}})){
                       $dataobj->Log(ERROR,"basedata",
                           "Change primary email from '$rec->{fullname}' ".
                           " to '$emailrec->{email}' done");
                     }
                  }
                  elsif (defined($alturec) && $alturec->{cistatusid}==6){
                     my $u=getModuleObject($self->getParent->Config(),
                                          "base::user");
                     if ($u->ValidatedUpdateRecord($alturec,{
                           email=>$alturec->{email}."old".time()
                        },{userid=>$alturec->{userid}})){
                        $dataobj->Log(ERROR,"basedata",
                            "EMail on disposte of waste contact ".
                            "record W5BaseID='$alturec->{userid}' changed");
                        if ($u->ValidatedUpdateRecord($rec,{
                              email=>$emailrec->{email}
                            },{userid=>$rec->{userid}})){
                           $dataobj->Log(ERROR,"basedata",
                               "Change primary email fro '$rec->{fullname}' ".
                               " to '$emailrec->{email}' after ".
                               "old contact update done");
                        }
                     }
                  }
                  else{
                     $dataobj->Log(ERROR,"basedata",
                         "Fail to set primary email '$emailrec->{email}' ".
                         "on '$rec->{fullname}'");
                  }
               }
            }
         }
         #####################################################################
         #printf STDERR ("fifi soll:\n%s\n\n",Dumper(\@emails));
         #printf STDERR ("fifi ist:\n%s\n\n",Dumper($rec->{emails}));

      }
      if (
          ((($caimanrec->{surname}=~m/^mustermann$/i) && 
           ($caimanrec->{givenname}=~m/^max$/i) ) ||
           # robotics Accounts beginnen mit pn- im Vor oder Nachnamen
           ($caimanrec->{surname}=~m/^PN-DUP/) ||
           ($caimanrec->{givenname}=~m/^PN-DUP/) ||
           ($caimanrec->{email}=~m/^.*\.pn-.*\@external.*$/i) ||
           ($caimanrec->{email}=~m/^pn-.*\@external.*$/i)) &&
           $rec->{cistatusid} ne "6"){
            $dataobj->Log(ERROR,"basedata",
                   "Dummy entry detected. The Contact '%s'\n".
                   "(userid=%s;dsid=%s;posix=%s) will be marked as delete\n-".
                   "\n-",
                   $rec->{fullname},$rec->{userid},$rec->{dsid},$rec->{posix});
            my $user=getModuleObject($self->getParent->Config(),
                                      "base::user");
            $user->ValidatedUpdateRecord($rec,
                     {cistatusid=>6},
                     {userid=>\$rec->{userid}});
            return(3,{qmsg=>['dummy contact detected']});
      }
      if ($caimanrec->{office_state} eq "DTAG User"){
         if ($rec->{posix} ne ""){
            $dataobj->Log(ERROR,"basedata",
                   "Contact '%s'\nseems to have an invalid posix entry. ".
                   "The\nCAIMAN Status 'DTAG User' is not a real contact!".
                   "\n-",
                   $rec->{fullname});
         }
         return($errorlevel,undef);
      }

      if (lc($caimanrec->{sex}) eq "w" ||
          lc($caimanrec->{sex}) eq "f"){
         if ($rec->{salutation} ne "f"){
            $forcedupd->{salutation}="f";
         }
      }
      if (lc($caimanrec->{sex}) eq "m"){
         if ($rec->{salutation} ne "m"){
            $forcedupd->{salutation}="m";
         }
      }
      if ($rec->{planneddismissaldate} ne "" &&
          $caimanrec->{ddismissal} eq ""){
         $forcedupd->{planneddismissaldate}=undef;
      }
      if ($rec->{planneddismissaldate} eq "" &&
          $caimanrec->{ddismissal} ne "" ||
          $rec->{planneddismissaldate} ne $caimanrec->{ddismissal}){
         $forcedupd->{planneddismissaldate}=$caimanrec->{ddismissal};
      }


      if ($caimanrec->{country} eq ""){
         $caimanrec->{country}=undef;
      }

      my @fieldlist=qw(office_phone office_street office_zipcode 
                       office_location office_mobile office_costcenter
                       office_accarea office_organisation country
                       office_sisnumber
                       office_facsimile office_room);
      if ($rec->{usertyp} ne "function" &&
          $rec->{usertyp} ne "service"){
         push(@fieldlist,"givenname","surname");
      }

      my $typeclass=undef;
      if (lc($caimanrec->{office_state}) eq lc("Employee") ||
          lc($caimanrec->{office_state}) eq lc("Manager") ||
          lc($caimanrec->{office_state}) eq lc("Employee-1st-Day")||#vorEintr.dat.
          lc($caimanrec->{office_state}) eq lc("Freelancer") ||
          lc($caimanrec->{office_state}) eq lc("Rumpfdatensatz") ||
          lc($caimanrec->{office_state}) eq lc("DTAG User")){
         $typeclass="user";
      }
      else{
         $typeclass="function";
      }
      my $typeclassmismatch=0;

      if ($rec->{usertyp} eq "user" || $rec->{usertyp} eq "extern"){
         $typeclassmismatch++ if ($typeclass ne "user");
      }
      if ($rec->{usertyp} eq "function"){
         $typeclassmismatch++ if ($typeclass ne "function" &&
                                  $typeclass ne "service");
      }
      if ($typeclassmismatch){
         $caiman->Log(ERROR,"basedata",
                   "Contact type '$rec->{usertyp}' for ".
                   "'$rec->{fullname}' did not ".
                   "match CAIMAN state '$caimanrec->{office_state}'");
      }

      foreach my $fld (@fieldlist){
          my $caimandata={$fld=>$caimanrec->{$fld}};
          if (ref($caimandata->{$fld}) eq "ARRAY"){
             $caimandata->{$fld}=$caimandata->{$fld}->[0];
          }
          if ($fld eq "office_phone" &&
              ($caimandata->{$fld}=~m/dummyvalue$/)){
             $caimandata->{$fld}=undef;
          }
          $caimandata->{$fld}=~s/^\s*unknown\s*$//i;
          if ($fld eq "country"){
             if ($caimandata->{country} eq ""){
                delete($caimandata->{country});
             }
          }
          if ($fld eq "office_accarea"){
             $caimandata->{$fld}=~s/^0+//;
             $rec->{$fld}=~s/^0+//;
          }
          $caimandata->{$fld}=rmNonLatin1($caimandata->{$fld});

          $self->IfComp($dataobj,
                     $rec,$fld,
                     $caimandata,$fld,0,
                     $forcedupd,$wfrequest,
                     \@qmsg,\@dataissue,\$errorlevel,
                     mode=>'string');
      }
      if ($rec->{country} eq "RU" &&
          $rec->{cistatusid} eq "5" &&
          uc($caimanrec->{country}) ne "RU" &&
          $rec->{allowifupdate} eq "1" &&
          $rec->{usertyp} eq "user"){
         $forcedupd->{cistatusid}=4;
         push(@qmsg,"reactivating russian colleague due land changed");
         msg(WARN,"land change reactivation of russion ".$rec->{email});
      }

      if (keys(%$forcedupd)){
         if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,
                     {userid=>\$rec->{userid}})){
            push(@qmsg,"all desired fields has been updated: ".
                       join(", ",keys(%$forcedupd)));
         }
         else{
            push(@qmsg,$self->getParent->LastMsg());
            $errorlevel=3 if ($errorlevel<3);
         }
      }
      
      if (keys(%$wfrequest)){
         my $msg="different values stored in CAIMAN: ";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
         $errorlevel=3 if ($errorlevel<3);
      }
      return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
   }
   return($errorlevel,undef);
}



1;
