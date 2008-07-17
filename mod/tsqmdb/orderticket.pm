package tsqmdb::orderticket;
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;

   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                align         =>'left',
                label         =>'ID',
                uivisible     =>'0',
                dataobjattr   =>'bestellschein.ROWID'),
                                                  
      new kernel::Field::Text(
                name          =>'orderticketnumber',
                htmlwidth     =>'150px',
                label         =>'Order Ticket Number',
                dataobjattr   =>'bestellschein.bs_nr'),
                                                  
      new kernel::Field::Id(
                name          =>'contractnumber',
                align         =>'left',
                label         =>'Contract Number',
                dataobjattr   =>'bestellschein.vertrag_nr'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Order Ticket Name',
                dataobjattr   =>'bestellschein.bezeichnung'),

      new kernel::Field::Date(
                name          =>'durationstart',
                label         =>'Duration Start',
                timezone      =>'CET',
                dataobjattr   =>'bestellschein.lz_beginn'),

      new kernel::Field::Date(
                name          =>'durationend',
                label         =>'Duration End',
                timezone      =>'CET',
                dataobjattr   =>'bestellschein.lz_ende'),

      new kernel::Field::Text(
                name          =>'orgunit',
                ignorecase    =>1,
                htmlwidth     =>'100px',
                label         =>'Org-Unit',
                dataobjattr   =>'ou.description'),

      new kernel::Field::Text(
                name          =>'orgunit1',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                label         =>'Org1-Unit',
                dataobjattr   =>'ou1.description'),

      new kernel::Field::Text(
                name          =>'orgunit2',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                label         =>'Org2-Unit',
                dataobjattr   =>'ou2.description'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmlwidth     =>'100px',
                label         =>'CO-Number',
                dataobjattr   =>'bestellschein.co_nummer'),

      new kernel::Field::Text(
                name          =>'typ',
                htmlwidth     =>'30px',
                label         =>'Typ',
                dataobjattr   =>'bestellschein.typ'),

      new kernel::Field::Link(
                name          =>'contractco',
                label         =>'Contract-CO',
                dataobjattr   =>'concat(bestellschein.vertrag_nr,'.
                                "concat(';',bestellschein.co_nummer))"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'bestellschein.insert_timestamp'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'bestellschein.update_timestamp'),

   );
   $self->setDefaultView(qw(linenumber name conumber fullname));
   $self->setWorktable("bestellschein");
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsqmdb"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->{use_distinct}=1;
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $wt=$self->{Worktable};
   my $from="$wt,organisationunit ou,organisationunit ou1,organisationunit ou2";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $wt=$self->{Worktable};
   my $where="$wt.ou_id=ou.ou_id(+) ".
             "and $wt.ou1_id=ou1.ou_id(+) ".
             "and $wt.ou2_id=ou2.ou_id(+) ";
   return($where);
}






sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}





1;
