package tsacinv::model;
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
   $self->{use_distinct}=0;
   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'lmodelid',
                label         =>'ModelID',
                dataobjattr   =>'assetmodel.lmodelid'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'350px',
                label         =>'Model',
                ignorecase    =>1,
                dataobjattr   =>'assetmodel.name'),

      new kernel::Field::Text(
                name          =>'barcode',
                label         =>'BarCode',
                ignorecase    =>1,
                dataobjattr   =>'assetmodel.barcode'),

      new kernel::Field::Text(
                name          =>'nature',
                label         =>'Nature',
                ignorecase    =>1,
                dataobjattr   =>'amnature.name'),

      new kernel::Field::Text(
                name          =>'barcode',
                label         =>'BarCode',
                ignorecase    =>1,
                dataobjattr   =>'assetmodel.barcode'),

      new kernel::Field::Float(
                name          =>'assetpowerinput',
                label         =>'PowerInput of Asset',
                unit          =>'KVA',
                dataobjattr   =>'assetpowerinput.powerinput'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"assetmodel.dtlastmodif"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(assetmodel.lmodelid,35,'0')"),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'assetmodel.dtlastmodif'),



   );
   $self->setDefaultView(qw(lmodelid barcode name nature));
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
   return("../../../public/itil/load/model.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from=
      "ammodel assetmodel,amnature,".
      "(select amfvmodel.fval PowerInput,lmodelid from amfvmodel,amfeature ".
      "where amfvmodel.lfeatid=amfeature.lfeatid and ".
      " amfeature.sqlname='PowerInput') assetpowerinput";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="assetmodel.lmodelid=assetpowerinput.lmodelid(+) and ".
             "assetmodel.lnatureid=amnature.lnatureid(+) ";
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
