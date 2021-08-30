package tsfiat::firewall;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'id',
                dataobjattr   =>'tsfiat_firewall.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'tsfiat_firewall.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>"concat(tsfiat_firewall.name,'-',".
                                "tsfiat_firewall.contextname)"),

      new kernel::Field::Text(
                name          =>'vendor',
                label         =>'Vendor',
                dataobjattr   =>'tsfiat_firewall.vendor'),

      new kernel::Field::Text(
                name          =>'domainname',
                label         =>'Domain name',
                dataobjattr   =>'tsfiat_firewall.domainname'),

      new kernel::Field::Text(
                name          =>'domainid',
                label         =>'Domain id',
                dataobjattr   =>'tsfiat_firewall.domainid'),

      new kernel::Field::Boolean(
                name          =>'isoffline',
                label         =>'is offline',
                dataobjattr   =>'tsfiat_firewall.isoffline'),

      new kernel::Field::Boolean(
                name          =>'istopology',
                label         =>'is topology',
                dataobjattr   =>'tsfiat_firewall.istopology'),

      new kernel::Field::Text(
                name          =>'contextname',
                label         =>'Context name',
                dataobjattr   =>'tsfiat_firewall.contextname'),

      new kernel::Field::Text(
                name          =>'ipaddress',
                label         =>'IP-Address',
                dataobjattr   =>'tsfiat_firewall.ipaddress'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tsfiat_firewall.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tsfiat_firewall.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tsfiat_firewall.modifydate'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'tsfiat_firewall.srcload'),

   );
   $self->setDefaultView(qw(name id ipaddress contextname mdate));
   $self->setWorktable("tsfiat_firewall");
   return($self);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","soure");
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}









1;
