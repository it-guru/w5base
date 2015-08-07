package tsciam::qrule::checkUser;
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

   if ($rec->{email} ne "" && $rec->{cistatusid}<=5){
      my $ciam=getModuleObject($self->getParent->Config(),"tsciam::user");
      $ciam->SetFilter([
#         {uid=>\$rec->{email}},
         {email=>\$rec->{email}},
         {email2=>\$rec->{email}},  
         {email3=>\$rec->{email}},
#         {email4=>\$rec->{email}}     # email4 scheint nicht indiziert
      ]);
      my @l=$ciam->getHashList(qw(twrid tcid uid email email2 email3 email4
                                  active primary ));
      if ($#l>0){
         my @prim_l;
         foreach my $r (@l){
            push(@prim_l,$r);
         }
         @l=@prim_l;
      }
print STDERR Dumper(\@l);
return();
      if ($#l>0){
         printf STDERR ("WiwUser: ununique email = '%s'\n",$rec->{email});
         return(3,{qmsg=>['ununique email in WhoIsWho '.$rec->{email}]});
      }
      my $msg;
      my $ciamrec=$l[0];
      if (!defined($ciamrec)){
         if ($rec->{posix} ne ""){  # email adress change of existing WIW-Acc
            $ciam->ResetFilter();
            $ciam->SetFilter({uid=>\$rec->{posix}});
            ($ciamrec,$msg)=$ciam->getOnlyFirst(qw(ALL));
            if (defined($ciamrec) && 
                lc($ciamrec->{email}) ne "" && 
                lc($ciamrec->{email}) ne "unknown" && 
                lc($ciamrec->{email}) ne "unregistered"){
               my $newemail=lc($ciamrec->{email});
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
         if (!defined($ciamrec)){
            return(0,{qmsg=>['user not found']});
         }
      }
      else{
         my $uidlist=$ciamrec->{uid};
         $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
         my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
         my $posix=$posix[0];
         if ($posix ne "" && $rec->{cistatusid}==4 &&
             $ciamrec->{office_state} ne "DTAG User"){
            my $user=getModuleObject($self->getParent->Config(),
                                      "base::user");
            $user->ValidatedUpdateRecord($rec,
                     {posix=>$posix},
                     {userid=>\$rec->{userid}}); # try to use found posix
         }
      }
      if ($ciamrec->{surname}=~m/_duplicate_/i){
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
      my $forcedupd={};
      my $wfrequest={};
      my @qmsg;
      my @dataissue;

      if (lc($ciamrec->{isVSNFD}) eq "ja" ||
          lc($ciamrec->{isVSNFD}) eq "1"  ||
          lc($ciamrec->{isVSNFD}) eq "yes" ||
          lc($ciamrec->{isVSNFD}) eq "true"){
         if ($rec->{dateofvsnfd} eq ""){
            $forcedupd->{dateofvsnfd}=NowStamp("en"); 
         }
      }
      else{
         if ($rec->{dateofvsnfd} ne ""){
            $forcedupd->{dateofvsnfd}=undef;
         }
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

          $self->IfaceCompare($dataobj,
                     $rec,$fld,
                     $ciamdata,$fld,
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
