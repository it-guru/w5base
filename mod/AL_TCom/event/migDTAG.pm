package AL_TCom::event::migDTAG;
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
use kernel;

@ISA=qw(kernel::Event);

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


   $self->RegisterEvent("MigDTAG","MigDTAG");
   return(1);
}


sub MigDTAG
{
   my $self=shift;
   my $lnk=getModuleObject($self->Config,"base::lnkgrpuser");

   $lnk->SetFilter({group=>'dtag.tdg.t-home* dtag.tdg.tmo* '.
                           'dtag.tdg.activebilling*'});

   my @l=$lnk->getHashList(qw(ALL));
   #printf STDERR ("fifi d=%s\n",Dumper(\@l));
   foreach my $lnkrec (@l){
      my $d=Dumper($lnkrec);
   }

   my $n=360;
   foreach my $lnkrec (@l){
      my %upd=();
      $upd{group}="DTAG.TDG";
      if ($lnkrec->{expiration} eq ""){
         $n+=5;
         $upd{expiration}=$lnk->ExpandTimeExpression("now+${n}d","en");
      }
      $upd{comments}=$lnkrec->{comments};
      $upd{comments}.="\n\n" if ($upd{comments} ne "");
      $upd{comments}.="Migration from ".$lnkrec->{group};
      $upd{mdate}=$lnkrec->{mdate};
      $upd{owner}=$lnkrec->{owner};
      $upd{owner}=$lnkrec->{owner};
     # $upd{roles}=$lnkrec->{nativroles};
      $upd{editor}=$lnkrec->{editor};
printf STDERR ("fifi d=%s\n",Dumper($lnkrec->{nativroles}));
      $lnk->ValidatedUpdateRecord($lnkrec,\%upd,
            {lnkgrpuserid=>\$lnkrec->{lnkgrpuserid}});

   }
   


   return({exitcode=>0});
}

1;
