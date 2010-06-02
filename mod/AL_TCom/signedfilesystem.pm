package AL_TCom::signedfilesystem;
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
use itil::signedfilesystem;
@ISA=qw(itil::signedfilesystem);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub SecureSetFilter   # access to signed files is restricted to databoss
{
   my $self=shift;
   my @flt=@_;
   if ($#flt>0){
      return($self->SetFilter({id=>\'-99'}));
   }

   my @baseflt=();

   my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                               [orgRoles()],"both");
   my @grpids=keys(%grps);
   my $userid=$self->getCurrentUserId(); 

   my $sys=getModuleObject($self->Config,"itil::system");
   #######################################################################
   # Zugriffsvariante a: directer Kontakt mit dem System,
   #                     schreibberechtigt oder trusted read
   #
   my @subflt=(
              {databossid=>$userid},
              {admid=>$userid},       {adm2id=>$userid},
              {sectargetid=>\$userid,sectarget=>\'base::user',
               secroles=>"*roles=?write?=roles* *roles=?privread?=roles*"},
              {sectargetid=>\@grpids,sectarget=>\'base::grp',
               secroles=>"*roles=?write?=roles* *roles=?privread?=roles*"}
             );

   $sys->SetFilter(\@subflt);
   my @idl=$sys->getVal("id");
   push(@idl,"-99") if ($#idl==-1);
   push(@baseflt,{parentid=>\@idl});
   #######################################################################
   # Zugriffsvariante b: Config-Manager oder Auditor des Mandaten
   #
   my %mandators=$self->getGroupsOf($ENV{REMOTE_USER},
                               [qw(RCFManager RAuditor)],"both");
   my @mandators=keys(%mandators);
   @mandators=(-1) if ($#mandators==-1);

   push(@baseflt,{mandatorid=>\@mandators});
   #######################################################################
   # Zugriffsvariante c: lesender Zugriff das System oder den Mandaten des
   #                     des Systems dürfen nur Labels die mit
   #                     /public/ beginen  lesen
   #
   my @subflt=(
              {sectargetid=>\$userid,sectarget=>\'base::user',
               secroles=>"*roles=?read?=roles*"},
              {sectargetid=>\@grpids,sectarget=>\'base::grp',
               secroles=>"*roles=?read?=roles*"}
             );

   $sys->SetFilter(\@subflt);
   my @idl=$sys->getVal("id");
   push(@idl,"-99") if ($#idl==-1);
   push(@baseflt,{parentid=>\@idl,label=>'/public/*'});

   #######################################################################
   $self->SetNamedFilter("BASESEC",\@baseflt);


   return($self->SetFilter(@flt));
}







1;
