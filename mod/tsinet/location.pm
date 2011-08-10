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
   $address1=~s/\sSCZ$//;
   my $newrec;
   $newrec->{country}=$country;
   $newrec->{location}=$location;
   $newrec->{address1}=$address1;
   $newrec->{zipcode}=$zipcode;

   $loc->Normalize($newrec);

   $loc->SetFilter({country=>\$newrec->{country},
                    location=>\$newrec->{location},
                    address1=>\$newrec->{address1},
                    zipcode=>\$newrec->{zipcode},
                    cistatusid=>\'4'}); 
   my @loclist;
   @loclist=$loc->getHashList(qw(id));
   if ($#loclist==-1){
      $loc->ResetFilter();
      $loc->SetFilter({country=>\$newrec->{country},
                       location=>\$newrec->{location},
                       address1=>\$newrec->{address1},
                       cistatusid=>\'4'}); 
      @loclist=$loc->getHashList(qw(id));
   }
   if ($#loclist==-1){
      $loc->ResetFilter();
      $loc->SetFilter({name=>"NONE"});
      if (($newrec->{location}=~m/Bamberg/i) &&
          ($newrec->{address1}=~m/Memmelsdorfer/i)){
         $loc->SetFilter({name=>"*bamberg*memmelsdorfer*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Heusenstamm/i) &&
          ($newrec->{address1}=~m/Jahnstr/i)){
         $loc->SetFilter({name=>"*Heusenstamm*Jahnstr",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Weiden/i) &&
          ($newrec->{address1}=~m/Stockerhutweg/i)){
         $loc->SetFilter({name=>"*weiden*Stockerhutweg*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Weiden/i) &&
          ($newrec->{address1}=~m/Bauscher/i)){
         $loc->SetFilter({name=>"*weiden*Bauscher*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Nürnberg/i) &&
          ($newrec->{address1}=~m/Allersberger/i)){
         $loc->SetFilter({name=>"*Nuernberg*Allersberger*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Traunstein/i) &&
          ($newrec->{address1}=~m/Rosenheimer/i)){
         $loc->SetFilter({name=>"*Traunstein*Rosenheimer*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Offenburg/i) &&
          ($newrec->{address1}=~m/Okenstr/i)){
         $loc->SetFilter({name=>"*Offenburg*Okenstr*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Göppingen/i) &&
          ($newrec->{address1}=~m/Salamander/i)){
         $loc->SetFilter({name=>"*Goeppingen*Salamander*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Neustadt/i) &&
          ($newrec->{address1}=~m/Chemnitzer.*2/i)){
         $loc->SetFilter({name=>"*Neustadt*Chemnitzer*2*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Hanau/i) &&
          ($newrec->{address1}=~m/Rückinger/i)){
         $loc->SetFilter({name=>"*Hanau*Ruckinger*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Heusenstamm/i) &&
          ($newrec->{address1}=~m/Jahnstr/i)){
         $loc->SetFilter({name=>"*Heusenstamm*Jahnstr*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Duisburg/i) &&
          ($newrec->{address1}=~m/Saarstr/i)){
         $loc->SetFilter({name=>"*Duisburg*Saarstr*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Bochum/i) &&
          ($newrec->{address1}=~m/Karl-Lange.*29/i)){
         $loc->SetFilter({name=>"*Bochum*Karl_Lange*29*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Magdeburg/i) &&
          ($newrec->{address1}=~m/Lübecker.*13/i)){
         $loc->SetFilter({name=>"*Magdeburg*Luebecker*13*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Detmold/i) &&
          (my ($no)=$newrec->{address1}=~m/Braunen.*(\d+)/i)){
         $loc->SetFilter({name=>"*Detmold*Braun*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Hannover/i) &&
          (my ($no)=$newrec->{address1}=~m/TÜV.*(\d+)/i)){
         $loc->SetFilter({name=>"*Hannover*TUEV*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Bremen/i) &&
          (my ($no)=$newrec->{address1}=~m/Stresemann.*(\d+)/i)){
         $loc->SetFilter({name=>"*Bremen*esemann*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Heide/i) &&
          (my ($no)=$newrec->{address1}=~m/Kleinbahnhof.*(\d+)/i)){
         $loc->SetFilter({name=>"*Heide*Kleinbahnhof*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Flensburg/i) &&
          (my ($no)=$newrec->{address1}=~m/Eckernf.*(\d+)/i)){
         $loc->SetFilter({name=>"*Flensburg*Eckernf*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Kronshagen/i) &&
          (my ($no)=$newrec->{address1}=~m/Posthorn.*3/i)){
         $loc->SetFilter({name=>"*Kronshagen*Posthorn*3*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Rostock/i) &&
          (my ($no)=$newrec->{address1}=~m/Deutsche.*(\d+)/i)){
         $loc->SetFilter({name=>"*Rostock*Deutsche*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Stahnsdorf/i) &&
          (my ($no)=$newrec->{address1}=~m/Güterfelder.*(\d+)/i)){
         $loc->SetFilter({name=>"*Stahnsdorf*Gueterfelder*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Berlin/i) &&
          (my ($no)=$newrec->{address1}=~m/Dernburgstr.*(\d+)/i)){
         $loc->SetFilter({name=>"*Berlin*Dernburgerstr*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Berlin/i) &&
          (my ($no)=$newrec->{address1}=~m/Lankwitzer/i)){
         $loc->SetFilter({name=>"*Berlin*Lankwitzer*13-17*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Berlin/i) &&
          (my ($no)=$newrec->{address1}=~m/Winterfeld.*21/i)){
         $loc->SetFilter({name=>"*Berlin*Winterfeld*21*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Leipzig/i) &&
          (my ($no)=$newrec->{address1}=~m/Gutenberg/i)){
         $loc->SetFilter({name=>"*Leipzig*Gutenberg*1*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Cottbus/i) &&
          (my ($no)=$newrec->{address1}=~m/Heinrich.*(\d+)/i)){
         $loc->SetFilter({name=>"*Cottbus*Heinrich*$no*",
                          cistatusid=>\'4'});
      }
      if (($newrec->{location}=~m/Radebeul/i) &&
          (my ($no)=$newrec->{address1}=~m/Dresdner.*(\d+)/i)){
         $loc->SetFilter({name=>"*Radebeul*Dresdner*$no*",
                          cistatusid=>\'4'});
      }
      @loclist=$loc->getHashList(qw(id));
   }

   my @locid;
   foreach my $locrec (@loclist){
      push(@locid,$locrec->{id});
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
   return(@result) if (defined($result[0]) eq "InitERROR");
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
   return("header","default","w5baselocation");
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
