package AL_TCom::workflow::P800special;
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
@ISA=qw(kernel::WfClass);

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
   $self->AddGroup("p800_app");
   return(1);
   return($self->SUPER::Init(@_));
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();
   
   return($self->InitFields(
           new kernel::Field::Message(
                name          =>'p800_msg1',
                label         =>'Message',
                group         =>'p800_msg',
                onRawValue    =>sub{return(<<EOF);
Dieser P800 Sonderleistungs-Report bezieht sich auf den Zeitraum 19. - 19.
eines Monats. Für Analysen bzw. Auswertungen sollte aber immer der P800 Report
mit monatlicher Bezugsbasis verwendet werden!
EOF
                }),

           new kernel::Field::Text(
                name          =>'p800_reportmonth',
                label         =>'month of report',
                group         =>'p800_msg',
                depend        =>['srcid'],
                htmldetail    =>0,
                onRawValue    =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   my $m=$current->{srcid};
                                   $m=~s/-.*$//;
                                   return($m);
                                }),

           new kernel::Field::Text(
                name          =>'p800_app_speicalwt',
                label        =>'total worktime of "special service" (projects)',                translation   =>'AL_TCom::workflow::P800',
                unit          =>'min',
                group         =>'p800_app',
                container     =>'headref'),

   ));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef);  # ALL means all groups - else return list of fieldgroups
}

sub IsModuleSelectable
{
   my $self=shift;

   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(ALL)) if (defined($rec));
   return(undef);
}



sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return("p800_msg","p800_app");
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   return();
}


#######################################################################
package AL_TCom::workflow::P800special::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub Validate
{
   my $self=shift;

   return(1);
}

sub getPosibleButtons
{
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   return(0);
}




1;
