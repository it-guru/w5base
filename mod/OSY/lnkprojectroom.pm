package OSY::lnkprojectroom;
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
use kernel::Field;
use base::lnkprojectroom;
@ISA=qw(base::lnkprojectroom);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);


   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'name'),
      insertafter=>'id'
   );

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'systemshortdesc',
                readonly      =>1,
                label         =>'Short description',
                vjointo       =>'itil::system',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'shortdesc'),

      new kernel::Field::DynWebIcon(
                name          =>'systemweblink',
                searchable    =>0,
                depend        =>['refid'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $sysido=$self->getParent->getField("refid");
                   my $sysid=$sysido->RawValue($current);

                   my $img="<img ";
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   $img.="title=\"\" border=0>";
                   my $dest="../../OSY/system/Detail?id=$sysid";
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      return("<a href=javascript:$onclick>$img</a>");
                   }
                   return("-");
                }),


   );



   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec)){
      $newrec->{parentobj}="itil::system";
   }
   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}



1;
