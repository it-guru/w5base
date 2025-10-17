package TeamLeanIX::lnkcontact_gov;
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use kernel::App::Web::Listedit;
use kernel::DataObj::ElasticSearch;
use TeamLeanIX::lib::Listedit;
use JSON;
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::ElasticSearch 
        TeamLeanIX::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(     
            name          =>'id',
            group         =>'source',
            dataobjattr   =>'_id',
            label         =>'Id'),

      new kernel::Field::Text(     
            name          =>'name',
            dataobjattr   =>'name',
            htmlwidth     =>'150px',
            label         =>'Name'),

      new kernel::Field::Text(     
            name          =>'email',
            dataobjattr   =>'email',
            label         =>'email'),

      new kernel::Field::Text(     
            name          =>'role',
            dataobjattr   =>'role',
            label         =>'role'),
   );
   $self->setDefaultView(qw(id name email role));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TeamLeanIX");
}



sub ESindexName
{
   my $self=shift;

   return("teamleanix__gov");
}



sub ESprepairRawResult
{
   my $self=shift;
   my $data=shift;

   my @result;

   map({
      $_=FlattenHash($_);
      if (ref($_->{'_source.subscriptions'}) eq "ARRAY"){
         foreach my $crec (@{$_->{'_source.subscriptions'}}){
            my %c=%{$crec};
            $c{_id}=$_->{_id};
            push(@result,\%c);
         }
      }
   } @$data);
   @$data=@result;
}




sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default component network subnet vlan source));
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}

sub isUploadValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/ipaddress.jpg?".$cgi->query_string());
#}


1;
