package tswiw::costcenter;
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
use kernel::App::Web;
use kernel::DataObj::LDAP;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::LDAP);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tswiw"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   $self->setBase("o=CostCenter,o=WiW");
   $self->AddFields(
      new kernel::Field::Id(       name       =>'id',
                                   label      =>'tCostCenterKey',
                                   align      =>'left',
                                   dataobjattr=>'tCostCenterKey'),

      new kernel::Field::Text(     name       =>'toplevelno',
                                   label      =>'tCostCenterTopLevelNo',
                                   dataobjattr=>'tCostCenterTopLevelNo'),

      new kernel::Field::Text(     name       =>'accarea',
                                   label      =>'tCostCenterAccountingArea',
                                   dataobjattr=>'tCostCenterAccountingArea'),

      new kernel::Field::Text(     name       =>'costcenter',
                                   label      =>'tCostCenterNo',
                                   dataobjattr=>'tCostCenterNo'),
   );
   $self->setDefaultView(qw(id));
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/finance/load/costcenter.jpg?".$cgi->query_string());
}

         

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
