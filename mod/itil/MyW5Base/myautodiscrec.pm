package itil::MyW5Base::myautodiscrec;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use kernel::MyW5Base;
@ISA=qw(kernel::MyW5Base);

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
   $self->{DataObj}=getModuleObject($self->getParent->Config,
                                    "itil::autodiscrec");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub getQueryTemplate
{
   my $self=shift;
   my $d=<<EOF;
<div class=searchframe>
<!--
<table class=searchframe>
<tr>
<td class=fname width=20%>\%name(label)\%:</td>
<td class=finput width=80% >\%name(search)\%</td>
</tr>
</table>
-->
</div>
%StdButtonBar(print,search)%
EOF
   return($d);
}

sub Result
{
   my $self=shift;
   my $userid=$self->getParent->getCurrentUserId();

   my @flt=(
      { sec_sys_databossid=>\$userid, sec_sys_cistatusid=>"<6",state=>\'1' },
      { sec_swi_databossid=>\$userid, sec_swi_cistatusid=>"<6",state=>\'1' },
   );

   print $self->{DataObj}->HtmlAutoDiscManager({
      filterTypes=>0,
      allowReload=>0
   },\@flt);
   return(1);
}


#sub ViewEditor
#{
#   my $self=shift;
#
#   return($self->{DataObj}->ViewEditor());
#}



1;
