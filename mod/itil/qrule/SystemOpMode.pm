package itil::qrule::SystemOpMode;
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::system"]);
}

sub qcheckRecord
{  
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   
   my $fndopmode=0;
   my $fndsystemclass=0;
   my @fl=$dataobj->getFieldObjsByView([qw(ALL)],current=>$rec);
   foreach my $f (@fl){
      $fndopmode++      if ($f->{group} eq "opmode" && $rec->{$f->{name}});
      $fndsystemclass++ if ($f->{group} eq "systemclass" && $rec->{$f->{name}});
   }
   my @qmsg;
   if (!$fndopmode){
      push(@qmsg,"no operation mode defined");
   }
   if (!$fndsystemclass){
      push(@qmsg,"no system classification defined");
   }
   if ($#qmsg!=-1){
       return(3,{qmsg=>\@qmsg,dataissue=>\@qmsg});
   }
   return(0,undef);

}




1;
