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
   my $errorlevel=0;

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
      my $forcedupd={};
      my $wfrequest={};
      my @qmsg;
      my @dataissue;

      my @fieldlist=qw(office_phone office_street office_zipcode 
                       office_location office_mobile office_costcenter
                       office_accarea
                       office_facsimile);
      if ($rec->{usertyp} ne "function" &&
          $rec->{usertyp} ne "service"){
         push(@fieldlist,"givenname","surname");
      }


      foreach my $fld (@fieldlist){
          my $wiwdata={$fld=>$wiwrec->{$fld}};
          if (ref($wiwdata->{$fld}) eq "ARRAY"){
             $wiwdata->{$fld}=$wiwdata->{$fld}->[0];
          }
          $wiwdata->{$fld}=~s/^\s*unknown\s*$//i;
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
