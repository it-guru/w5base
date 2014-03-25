package tssc::lnkticket;
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
use Data::Dumper;
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use tssc::lib::io;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'lnkid',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'LinkID',
                dataobjattr   =>'screlationm1.ROWID'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'relation name',
                uppersearch   =>1,
                dataobjattr   =>"concat(screlationm1.source,".
                                "concat('-',screlationm1.depend))"),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                timezone      =>'CET',
                label         =>'Modification-Date',
                dataobjattr   =>'screlationm1.sysmodtime'),

      new kernel::Field::Text(
                name          =>'src',
                group         =>'src',
                label         =>'Source-ID',
                uppersearch   =>1,
                dataobjattr   =>'screlationm1.source'),

      new kernel::Field::Text(
                name          =>'srcfilename',
                group         =>'src',
                label         =>'Source-filename',
                dataobjattr   =>'screlationm1.source_filename'),

      new kernel::Field::Text(
                name          =>'dst',
                group         =>'dst',
                label         =>'System-ID',
                dataobjattr   =>'screlationm1.depend'),

      new kernel::Field::Text(
                name          =>'dstfilename',
                group         =>'dst',
                label         =>'Destination-filename',
                dataobjattr   =>'screlationm1.depend_filename'),

      new kernel::Field::Text(
                name          =>'dstobj',
                group         =>'dst',
                label         =>'Destination-obj',
                dataobjattr   =>"DECODE(screlationm1.depend_filename,
                                    'problem',  'tssc::inm',
                                    'rootcause','tssc::prm',
                                    'cm3r',     'tssc::chm')"),

      new kernel::Field::MultiDst(
                name          =>'dstid',
                group         =>'status',
                label         =>'Ticket-ID',
                htmlwidth     =>'200px',
                dst           =>['tssc::inm'=>'incidentnumber',
                                 'tssc::prm'=>'problemnumber',  
                                 'tssc::chm'=>'changenumber'],  
                dsttypfield   =>'dstobj',
                dstidfield    =>'dst'),

      new kernel::Field::MultiDst(
                name          =>'priority',
                group         =>'status',
                label         =>'Priority',
                translation   =>'tssc::lnk',
                dst           =>['tssc::inm'=>'priority',
                                 'tssc::prm'=>'priority',  
                                 'tssc::chm'=>'urgency'],  
                dsttypfield   =>'dstobj',
                dstidfield    =>'dst'),

      new kernel::Field::MultiDst(
                name          =>'status',
                group         =>'status',
                label         =>'Status',
                dst           =>['tssc::inm'=>'status',
                                 'tssc::prm'=>'status',  
                                 'tssc::chm'=>'status'],  
                dsttypfield   =>'dstobj',
                dstidfield    =>'dst'),

   );
   
   $self->{use_distinct}=1;
   $self->setWorktable("screlationm1");

   $self->setDefaultView(qw(linenumber dst status));

   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(src dst status));
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


sub getSqlFrom
{
   my $self=shift;
   my $from="scadm1.screlationm1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="screlationm1.depend_filename IN ('problem','rootcause','cm3r')";
   return($where);
}


1;
