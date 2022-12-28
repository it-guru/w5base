package AL_TCom::event::fixupCI1stActivation;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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

   return($self);
}


sub fixupCI1stActivation
{
   my $self=shift;

   my $ca=getModuleObject($self->Config,"itil::itcloudarea");
   my $hist=getModuleObject($self->Config,"base::history");

   $ca->SetFilter({cistatusid=>"<6"});
   my $n=0;

   foreach my $oldrec ($ca->getHashList(qw(ALL))){
      $hist->ResetFilter();
      $hist->SetFilter({dataobjectid=>\$oldrec->{id},
                        dataobject=>\'itil::itcloudarea',
                        name=>'cistatusid',
                        newstate=>'4'});
      my @l=$hist->getHashList(qw(+cdate name newstate));
      if ($#l!=-1){
         my $firstact=$l[0]->{cdate};
         if ($oldrec->{cifirstactivation} ne $firstact){
            printf STDERR ("CloudArea %s upd from %s to %s\n",
                           $oldrec->{id},
                           $oldrec->{cifirstactivation},$firstact);
            my $op=$ca->Clone();
            $op->UpdateRecord({cifirstactivation=>$firstact},
                              {id=>\$oldrec->{id}});
            $n++;
         }
      }
   }
   msg(INFO,"update count=".$n);


   return({exitcode=>0,msg=>'replaced '.$n});
}





1;
