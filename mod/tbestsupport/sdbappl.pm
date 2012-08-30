package tbestsupport::sdbappl;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
                label         =>'ID',
                dataobjattr   =>"id"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'shortname',
                dataobjattr   =>'kurzname'),

      new kernel::Field::Text(
                name          =>'prio',
                label         =>'prio',
                dataobjattr   =>'prioritaet'),

      new kernel::Field::Text(
                name          =>'state',
                label         =>'state',
                dataobjattr   =>'status'),

      new kernel::Field::Link(
                name          =>'contractnumber',
                noselect      =>'1',
                dataobjattr   =>'vertragsnummer'),

#      new kernel::Field::Textarea(        # distinct Problem!
#                name          =>'description',
#                label         =>'description',
#                dataobjattr   =>'kurzbeschreibung'),

      new kernel::Field::Email(
                name          =>'sm',
                label         =>'SM',
                dataobjattr   =>'SM'),

      new kernel::Field::Email(
                name          =>'cmi',
                label         =>'CMI',
                dataobjattr   =>'CMI'),

      new kernel::Field::Email(
                name          =>'cmo',
                label         =>'CMO',
                dataobjattr   =>'CMO'),

      new kernel::Field::SubList(
                name          =>'custcontracts',
                label         =>'Contracts',
                group         =>'contracts',
                vjointo       =>'tbestsupport::sdbcontract',
                vjoinon       =>['id'=>'sdbapplid'],
                vjoindisp     =>['contractnumber','contractstate'])

   );
   #$self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(name prio state));
   $self->setWorktable("SDB_DARWIN");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tbestsupport"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","contracts");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}
         



1;
