package tscape::event::CapeCanvasHubimport;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{fieldlist}=[qw(ictono)];

   return($self);
}


sub CapeCanvasHubimport
{
   my $self=shift;
   my $start=NowStamp("en");


   my $c=0;

   my $i=getModuleObject($self->Config,"tscape::archappl");
   return({}) if ($i->isSuspended());

   my $vou=getModuleObject($self->Config,"TS::vou");
   return({}) if ($vou->isSuspended());

   my $canvaso=getModuleObject($self->Config,"TS::canvas");
   return({}) if ($canvaso->isSuspended());

   my $lnkcanv=getModuleObject($self->Config,"TS::lnkcanvas");
   return({}) if ($lnkcanv->isSuspended());


   $vou->SetFilter({cistatusid=>"<6"});
   $vou->SetCurrentView(qw( id shortname ));
   my $v=$vou->getHashIndexed(qw(shortname));


   $canvaso->SetFilter({cistatusid=>"<6"});
   $canvaso->SetCurrentView(qw( id canvasid ));
   my $canvas=$canvaso->getHashIndexed(qw(canvasid));



   my $iname=$i->Self();
   $i->SetFilter({status=>'"!Retired"'});
   foreach my $irec ($i->getHashList(qw(archapplid 
                                        id 
                                        respvorg  orgarea organisation
                                        canvas))){
      next if ($irec->{canvas}=~m/^C99 /); # No Canvas dummy records
      next if ($irec->{canvas} eq "");
      $c++;
      my $icto=$irec->{archapplid};
      my $ictoid=$irec->{id};
      my ($canvasidstr)=$irec->{canvas}=~m/^(C[0-9]{1,3})\s+/;
      my ($hubshort)=$irec->{organisation}=~m/^E-HUB-[0-9]+\s+(\S{2,4})\s+/;
      if ($hubshort eq ""){
         ($hubshort)=$irec->{organisation}=~m/^(\S{3})\s+/;
      }
      my $vouid;
      if (exists($v->{shortname}->{$hubshort})){
         $vouid=$v->{shortname}->{$hubshort}->{id};
      }
      my $canvasid;
      if (exists($canvas->{canvasid}->{$canvasidstr})){
         $canvasid=$canvas->{canvasid}->{$canvasidstr}->{id};
      }
      
      if (0){
         printf STDERR (
             "%03d %-8s %-8s %-3s hub=%-3s vou=%s canvas=%s\n",
             $c,$icto,$ictoid,$canvasidstr,$hubshort,$vouid,$canvasid
         );
         printf STDERR ("rec[$c]=%s\n",Dumper($irec));
      }

      my $newrec={
         ictoid=>$ictoid,
         vouid=>$vouid,
         canvasid=>$canvasid,
         srcsys=>$iname,
         srcload=>NowStamp("en")
      };

      $lnkcanv->ResetFilter();
      $lnkcanv->SetFilter({ictoid=>\$newrec->{ictoid}});
      my @l=$lnkcanv->getHashList(qw(ALL));
      if ($#l>0){
         msg(WARN,"something went wron - somebody has ass manuell entries");
         msg(WARN,"to lnkcanvas for ICTO $newrec->{ictoid}");
         foreach my $oldrec (@l){
            $lnkcanv->ValidatedDeleteRecord($oldrec,{id=>\$oldrec->{id}});
         }
      }
      if ($canvasid ne ""){
         $lnkcanv->ResetFilter();
         $lnkcanv->ValidatedInsertOrUpdateRecord($newrec,{
            ictoid=>\$newrec->{ictoid}
         });
      }
      # manuell erstellte Einträge werden gelöscht bzw. überschrieben 
      # da Cape aktuell als Master angesehen werden soll
   }
   $lnkcanv->BulkDeleteRecord({'srcload'=>"<\"$start\"",srcsys=>\$iname});
   return({exitcode=>0});
}


1;
