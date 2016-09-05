package itil::lnkapplurlip;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use URI;
use URI::URL;
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

      new kernel::Field::Id(
                name          =>'id',
                label         =>'URL ID',
                searchable    =>0,
                dataobjattr   =>'accessurllastip.id'),
                                                 
      new kernel::Field::Text(
                name          =>'name',
                label         =>'IP',
                dataobjattr   =>'accessurllastip.name'),

      new kernel::Field::Link(
                name          =>'lnkapplurlid',
                label         =>'NetworkID',
                dataobjattr   =>'accessurllastip.accessurl'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Discover-Date',
                dataobjattr   =>'accessurllastip.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"accessurllastip.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(accessurllastip.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'accessurllastip.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'accessurllastip.modifydate')
   );
   $self->setDefaultView(qw(name srcload));
   $self->setWorktable("accessurllastip");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(0) if (effVal($oldrec,$newrec,"name") eq "");
   return(1);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default  source));
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return(qw(default)) if ($self->IsMemberOf("admin"));

   return(undef);
}









1;
