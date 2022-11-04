package kernel::ExploreApplet;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;

@ISA=qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   $self->{formular}=0 if (!exists($self->{formular}));
   return($self);
}


sub isAppletVisible
{
   my $self=shift;
   my $app=shift;

   return(1);
}

sub getObjectHiddenState
{
   my $self=shift;
   my $app=shift;

   return(0);
}

sub getJSObjectClass
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;
   my $selfname=$self->Self();

   my $skinbase=$selfname;
   $skinbase=~s/::.*$//;

   my $opt={
      skinbase=>$skinbase,
      static=>{
         SELFNAME=>$selfname
      }
   };
   my $tmpl=$selfname;
   $tmpl=~s/::/./g;
   $tmpl="tmpl/".$tmpl.".js";


   my $prog="";
   $prog=$app->getParsedTemplate($tmpl,$opt);
   utf8::encode($prog);
   return($prog);
}





sub getObjectPrio
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;

   return(500);
}



sub getObjectInfo
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;

   return({
      label=>$app->T($self->Self,$self->Self),
      description=>$app->T("description",$self->Self),
      sublabel=>$app->T("sublabel",$self->Self),
      hidden=>$self->getObjectHiddenState($app,$lang),
      formular=>$self->{formular},
      prio=>$self->getObjectPrio($app,$lang)
   });
}


1;

