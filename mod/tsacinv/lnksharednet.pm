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
                dataobjattr   =>'TsiParentChild.ltsiparentchildid'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                align         =>'left',
                dataobjattr   =>'TsiParentChild.description'),

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
                dataobjattr   =>'netpartnernature.name'),

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
   my $from="amcomputer ".
    "join amportfolio systemportfolio ".
     "on (amcomputer.litemid=systemportfolio.lportfolioitemid and ".
         "systemportfolio.bdelete='0') ".
    "join ( ".
       "select ".
               "amTsiParentChild.ltsiparentchildid,".
               "amTsiParentChild.lparentid a,".
               "amTsiParentChild.lchildid b,".
               "amTsiParentChild.description ".
       "from amTsiParentChild ".
       "union all ".
       "select ".
               "amTsiParentChild.ltsiparentchildid,".
               "amTsiParentChild.lchildid a,".
               "amTsiParentChild.lparentid b,".
               "amTsiParentChild.description ".
       "from amTsiParentChild ".
    ") TsiParentChild on systemportfolio.lportfolioitemid=TsiParentChild.a ".
    "join amportfolio netportfolio ".
     "on (TsiParentChild.b=netportfolio.lportfolioitemid and ".
         "netportfolio.bdelete='0') ".
    "join amcomputer netcomputer ".
     "on (netcomputer.litemid=netportfolio.lportfolioitemid and ".
         "netcomputer.status<>'out of operation') ".
    "join amportfolio netpartnerportfolio ".
     "on netportfolio.lparentid=netpartnerportfolio.lportfolioitemid ".
    "join ammodel netpartnermodel ".
     "on netpartnerportfolio.lmodelid=netpartnermodel.lmodelid ".
    "join amnature netpartnernature ".
     "on (netpartnermodel.lnatureid=netpartnernature.lnatureid and ".
         "netpartnernature.name in ".
         "('SWITCH','FIREWALL-BOX','FIREWALL','FC-SWITCH','ROUTER')) ".
    "left outer join amtsirelportfappl ".
     "on (systemportfolio.lportfolioitemid=amtsirelportfappl.lportfolioid and ".
         "amtsirelportfappl.bdelete='0') ".
    "left outer join amtsicustappl ".
     "on amtsirelportfappl.lapplicationid=amtsicustappl.ltsicustapplid ";

   return($from);
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
