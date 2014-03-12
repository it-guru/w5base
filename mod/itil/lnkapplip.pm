package itil::lnkapplip;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use vars qw(@ISA $VERSION $DESCRIPTION);
use kernel;
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);


$VERSION="1.0";
$DESCRIPTION=<<EOF;
Tempoary object to speedup search for ip adresses based
on application name.
EOF




sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
  
   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),
      new kernel::Field::Link(
                name          =>'applid',
                label         =>'ApplicationID',
                dataobjattr   =>'appl.id'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplicationID CI-StatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'ipaddress',
                label         =>'IP-Address',
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['ipaddressid'=>'id'],
                vjoindisp     =>'name'),
      new kernel::Field::Group(
                name          =>'customer',
                label         =>'Customer',
                vjoinon       =>['customerid'=>'grpid']),
      new kernel::Field::Link(
                name          =>'customerid',
                label         =>'Customer',
                dataobjattr   =>'appl.customer'),
      new kernel::Field::Link(
                name          =>'ipaddressid',
                label         =>'IP-AddressID',
                dataobjattr   =>'ipaddress.id'),

   );
   $self->setDefaultView(qw(appl ipaddress customer));
   return($self);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   push(@flt,[ {ipaddressid=>\'-1'}]);
   return($self->SetFilter(@flt));
}



sub getSqlFrom
{
   my $self=shift;
   my $from=<<EOF;
( select lnkapplsystem.appl applid,ipaddress.id as ipid
      from lnkapplsystem,ipaddress
      where lnkapplsystem.system=ipaddress.system
   union
   select lnkitclustsvcappl.appl applid,ipaddress.id ipid 
      from lnkitclustsvcappl,ipaddress 
      where lnkitclustsvcappl.itclustsvc=ipaddress.lnkitclustsvc
   union
   select lnkitclustsvcappl.appl applid,ipaddress.id ipid 
      from lnkitclustsvcappl,lnkitclustsvc,itclust,system,ipaddress 
      where lnkitclustsvcappl.itclustsvc=lnkitclustsvc.id and
            lnkitclustsvc.itclust=itclust.id and 
            system.clusterid=itclust.id and
            ipaddress.system=system.id and
            system.cistatus<=4 and
            itclust.cistatus<=4 
) as ai,appl,ipaddress 

EOF

   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   my $where="ai.applid=appl.id and ai.ipid=ipaddress.id";
   return($where);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return(undef);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return(qw(ALL));
}


1;
