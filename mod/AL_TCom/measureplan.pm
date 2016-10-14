package AL_TCom::measureplan;
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
use kernel::Field;
use temporal::CalendarEngine;
@ISA=qw(temporal::CalendarEngine);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getExMenuWidth
{
   my $self=shift;

   return("0");

}

sub getDataDetailCode
{
   my $self=shift;
   my $opt={
   };
   my $d=$self->getParsedTemplate("tmpl/AL_TCom.measureplan.DataDetail",$opt);
   
   return($d);
}



sub EventList
{
   my $self=shift;

   print $self->HttpHeader("text/javascript",charset=>'UTF-8');

   my $timezone=Query->Param("timezone");
   if ($timezone eq ""){
      $timezone=$self->getFrontendTimezone();
   }
   my $s=Query->Param("start");
   my $e=Query->Param("end");
   my $trange="";

   if ($e ne "" && $s ne ""){
      $trange="\"${s} 00:00:00/${e} 23:59:59\"";
   }
   my @l=();

   my $o=getModuleObject($self->Config,"temporal::tspan");
   $o->SecureSetFilter({
      trange=>$trange,
      planclass=>\'TCLASS.measureplan'
   });
   foreach my $ev ($o->getHashList(qw(id tfrom tto name planid comments
                                      color subsys recordWrite recordDelete
                                      mgmtitemgroupname mgmtitemgroupid))){
      my $start=$self->ExpandTimeExpression($ev->{tfrom},"en","GMT",$timezone);
      my $end=$self->ExpandTimeExpression($ev->{tto},"en","GMT",$timezone);
      my %e=(
         title=>$ev->{name},
         start=>$start,
         mgmtitemgroupname=>$ev->{mgmtitemgroupname},
         mgmtitemgroupid=>$ev->{mgmtitemgroupid},
         subsys=>$ev->{subsys},
         recordWrite=>$ev->{recordWrite},
         recordDelete=>$ev->{recordDelete},
         start_formated=>$start,
         color=>$ev->{color},
         comments=>$ev->{comments},
         end=>$end,
         end_formated=>$end,
         id=>$ev->{id},
      );
      push(@l,\%e);
      #print STDERR Dumper($ev);

   }
   eval("use JSON;");
   if ($@ eq ""){
      my $json;
      eval('$json=to_json(\@l, {ascii => 1});');
      #print STDERR $json."\n";
      print $json;
   }
   else{
      printf STDERR ("ERROR: ganz schlecht: %s\n",$@);
   }
}












1;
