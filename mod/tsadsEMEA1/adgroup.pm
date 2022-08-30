package tsadsEMEA1::adgroup;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use tsadsEMEA1::lib::Listedit;
use kernel;
use kernel::Field;
@ISA=qw(tsadsEMEA1::lib::Listedit);

# Attribute im ADS LDAP:


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   my $module=$self->Module();
   my $domain=lc($module);
   $domain=~s/^tsads//;
   
   $self->setBase("DC=$domain,DC=cds,DC=t-internal,DC=com");
   $self->{objectClass}="Group";
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(     
                name          =>'fullname',
                label         =>'Name',
                dataobjattr   =>'displayName'),

      new kernel::Field::Textarea(
                name          =>'info',
                label         =>'Comments',
                dataobjattr   =>'info'),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'mail'),

      new kernel::Field::Text(
                name          =>'member',
                htmldetail    =>0,
                group         =>'members',
                label         =>'member',
                dataobjattr   =>'member'),

      new kernel::Field::SubList(
                name          =>'members',
                group         =>'members',
                label         =>'members',
                searchable    =>0,
                vjointo       =>'tsadsEMEA1::lnkaduseradgroup',
                vjoinon       =>['distinguishedName'
                                 =>'groupObjectID'],
                vjoindisp     =>['user'],
                vjoinonfinish =>sub{   #Hack to allow spaces 
                   my $self=shift;    #ids
                   my $flt=shift;
                   my $current=shift;
                   my $mode=shift;
                 
                   if ($flt->{groupObjectID} ne ""){
                      $flt->{groupObjectID}=
                          '"'.$flt->{groupObjectID}.'"';
                   }
                   return($flt);
                },
                vjoininhash   =>['userObjectId','usergroup']),

      new kernel::Field::Text(
                name          =>'distinguishedName',
                label         =>'distinguishedName',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>'distinguishedName'),

      new kernel::Field::Text(
                name          =>'objectClass',
                label         =>'ObjectClass',
                group         =>'source',
                dataobjattr   =>'objectClass'),

      new kernel::Field::Id(
                name          =>'objectGUID',
                label         =>'ObjectGUID',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>'objectGUID'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'Creation-Date',
                dataobjattr   =>'whenCreated'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                searchable    =>0,
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'whenChanged'),


   );
   $self->setDefaultView(qw(fullname));
   return($self);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","members","source");
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
}
         

1;
