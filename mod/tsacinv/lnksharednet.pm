package tsacinv::lnksharednet;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=1;
   
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'netlnkid',
                label         =>'NetRelID',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                align         =>'left',
                dataobjattr   =>'amTsiParentChild.ltsiparentchildid'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                align         =>'left',
                dataobjattr   =>'amTsiParentChild.description'),

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

      new kernel::Field::Text(
                name          =>'systemsystemid',
                label         =>'System SystemID',
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
                name          =>'netsystemid',
                label         =>'Network-Component SystemID',
                size          =>'20',
                uppersearch   =>1,
                dataobjattr   =>'netportfolio.assettag'),

      new kernel::Field::Text(
                name          =>'netname',
                label         =>'Network-Component Name',
                size          =>'20',
                ignorecase    =>1,
                dataobjattr   =>'netportfolio.name'),

      new kernel::Field::Text(
                name          =>'netnature',
                label         =>'Network-Component Nature',
                size          =>'20',
                ignorecase    =>1,
                dataobjattr   =>'netparentnature.name'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'AC-ComputerID',
                dataobjattr   =>'amcomputer.lcomputerid'),

   );
   $self->setDefaultView(qw(netlnkid description applname systemname netname));
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
   my $from="amTsiParentChild,".
            "amportfolio systemportfolio,".
            "amcomputer,".
            "amportfolio netportfolio,".
            "amportfolio netparentportfolio,".
            "ammodel     netparentmodel,".
            "amnature    netparentnature,".
            "amtsirelportfappl,".
            "amtsicustappl";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amTsiParentChild.lchildid=systemportfolio.lportfolioitemid ".
      "and systemportfolio.bdelete='0' ".
      "and amcomputer.litemid=systemportfolio.lportfolioitemid ".
      "and amTsiParentChild.lparentid=netportfolio.lportfolioitemid  ".
      "and netportfolio.lparentid=netparentportfolio.lportfolioitemid ".
      "and netportfolio.bdelete='0'  ".
      "and netparentportfolio.lmodelid=netparentmodel.lmodelid ".
      "and netparentmodel.lnatureid=netparentnature.lnatureid ".
      "and amtsirelportfappl.lportfolioid=systemportfolio.lportfolioitemid ".
      "and amtsirelportfappl.bdelete='0' ".
      "and netparentnature.name in ('SWITCH') ".
      "and amtsirelportfappl.lapplicationid=amtsicustappl.ltsicustapplid ";
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
