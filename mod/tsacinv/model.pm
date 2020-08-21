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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=1;
   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'lmodelid',
                label         =>'ModelID',
                dataobjattr   =>'"lmodelid"'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'350px',
                label         =>'Model',
                ignorecase    =>1,
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(
                name          =>'barcode',
                label         =>'BarCode',
                ignorecase    =>1,
                dataobjattr   =>'"barcode"'),

      new kernel::Field::Text(
                name          =>'nature',
                label         =>'Nature',
                ignorecase    =>1,
                dataobjattr   =>'"nature"'),

      new kernel::Field::Text(
                name          =>'vendor',
                label         =>'Vendor',
                ignorecase    =>1,
                dataobjattr   =>'"vendor"'),

      new kernel::Field::Text(
                name          =>'barcode',
                label         =>'BarCode',
                ignorecase    =>1,
                dataobjattr   =>'"barcode"'),

      new kernel::Field::Float(
                name          =>'assetpowerinput',
                label         =>'PowerInput of Asset',
                unit          =>'KVA',
                dataobjattr   =>'"assetpowerinput"'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'"replkeypri"'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>'"replkeysec"'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'"mdate"')
   );
   $self->setWorktable("model");
   $self->setDefaultView(qw(lmodelid barcode name nature));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/model.jpg?".$cgi->query_string());
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
