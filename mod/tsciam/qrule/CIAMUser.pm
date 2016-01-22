package tsciam::qrule::CIAMUser;
#######################################################################
=pod

=head3 PURPOSE

This quality rule syncs to CIAM user contacts.


=head3 IMPORTS

Synced fields ...
office_phone office_street office_zipcode office_location office_mobile 
office_costcenter office_accarea office_facsimile givenname surname
On contacts of typ function and service, there will be givenname
and surname excluded.



=cut

#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
      my $ciam=getModuleObject($self->getParent->Config(),"tsciam::user");
      $ciam->SetFilter([
         {email=>\$rec->{email},active=>\'true',primary=>\'true'},
         {email2=>\$rec->{email},active=>\'true',primary=>\'true'},
         {email3=>\$rec->{email},active=>\'true',primary=>\'true'}
      ]);
      my @l=$ciam->getHashList(qw(ALL));
      if ($#l==-1){
         # Workaround für nicht indiziertes email4 Feld - da suchen wir
         # dann nur, wenns wirklich sein muß.
         # ACHTUNG: Uneindeutigkeiten gegenüber email4 können somit vermutlich
         #          NICHT erkannt werden
         $ciam->ResetFilter();
         msg(INFO,"OK, dann müssen wir eben noch in email4 nachsehen");
         $ciam->SetFilter([
            {email4=>\$rec->{email},active=>\'true',primary=>\'true'} 
             # NICHT indiziert!
         ]);
         @l=$ciam->getHashList(qw(ALL));
         if ($#l==-1 &&
             ( ($rec->{email}=~m/\@telekom\.de$/) ||
               ($rec->{email}=~m/\@t-systems\.com$/)) &&
             ($rec->{usertyp} eq "extern" || $rec->{usertyp} eq "user")){
            $dataobj->Log(ERROR,"basedata",
                   "Contact '%s' seems to have leave ".
                   " the DTAG concern.",
                   $rec->{fullname});
            return(0,{qmsg=>['telekom user not found']});
         }
      }

      if ($#l>0){
         printf STDERR ("CIAM: ununique email = '%s'\n",$rec->{email});
         return(3,{qmsg=>['ununique email in CIAM '.$rec->{email}]});
      }
      
      my $msg;
      my $ciamrec=$l[0];
      if (!defined($ciamrec)){
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
               $ciam->ResetFilter();
               my $chkval=$rec->{$chop->{rfld}};
               if ($chop->{rfld} eq "tcid"){
                  $chkval=~s/^tCID://;
               }
               $ciam->SetFilter({$chop->{rfld}=>\$chkval,
                                 active=>\'true',primary=>\'true'});
               ($ciamrec,$msg)=$ciam->getOnlyFirst(qw(ALL));
               if (defined($ciamrec) && 
                   lc($ciamrec->{email}) ne "" && 
                   lc($ciamrec->{email}) ne "unknown" && 
                   lc($ciamrec->{email}) ne "unregistered"){
                  my $newemail=lc($ciamrec->{email});
                  if ($rec->{usertyp} eq "extern" || $rec->{usertyp} eq "user"){
                     my $ue=getModuleObject($self->getParent->Config(),
                                              "base::useremail");
                     $ue->SetFilter({email=>\$newemail});
                     my ($alturec,$msg)=$ue->getOnlyFirst(qw(ALL));
                     if (defined($alturec)){
                        if ($alturec->{emailtyp} eq "alternate"){
                           $ue->DeleteRecord($alturec);
                        }
                     }
                     if (!defined($alturec)){ # es ist platz bzw. es wurde
                        # Platz geschaffen, um die neue Primary E-Mail 
                        # aufnehmen zu können (doublicates dürften nicht
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
            last if (defined($ciamrec));
         }
         #####################################################################

         if (!defined($ciamrec)){
            return(0,{qmsg=>['user not found']});
         }
      }
      else{
         my $uidlist=$ciamrec->{wiwid};
         $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
         my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
         my $posix=$posix[0];
         if ($posix ne "" && $rec->{posix} ne $posix ){
            $forcedupd->{posix}=$posix;
         }
         my $dsid="tCID:".$ciamrec->{tcid};
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
            # Mann könnte die Axxxxx als POSIX verwenden
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
         foreach my $emailattr (qw(email email2 email3 email4)){
            my $emailtyp="alternate";
            $emailtyp="primary" if ($emailattr eq "email");
            if ($ciamrec->{$emailattr}=~m/^.+\@.+$/){
               my $lcemail=lc($ciamrec->{$emailattr});
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
            if (!$found && $emailrec->{emailtyp} eq "alternate"){
               my $ue=getModuleObject($self->getParent->Config(),
                                        "base::useremail");
               $ue->SetFilter({email=>\$emailrec->{email}});
               my ($alturec,$msg)=$ue->getOnlyFirst(qw(ALL));
               if (defined($alturec)){
                  # need to remove alternate email adress from outer contact
                  if ($alturec->{srcsys} ne "CIAM"){
                     $dataobj->Log(ERROR,"basedata",
                          "Fail to move alternate email '$emailrec->{email}' ".
                          "to '$rec->{fullname}' - admin intervention ".
                          "needed");
                  }
                  else{
                     if ($ue->DeleteRecord($alturec)){
                        $dataobj->Log(ERROR,"basedata",
                            "Transfer alternate email '$emailrec->{email}' ".
                            "from '$alturec->{user}' to '$rec->{fullname}' ".
                            "sucessfuly done");
                        $alturec=undef;
                     }
                  }
               }
               if (!defined($alturec)){
                  $ue->ValidatedInsertRecord({
                     cistatusid=>'4',
                     email=>$emailrec->{email},
                     srcsys=>'CIAM',
                     userid=>$rec->{userid}
                  });
               }
            }
         }
         #####################################################################
         #printf STDERR ("fifi soll:\n%s\n\n",Dumper(\@emails));
         #printf STDERR ("fifi ist:\n%s\n\n",Dumper($rec->{emails}));

      }
      if ($ciamrec->{office_state} eq "DTAG User"){
         if ($rec->{posix} ne ""){
            $dataobj->Log(ERROR,"basedata",
                   "Contact '%s'\nseems to have an invalid posix entry. ".
                   "The\nWIW Status 'DTAG User' is not a real contact!".
                   "\n-",
                   $rec->{fullname});
         }
         return($errorlevel,undef);
      }

      if (lc($ciamrec->{sex}) eq "w" ||
          lc($ciamrec->{sex}) eq "f"){
         if ($rec->{salutation} ne "f"){
            $forcedupd->{salutation}="f";
         }
      }
      if (lc($ciamrec->{sex}) eq "m"){
         if ($rec->{salutation} ne "m"){
            $forcedupd->{salutation}="m";
         }
      }
      if ($ciamrec->{country} eq ""){
         $ciamrec->{country}=undef;
      }

      my @fieldlist=qw(office_phone office_street office_zipcode 
                       office_location office_mobile office_costcenter
                       office_accarea office_organisation country
                       office_facsimile);
      if ($rec->{usertyp} ne "function" &&
          $rec->{usertyp} ne "service"){
         push(@fieldlist,"givenname","surname");
      }

      my $typeclass=undef;
      if ($ciamrec->{office_state} eq "Employee" ||
          $ciamrec->{office_state} eq "Manager" ||
          $ciamrec->{office_state} eq "Employee-1st-Day" ||  # vor Eintrittsdat.
          $ciamrec->{office_state} eq "Freelancer" ||
          $ciamrec->{office_state} eq "DTAG User"){
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
         $ciam->Log(ERROR,"basedata",
                   "Contact type '$rec->{usertyp}' for ".
                   "'$rec->{fullname}' did not ".
                   "match WIW state '$ciamrec->{office_state}'");
      }

      foreach my $fld (@fieldlist){
          my $ciamdata={$fld=>$ciamrec->{$fld}};
          if (ref($ciamdata->{$fld}) eq "ARRAY"){
             $ciamdata->{$fld}=$ciamdata->{$fld}->[0];
          }
          if ($fld eq "office_phone" &&
              ($ciamdata->{$fld}=~m/dummyvalue$/)){
             $ciamdata->{$fld}=undef;
          }
          $ciamdata->{$fld}=~s/^\s*unknown\s*$//i;
          if ($fld eq "country"){
             if ($ciamdata->{country} eq ""){
                delete($ciamdata->{country});
             }
          }
          if ($fld eq "office_accarea"){
             $ciamdata->{$fld}=~s/^0+//;
             $rec->{$fld}=~s/^0+//;
          }
          $ciamdata->{$fld}=rmNonLatin1($ciamdata->{$fld});

          $self->IfComp($dataobj,
                     $rec,$fld,
                     $ciamdata,$fld,0,
                     $forcedupd,$wfrequest,
                     \@qmsg,\@dataissue,\$errorlevel,
                     mode=>'string');
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
         my $msg="different values stored in CIAM: ";
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
