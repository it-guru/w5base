package AL_TCom::ext::infoabo;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getControlData
{
   my $self=shift;
   my $app=$self->getParent();


   return({                                     
           'AL_TCom::appl'=>   {target=>'name',
                                mode  =>[    
                                     'changenotify'=>'itil::appl',
                                     'daily_modified_appldiary'=>'itil::appl'
                                ],
                               },
           'itil::appl'=>      {target=>'name',
                                mode  =>[
                                ],
                               },
           'itil::network'=>   {target=>'name',
                                mode  =>[
                                ],
                               },
           'base::location'=>  {target=>'name',
                                mode  =>[
                                ],
                               },
           'base::grp'=>       {target=>'fullname',
                                mode  =>[
                                ],
                               },
          });

}






1;
