package base::qrule::ContactScrap;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This rule analyses a contact for indicators if the contact
needs to set as "disposed of waste".
Contacts with a lastexternalseeni more then 6 weeks in the past are
candidates to set as "disposed of waste". If there are logons on
this contacts in the last 4,5 weeks, this indicates a inconsistency
which will be logged in basedata logs. 

=head3 IMPORTS

NONE

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   if ($rec->{cistatusid}<6 && $rec->{cistatusid}>2){
      if ($rec->{lastexternalseen} ne ""){
         my $lseen=$rec->{lastexternalseen};
         my $llogon=$rec->{lastlogon};
         if ($llogon ne ""){
            my $d=CalcDateDuration($llogon,NowStamp("en"));
            if (defined($d) && $d->{totalminutes}>45360){  # 4,5 weeks
               $llogon=undef;
            }
         }
         my $d=CalcDateDuration($rec->{lastexternalseen},NowStamp("en"));
         if (defined($d)){
            if ($d->{totalminutes}>60480){     # 6 weeks
               if ($llogon eq ""){  # ok, cleanup
                  my $o=$dataobj->Clone();
                  $o->ValidatedUpdateRecord($rec,{
                        lastexternalseen=>'',
                        cistatusid=>6,mdate=>NowStamp("en")
                     },{userid=>\$rec->{userid}
                  });
                  push(@qmsg,"deactivating contact entry");
               }
               else{               # error, logons without external ok
                  $dataobj->Log(ERROR,"basedata",
                                 "contact '%s' logons without up to date ".
                                 "externalseen date",
                                 $rec->{fullname});
                  $errorlevel=3;
               }
            }
         }
         else{
             msg(ERROR,"not good - date calc error");
             print STDERR Dumper($rec);
         }
      }
      else{
         push(@qmsg,"contact never has been seen");
      }
   }
   else{
      return(undef,undef);
   }
   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
