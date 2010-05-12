package tswiw::qrule::WiwUser;
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

   if ($rec->{email} ne ""){
      my $wiw=getModuleObject($self->getParent->Config(),"tswiw::user");
      $wiw->SetFilter({email=>\$rec->{email}});
      my ($wiwrec,$msg)=$wiw->getOnlyFirst(qw(ALL));
      if (!defined($wiwrec)){
         return(0,{qmsg=>['user not found']});
      }
      my $forcedupd={};
      my $wfrequest={};
      my @qmsg;
      my @dataissue;
      foreach my $fld (qw(office_phone office_street office_zipcode 
                          office_location office_mobile office_costcenter
                          office_accarea
                          office_facsimile
                          givenname surname)){
          my $wiwdata={$fld=>$wiwrec->{$fld}};
          if (ref($wiwdata->{$fld}) eq "ARRAY"){
             $wiwdata->{$fld}=$wiwdata->{$fld}->[0];
          }
          $wiwdata->{$fld}=~s/^\s*unknown\s*$//i;
          
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
            push(@qmsg,"some fields has been updated");
         }
         else{
            push(@qmsg,$self->getParent->LastMsg());
            return(3,{qmsg=>\@qmsg});
         }
      }
      return($errorlevel,{qmsg=>\@qmsg});
   }
   return($errorlevel,undef);
}



1;
