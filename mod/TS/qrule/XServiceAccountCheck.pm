package TS::qrule::XServiceAccountCheck;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Validates and corrects EMEA?/X* accounts

=head3 IMPORTS

NONE

=head3 HINTS

Verification of the use of EMEA?/X* identifiers and correction of possible misconfigurations.Service accounts are not allowed as identifiers for contact type "user".


[de:]

Überprüfung der Verwendung von EMEA?/X* Kennungen und Korrektur 
möglicher Fehlkonfigurationen. Service Kennungen sind nicht als 
Benutzerkennungen bei Kontakt Typ "user" erlaubt. 




=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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


  # return(undef) if ($rec->{cistatusid}!=4);

   my %xaccount;
   my %saccount;
   my %uaccount;

   foreach my $arec (@{$rec->{accounts}}){
      if ($arec->{account}=~m/^emea[0-9]{1,2}[\/\\_]x[0-9]+$/i){
         $xaccount{$arec->{account}}++;
      }   
      elsif ($arec->{account}=~m/^service[\/\\_].+$/i){
         $saccount{$arec->{account}}++;
      }
      else{
         $uaccount{$arec->{account}}++;
      }
   }

   #print STDERR "xaccount:".Dumper(\%xaccount);
   #print STDERR "saccount:".Dumper(\%saccount);
   #print STDERR "uaccount:".Dumper(\%uaccount);
   #printf STDERR ("usertyp=%s\n",$rec->{usertyp});

   if ($rec->{usertyp} eq "serivce"){
      if (keys(%uaccount)){
         push(@qmsg,"personalized account detected");
      }
   }
   if ($rec->{usertyp} eq "user"){
      #printf STDERR ("fifi u:%d\n",scalar(keys(%uaccount)));
      #printf STDERR ("fifi s:%d\n",scalar(keys(%saccount)));
      #printf STDERR ("fifi x:%d\n",scalar(keys(%xaccount)));
      if (keys(%uaccount) && ( keys(%saccount) || keys(%xaccount))){
         push(@qmsg,"mixed account constellation in user contact");
         if (keys(%saccount)){
            $errorlevel=3 if ($errorlevel<3);
            my $msg="illegal service account in user contact";
            push(@qmsg,$msg);
            push(@dataissue,$msg);
         }
         if (keys(%xaccount)){
            my $o=getModuleObject($dataobj->Config,"base::useraccount");
            foreach my $acc (keys(%xaccount)){
               push(@qmsg,"drop account: $acc");
               $o->ValidatedDeleteRecord({
                   account=>$acc,
                   userid=>$rec->{userid}
               });
            }
         }
      }
      elsif (!keys(%uaccount) && ( keys(%xaccount))){
         push(@qmsg,"self created service account detected - change user typ");
         $forcedupd->{usertyp}="service";
      }
   }
   if ($rec->{usertyp} eq "extern"){
      if (keys(%uaccount) || keys(%saccount) || keys(%xaccount)){
         push(@qmsg,"illeagal account in extern contact");
      }
   }








   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}



1;
