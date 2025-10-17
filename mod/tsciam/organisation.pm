package tsciam::organisation;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::LDAP;
use kernel::Field;
use HTML::TreeGrid;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::LDAP);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->setBase("ou=Company,o=DTAG");
   $self->setLdapQueryPageSize(3499);
   $self->AddFields(
      new kernel::Field::Id(       name       =>'tocid',
                                   label      =>'toCID',
                                   size       =>'10',
                                   align      =>'left',
                                   dataobjattr=>'toCID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     name       =>'name',
                                   label      =>'Organisation-Name (toLD)',
                                   dataobjattr=>'toLD'),

      new kernel::Field::Text(     name       =>'shortname',
                                   label      =>'Organisation-ShortName (toSD)',
                                   dataobjattr=>'toSD'),

      new kernel::Field::Text(     name       =>'abbreviation',
                                   label      =>'Abbreviation (toAbbreviation)',
                                   dataobjattr=>'toAbbreviation'),

      new kernel::Field::Text(     name       =>'sisnumber',
                                   label      =>'SIS Number',
                                   dataobjattr=>'tTSISnumber'),

      new kernel::Field::Text(     name       =>'fullname',
                                   htmldetail =>0,
                                   label      =>'(O) Fullname',
                                   searchable =>0,
                                   dataobjattr=>'o'),

   );
   $self->setDefaultView(qw(name abbreviation tocid SISnumber));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tsciam"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   return(1) if (defined($self->{tsciam}));
   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





sub SetFilterForQualityCheck
{  
   my $self=shift;
   my @view=@_;
   return(undef);
}
   


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
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


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_disabled"))){
     Query->Param("search_disabled"=>"\"".$self->T("boolean.false")."\"");
   }
}








1;
