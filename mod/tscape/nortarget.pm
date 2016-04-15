package tscape::nortarget;
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'NORid',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"REFSTR"'),

      new kernel::Field::Text(
                name          =>'appl',
                label         =>'W5Base Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['w5baseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'archapplid',
                label         =>'ICTO-ID',
                dataobjattr   =>'"ICTO-ID"'),

      new kernel::Field::Text(
                name          =>'w5baseid',
                label         =>'W5BaseID',
                searchable    =>0,
                dataobjattr   =>'"W5BASEID"'),

      new kernel::Field::Text(
                name          =>'bmodel_prod',
                group         =>'nortarget',
                label         =>'OperationModel Prod',
                dataobjattr   =>'"Betriebsmodell (Prod)"'),

      new kernel::Field::Text(
                name          =>'bmodel_test',
                group         =>'nortarget',
                label         =>'OperationModel Test',
                dataobjattr   =>'"Betriebsmodell (Test)"'),

      new kernel::Field::Text(
                name          =>'bmodel_entw',
                group         =>'nortarget',
                label         =>'OperationModel Entw',
                dataobjattr   =>'"Betriebsmodell (Entw)"'),

      new kernel::Field::Text(
                name          =>'bmodel_sonst1',
                group         =>'nortarget',
                label         =>'OperationModel Sonst1',
                dataobjattr   =>'"Betriebsmodell (Sonst1)"'),

      new kernel::Field::Text(
                name          =>'bmodel_sonst2',
                group         =>'nortarget',
                label         =>'OperationModel Sonst2',
                dataobjattr   =>'"Betriebsmodell (Sonst2)"'),

      new kernel::Field::Text(
                name          =>'bmodel_sonst3',
                group         =>'nortarget',
                label         =>'OperationModel Sonst3',
                dataobjattr   =>'"Betriebsmodell (Sonst3)"'),

      new kernel::Field::Text(
                name          =>'bmodel_sonst4',
                group         =>'nortarget',
                label         =>'OperationModel Sonst4',
                dataobjattr   =>'"Betriebsmodell (Sonst4)"'),

      new kernel::Field::Text(
                name          =>'bmodel_sonst5',
                group         =>'nortarget',
                label         =>'OperationModel Sonst5',
                dataobjattr   =>'"Betriebsmodell (Sonst5)"'),

      new kernel::Field::Text(
                name          =>'persdata',
                group         =>'nortarget',
                label         =>'Person related data',
                dataobjattr   =>'"Personendaten"'),

      new kernel::Field::Text(
                name          =>'tkdata',
                group         =>'nortarget',
                label         =>'TK-Data',
                dataobjattr   =>'"TK-Bestandsdaten/TK-Verkehrsdaten"'),

      new kernel::Field::Text(
                name          =>'cnfciam',
                group         =>'source',
                label         =>'Confirmer CIAM-ID',
                dataobjattr   =>'"CIAM-ID Confirmer"'),

      new kernel::Field::Text(
                name          =>'cnfwiw',
                group         =>'source',
                label         =>'Confirmer WIW-ID',
                dataobjattr   =>'"WIW-ID Confirmer"'),

   );
   $self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(id archapplid w5baseid appl));
   $self->setWorktable("V_DARWIN_EXPORT_NOR");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tscape"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_status"))){
#     Query->Param("search_status"=>"\"!Retired\"");
#   }
#}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","nortarget","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appladv.jpg?".$cgi->query_string());
}
         



1;
