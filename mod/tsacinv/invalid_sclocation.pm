package tsacinv::invalid_sclocation;
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
use tsacinv::sclocation;
@ISA=qw(tsacinv::sclocation);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'isclocationid',
                label         =>'iSC-LocationID',
                dataobjattr   =>'amtsisclocations.sclocationid')
   );
   $self->setDefaultView(qw(linenumber name sclocationid));

   return($self);
}



sub SetFilter
{
   my $self=shift;
   my @flt=@_;

   if ($#flt!=0 || ref($flt[0]) ne "HASH"){
      $self->LastMsg("ERROR","invalid Filter request on $self");
      return(undef);
   }
   my @fltfields=keys(%{$flt[0]});
   if ($#fltfields!=0 || $fltfields[0] ne "id"){
      my $o=getModuleObject($self->Config,"tssm::company");
      $o->SetCurrentView(qw(id msskey));
     
      my $validComp=$o->getHashIndexed("msskey");
      $flt[0]->{isclocationid}=join(" ",
          map({'"!'.$_.'"'} keys(%{$validComp->{msskey}}))
      );
   }

   return($self->SUPER::SetFilter(@flt));
}








1;
