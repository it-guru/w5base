package itil::autodiscmap;
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
                dataobjattr   =>'autodiscmap.id'),

      new kernel::Field::RecordUrl(),

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
                dataobjattr   =>'autodiscmap.engine'),

      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'200px',
                label         =>'Software',
                vjoineditbase =>{pclass=>\'MAIN',cistatusid=>[3,4]},
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'softwareid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'SoftwareID',
                dataobjattr   =>'autodiscmap.software'),
                                                  
                                                  
      new kernel::Field::Text(
                name          =>'scanname',
                label         =>'Scanname',
                dataobjattr   =>'autodiscmap.scanname'),

      new kernel::Field::Select(
                name          =>'probability',
                label         =>'probability',
                transprefix   =>'prob.',
                default       =>'9',
                value         =>['1',
                                 '5',
                                 '9'],
                sqlorder      =>'desc',
                dataobjattr   =>'autodiscmap.probability'),
                                                  
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'autodiscmap.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Update-Date',
                dataobjattr   =>'autodiscmap.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'autodiscmap.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'autodiscmap.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'autodiscmap.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'autodiscmap.realeditor'),
   );
   $self->setDefaultView(qw(engine scanname software probability mdate));
   $self->setWorktable("autodiscmap");
   $self->{history}={
      delete=>[
         'local'
      ],
      update=>[
         'local'
      ]
   };

   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/autodiscmap.jpg?".$cgi->query_string());
#}

sub isCopyValid
{
   my $self=shift;

   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default autoimport source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if ($self->IsMemberOf("admin") || 
       $self->IsMemberOf("w5base.softwaremgmt.admin")){
      return("default","autoimport");
   }
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
