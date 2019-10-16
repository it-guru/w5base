package tsinet::location;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'TSINETid',
                dataobjattr   =>"concat(concat(streetser,'-'),kunde)"),

      new kernel::Field::Text(
                name          =>'streetser',
                sqlorder      =>'desc',
                label         =>'StreetSer',
                dataobjattr   =>'streetser'),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                ignorecase    =>1,
                translation   =>'base::location',
                dataobjattr   =>'townname'),

      new kernel::Field::Text(
                name          =>'country',
                label         =>'Country',
                uppersearch   =>1,
                translation   =>'base::location',
                dataobjattr   =>'upper(code)'),

      new kernel::Field::Text(
                name          =>'zipcode',
                label         =>'ZIP Code',
                translation   =>'base::location',
                dataobjattr   =>'streetplz'),

      new kernel::Field::Text(
                name          =>'address1',
                htmlwidth     =>'200px',
                ignorecase    =>1,
                translation   =>'base::location',
                label         =>'Street address',
                dataobjattr   =>'streetname'),

      new kernel::Field::Text(
                name          =>'prio',
                label         =>'Location prio',
                dataobjattr   =>'prio'),

      new kernel::Field::Date(
                name          =>'validto',
                label         =>'Valid to',
                sqlorder      =>'NONE',
                dataobjattr   =>"decode(to_char(validto,'YYYY-MM-DD'),'2100-01-01',to_date(null,'YYYY-MM-DD HH24:MI:SS'),validto)"),

      new kernel::Field::Text(
                name          =>'customer',
                label         =>'Customer',
                dataobjattr   =>'kunde'),

      new kernel::Field::Text(
                name          =>'w5locid',
                label         =>'W5Base Location ID',
                group         =>'w5baselocation',
                searchable    =>0,
                depend        =>[qw(location address1 country zipcode)],
                onRawValue    =>\&findW5LocID),

      new kernel::Field::TextDrop(
                name          =>'w5location',
                group         =>'w5baselocation',
                label         =>'W5Base Location',
                vjointo       =>'base::location',
                vjoindisp     =>'name',
                vjoinon       =>['w5locid'=>'id'],
                searchable    =>0),

      new kernel::Field::Text(
                name          =>'sla',
                ignorecase    =>1,
                label         =>'SLA',
                dataobjattr   =>'service_option'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                timezone      =>'CET',
                label         =>'Modification-Date',
                dataobjattr   =>"to_date(substr(tsupdate,0,14),".
                                "'YYYYMMDDHH24MISS')"),

      new kernel::Field::Text(
                name          =>'mnote',
                group         =>'source',
                timezone      =>'CET',
                label         =>'Modification-Note',
                dataobjattr   =>"description")

   );
   $self->setDefaultView(qw(country zipcode location address1 prio 
                            customer w5location));
   $self->setWorktable("TSIIMP.V_DARWIN_STANDORT_PRIO_KUNDEN");
   return($self);
}

sub findW5LocID
{
   my $self=shift;
   my $current=shift;

   my $loc=getModuleObject($self->getParent->Config,"base::location");
   my $address1=$self->getParent->getField("address1")->RawValue($current);
   my $location=$self->getParent->getField("location")->RawValue($current);
   my $zipcode=$self->getParent->getField("zipcode")->RawValue($current);
   my $country=$self->getParent->getField("country")->RawValue($current);
   my $newrec;
   $newrec->{country}=$country;
   $newrec->{location}=$location;
   $newrec->{address1}=$address1;
   $newrec->{zipcode}=$zipcode;
   $newrec->{cistatusid}="4";

   foreach my $k (keys(%$newrec)){
      delete($newrec->{$k}) if (!defined($newrec->{$k}));
   }
   #printf STDERR ("fifi newrec=%s\n",Dumper($newrec));
   my $d;
   my @locid=$loc->getIdByHashIOMapped($self->getParent->Self,$newrec,
                                       DEBUG=>\$d,
                                       ForceLikeSearch=>1);
   #printf STDERR ("debug=%s\n",$d);
   $d="";
   if ($newrec->{zipcode} ne "" && $#locid==-1){ # try without zipcode
      delete($newrec->{zipcode});
      @locid=$loc->getIdByHashIOMapped($self->getParent->Self,$newrec,
                                       DEBUG=>\$d,
                                       ForceLikeSearch=>1);
   }
  
   if ($#locid!=-1){
      return(\@locid);
   }
   return(undef);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsinet"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_validto"))){
     Query->Param("search_validto"=>
                  ">now OR [EMPTY]");
   }
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","w5baselocation","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/location.jpg?".$cgi->query_string());
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
