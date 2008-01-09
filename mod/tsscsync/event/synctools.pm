package tsscsync::event::synctools;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use Data::Dumper;
use kernel;
use kernel::Event;
use tsscsync::lib::io;
#use SC::Customer::TSystems;
@ISA=qw(kernel::Event tsscsync::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("softwareidsync","SoftwareIdSync",timeout=>60);
   $self->RegisterEvent("syncPassReset","syncPassReset",timeout=>60);
   return(1);
}

sub SoftwareIdSync
{
   my $self=shift;

   my $appl=getModuleObject($self->Config,"tsacinv::appl");
   if (!defined($appl)){
      return({exitcode=>1,msg=>"can't create Object tsacinv::appl"});
   }
   my $bk=$self->ConnectSC();
   return($bk) if (defined($bk));
   #$self->{sc}->setDebugDirectory(".");

   msg(DEBUG,"starting SoftwareIdSync");

   my $searchResult;
   my %flt=('parent.location.name' => 'TCOM-D-BONN-LAND-151');
   if (!defined($searchResult=$self->{sc}->SoftwareInstallationSearch(%flt))){
      return({exitcode=>1,msg=>"SoftwareInstallationSearch failed"});
   }
   my %scsoftwareid=(); 
   if (ref($searchResult) eq "ARRAY"){
      do{
         $scsoftwareid{$searchResult->[0]->{'sw.name'}}=1;
      }until(!defined($searchResult=$self->{sc}->SearchNextRecord()));
   }
   my @scsoftwareid=sort(keys(%scsoftwareid));

   $appl->SetFilter({srcsys=>\"W5Base"});
   my @acappl=$appl->getHashList("name");
   my @acname=sort(map({$_->{name}} @acappl));
   my $c=0;
   foreach my $acname (@acname){
      my $qacname=quotemeta($acname);
      if (!grep(/^$qacname$/,@scsoftwareid)){
         $c++;
         msg(DEBUG,"SoftwareID '%s' is missing in ServiceCenter",$acname);
      }
   }

   foreach my $scsoftwareid (@scsoftwareid){
      my $qscsoftwareid=quotemeta($scsoftwareid);
      if (!grep(/^$qscsoftwareid$/,@acname)){
         $c++;
         msg(DEBUG,"SoftwareID '%s' is obsolete in ServiceCenter",
                   $scsoftwareid);
      }
   }
   msg(DEBUG,"Found %d deltas SC=%d records  ; AC=%d records",$c,
              $#scsoftwareid+1,$#acname+1);

   my $bk=$self->DisconnectSC();
   return($bk) if (defined($bk));
   return({exitcode=>'0'});
}


sub syncPassReset
{
   my $self=shift;
   my $wfid=shift;

}

1;
