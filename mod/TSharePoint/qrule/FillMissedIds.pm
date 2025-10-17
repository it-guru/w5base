package TSharePoint::qrule::FillMissedIds;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule tries to fill up missing IDs
by consolidating the SharePoint HUB DataMaster.

=head3 IMPORTS

- short name
- HUB ID

=head3 HINTS

[en:]

Using Telekom SharePoint, certain missing information in the 
virtual organizational unit can be filled in or completed.


[de:]

Über den Telekom SharePoint können bestimmte, fehlende
Information in der virutelle Org-Einheit aufgefüllt/vervollständigt
werden.


=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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
   return(["TS::vou"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   # in TS::vou no allowifupdate switch exists
   my $autocorrect=1;

   return(0,undef) if ($rec->{cistatusid}>5);

   my $par=getModuleObject($self->getParent->Config(),
                           "TSharePoint::SharePointHubMaster"
   );

   msg(INFO,$self->Self()." start check $par");
   return(undef,undef) if ($par->isSuspended());
   return(undef,undef) if (!$par->Ping());

   my ($parrec,$msg);

   msg(INFO,$self->Self()." start try to find parrec");
   if (!defined($parrec) && $rec->{hubid} ne ""){
      # try to find parrec by hubid
      $par->ResetFilter();
      $par->SetFilter({hubid=>\$rec->{hubid}});
      ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (defined($parrec)){
         msg(INFO,$self->Self()." found parrec by hubid");
      }
   }
   if (!defined($parrec) && $rec->{shortname} ne ""){
      # try to find parrec by shortname
      $par->ResetFilter();
      $par->SetFilter({shortname=>\$rec->{shortname}});
      ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      if (defined($parrec)){
         msg(INFO,$self->Self()." found parrec by shortname");
      }
   }
   msg(INFO,$self->Self()." found leaderitid=$rec->{leaderitid}");
   if (!defined($parrec) && $rec->{leaderitid} ne ""){
      # check, if more then 50 VOUs have a HUB-ID
      $dataobj->ResetFilter();
      $dataobj->SetFilter({hubid=>'![EMPTY]'});
      my $n=$dataobj->CountRecords();

      if ($n>50){
         # try to find a unique relation over BO-IT 
         my $o=getModuleObject($self->getParent->Config(),"base::user");
         $o->SetFilter({userid=>\$rec->{leaderitid},cistatusid=>4});
         my ($urec,$msg)=$o->getOnlyFirst(qw(cistatusid fullname email));
         if (defined($urec)){
            $par->ResetFilter();
            msg(INFO,$self->Self()." search by $urec->{email}");
            $par->SetFilter({boit_email=>$urec->{email}});
            my @l=$par->getHashList(qw(ALL));
            if ($#l==0){
               msg(INFO,$self->Self()." found unique parrec by BO-IT");
               $parrec=$l[0];
            }
         }
      }
      if (defined($parrec)){
         msg(INFO,$self->Self()." found parrec by BO-IT");
      }

   }


   if (defined($parrec)){


      if ($parrec->{hubid} ne "" && $parrec->{hubid} ne $rec->{hubid}){
         # check if new $parrec->{hubid} is free
         $dataobj->ResetFilter();
         $dataobj->SetFilter({hubid=>\$parrec->{hubid},
                              id=>"!".$rec->{id}});
         my ($chkrec,$msg)=$dataobj->getOnlyFirst(qw(ALL));
         if (defined($chkrec)){
            my $msg="desired already used by other VOU: ".
                    $parrec->{hubid};
            push(@qmsg,$msg);
         }
         else{
            $self->IfComp($dataobj,
                          $rec,"hubid",
                          $parrec,"hubid",
                          $autocorrect,$forcedupd,$wfrequest,
                          \@qmsg,\@dataissue,\$errorlevel,
                          mode=>'string');
         }
      }


   }

   my @result=$self->HandleQRuleResults("TSharePoint-HUB-Master",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
