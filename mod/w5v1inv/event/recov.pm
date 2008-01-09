package w5v1inv::event::recov;
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
use kernel::database;
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


   $self->RegisterEvent("recov","recov");  # seems OK
   return(1);
}


sub recov
{
   my $self=shift;
   my $db=new kernel::database($self->getParent,"w5base");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from wfhead where wfclass in ".
           "('AL_TCom::workflow::change','AL_TCom::workflow::incident')";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   open(F,">recov.sql");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      my %h=Datafield2Hash($rec->{headref});
      if (defined($h{tcomcodrelevant})){
         my $qheadref=$db->quotemeta($rec->{headref});
         printf F ("update wfhead set wfclass='%s',wfstate='%s',".
                   "headref=%s where ".
                   "wfclass='%s' and srcid='%s';\n",
                   $rec->{wfclass},$rec->{wfstate},
                   $qheadref,$rec->{wfclass},$rec->{srcid}); 
         msg(INFO,"process %s",($rec->{srcsys}.":".$rec->{srcid}));
         #msg(INFO,"additional=%s",Dumper(\%h));
      }
   }
   close(F);
}
1;
