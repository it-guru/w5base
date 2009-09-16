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
   $self->setDefaultView(qw(country zipcode location address1 prio));
   $self->setWorktable("TSIIMP.V_DARWIN_STANDORT_PRIO");
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
   printf STDERR ("fifi $country $location $zipcode address1=$address1\n");
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
                    zipcode=>\$newrec->{zipcode}}); 
   my @locid;
   foreach my $locrec ($loc->getHashList(qw(id))){
      push(@locid,$locrec->{id});
   }
  
   my ($locrec)=$loc->getOnlyFirst(qw(id));
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
