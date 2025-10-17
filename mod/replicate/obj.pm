package replicate::obj;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'replicateobject.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Dataobject name',
                dataobjattr   =>'replicateobject.name'),

      new kernel::Field::TextDrop(
                name          =>'partner',
                label         =>'Replication-Partner',
                vjointo       =>'replicate::partner',
                vjoinon       =>['partnerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'partnerid',
                label         =>'Replication Partner ID',
                dataobjattr   =>'replicateobject.replpartner'),

      new kernel::Field::Boolean(
                name          =>'allow_phase1',
                label         =>'allow phase 1 (modified)',
                dataobjattr   =>'replicateobject.allow_phase1'),

      new kernel::Field::Boolean(
                name          =>'allow_phase2',
                label         =>'allow phase 2 (refresh)',
                dataobjattr   =>'replicateobject.allow_phase2'),

      new kernel::Field::Boolean(
                name          =>'allow_phase3',
                label         =>'allow phase 3 (cleanup)',
                dataobjattr   =>'replicateobject.allow_phase3'),

      new kernel::Field::Number(
                name          =>'minrefreshlatency',
                unit          =>'h',
                label         =>'minimal refresh latency',
                dataobjattr   =>'replicateobject.minrefreshlatency'),

      new kernel::Field::Select(
                name          =>'commitblocksize',
                label         =>'commit block size',
                value         =>['2','5','10','25','50','75','100','125','150'],
                default       =>'50',
                dataobjattr   =>'replicateobject.commitblocksize'),

      new kernel::Field::Textarea(
                name          =>'qfilter',
                label         =>'replication filter',
                dataobjattr   =>'replicateobject.qfilter'),

      new kernel::Field::Number(
                name          =>'entrycount',
                group         =>'stat',
                label         =>'replicated entries',
                dataobjattr   =>'replicateobject.entrycount'),
                                                  
      new kernel::Field::Number(
                name          =>'maxlatency',
                group         =>'stat',
                unit          =>'h',
                precision     =>'2',
                label         =>'max latency',
                dataobjattr   =>'replicateobject.latency'),

      new kernel::Field::Number(
                name          =>'avgrecaccess',
                group         =>'stat',
                unit          =>'ms',
                precision     =>'2',
                label         =>'averaged record access time',
                dataobjattr   =>'replicateobject.avgrecaccess'),

      new kernel::Field::Date(
                name          =>'last_phase1',
                group         =>'stat',
                label         =>'last phase 1 finish',
                dataobjattr   =>'replicateobject.last_phase1'),
                                                  
      new kernel::Field::Date(
                name          =>'last_phase2',
                group         =>'stat',
                label         =>'last phase 2 finish',
                dataobjattr   =>'replicateobject.last_phase2'),
                                                  
      new kernel::Field::Date(
                name          =>'last_phase3',
                group         =>'stat',
                label         =>'last phase 3 finish',
                dataobjattr   =>'replicateobject.last_phase3'),
                                                  
      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"replicateobject.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(replicateobject.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'replicateobject.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'replicateobject.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'replicateobject.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'replicateobject.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'replicateobject.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'replicateobject.realeditor'),

   );
   $self->setDefaultView(qw(linenumber partner name allow_phase1 
                            allow_phase2 allow_phase3 cdate));
   $self->setWorktable("replicateobject");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name=~m/\s/i){
      $self->LastMsg(ERROR,"invalid name '%s' specified",$name); 
      return(undef);
   }
   $newrec->{'name'}=$name;
   return(1);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default stat source));
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





1;
