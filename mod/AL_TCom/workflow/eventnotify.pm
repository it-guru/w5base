package AL_TCom::workflow::eventnotify;
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
use kernel::WfClass;
use itil::workflow::eventnotify;

@ISA=qw(itil::workflow::eventnotify);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=AL_TCom::workflow::eventnotify');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub activateMailSend
{
   my $self=shift;
   my $WfRec=shift;
   my $wf=shift;
   my $id=shift;
   my $newmailrec=shift;

   my %d=(step=>'base::workflow::mailsend::waitforspool',
          emailsignatur=>'EventNotification: AL T-Com');
   $self->linkMail($WfRec->{id},$id);
   if (my $r=$wf->Store($id,%d)){
      return(1);
   }
   return(0);
}

sub ValidateCreate
{
   my $self=shift;
   my $newrec=shift;

   if (!defined($newrec->{kh}->{mandator}) || 
       ref($newrec->{kh}->{mandator}) ne "ARRAY" ||
       !grep(/^AL T-Com$/,@{$newrec->{kh}->{mandator}})){
      $self->LastMsg(ERROR,"no AL T-Com mandator included");
      return(0);
   }
        
   return(1);
}

sub getPosibleEventStatType
{
   my $self=shift;
   my @l;
   
   foreach my $int ('',
                    qw(EVt.iswtsi EVt.iswext EVt.wrkerr EVt.wrkerrito
                       EVt.dqual EVt.stdswbug EVt.stdswold 
                       EVt.hwfail EVt.busoverflow EVt.tecoverflow
                       EVt.parammod EVt.rzinfra EVt.hitnet EVt.inanalyse
                       EVt.unknown)){
      push(@l,$int,$self->getParent->T($int));
   }
   
   return(@l);
}







1;
