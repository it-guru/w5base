package tsacinv::lnkschain;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
                label         =>'id',
                dataobjattr   =>'schainrel.id'),

      new kernel::Field::Link(
                name          =>'lsspid',
                label         =>'id',
                dataobjattr   =>'schainrel.lsspid'),

      new kernel::Field::Text(
                name          =>'itemid',
                label         =>'Item ID',
                dataobjattr   =>'schainrel.itemid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Item Name',
                htmlwidth     =>'300px',
                dataobjattr   =>'schainrel.itemname'),

      new kernel::Field::Text(
                name          =>'class',
                label         =>'Item Class',
                htmlwidth     =>'140px',
                uppersearch   =>1,
                dataobjattr   =>'schainrel.itemclass'),


      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'schainrel.dtlastmodif'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(schainrel.lsspid,35,'0')"),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'schainrel.dtlastmodif'),

   );
   $self->setDefaultView(qw(linenumber id itemid name class));
   $self->{MainSearchFieldLines}=4;
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from=<<EOF;
 (
  select 'P'||amtsirelsspport.LTSIRELSSPPORTID            id,
          amtsirelsspport.lsspid                          lsspid,
          cast(amportfolio.assettag as VARCHAR2(40))      itemid,
          cast(amportfolio.name as VARCHAR2(4000))         itemname,
          cast(amportfolio.dfe547e741 as VARCHAR2(80))    itemclass,
          NULL itemdataobj,
          amtsirelsspport.dtlastmodif
   from amtsirelsspport,amportfolio
   where  amtsirelsspport.lportfolioid=amportfolio.lportfolioitemid
          and amportfolio.bdelete=0
          and amtsirelsspport.bdelete=0
   union all
   select 'A'||amtsirelsspappl.LTSIRELSSPAPPLID          id,
          amtsirelsspappl.lsspid                         lsspid,
          cast(amtsicustappl.code as VARCHAR(40))        itemid,
          cast(amtsicustappl.name as VARCHAR2(4000))      itemname,
          cast('APPLICATION' as VARCHAR2(80))            itemclass,
          NULL itemdataobj,
          amtsirelsspappl.dtlastmodif
   from amtsirelsspappl,amtsicustappl
   where  amtsirelsspappl.lapplicationid=amtsicustappl.ltsicustapplid
          and amtsicustappl.bdelete=0
          and amtsirelsspappl.bdelete=0
) schainrel 
EOF
   return($from);
}





sub initSqlWhere
{
   my $self=shift;
   my $where="amtsisalessrvcpkg.bdelete=0";
   my $where="";
   return($where);
}


sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_status"))){
#     Query->Param("search_status"=>"\"!out of operation\"");
#   }
   if (!defined(Query->Param("search_tenant"))){
     Query->Param("search_tenant"=>"CS");
   }

}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/location.jpg?".$cgi->query_string());
#}
         

sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("amlocation");
   return(1) if (defined($self->{DB}));
   return(0);
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
