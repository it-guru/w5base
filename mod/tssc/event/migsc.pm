package tssc::event::migsc;
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


   $self->RegisterEvent("migsc","migsc");
}

sub migsc
{
   my $self=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");
   $wf->SetFilter({srcsys=>['tssc::event::scchange'],
   #                srcid=>[qw( 432578 435253)]
                   });
   $wf->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
         my $changed=0;
         if (($rec->{srcid}=~m/^\d+$/)){
            msg(INFO,"============= srcid=%s ================",$rec->{srcid});
            my %newrec=(additional=>$rec->{additional},
                        mdate=>$rec->{mdate},
                        owner=>$rec->{owner},
                        editor=>$rec->{editor},
                        realeditor=>$rec->{realeditor},
                        );
            if (ref($rec->{additional}) ne "HASH"){
               my %add=Datafield2Hash($rec->{additional});
               $newrec{additional}=\%add;
            }
            if ($rec->{srcsys} eq "tssc::event::scchange"){
               if (!($rec->{srcid}=~m/^GER/)){
                  $newrec{srcid}="GER_".$rec->{srcid};
                  $newrec{additional}->{ServiceCenterChangeNumber}->[0]=
                                  $newrec{srcid};
                  $changed=1;
               }
            }
            if ($changed){
               #msg(INFO,"%s",Dumper($rec));
               $wf->ValidatedUpdateRecord($rec,\%newrec,{id=>\$rec->{id}});
            }
         }

         ($rec,$msg)=$wf->getNext();
         if (defined($msg)){
            msg(ERROR,"db record problem: %s",$msg);
            return({exitcode=>1});
         }
      }until(!defined($rec));
   }



   return({}); 
}





1;
