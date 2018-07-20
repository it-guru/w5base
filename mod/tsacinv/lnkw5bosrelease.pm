package tsacinv::lnkw5bosrelease;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.id'),


      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Fullname',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.tsacname'),

      new kernel::Field::TextDrop(
                name          =>'w5bosrelease',
                label         =>'W5Base OS',
                vjointo       =>\'itil::osrelease',
                vjoinon       =>['w5bosreleaseid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Link(
                name          =>'w5bosreleaseid',
                label         =>'W5Base os release id',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.w5bid'),


      new kernel::Field::Select(
                name          =>'direction',
                label         =>'direction',
                searchable    =>0,
                transprefix   =>'DIR.',
                value         =>['1',
                                 ''],
                dataobjattr   =>'tsacinv_lnkw5bosrelease.outgoing'),

      new kernel::Field::Text(
                name          =>'extosrelease',
                group         =>'acentry',
                label         =>'AssetManager OS',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.tsacname'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.modifyuser'),
                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                vjointo       =>\'base::user',
                label         =>'Editor Account',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                vjointo       =>\'base::user',
                label         =>'real Editor Account',
                dataobjattr   =>'tsacinv_lnkw5bosrelease.realeditor'),

   );
   $self->setDefaultView(qw(w5bosrelease direction extosrelease mdate));
   $self->setWorktable("tsacinv_lnkw5bosrelease");
   return($self);
}


#sub getSqlFrom
#{
#   my $self=shift;
#   my $from="lnkapplitclust tsacinv_lnkw5bosrelease left outer join appl ".
#            "on tsacinv_lnkw5bosrelease.appl=appl.id ".
#            "left outer join itclust ".
#            "on tsacinv_lnkw5bosrelease.itclust=itclust.id";
#   return($from);
#}

# Einbindung von Clustern könnte wie folgt aufgebaut werden:
# select u1.name,user.userid from (select fullname as name from user 
# where fullname like 'Vo%' union select fullname as name from grp 
# where fullname like '%DB') u1 left outer join user on u1.name=user.fullname;




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (effVal($oldrec,$newrec,'direction') eq ""){
      $newrec->{direction}=undef;
   }

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
   my $oldrec=shift;
   my $newrec=shift;

   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header acentry default source));
}







1;
