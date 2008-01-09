package w5v1inv::ipaddress;
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
use Data::Dumper;
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
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->setWorktable("ip");

   $self->AddFields(
      new kernel::Field::Id(      name    =>'id',
                                  label    =>'W5BaseID',
                                  size    =>'10',
                                  dataobjattr  =>'ip.id'),
      new kernel::Field::Text(    name    =>'addr',
                                  label    =>'IP-Address',
                                  size    =>'15',
                                  dataobjattr  =>'ip.addr'),
      new kernel::Field::Text(    name    =>'netmask',
                                  label    =>'Netmask',
                                  dataobjattr  =>'ip.netmask'),
      new kernel::Field::Text(    name    =>'name',
                                  label    =>'DNS-Name',
                                  size    =>'40',
                                  onClick =>\&MakeGoogleLink,
                                  dataobjattr  =>'ip.dnsname'),
      new kernel::Field::Text(    name    =>'app',
                                  label    =>'App-Modul',
                                  dataobjattr  =>'ip.app'),
      new kernel::Field::Link(    name    =>'uniqflag',
                                  label    =>'uniqflag',
                                  dataobjattr  =>'ip.uniqflag'),
      new kernel::Field::Link(    name    =>'w5systemid',
                                  label    =>'associated-to',
                                  dataobjattr  =>'ip.hardware'),
   );
   $self->setDefaultView(qw(addr name netmask app));
   return($self);
}

sub MakeGoogleLink
{
   my $self=shift;
   my $app=shift;
   my $name=$app->ResolvFieldValue("name");

   return("") if ($name eq "");
   return("openwin(\"http://www.google.de/search?q=$name\",\"_blank\",".
          "\"height=500,width=640,toolbar=no,scrollbars=auto\")");
}

#sub SkinBase
#{
#   return("w5v1inv");
#}
#
#
sub getSqlFrom
{
   my $self=shift;
   #sleep(2);
   return("ip");
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec)){
      $newrec->{uniqflag}=time();
   }

   return(1);
}

sub validateSearchQuery
{
   my $self=shift;
   $self->SetNamedFilter("BASE",{app=>'bchw'});
   return(1);
}

sub isViewValid
{
   return("ALL");
}


1;
