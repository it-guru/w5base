package base::w5statmaster;
#  W5Base Framework
#  Copyright (C) 2008  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                htmldetail    =>0,
                searchable    =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'w5statmaster.id'),
                                                  
      new kernel::Field::Select(
                name          =>'sgroup',
                label         =>'Statistic Group',
                value         =>['Group','Application','Location','User',
                                 'Contract'],
                dataobjattr   =>'w5statmaster.statgroup'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Statistic Name',
                dataobjattr   =>'w5statmaster.name'),

      new kernel::Field::Text(
                name          =>'dstrange',
                label         =>'Month/CW/day',
                dataobjattr   =>'w5statmaster.monthkwday'),

      new kernel::Field::Text(
                name          =>'dataname',
                label         =>'Staistic Variable Name',
                dataobjattr   =>'w5statmaster.statname'),

      new kernel::Field::Text(
                name          =>'dataval',
                label         =>'Staistic Variable Value',
                dataobjattr   =>'w5statmaster.statval'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'w5statmaster.createdate'),
 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'w5statmaster.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'w5statmaster.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'w5statmaster.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'w5statmaster.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'w5statmaster.realeditor'),

   );
   $self->setDefaultView(qw(linenumber dstrange fullname sgroup dataval mdate));
   $self->setWorktable("w5statmaster");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   return(0) if (!$self->IsMemberOf("admin"));
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/w5statmaster.jpg?".$cgi->query_string());
}







1;
