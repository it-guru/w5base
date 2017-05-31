package AL_TCom::MyW5Base::ChangeNotChmMgr;
#  W5Base Framework
#  Copyright (C) 2017  Markus Zeis (w5base@zeis.email)
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
use Data::Dumper;
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
   $self->{approvereq}=getModuleObject($self->getParent->Config,"tssm::chm_approvereq");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}


sub isSelectable
{
   my $self=shift;

   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                                        'AL_TCom::MyW5Base::ChangeNotChmMgr$');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}


sub getQueryTemplate
{
   my $self=shift;

   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>Change Type (CBI):</td>
<td class=finput>
   <input class=finput type="text" name="search_TYPE" value="!minor">
</td>
</tr>
</table>
</div>
%StdButtonBar(print,bookmark,search)%
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my $search_type=Query->Param("search_TYPE");

   my $smflt={type=>$search_type,
              name=>'TIT.TSI.INT.CHM*',
              chmmgrgrp=>'!TIT.TSI.INT.CHM-MGR.CM'};
   my $approbj=$self->{approvereq};
   $approbj->ResetFilter();
   $approbj->SetFilter($smflt);
   $approbj->{use_distinct}=1;

   my @chg2approve=map({$_->{changenumber}}
                       @{$approbj->getHashList(qw(changenumber))});

   my $wfflt={srcid=>\@chg2approve,
              stateid=>2,
              class=>\'TS::workflow::change'};

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter($wfflt);
   $self->{DataObj}->setDefaultView(qw(eventstart eventend srcid name
                                       additional.ServiceManagerApprovalState
                                       additional.ServiceManagerChmTITPending
                                       shortactionlog));
   my %param=(ExternalFilter=>1);

   return($self->{DataObj}->Result(%param));
}



1;
