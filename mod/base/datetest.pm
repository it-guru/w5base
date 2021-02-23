package base::datetest;
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
      new kernel::Field::Text(
                name          =>'id',
                label         =>'W5BaseID',
                selectfix     =>1,
                dataobjattr   =>'id'),
                                                  
      new kernel::Field::Date(
                name          =>'dt',
                label         =>'Date',
                selectfix     =>1,
                dataobjattr   =>'dt'),
                                                  
      new kernel::Field::Htmlarea(
                name          =>'dttext',
                label         =>'Date String',
                onRawValue    =>\&extractString)
                                                  
   );
   $self->setDefaultView(qw(id dt dttext));
   return($self);
}

sub extractString
{
   my $self=shift;
   my $current=shift;

   my $fld=$self->getParent->getField("dt");

   my $d="xx ".$current->{dt}." yy ".$fld;

   $d=$fld->FormatedDetail($current,"HtmlDetail");



   return($d);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my @l;

   my $base="-".(86400*3);
   for(my $c=0;$c<=86400*6;$c+=3321){
      push(@l,"select utc_timestamp()-$base+$c id,".
                      "timestampadd(second,$base+$c,utc_timestamp()) dt ");
   }

   my $from="(".join(" union \n",@l).") l";

   return($from);
}






1;
