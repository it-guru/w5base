package tsciam::ext::XLSExpand;
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
use kernel::XLSExpand;
@ISA=qw(kernel::XLSExpand);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub GetKeyCriterion
{
   my $self=shift;
   my $d={};
   if ($self->getParent->IsMemberOf("admin")){
      $d={in=>{'tsciam::user::tcid'       =>{label=>'Person tCID',
                                             out=>['tsciam::user::tcid']},
          },
          out=>{'tsciam::user::wiwid'          =>{
                    label=>'CIAM Person: WIW ID'
               }
          }
         };
   }
   return($d);
}

sub ProcessLine
{
   my $self=shift;
   my $line=shift;
   my $in=shift;
   my $out=shift;
   my $loopcount=shift;

   if (exists($out->{'tsciam::user::wiwid'}) &&
       !defined($out->{'tsciam::user::wiwid'})){
      if (defined($in->{'tsciam::user::tcid'})){
         my $o=$self->getParent->getPersistentModuleObject('tsciam::user');
         $o->SetFilter({tcid=>\$in->{'tsciam::user::tcid'},
                        active=>'true',primary=>'true'});
         foreach my $irec ($o->getHashList(qw(wiwid))){
            $out->{'tsciam::user::wiwid'}->{$irec->{wiwid}}=1;
            msg(INFO,"XLSExpand line $line tCID $in->{'tsciam::user::tcid'} ".
                     "= WIWID $irec->{wiwid}");
         }
      }
   }

   return(1);
}





1;
