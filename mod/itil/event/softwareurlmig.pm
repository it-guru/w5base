package itil::event::softwareurlmig;
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub softwareurlmig
{
   my $self=shift;
   my $sw=getModuleObject($self->Config,"itil::software");
   $sw->SetFilter({cistatusid=>"<6"});
   $sw->SetCurrentOrder(qw(NONE));
   $sw->SetCurrentView(qw(ALL));

   my ($swrec,$msg)=$sw->getFirst(unbuffered=>1);
   if (defined($swrec)){
      do{
         msg(DEBUG,"process %s",$swrec->{name});
         if ($swrec->{iurl} eq ""){
            msg(DEBUG," - check %s",$swrec->{name});
            sub _upd{
                my $url=shift;
                my $text=shift;
                my $op=$sw->Clone();
                $op->ValidatedUpdateRecord($swrec,
                     {iurl=>$url},{id=>$swrec->{id}});
                msg(DEBUG," - found %s",$url);
            
            }
            my $d=$swrec->{comments};
            $d=~s#(http|https)(://\S+?)(\?\S+){0,1}(["']{0,1}\s)#_upd("$1$2$3",$4)#ge;
            $d=~s#(http|https)(://\S+?)(\?\S+){0,1}$#_upd("$1$2$3",$4)#ge;
         }
         ($swrec,$msg)=$sw->getNext();
      }until(!defined($swrec));
   }

   return({exitcode=>0,msg=>'ok'});
}

1;
