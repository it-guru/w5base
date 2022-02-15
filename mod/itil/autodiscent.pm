package itil::autodiscent;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
                dataobjattr   =>'autodiscent.id'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                uivisible     =>0,
                depend        =>['disc_on_system','engine'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $sys=$self->getParent->getField("disc_on_system",
                               $current)->RawValue($current);
                   my $eng=$self->getParent->getField("engine",
                               $current)->RawValue($current);
                   return($eng."-".$sys);
                }),

      new kernel::Field::TextDrop(
                name          =>'engine',
                htmlwidth     =>'200px',
                label         =>'Engine',
                vjointo       =>'itil::autodiscengine',
                vjoinon       =>['engineid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'engineid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'EngineID',
                dataobjattr   =>'autodiscent.engine'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'disc_on_system',
                label         =>'discovered on System',
                vjointo       =>'itil::system',
                vjoinon       =>['disc_on_systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'disc_on_systemid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'discovered on SystemID',
                dataobjattr   =>'autodiscent.discon_system'),

      new kernel::Field::SubList(
                name          =>'recs',
                label         =>'AutoDiscRecords',
                group         =>'rec',
                forwardSearch =>1,
                vjointo       =>'itil::autodiscrec',
                vjoinon       =>['id'=>'entryid'],
                vjoindisp     =>['section','scanname','mdate']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'autodiscent.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Update-Date',
                dataobjattr   =>'autodiscent.updatedate'),

   );
   $self->setDefaultView(qw(name fullname cistatus mdate));
   $self->setWorktable("autodiscent");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/autodiscent.jpg?".$cgi->query_string());
#}

sub isCopyValid
{
   my $self=shift;

   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default rec autoimport source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","autoimport") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}





1;
