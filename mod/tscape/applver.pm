package tscape::applver;
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'CapeID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"APP_Internal_Key"),

      new kernel::Field::Text(
                name          =>'ictoid',
                label         =>'ICTO-ID',
                dataobjattr   =>'ICTO_Nummer'),

      new kernel::Field::Text(
                name          =>'fullname',
                searchable    =>0,
                htmlwidth     =>'200px',
                sqlorder      =>'NONE',
                label         =>'fullname',
                dataobjattr   =>"APP_Name+' - '+Version"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'APP_Name'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'Status'),

      new kernel::Field::Text(
                name          =>'applversid',
                label         =>'Applicationversion ID',
                dataobjattr   =>'APP_Nummer'),

      new kernel::Field::Text(
                name          =>'retirement_type',
                label         =>'Retirement Type',
                dataobjattr   =>'Retirement_Type'),

      new kernel::Field::Date(
                name          =>'retirement_date',
                label         =>'Retirement Date',
                timezone      =>'CET',
                dataobjattr   =>'Retirement_Date'),


      new kernel::Field::Text(
                name          =>'applversion',
                label         =>'application version',
                dataobjattr   =>'Version'),

      new kernel::Field::Date(
                name          =>'planed_activation',
                label         =>'planed activation',
                dataobjattr   =>'Startdatum'),

      new kernel::Field::Date(
                name          =>'planed_retirement',
                label         =>'planed retirement',
                dataobjattr   =>'Enddatum'),

      new kernel::Field::Text(
                name          =>'shortname',
                label         =>'shortname',
                dataobjattr   =>'APP_Kurzname'),

      new kernel::Field::Textarea(       
                name          =>'description',
                label         =>'description',
                dataobjattr   =>'APP_Beschreibung'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"APP_Last_Update"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"right(replicate('0',35)+APP_Internal_Key,35)"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'none',    # in MSSQL zwingend!
                label         =>'Modification-Date',
                timezone      =>'CET',
                dataobjattr   =>'convert(VARCHAR,APP_Last_Update,20)'),

   );
   $self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(name shortname applversion status 
                            planed_activation planed_retirement));
   $self->setWorktable("V_DARWIN_EXPORT_APP");
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

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!Retired\"");
   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}






sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
