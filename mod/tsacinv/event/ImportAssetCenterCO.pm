package tsacinv::event::ImportAssetCenterCO;
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

   $self->RegisterEvent("ImportAssetCenterCO","ImportAssetCenterCO");
   return(1);
}

sub ImportAssetCenterCO
{
   my $self=shift;

   my $co=getModuleObject($self->Config,"tsacinv::costcenter");
   my $w5co=getModuleObject($self->Config,"itil::costcenter");
   $co->SetFilter({bc=>\'AL T-COM'});
   my @l=$co->getHashList(qw(name description));
   foreach my $rec (@l){
     msg(INFO,"co=$rec->{name}");
     next if (!($rec->{name}=~m/^\d{5,20}$/));
     $w5co->ResetFilter();
     $w5co->SetFilter({name=>\$rec->{name}});
     my ($w5rec,$msg)=$w5co->getOnlyFirst(qw(name));
     my $newrec={cistatusid=>4,
                 fullname=>$rec->{description},
                 comments=>"authority at AssetCenter",
                 srcload=>NowStamp(),
                 name=>$rec->{name}};
     if (!defined($w5rec)){
        $w5co->ValidatedInsertRecord($newrec);
     }
     else{
        $w5co->ValidatedUpdateRecord($w5rec,$newrec,{name=>\$rec->{name}});
     }
   }
   return({exitcode=>0}); 
}



1;
