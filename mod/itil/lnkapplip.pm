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
   my $mode=shift;
   my @filter=@_;

   my $ipaddressrest="";

   if ($mode eq "select"){
      foreach my $f (@filter){
         if (ref($f) eq "HASH"){
            if (exists($f->{ipaddressid}) && $f->{ipaddressid}=~m/^\d+$/){
               $f->{ipaddressid}=[$f->{ipaddressid}];
            }
            if (ref($f->{ipaddressid}) eq "SCALAR"){
               my $str=${$f->{ipaddressid}};
               $f->{ipaddressid}=[$str];
            }
            if (ref($f->{ipaddressid}) eq "ARRAY" &&
                $#{$f->{ipaddressid}}==0){
               my $id=$f->{ipaddressid}->[0];
               $id=~s/[^0-9]//;
               $ipaddressrest="and ipaddress.id='$id'";
            }
         }
      }
   }



   my $from=<<EOF;
( select lnkapplsystem.appl applid,ipaddress.id as ipid
      from lnkapplsystem,ipaddress
      where lnkapplsystem.system=ipaddress.system 
            and lnkapplsystem.cistatus='4'
            $ipaddressrest
   union
   select lnkitclustsvcappl.appl applid,ipaddress.id ipid 
      from lnkitclustsvcappl,ipaddress 
      where lnkitclustsvcappl.itclustsvc=ipaddress.lnkitclustsvc
            $ipaddressrest
   union
   select itcloudarea.appl applid,ipaddress.id ipid 
      from itcloudarea,ipaddress 
      where itcloudarea.id=ipaddress.itcloudarea
            $ipaddressrest
   union
   select lnkitclustsvcappl.appl applid,ipaddress.id ipid 
      from lnkitclustsvcappl
           join lnkitclustsvc on lnkitclustsvcappl.itclustsvc=lnkitclustsvc.id
           join itclust on lnkitclustsvc.itclust=itclust.id 
           join system on system.clusterid=itclust.id 
           join ipaddress on ipaddress.system=system.id
           left outer join lnkitclustsvcsyspolicy 
              on lnkitclustsvc.id=lnkitclustsvcsyspolicy.itclustsvc 
                 and lnkitclustsvcsyspolicy.system=system.id 
      where system.cistatus<=4 and itclust.cistatus<=4 
            $ipaddressrest
            and ( (lnkitclustsvcsyspolicy.runpolicy is null and 
                   itclust.defrunpolicy<>'deny') or 
                  (lnkitclustsvcsyspolicy.runpolicy is not null and 
                   lnkitclustsvcsyspolicy.runpolicy<>'deny'))

) as ai,appl,ipaddress 

EOF
   $from=~s/\n/ /gs;  # reduce data in
   $from=~s/ +/ /gs;  # sql logs

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
