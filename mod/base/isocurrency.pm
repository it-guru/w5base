package base::isocurrency;
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

# 
#  based on ISO 3166 country codes  + SSG-FI extensions (II,EU und EUROPE)
# 

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'isocurrency.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                label         =>'full currency name',
                dataobjattr   =>'isocurrency.fullname'),

      new kernel::Field::Text(
                name          =>'token',
                label         =>'ISO-Token',
                dataobjattr   =>'isocurrency.token'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Currencyname',
                dataobjattr   =>'isocurrency.name'),

      new kernel::Field::Text(
                name          =>'subunit',
                label         =>'Subunit',
                dataobjattr   =>'isocurrency.subunit'),

      new kernel::Field::Number(
                name          =>'numericcode',
                label         =>'numeric code',
                dataobjattr   =>'isocurrency.numerictoken'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'isocurrency.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'isocurrency.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'isocurrency.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'isocurrency.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'isocurrency.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'isocurrency.realeditor'),

   );
   $self->setDefaultView(qw(linenumber token fullname cistatus cdate mdate));
   $self->setWorktable("isocurrency");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $name=trim(effVal($oldrec,$newrec,"name"));
   my $token=trim(effVal($oldrec,$newrec,"token"));
   if (length($token)!=3 || ($token=~m/\s/)){
      $self->LastMsg(ERROR,"invalid token");
      return(0);
   }
   if ($name eq "" || ($name=~m/[^-a-z0-9\._ \(\)]/i)){
      $self->LastMsg(ERROR,"invalid country name");
      return(0);
   }

   if (exists($newrec->{token}) ||
       exists($newrec->{name})  ){
      $newrec->{token}=uc($newrec->{token});
      my $fname=uc($token);
      $fname.=($fname ne "" && $name ne "" ? "-" : "").$name;
      $newrec->{'fullname'}=$fname;
      $newrec->{'fullname'}=~s/[\(\)]/ /g;
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}





1;
