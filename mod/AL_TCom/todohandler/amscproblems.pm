package AL_TCom::todohandler::amscproblems;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub preHandle
{
   my $self=shift;
   my $param=shift;


}

sub Handle
{
   my $self=shift;
   my $class=shift;     # handler (or undef if base::workflow::todo)
   my $id=shift;        # unique in class or undef
   my $subject=shift;
   my $text=shift;
   my $target=shift;    # array

   my $app=$self->getParent();

   my $inm=$app->getPersistentModuleObject("tssc::inm");

   $inm->SetFilter({deviceid=>\$id,rawname=>\$subject});
   my @l=$inm->getHashList(qw(ALL));
   if ($#l==-1){
      my $assignto="the nessasary responsible";
      if ($subject=~m/^MISS_SCLOC/){
         $assignto="the ServiceCenter Operating";
      }
      my $email="Dear responsible,\n\n".
                "please create a new Incident-Ticket in ServiceCenter ".
                "with ...\n\n---\n".
                "<b>Brief description:</b> $subject\n\n".
                "<b>Config-Item:</b> $id\n\n".
                "<b>Description:</b>\n".
                "$text\n---\n\n".
                "... and assign the ticket to $assignto.\n\n";
      my $wfa=$app->getPersistentModuleObject("base::workflowaction");
      $wfa->Notify("INFO","Incident-Request: $subject",$email,
                   emailfrom=>'"W5Base/Darwin - SM9 mandator validation" <>',
                   emailto=>$target,
                   emailcc=>['11634953080001']); # vogler
      return(1);
   }
   return(0);
}




1;
