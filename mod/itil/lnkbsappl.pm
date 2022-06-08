package itil::lnkbsappl;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
  
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'businessserviceid',
                label         =>'Businessservice ID',
                dataobjattr   =>'a.businessservice'),

      new kernel::Field::Text(
                name          =>'applid',
                label         =>'Application ID',
                dataobjattr   =>'a.id'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'a.name')
   );
   $self->setDefaultView(qw(businessserviceid appl applid));
   $self->setWorktable("lnkbscomp");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$workdb)=$self->getWorktable();

   my $precision0="";
   my $precision1="";
   my $precision2="";
   my $precision3="";
   if ($mode eq "select"){
      if ($#filter==0 && ref($filter[0]) eq "HASH" && 
          defined($filter[0]->{applid})){
         $precision0="and l0.appl='$filter[0]->{applid}' "; 
         $precision1="and l1.obj1id='$filter[0]->{applid}' "; 
      }
   }
 

   # Attention: Only application components are considered !

   return("(".
      "select l0.id businessservice,a0.id,a0.name ".
         "from businessservice l0,appl a0 where l0.appl=a0.id ".$precision0.
      "union ".
         "select l1.businessservice,a1.id,a1.name ".
            "from lnkbscomp l1,appl a1 ".
            "where l1.objtype='itil::appl' and l1.obj1id=a1.id ".$precision1.
      ") a");
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
