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

      new kernel::Field::RecordUrl(),

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
                name          =>'organisation',
                label         =>'Organisation',
                dataobjattr   =>'Organisation'),

      new kernel::Field::Boolean(
                name          =>'nortargetdefined',
                label         =>'NOR-Target defined',
                dataobjattr   =>"CASE  ".
                    "when (\"Betriebsmodell (Prod)\" is not null ".
                      "and \"Betriebsmodell (Prod)\"<>'') OR ".
                         "(\"Betriebsmodell (Test)\" is not null ".
                      "and \"Betriebsmodell (Test)\"<>'') OR ".
                         "(\"Betriebsmodell (Entw)\" is not null ".
                      "and \"Betriebsmodell (Entw)\"<>'') OR ".
                         "(\"Betriebsmodell (Abnahme)\" is not null ".
                      "and \"Betriebsmodell (Abnahme)\"<>'') OR ".
                         "(\"Betriebsmodell (Sonst1)\" is not null ".
                      "and \"Betriebsmodell (Sonst1)\"<>'') OR ".
                         "(\"Betriebsmodell (Sonst2)\" is not null ".
                      "and \"Betriebsmodell (Sonst2)\"<>'') OR ".
                         "(\"Betriebsmodell (Sonst3)\" is not null ".
                      "and \"Betriebsmodell (Sonst3)\"<>'') OR ".
                         "(\"Betriebsmodell (Sonst4)\" is not null ".
                      "and \"Betriebsmodell (Sonst4)\"<>'') OR ".
                         "(\"Betriebsmodell (Sonst5)\" is not null ".
                      "and \"Betriebsmodell (Sonst5)\"<>'') ".
                    "then '1' else '0' END"),

      new kernel::Field::Text(
                name          =>'w5baseid',
                label         =>'W5BaseID',
                searchable    =>0,
                dataobjattr   =>'"W5BASEID"'),

      new kernel::Field::Text(
                name          =>'itnormodel_prod',
                group         =>'nortarget',
                label         =>'OperationModel Prod',
                dataobjattr   =>'"Betriebsmodell (Prod)"'),

      new kernel::Field::Text(
                name          =>'itnormodel_test',
                group         =>'nortarget',
                label         =>'OperationModel Test',
                dataobjattr   =>'"Betriebsmodell (Test)"'),

      new kernel::Field::Text(
                name          =>'itnormodel_entw',
                group         =>'nortarget',
                label         =>'OperationModel Entw',
                dataobjattr   =>'"Betriebsmodell (Entw)"'),

      new kernel::Field::Text(
                name          =>'itnormodel_abn',
                group         =>'nortarget',
                label         =>'OperationModel Abnahme',
                dataobjattr   =>'"Betriebsmodell (Abnahme)"'),

      new kernel::Field::Text(
                name          =>'itnormodel_sonst1',
                group         =>'nortarget',
                label         =>'OperationModel Sonst1',
                dataobjattr   =>'"Betriebsmodell (Sonst1)"'),

      new kernel::Field::Text(
                name          =>'itnormodel_sonst2',
                group         =>'nortarget',
                label         =>'OperationModel Sonst2',
                dataobjattr   =>'"Betriebsmodell (Sonst2)"'),

      new kernel::Field::Text(
                name          =>'itnormodel_sonst3',
                group         =>'nortarget',
                label         =>'OperationModel Sonst3',
                dataobjattr   =>'"Betriebsmodell (Sonst3)"'),

      new kernel::Field::Text(
                name          =>'itnormodel_sonst4',
                group         =>'nortarget',
                label         =>'OperationModel Sonst4',
                dataobjattr   =>'"Betriebsmodell (Sonst4)"'),

      new kernel::Field::Text(
                name          =>'itnormodel_sonst5',
                group         =>'nortarget',
                label         =>'OperationModel Sonst5',
                dataobjattr   =>'"Betriebsmodell (Sonst5)"'),

      new kernel::Field::Text(
                name          =>'itnormodel',
                group         =>'nortarget',
                depend        =>[qw(itnormodel_prod   itnormodel_test   
                                    itnormodel_entw itnormodel_abn
                                    itnormodel_sonst1 itnormodel_sonst2 
                                    itnormodel_sonst3 itnormodel_sonst4 
                                    itnormodel_sonst5)],
                label         =>'effective NOR Model to use',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $dep=$self->{depend};
                   my %m;
                   my $sfound=0;
                   foreach my $dep (@{$dep}){
                      my $fld=$self->getParent->getField($dep);
                      my $model=$fld->RawValue($current);
                      next if ($model=~m/nicht relevant/); # sehr seltsam!
                      $model=~s/ .*$//;
                      if ($model eq "S"){
                         $sfound++;
                         next;
                      }
                      next if ($model eq "");
                      $m{$model}++;
                   }
                   my @smodes=sort({$b cmp $a} keys(%m));
                   my $mode=$smodes[0];
                   if (!defined($mode) && $sfound){
                      $mode="S";
                   }
                   return($mode);
                }),

      new kernel::Field::Boolean(
                name          =>'persdata',
                group         =>'nortarget',
                label         =>'Person related data',
                dataobjattr   =>"CASE \"Personendaten\" ".
                                "when 'yes' then '1' else '0' END"),

      new kernel::Field::Boolean(
                name          =>'tkdata',
                group         =>'nortarget',
                label         =>'TK-Data',
                dataobjattr   =>"CASE \"TK-Bestandsdaten/TK-Verkehrsdaten\" ".
                                "when 'yes' then '1' else '0' END"),

      new kernel::Field::Text(
                name          =>'cnfciam',
                group         =>'source',
                label         =>'Confirmer CIAM-ID',
                dataobjattr   =>'"CIAM-ID Confirmer"'),

      new kernel::Field::Text(
                name          =>'cnfemail',
                group         =>'source',
                label         =>'Confirmer EMail',
                dataobjattr   =>'"Email_Confirmer"'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                timezone      =>'CET',
                label         =>'Confirmer Date',
                dataobjattr   =>'"Confirmdate"'),

   );
   $self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(id archapplid appl itnormodel mdate));
   $self->setWorktable("V_DARWIN_EXPORT_NOR");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tscape"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable join V_DARWIN_EXPORT ".
            "on $worktable.\"ICTO-ID\"=V_DARWIN_EXPORT.ICTO_Nummer ";

   return($from);
}



sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_nortargetdefined"))){
     Query->Param("search_nortargetdefined"=>
                   "\"".$self->T("boolean.true")."\"");
   }




}



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
