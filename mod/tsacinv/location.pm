package tsacinv::location;
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
use kernel::Field::OSMap;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   sub AddressBuild{
      my $self=shift;
      my $current=shift;
      my $a="";
      $a.=" ".$current->{country};
      $a.=" ".$current->{zipcode};
      $a.=" ".$current->{location};
      $a.=" ".$current->{address1};
      return($a);
   }

   
   $self->AddFields(
      new kernel::Field::Linenumber(name     =>'linenumber',
                                  label      =>'No.'),


      new kernel::Field::Id(      name       =>'code',
                                  label      =>'Code',
                                  dataobjattr  =>'amlocation.barcode'),

      new kernel::Field::Id(      name       =>'locationid',
                                  label      =>'LocationID',
                                  dataobjattr  =>'amlocation.llocaid'),

      new kernel::Field::Text(    name       =>'fullname',
                                  label      =>'Fullname',
                                  ignorecase =>1,
                                  dataobjattr     =>'amlocation.fullname'),

      new kernel::Field::Text(    name       =>'address1',
                                  label      =>'Street',
                                  ignorecase =>1,
                                  dataobjattr=>'amlocation.address1'),

      new kernel::Field::Text(    name       =>'zipcode',
                                  label      =>'ZIP',
                                  dataobjattr=>'amlocation.zip'),

      new kernel::Field::Text(    name       =>'country',
                                  label      =>'Country',
                                  ignorecase =>1,
                                  dataobjattr=>'amcountry.isocode'),

      new kernel::Field::Text(    name       =>'location',
                                  label      =>'Location',
                                  ignorecase =>1,
                                  dataobjattr=>'amlocation.city'),

      new kernel::Field::Text(    name       =>'locationtype',
                                  label      =>'Location Type',
                                  ignorecase =>1,
                                  dataobjattr=>'amlocation.locationtype'),

      new kernel::Field::Text(    name       =>'name',
                                  label      =>'Name',
                                  ignorecase =>1,
                                  dataobjattr=>'amlocation.name'),

      new kernel::Field::OSMap(
                name          =>'osmap',
                uploadable    =>0,
                searchable    =>0,
                group         =>'map',
                htmlwidth     =>'500px',
                label         =>'OpenStreetMap',
                depend        =>['country','address1',
                                 'label',
                                 'gpslongitude',
                                 'gpslatitude',
                                 'zipcode','location']),



#      new kernel::Field::GoogleMap(  name          =>'googlemap',
#                                     group         =>'map',
#                                     htmlwidth     =>'500px',
#                                     label         =>'GoogleMap',
#                                     depend        =>['country','address1',
#                                                      'fullname',
#                                                      'gpslongitude',
##                                                      'gpslatitude',
#                                                      'zipcode','location'],
#                                     marker=>sub{
#                                        my $self=shift;
#                                        my $current=shift;
#                                        my $m="";
#                                        $m=$current->{fullname};
#                                        $m="<b>$m</b>" if ($m ne "");
#                                        $m.="<br>" if ($m ne "");
#                                        if ($current->{address1} ne ""){
#                                           $m.="<br>".$current->{address1};
#                                        }
#                                        my $o=$current->{country};
#                                        if ($current->{zipcode} ne ""){
#                                           $o.="-" if ($o ne "");
#                                           $o.=$current->{zipcode};
#                                        }
#                                        if ($current->{location} ne ""){
#                                           $o.=" " if ($o ne "");
#                                           $o.=$current->{location};
#                                        }
#                                        if ($o ne ""){
#                                           $m.="<br>$o";
#                                        }
#                                        return($m);
#                                     },
#                                     address=>\&AddressBuild),

#      new kernel::Field::GoogleAddrChk(name        =>'googlechk',
#                                     group         =>'map',
#                                     htmldetail    =>0,
#                                     htmlwidth     =>'200px',
#                                     label         =>'Google Address Check',
#                                     depend        =>['country','address1',
#                                                      'label',
#                                                      'gpslongitude',
#                                                      'gpslatitude',
#                                                      'zipcode','location'],
#                                     address=>\&AddressBuild),

   );
   $self->setDefaultView(qw(linenumber code locationid fullname zipcode location address1));
   $self->{MainSearchFieldLines}=4;
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="amlocation, amcountry";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amlocation.lcountryid=amcountry.lcountryid(+) ";
   return($where);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/location.jpg?".$cgi->query_string());
}
         

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
