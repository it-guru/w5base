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
         $precision2="and l2.obj2id='$filter[0]->{applid}' "; 
         $precision3="and l3.obj3id='$filter[0]->{applid}' "; 
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
      "union ".
         "select l2.businessservice,a2.id,a2.name ".
            "from lnkbscomp l2,appl a2 ".
            "where l2.objtype='itil::appl' and l2.obj2id=a2.id ".$precision2.
      "union ".
         "select l3.businessservice,a3.id,a3.name ".
            "from lnkbscomp l3,appl a3 ".
            "where l3.objtype='itil::appl' and l3.obj3id=a3.id ".$precision3.
      #union
      #   select l11.businessservice,a11.name
      #      from lnkbscomp l11,lnkapplsystem las11,appl a11
      #      where l11.objtype='itil::system'
      #         and l11.obj1id=las11.system
      #         and las11.appl=a11.id and a11.cistatus<=4
      #union 
      #   select l12.businessservice,a12.name 
      #      from lnkbscomp l12,lnkapplsystem las12,appl a12 
      #      where l12.objtype='itil::system' 
      #         and l12.obj2id=las12.system
      #         and las12.appl=a12.id and a12.cistatus<=4
      #union 
      #   select l13.businessservice,a13.name 
      #      from lnkbscomp l13,lnkapplsystem las13,appl a13 
      #      where l13.objtype='itil::system' 
      #         and l13.obj3id=las13.system
      #         and las13.appl=a13.id and a13.cistatus<=4
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
