package TS::event::GrpMig;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub GrpMig
{
   my $self=shift;
   my $bak={exitcode=>0};

   if (!open(MISS,">MissInAssetManager.csv")){
      die("fail to open MissInAssetManager.csv"); 
   }
   if (!open(BAD,">BadInAssetManager.csv")){
      die("fail to open BadInAssetManager.csv"); 
   }
   if (!syswrite(MISS,"groupname;usecount\r\n")){
      die("fail to write MissInAssetManager.csv"); 
   }
   if (!syswrite(BAD,"groupname;failcount\r\n")){
      die("fail to write BadInAssetManager.csv"); 
   }

   my $appl=getModuleObject($self->Config,"TS::appl");
   $appl->SetFilter({cistatusid=>"<6"});
   my @fld=qw(scapprgroup scapprgroup2);

   my %ref;
   my %bad;
   
   foreach my $rec ($appl->getHashList(@fld)){
      foreach my $f (@fld){
         if ($rec->{$f} ne ""){
            $ref{$rec->{$f}}++;
         }
      }
   }
   my $grp=getModuleObject($self->Config,"tsacinv::group");
   $grp->SetFilter({name=>[keys(%ref)]});
   foreach my $rec ($grp->getHashList(qw(name))){
      if (exists($ref{$rec->{name}})){
         delete($ref{$rec->{name}});
      }
      else{
         $bad{$ref{$rec->{name}}}++;
      }
   }
   foreach my $grp (sort(keys(%ref))){
      syswrite(MISS,sprintf("%s;%s\r\n",$grp,$ref{$grp}));
   }
   foreach my $grp (sort(keys(%bad))){
      syswrite(BAD,sprintf("%s;%s\r\n",$grp,$bad{$grp}));
   }

   close(MISS);
   close(BAD);
   return($bak);
}
1;
