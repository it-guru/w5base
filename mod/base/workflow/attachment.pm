package base::workflow::attachment;
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

sub IsModuleSelectable
{
   my $self=shift;
   return(0);
}



#######################################################################
package base::workflow::attachment::edit;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   my $templ=<<EOF;
<table border=1 width=100%>
<tr>
<td>Anlagenbearbeitung</td>
<td>%name(detail)%</td>
</tr>
<tr>
<td colspan=2 align=center>
<input type=submit name=Add value="Hinzufügen" class=workflowbutton>
</td>
</tr>
</table>
EOF
   return($templ);
}

sub Process
{
   my $self=shift;
   my $button=shift;
   my $WfRec=shift;

   return($self->SUPER::Process($button,$WfRec));
}


#######################################################################


1;
