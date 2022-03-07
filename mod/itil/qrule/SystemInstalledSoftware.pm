package itil::qrule::SystemInstalledSoftware;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every System in CI-State "installed/active" or "available/in project" 
may only use software products in software installations with a CI-State 
of 3, 4 or 5. In other cases a DataIssue will be generated. A check is 
executed for some instance types (OracleDB, Tomcat, Apache, Mysql) 
to find out whether the software needed for these instances is installed 
on the logical system.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Please enter a valid software product that is installed on the system. 
An overview of software that can be entered on a system can be found under 
"IT-Inventory -> Basedata -> Software". You can find a more detailed 
explanation in the FAQ Article
https://darwin.telekom.de/darwin/auth/faq/article/ById/12560368290002

[de:]

Bitte tragen Sie ein gültiges Software-Produkt ein. 
Einen Überblick der Software, die eingetragen werden kann, ist 
unter "IT-Inventar -> Stammdaten -> Software"
zu finden. Eine detaillierte Beschreibung zum Eintragen von Software finden 
Sie in dem FAQ-Artikel
https://darwin.telekom.de/darwin/auth/faq/article/ById/12560368290002


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
   return(["itil::system","itil::lnkitclustsvc"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my @msg;

   if ($dataobj->SelfAsParentObject() eq "itil::system"){
      return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   }

   my %swneeded=();
   my %swifound=();
   my %swiprod=();
   if (ref($rec->{swinstances}) eq "ARRAY"){
      foreach my $swi (@{$rec->{swinstances}}){
         if ($swi->{softwareinstname} eq ""){ # this is a instance with no
            $swneeded{$swi->{swnature}}++;    # assigned software installation
         }
         my $techdatavalid=0;

         if ($swi->{techdataupdate} ne ""){
            my $d=CalcDateDuration($swi->{techdataupdate},NowStamp("en"));
            if (defined($d) && $d->{days}<90){
               $techdatavalid=1;
            }
         }

         if ($techdatavalid){
            if ($swi->{techproductstring} ne ""){
               if (!defined($swiprod{$swi->{techproductstring}})){
                  $swiprod{$swi->{techproductstring}}={};
               }
               if ($swi->{techrelstring}=~m/[0-9.]+/){
                  $swiprod{$swi->{techproductstring}}->{$swi->{techrelstring}}++;
               }
               else{
                  $swiprod{$swi->{techproductstring}}->{'ANY'}++;
               }
            }
         }
         else{
            if ($swi->{techproductstring} ne "" ||
                $swi->{techrelstring} ne ""){
               # reset techdata (autodisc)
               my $swinst=getModuleObject($dataobj->Config,"itil::swinstance");
               $swinst->SetFilter({id=>\$swi->{id}});
               my ($old,$msg)=$swinst->getOnlyFirst(qw(ALL));
               if (defined($old)){
                  msg(INFO,"reset techdata on swinstance $swi->{id}");
                  $swinst->ValidatedUpdateRecord($old,{
                     techproductstring=>undef,
                     techrelstring=>undef
                  },{id=>\$swi->{id}});
               }
            }
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
         if ($swrec->{softwarecistatusid}!=4 &&
             $swrec->{softwarecistatusid}!=5 &&
             $swrec->{softwarecistatusid}!=3){
            my $n=$swrec->{software};
            $n=~s/\[\d+\]$//;
            push(@msg,"an installed software is no longer valid: ".$n);
         }
      }
   }


   # check if assign of a plausible software-installation is posible. If
   # we on an logical system, only all software on this system are candidats.
   # if we on a clusterservice, all software on the clusterservice and all
   # nodes are candidats
   my $softinst=getModuleObject($dataobj->Config,"itil::lnksoftwaresystem");
   my @softinstid;

   if (ref($rec->{software}) eq "ARRAY"){
      foreach my $swrec (@{$rec->{software}}){
         push(@softinstid,$swrec->{id});
      }
   }
   @softinstid=(-1) if ($#softinstid==-1);

   my @softinstflt=({id=>\@softinstid});
   if ($dataobj->SelfAsParentObject() eq "itil::lnkitclustsvc"){
      my @sys;
      foreach my $sys (@{$rec->{posiblesystems}}){
         push(@sys,$sys->{syssystemid});
      } 
      @sys=(-1) if ($#sys==-1);
      push(@softinstflt,{systemid=>\@sys});
   }
   $softinst->SetFilter(\@softinstflt);

   foreach my $swrec ($softinst->getHashList(qw(id software version))){
      my @swname=($swrec->{software});
      if ($swrec->{software}=~m/^oracle_database.*/i){
         push(@swname,"Oracle_Database_Enterprise_Edition");
      }
      foreach my $swname (@swname){
         $swifound{$swname}++;
         if (exists($checkedswiprod{$swname})){
            delete($checkedswiprod{$swname}->{$swrec->{version}});
            delete($checkedswiprod{$swname}->{'ANY'});
            if (!keys(%{$checkedswiprod{$swname}})){
               delete($checkedswiprod{$swname});
            }
         }
      }
   }



   if (keys(%checkedswiprod)){
      foreach my $software (sort(keys(%checkedswiprod))){
         foreach my $version (sort(keys(%{$checkedswiprod{$software}}))){
            if ($version eq "ANY"){
               push(@msg,
                    "missing software installation for ".
                    "related software instances: ".$software);
            }
            else{
               push(@msg,
                    "missing software installation for ".
                    "related software instances: ".$software." - ".$version);
            }
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
