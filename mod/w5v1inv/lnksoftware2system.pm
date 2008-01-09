package w5v1inv::lnksoftware2system;
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
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(      name         =>'id',
                                  label        =>'W5BaseID',
                                  size         =>'10',
                                  dataobjattr  =>'lnkmwbchw.id'),

      new kernel::Field::Text(    name         =>'system',
                                  label        =>'Systemname',
                                  vjointo      =>'w5v1inv::system',
                                  vjoinon      =>['w5systemid'=>'w5systemid'],
                                  vjoindisp    =>'name'),
                                              
      new kernel::Field::Text(    name         =>'software',
                                  label        =>'Softwarename',
                                  vjointo      =>'w5v1inv::software',
                                  vjoinon      =>['w5softwareid'=>
                                                  'w5softwareid'],
                                  vjoindisp    =>'name'),

      new kernel::Field::Text(    name         =>'version',
                                  label        =>'version',
                                  dataobjattr  =>'lnkmwbchw.version'),

      new kernel::Field::Text(    name         =>'licencecount',
                                  label        =>'licencecount',
                                  dataobjattr  =>'lnkmwbchw.licencecount'),

      new kernel::Field::Link(    name         =>'w5softwareid',
                                  label        =>'SoftwareID',
                                  dataobjattr  =>'lnkmwbchw.mw'),

      new kernel::Field::Link(    name         =>'w5systemid',
                                  label        =>'SystemID',
                                  dataobjattr  =>'lnkmwbchw.bchw'),
   );
   $self->setDefaultView(qw(system software version licencecount id));
   return($self);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(ALL));

}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1);
}


sub getSqlFrom
{
   my $self=shift;

   return("lnkmwbchw");
}


1;
