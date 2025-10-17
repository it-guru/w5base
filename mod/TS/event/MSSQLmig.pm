package TS::event::MSSQLmig;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
use finance::costcenter;
@ISA=qw(kernel::Event);

our @okmssql=qw(
   MS_SQL_Server_EnterpriseEdition
   MS_SQL_Server_ExpressEdition
   MS_SQL_Server_StandardEdition
   MS_SQL_Server_DeveloperEdition
);
our @depmssql=qw(
   MS_SQL_Server_2000_Standard
   MS_SQL_Server_2005_EnterpriseEdition
   MS_SQL_Server_2005_Express
   MS_SQL_Server_2008_DeveloperEdition
   MS_SQL_Server_2008_DeveloperEdition_R2
   MS_SQL_Server_2008_EnterpriseEdition
   MS_SQL_Server_2008_Enterprise_R2
   MS_SQL_Server_2008_Express
   MS_SQL_Server_2008_Express_R2
   MS_SQL_Server_2008_Standard
   MS_SQL_Server_2008_Standard_R2
   MS_SQL_Server_2012_Business_Intelligence
   MS_SQL_Server_2012_Enterprise
   MS_SQL_Server_2012_Express
   MS_SQL_Server_2012_Standard
);

our $versionmap=<<EOF;
MSSQL Marketing Version -> technical Versions
(based on https://de.wikipedia.org/wiki/Microsoft_SQL_Server )

MSSQL Server 1.0     =  1.0
MSSQL Server 1.1     =  1.1
MSSQL Server 4,21    =  4.21
MSSQL Server 6.0     =  6.0
MSSQL Server 7.0     =  7.0
MSSQL Server 2000    =  8.0
MSSQL Server 2005    =  9.0
MSSQL Server 2008    = 10.0
MSSQL Azure          = 10.25
MSSQL Server 2008 R2 = 10.5
MSSQL Server 2012    = 11.0
MSSQL Server 2014    = 12.0

EOF
our $swmap;

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub MSSQLmig
{
   my $self=shift;
   my $sw=getModuleObject($self->Config,"itil::software");

   $W5V2::HistoryComments="Modifications based on Request https://darwin.telekom.de/darwin/auth/base/workflow/ById/14358300160005";

   $sw->SetFilter({name=>[@okmssql,@depmssql],cistatusid=>4});
   $sw->SetCurrentView(qw(id name releaseexp comments cistatusid 
                          is_dms is_mw comments producer producerid));

   $swmap=$sw->getHashIndexed(qw(id name));


   my $lnk=getModuleObject($self->Config,"itil::lnksoftware");
   $lnk->SetFilter({software=>[keys(%{$swmap->{name}})],cicistatusid=>'!6'});
   $lnk->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$lnk->getFirst();
   if (defined($rec)){
      do{
         my $upd;
         if (in_array(\@okmssql,$rec->{software})){
            $upd->{software}=$rec->{software};
            if ($rec->{version} eq "2000"){
               $upd->{version}='8.0'; 
            }
            if ($rec->{version} eq "2012"){
               $upd->{version}='11.0'; 
            }
            if ($rec->{version} eq "2008"){
               $upd->{version}='10.0'; 
            }
            if ($rec->{version} eq "2008R2"){
               $upd->{version}='10.5'; 
            }
            if ($rec->{version}=~m/^2005/){
               $upd->{version}='9.0'; 
            }
         }
         if ($rec->{software} eq "MS_SQL_Server_2012_Standard"){
            $upd->{software}='MS_SQL_Server_StandardEdition';
            if (!($rec->{version}=~m/^11\.0/)){
               $upd->{version}='11.0'; 
            }
         }

         if ($rec->{software} eq "MS_SQL_Server_2008_Standard"){
            $upd->{software}='MS_SQL_Server_StandardEdition';
            if (!($rec->{version}=~m/^10\.0/)){
               $upd->{version}='10.0'; 
            }
         }
         if ($rec->{software} eq "MS_SQL_Server_2008_Standard_R2"){
            $upd->{software}='MS_SQL_Server_StandardEdition';
            if (!($rec->{version}=~m/^10\.5/)){
               $upd->{version}='10.5'; 
            }
         }

         if ($rec->{software} eq "MS_SQL_Server_2000_Standard"){
            $upd->{software}='MS_SQL_Server_StandardEdition';
            if (!($rec->{version}=~m/^8\.0/)){
               $upd->{version}='8.0'; 
            }
         }

         if ($rec->{software} eq "MS_SQL_Server_2012_Express"){
            $upd->{software}='MS_SQL_Server_ExpressEdition';
            if (!($rec->{version}=~m/^11\.0/)){
               $upd->{version}='11.0'; 
            }
         }
         if ($rec->{software} eq "MS_SQL_Server_2008_Express"){
            $upd->{software}='MS_SQL_Server_ExpressEdition';
            if (!($rec->{version}=~m/^10\.0/)){
               $upd->{version}='10.0'; 
            }
         }
         if ($rec->{software} eq "MS_SQL_Server_2008_Express_R2"){
            $upd->{software}='MS_SQL_Server_ExpressEdition';
            if (!($rec->{version}=~m/^10\.5/)){
               $upd->{version}='10.5'; 
            }
         }
         if ($rec->{software} eq "MS_SQL_Server_2005_Express"){
            $upd->{software}='MS_SQL_Server_ExpressEdition';
            if (!($rec->{version}=~m/^9\.0/)){
               $upd->{version}='9.0'; 
            }
         }

         if ($rec->{software} eq "MS_SQL_Server_2012_Enterprise"){
            $upd->{software}='MS_SQL_Server_EnterpriseEdition';
            if (!($rec->{version}=~m/^11\.0/)){
               $upd->{version}='11.0'; 
            }
         }

         if ($rec->{software} eq "MS_SQL_Server_2008_EnterpriseEdition"){
            $upd->{software}='MS_SQL_Server_EnterpriseEdition';
            if (!($rec->{version}=~m/^10\.0/)){
               $upd->{version}='10.0'; 
            }
         }

         if ($rec->{software} eq "MS_SQL_Server_2008_Enterprise_R2"){
            $upd->{software}='MS_SQL_Server_EnterpriseEdition';
            if (!($rec->{version}=~m/^10\.5/)){
               $upd->{version}='10.5'; 
            }
         }

         if ($rec->{software} eq "MS_SQL_Server_2005_EnterpriseEdition"){
            $upd->{software}='MS_SQL_Server_EnterpriseEdition';
            if (!($rec->{version}=~m/^9\.0/)){
               $upd->{version}='9.0'; 
            }
         }
         if ($rec->{majorminorkey} eq "" ||
             $rec->{majorminorkey} eq "?"){
           $upd->{version}=$rec->{version};
         }

         if (defined($upd)){
            my $lnk=getModuleObject($self->Config,"itil::lnksoftware");
            $lnk->ValidatedUpdateRecord($rec,$upd,{id=>\$rec->{id}});
         }
         else{
            msg(ERROR,"missing mapping $rec->{software} Version $rec->{version}");
         }
         #msg(DEBUG,"dump=%s",Dumper($rec));
         ($rec,$msg)=$lnk->getNext();
      } until(!defined($rec));
   }





   #print STDERR Dumper($swmap);

   #$self->UpdateBaseData();
   return({exitcode=>0});
}


sub UpdateBaseData
{
   my $self=shift;

   my $sw=getModuleObject($self->Config,"itil::software");
   foreach my $depmssql (@depmssql){
      my $oldrec=$swmap->{name}->{$depmssql};
      if (defined($oldrec)){
         my $bk=$sw->ValidatedUpdateRecord($oldrec,{cistatusid=>6},
                                           {id=>\$oldrec->{id}});
         printf STDERR ("fifi bk on $depmssql = $bk\n");
      }
      else{
         msg(ERROR,"missing $depmssql");
      }
   }
   foreach my $okmssql (@okmssql){
      my $oldrec=$swmap->{name}->{$okmssql};
      if (defined($oldrec)){
         my $bk=$sw->ValidatedUpdateRecord($oldrec,{comments=>$versionmap},
                                           {id=>\$oldrec->{id}});
         printf STDERR ("fifi bk on $okmssql = $bk\n");
      }
      else{
         msg(ERROR,"missing $okmssql");
      }
   }
}


1;
