package tswiw::qrule::WiwUser;
#######################################################################
=pod

=head3 PURPOSE

This quality rule syncs to WhoIsWho user contacts.


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

   if ($rec->{dsid} ne ""){ # Das haben nur in CIAM gefundene Datensätze
      return($errorlevel,undef);
   }

   if ($rec->{email} ne "" && $rec->{cistatusid}<=5){
      my $wiw=getModuleObject($self->getParent->Config(),"tswiw::user");
      $wiw->SetFilter([{email=>\$rec->{email}},{email2=>\$rec->{email}},
                       {email3=>\$rec->{email}}]);
      my @l=$wiw->getHashList(qw(ALL));
      if ($#l>0){
         printf STDERR ("WiwUser: ununique email = '%s'\n",$rec->{email});
         return(3,{qmsg=>['ununique email in WhoIsWho '.$rec->{email}]});
      }
      my $msg;
      my $wiwrec=$l[0];
      if (!defined($wiwrec)){
         if ($rec->{posix} ne ""){  # email adress change of existing WIW-Acc
            $wiw->ResetFilter();
            $wiw->SetFilter({uid=>\$rec->{posix}});
            ($wiwrec,$msg)=$wiw->getOnlyFirst(qw(ALL));
            if (defined($wiwrec) && 
                lc($wiwrec->{email}) ne "" && 
                lc($wiwrec->{email}) ne "unknown" && 
                lc($wiwrec->{email}) ne "unregistered"){
               my $newemail=lc($wiwrec->{email});
               if ($rec->{usertyp} eq "extern" || $rec->{usertyp} eq "user"){
                  printf STDERR ("WiwUser: email address change detected!\n".
                                 "         from '%s' to '%s' for userid '%s'\n",
                                 $rec->{email},$newemail,$rec->{posix});
                  my $user=getModuleObject($self->getParent->Config(),
                                           "base::user");
                  $user->SetFilter({email=>\$newemail});
                  my ($alturec,$msg)=$user->getOnlyFirst(qw(ALL));
                  if (defined($alturec)){
                     printf STDERR ("WiwUser: ".
                                    "address change failed - ".
                                    "problem not automatic repairable.\n");
                     return(0,
                        {qmsg=>['unrepairable email address change detected']});
                  }
                  if ($user->ValidatedUpdateRecord($rec,
                      {email=>$newemail},
                      {userid=>\$rec->{userid},posix=>\$rec->{posix}})){
                     printf STDERR ("WiwUser: ".
                                    "address change done sucessfuly.\n");
                  }
               }
            }
         }
         if (!defined($wiwrec)){
            return(0,{qmsg=>['user not found']});
         }
      }
      else{
         my $uidlist=$wiwrec->{uid};
         $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
         my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
         my $posix=$posix[0];
         if ($posix ne "" && $rec->{cistatusid}==4 &&
             $wiwrec->{office_state} ne "DTAG User"){
            my $user=getModuleObject($self->getParent->Config(),
                                      "base::user");
            $user->ValidatedUpdateRecord($rec,
                     {posix=>$posix},
                     {userid=>\$rec->{userid}}); # try to use found posix
         }
      }
      if ($wiwrec->{surname}=~m/_duplicate_/i){
            $dataobj->Log(ERROR,"basedata",
                   "Duplicate_ entry detected. The Contact '%s'\n".
                   "will be marked as delete\n-",
                   "\n-",
                   $rec->{fullname});
            my $user=getModuleObject($self->getParent->Config(),
                                      "base::user");
            $user->ValidatedUpdateRecord($rec,
                     {cistatusid=>6},
                     {userid=>\$rec->{userid}}); 
      }
      if ($wiwrec->{office_state} eq "DTAG User"){
         if ($rec->{posix} ne ""){
            $dataobj->Log(ERROR,"basedata",
                   "Contact '%s'\nseems to have an invalid posix entry. ".
                   "The\nWIW Status 'DTAG User' is not a real contact!".
                   "\n-",
                   $rec->{fullname});
         }
         return($errorlevel,undef);
      }
      my $forcedupd={};
      my $wfrequest={};
      my @qmsg;
      my @dataissue;

      if (lc($wiwrec->{isVSNFD}) eq "ja" ||
          lc($wiwrec->{isVSNFD}) eq "1"  ||
          lc($wiwrec->{isVSNFD}) eq "yes" ||
          lc($wiwrec->{isVSNFD}) eq "true"){
         if ($rec->{dateofvsnfd} eq ""){
            $forcedupd->{dateofvsnfd}=NowStamp("en"); 
         }
      }
      else{
         if ($rec->{dateofvsnfd} ne ""){
            $forcedupd->{dateofvsnfd}=undef;
         }
      }

      if (lc($wiwrec->{sex}) eq "w" ||
          lc($wiwrec->{sex}) eq "f"){
         if ($rec->{salutation} ne "f"){
            $forcedupd->{salutation}="f";
         }
      }
      if (lc($wiwrec->{sex}) eq "m"){
         if ($rec->{salutation} ne "m"){
            $forcedupd->{salutation}="m";
         }
      }
      if ($wiwrec->{country} eq ""){
         $wiwrec->{country}=undef;
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
      if ($wiwrec->{office_state} eq "Employee" ||
          $wiwrec->{office_state} eq "Manager" ||
          $wiwrec->{office_state} eq "Employee-1st-Day" ||  # vor Eintrittsdat.
          $wiwrec->{office_state} eq "Freelancer" ||
          $wiwrec->{office_state} eq "DTAG User"){
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
         $wiw->Log(ERROR,"basedata",
                   "Contact type '$rec->{usertyp}' for ".
                   "'$rec->{fullname}' did not ".
                   "match WIW state '$wiwrec->{office_state}'");
      }

      foreach my $fld (@fieldlist){
          my $wiwdata={$fld=>$wiwrec->{$fld}};
          if (ref($wiwdata->{$fld}) eq "ARRAY"){
             $wiwdata->{$fld}=$wiwdata->{$fld}->[0];
          }
          if ($fld eq "office_phone" &&
              ($wiwdata->{$fld}=~m/dummyvalue$/)){
             $wiwdata->{$fld}=undef;
          }
          $wiwdata->{$fld}=~s/^\s*unknown\s*$//i;
          if ($fld eq "country"){
             if ($wiwdata->{country} eq ""){
                delete($wiwdata->{country});
             }
          }
          if ($fld eq "office_accarea"){
             $wiwdata->{$fld}=~s/^0+//;
             $rec->{$fld}=~s/^0+//;
          }
          $wiwdata->{$fld}=rmNonLatin1($wiwdata->{$fld});

          $self->IfaceCompare($dataobj,
                     $rec,$fld,
                     $wiwdata,$fld,
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
         my $msg="different values stored in WhoIsWho: ";
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
