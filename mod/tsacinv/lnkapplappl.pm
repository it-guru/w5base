package tsacinv::lnkapplappl;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                dataobjattr   =>"amtsirelappl.lrelapplid"),

      new kernel::Field::TextDrop(
                name          =>'parent',
                label         =>'Parent Application',
                vjointo       =>'tsacinv::appl',
                vjoinon       =>['lparentid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'child',
                label         =>'Child Application',
                weblinkto     =>'tsacinv::appl',
                weblinkon     =>['lchildid'=>'id'],
                dataobjattr   =>'amtsicustappl.name'),

      new kernel::Field::TextDrop(
                name          =>'parent_applid',
                label         =>'Parent ApplicationID',
                vjointo       =>'tsacinv::appl',
                vjoinon       =>['lparentid'=>'id'],
                vjoindisp     =>'applid'),

      new kernel::Field::TextDrop(
                name          =>'child_applid',
                label         =>'Child ApplicationID',
                weblinkto     =>'tsacinv::appl',
                weblinkon     =>['lchildid'=>'id'],
                dataobjattr   =>'amtsicustappl.code'),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'type',
                dataobjattr   =>'amtsirelappl.type'),

      new kernel::Field::Interface(
                name          =>'lparentid',
                label         =>'lparentid',
                dataobjattr   =>'amtsirelappl.lparentid'),

      new kernel::Field::Interface(
                name          =>'lchildid',
                label         =>'lchildid',
                dataobjattr   =>'amtsirelappl.lchildid'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'amtsirelappl.dtlastmodif'),

      new kernel::Field::Text(
                name          =>'srcsys',
                ignorecase    =>1,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amtsirelappl.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amtsirelappl.externalid'),


   );
   $self->setDefaultView(qw(id parent child));
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

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplappl.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="amtsirelappl,amtsicustappl";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   return("amtsirelappl.bdelete=0 and ".
          "amtsirelappl.lchildid=amtsicustappl.ltsicustapplid");
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
