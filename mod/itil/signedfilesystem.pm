package itil::signedfilesystem;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use base::signedfile;
@ISA=qw(base::signedfile);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'parentname',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['parentid'=>'id'],
                vjoindisp     =>'name'),
      insertafter=>'id'
   );

   $self->{secparentobj}="itil::system";

   return($self);
}

sub SecureSetFilter   # access to signed files is restricted to databoss
{
   my $self=shift;
   my @flt=@_;
   if ($#flt>0){
      return($self->SetFilter({id=>\'-99'}));
   }
   my $userid=$self->getCurrentUserId(); 
   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter({databossid=>\$userid});
   my @idl=$sys->getVal("id");
   push(@idl,"-99") if ($#idl==-1);

   $self->SetNamedFilter("BASE",{parentid=>\@idl});
   return($self->SetFilter(@flt));
}







1;
