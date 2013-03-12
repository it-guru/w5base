package tsacinv::lnksharedstorage;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=1;
   
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'storageassetid',
                label         =>'Storage AssetId',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                align         =>'left',
                dataobjattr   =>'storageportfolio.assettag'),

      new kernel::Field::Text(
                name          =>'storagename',
                label         =>'Storage Name',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                align         =>'left',
                dataobjattr   =>'storageportfolio.name'),

      new kernel::Field::Link(
                name          =>'storageid',
                sqlorder      =>'NONE',
                label         =>'StorageID',
                dataobjattr   =>'amtsiprovsto.lprovidedstorageid'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'AC-ComputerID',
                dataobjattr   =>'amcomputer.lcomputerid'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                label         =>'SystemID',
                size          =>'20',
                uppersearch   =>1,
                dataobjattr   =>'systemportfolio.assettag'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                size          =>'20',
                ignorecase    =>1,
                dataobjattr   =>'systemportfolio.name'),

      new kernel::Field::Text(
                name          =>'applid',
                label         =>'ApplicationID',
                size          =>'13',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'amtsicustappl.code'),


      new kernel::Field::Text(
                name          =>'applname',
                label         =>'Applicationname',
                uppersearch   =>1,
                dataobjattr   =>'amtsicustappl.name'),

   );
   $self->setDefaultView(qw(storageassetid storagename 
                            systemsystemid systemname 
                            applname applid));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="amtsiprovsto,amportfolio storageportfolio,amtsiprovstomounts,".
            "amcomputer,amportfolio systemportfolio,".
            "amtsirelportfappl,amtsicustappl";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amtsiprovsto.lassetid=storageportfolio.lastid ".
             "and amtsiprovsto.bdelete='0' ".
             "and amtsiprovsto.lprovidedstorageid=".
             "amtsiprovstomounts.lprovidedstorageid ".
             "and amtsiprovstomounts.bdelete='0' ".
             "and amtsiprovstomounts.lcomputerid=amcomputer.lcomputerid ".
             "and amcomputer.litemid=systemportfolio.lportfolioitemid ".
             "and systemportfolio.lportfolioitemid=".
             "amtsirelportfappl.lportfolioid ".
             "and amtsirelportfappl.bdelete=0 ".
             "and amtsirelportfappl.lapplicationid=".
             "amtsicustappl.ltsicustapplid";

   return($where);
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
