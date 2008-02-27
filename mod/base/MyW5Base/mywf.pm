package base::MyW5Base::mywf;
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
   $self->{DataObj}=getModuleObject($self->getParent->Config,"base::workflow");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub getDefaultStdButtonBar
{
   my $self=shift;
   return('%StdButtonBar(print,search)%');
}

sub getQueryTemplate
{
   my $self=shift;
   my $bb=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%name(label)\%:</td>
<td class=finput width=50% >\%name(search)\%</td>
<td class=fname width=10%>\%prio(label)\%:</td>
<td class=finput width=30%>\%prioid(search)\%</td>
</tr>
<tr>
<td class=fname width=10%>\%class(label)\%:</td>
<td class=finput width=50% >\%class(search)\%</td>
<td class=fname width=10%>&nbsp;</td>
<td class=finput width=50% >&nbsp;</td>
</tr>
</table>
</div>
<script language="JavaScript">
setEnterSubmit(document.forms[0],document.DoSearch);
</script>
   
EOF
   
   $bb.=$self->getDefaultStdButtonBar();
   return($bb);
}



sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();

   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);
   my %q1=%q;
   $q1{openuser}=\$userid;
   $q1{stateid}="<20";

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([\%q1]);
   $self->{DataObj}->setDefaultView(qw(createdate state nature name editor));
   
   return($self->{DataObj}->Result(ExternalFilter=>1));
}




1;
