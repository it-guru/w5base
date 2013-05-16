package itil::qrule::SystemInstalledSoftware;
#######################################################################
=pod

=head3 PURPOSE

Every System in in CI-Status "installed/active" or "available", may
only use software products in software installations with an CI-Status
of 3,4 or 5. In other cases, there will be a dataissue produced.
For some instance types (OracleDB, Tomcat, Apache, Mysql) there will be
a check done, if needed Software for these instances is installed
on the logical system.


=head3 IMPORTS

NONE

=cut
#######################################################################
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
   return(["itil::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my @msg;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   my %swneeded=();
   my %swifound=();
   my %swiprod=();
   if (ref($rec->{swinstances}) eq "ARRAY"){
      foreach my $swi (@{$rec->{swinstances}}){
         if ($swi->{softwareinstname} eq ""){ # this is a instance with no
            $swneeded{$swi->{swnature}}++;    # assinged software installation
         }
         if ($swi->{techproductstring} ne "" &&
             ($swi->{techrelstring}=~m/[0-9.]+/)){
            if (!defined($swiprod{$swi->{techproductstring}})){
               $swiprod{$swi->{techproductstring}}={};
            }
            $swiprod{$swi->{techproductstring}}->{$swi->{techrelstring}}++;
         }
      }
   }
   my %checkedswiprod;
   if (keys(%swiprod)){
      my $sw=getModuleObject($dataobj->Config,"itil::software");
      $sw->SetFilter({name=>[keys(%swiprod)]});
      foreach my $s ($sw->getHashList(qw(name id))){
         if (ref($swiprod{$s->{name}}) eq "HASH"){
            $checkedswiprod{$s->{name}}=$swiprod{$s->{name}};
         }
      }
   }

   if (ref($rec->{software}) eq "ARRAY"){
      foreach my $swrec (@{$rec->{software}}){
         $swifound{$swrec->{software}}++;
         if (exists($checkedswiprod{$swrec->{software}})){
            delete($checkedswiprod{$swrec->{software}}->{$swrec->{version}});
            if (!keys(%{$checkedswiprod{$swrec->{software}}})){
               delete($checkedswiprod{$swrec->{software}});
            }
         }
         if ($swrec->{softwarecistatusid}!=4 &&
             $swrec->{softwarecistatusid}!=5 &&
             $swrec->{softwarecistatusid}!=3){
            my $n=$swrec->{software};
            $n=~s/\[\d+\]$//;
            push(@msg,"an installed software is no longer valid: ".$n);
         }
      }
   }
   if (keys(%checkedswiprod)){
      foreach my $software (sort(keys(%checkedswiprod))){
         foreach my $version (sort(keys(%{$checkedswiprod{$software}}))){
            push(@msg,
                 "missing software installation for ".
                 "related software instances: ".$software." - ".$version);
         }
      }
   }
   my %chkmap=("Oracle DB Server"=>'^oracle.*database.*$',
               "Apache"=>'^.*apache.*(web|http).*$',
               "Tomcat"=>'^.*tomcat.*$',
               "MySQL"=>'^.*mysql.*server.*$');
   foreach my $chk (sort(keys(%chkmap))){
      if (exists($swneeded{$chk})){
         my $chkexp=$chkmap{$chk};
         if (!(grep(/$chkexp/i,keys(%swifound)))){
            push(@msg,"missing installation of software for: ".$chk);
         }
      }
   }
   #printf STDERR ("fifi needed=%s found=%s\n",
   #               Dumper(\%swneeded),Dumper(\%swifound));
   if ($#msg!=-1){
      return(3,{qmsg=>\@msg,dataissue=>\@msg});
   }
   return(0,undef);

}



1;
