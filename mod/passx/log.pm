package passx::log;
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
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseJobID',
                dataobjattr   =>'passxlog.logid'),
                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Operation',
                dataobjattr   =>'passxlog.name'),

      new kernel::Field::Link(
                name          =>'entryid',
                label         =>'EntryID',
                dataobjattr   =>'passxlog.entryid'),

      new kernel::Field::CDate(
                name          =>'cdate',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'passxlog.createdate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'passxlog.createuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'passxlog.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'passxlog.realeditor'),
   );
   $self->setDefaultView(qw(id name editor cdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->setWorktable("passxlog");
   return(1);
}

sub InitRequest
{
   my $self=shift;
   my $bk=$self->SUPER::InitRequest(@_);

   if ($ENV{REMOTE_USER} eq "" || $ENV{REMOTE_USER} eq "anonymous"){
      print($self->noAccess());
      return(undef);
   }
   return($bk);
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
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

1;
