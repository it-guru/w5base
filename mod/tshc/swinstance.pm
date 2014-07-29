package tshc::swinstance;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use TS::swinstance;
@ISA=qw(TS::swinstance);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'automuser',
                htmldetail    =>1,
                uploadable    =>1,
                group         =>'hcautom',
                label         =>'Automation Username',
                container     =>'additional'),

      new kernel::Field::Text(
                name          =>'autompassword',
                htmldetail    =>1,
                uploadable    =>1,
                group         =>'hcautom',
                label         =>'Automation Password',
                container     =>'additional'),

      new kernel::Field::Text(
                name          =>'hcconnectstring',
                htmldetail    =>1,
                uploadable    =>1,
                group         =>'hcautom',
                label         =>'HealthChecker ConnectString',
                container     =>'additional'),
   );

   $self->AddGroup("hcautom",translation=>'tshc::swinstance');
 
   return($self);
}


sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   if (grep(/^(default|ALL)$/,@l)){
      push(@l,"hcautom");
   }
   return(@l);
}


sub isViewValid
{
   my $self=shift;
   my @l=$self->SUPER::isViewValid(@_);
   if (grep(/^(default|ALL)$/,@l)){
      push(@l,"hcautom");
   }
   return(@l);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l; 
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "relations");
   }
   splice(@l,$inserti,$#l-$inserti,("hcautom",@l[$inserti..($#l+-1)]));
   return(@l);

}

    





1;
