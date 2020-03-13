package base::w5plug;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'w5plug.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Label',
                dataobjattr   =>'w5plug.name'),

      new kernel::Field::Textarea(
                name          =>'code',
                label         =>'Code',
                htmlheight    =>'400',
                dataobjattr   =>'w5plug.plugcode'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Note',
                dataobjattr   =>'w5plug.comments'),

      new kernel::Field::Text(
                name          =>'parentobj',
                label         =>'parent object',
                dataobjattr   =>'w5plug.dataobj'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'w5plug.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'w5plug.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                searchable    =>0,
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'w5plug.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                label         =>'CreatorID',
                dataobjattr   =>'w5plug.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'w5plug.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'w5plug.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'w5plug.realeditor'),

   );
   $self->setDefaultView(qw(linenumber name comments mdate));
   $self->setWorktable("w5plug");
   return($self);
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift; 
   return(0) if (!defined($rec));
   return(1);
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
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}







sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if (($name=~m/^\s*$/i) ||
       ($name=~m/[^a-zA-Z0-9_]/) ||
       ($name=~m/^[0-9_]/)){
      $self->LastMsg(ERROR,"invalid name '%s' specified",$name); 
      return(undef);
   }

   my $dataobj=effVal($oldrec,$newrec,"parentobj");
   if (defined($dataobj)){
      $dataobj=trim($dataobj);
      if ($dataobj eq "" ||
          !($dataobj=~m/^[a-z,0-9,_]+::[a-z,0-9,_]+$/i) &&
          !($dataobj=~m/^[a-z,0-9,_]+::workflow::[a-z,0-9,_]+$/i)){
         $self->LastMsg(ERROR,"invalid dataobject nameing");
         return(undef);
      }
      $newrec->{dataobj};
   }
   my $do=getModuleObject($self->Config(),$dataobj);
   if (!defined($do)){
      $self->LastMsg(ERROR,"dataobj not functional");
      return(undef);
   }

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","rel","soure");
}






1;
