package aws::event::AWS_CloudAreaSync;
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
use kernel::QRule;
@ISA=qw(kernel::Event);

sub Init
{
   my $self=shift;

   $self->RegisterEvent("AWS_QualityCheck","AWS_QualityCheck");
   return(1);
}

sub AWS_QualityCheck
{
   my $self=shift;
   my $cloudareaid=shift;

   my $job=getModuleObject($self->Config,"base::joblog");
   $job->SetFilter({event=>"\"QualityCheck 'itil::itcloudarea'\" ".
                           "\"QualityCheck 'itil::itcloudarea' T*\"",
                    exitstate=>"[EMPTY]",
                    cdate=>">now-6h"});
   my @l=$job->getHashList(qw(mdate id event exitstate));

   if ($#l==-1){
      my $bk=$self->W5ServerCall("rpcCallEvent",
                                 "QualityCheck","itil::itcloudarea",
                                 $cloudareaid);
      return({exitcode=>'0'});
   }
   #else{
   #   printf STDERR ("retry event for AWS_QualityCheck due job entries %s\n",
   #                  Dumper(\@l));
   #   sleep(1);
   #   printf STDERR ("\n\n");
   #}
   return({exitcode=>'1'});
}





1;
