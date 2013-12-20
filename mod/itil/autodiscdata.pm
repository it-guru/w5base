package itil::autodiscdata;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'autodiscdata.id'),
                                                  
      new kernel::Field::Text(
                name          =>'engine',
                htmleditwidth =>'80px',
                label         =>'Name',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                dataobjattr   =>'autodiscdata.engine'),

      new kernel::Field::Text(
                name          =>'target',
                htmlwidth     =>'250px',
                label         =>'Target',
                readonly      =>1,
                dataobjattr   =>
                   'if (system.name is null,swinstance.fullname,system.name)'),

      new kernel::Field::Text(
                name          =>'targettyp',
                htmlwidth     =>'250px',
                label         =>'Target Type',
                readonly      =>1,
                dataobjattr   =>
                   "if (system.name is null,'SYSTEM','INSTANCE')"),

      new kernel::Field::Interface(
                name          =>'systemid',
                htmlwidth     =>'250px',
                label         =>'SystemID',
                dataobjattr   =>'autodiscdata.system'),

      new kernel::Field::Interface(
                name          =>'swinstanceid',
                htmlwidth     =>'250px',
                label         =>'SoftwareinstanceID',
                dataobjattr   =>'autodiscdata.swinstance'),

      new kernel::Field::XMLInterface(
                name          =>'data',
                uivisible     =>1,
                htmldetail    =>1,
                label         =>'AutodiscoveryData',
                dataobjattr   =>'autodiscdata.addata'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'autodiscdata.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'autodiscdata.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'autodiscdata.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'autodiscdata.realeditor'),
   

   );
   $self->setDefaultView(qw(engine targettyp target  mdate));
   $self->setWorktable("autodiscdata");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();

   my $from="$worktable left outer join system ".
            "on autodiscdata.system=system.id ".
            "left outer join swinstance ".
            "on autodiscdata.swinstance=swinstance.id";
   return($from);
}


sub isCopyValid
{
   my $self=shift;

   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","autoimport") if ($self->IsMemberOf("admin"));
   return(undef);
}







sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) &&
       ($newrec->{systemid} eq "" &&
        $newrec->{swinstanceid} eq "")){
      $self->LastMsg(ERROR,"invalid object reference specified");
      return(0);
   }

   return(1);
}





1;
