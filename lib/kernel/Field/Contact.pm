package kernel::Field::Contact;
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
@ISA    = qw(kernel::Field::TextDrop);


sub new
{
   my $type=shift;
   my %param=@_;
   if (ref($param{vjoinon}) ne "ARRAY"){
      $param{vjoinon}=[$param{vjoinon}=>'userid'];
   }
   $param{vjointo}='base::user'  if (!defined($param{vjointo}));
  # $param{vjoindisp}='fullname'  if (!defined($param{vjoindisp}));
   if (!defined($param{vjoindisp})){
      $param{vjoindisp}=['fullname','email','office_phone','office_mobile'];
   }
   if (!defined($param{vjoineditbase})){
      $param{vjoineditbase}={'cistatusid'=>[3,4]};
   }
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;

   my $d=$self->SUPER::FormatedDetail($current,$mode);
   return($d);
}

sub addWebLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;
   my %param=@_;

   $param{contextMenu}="contextMenu_".$self->Name;
   return($self->SUPER::addWebLinkToFacility($d,$current,%param));
}

sub contextMenu
{
   my $self=shift;
   my %param=@_;

   my $detailx=$self->getParent->DetailX();
   my $detaily=$self->getParent->DetailY();
   my $target="../../base/user/Detail";
   my $targetval=$param{current}->{$self->{vjoinon}->[0]};
   my $onclick="openwin('$target?".
               "AllowClose=1&search_userid=$targetval',".
               "'_blank',".
               "'height=$detaily,width=$detailx,toolbar=no,status=no,".
               "resizable=yes,scrollbars=no')";
   my $rec=$self->getLastVjoinRec();
   my @ml=($self->getParent->T("Contact Detail")=>$onclick);
   if (defined($rec) && ref($rec) eq "ARRAY"){
      my $email=$rec->[0]->{email};
      if ($email ne ""){
         push(@ml,$self->getParent->T("send a mail"),
                  "window.location.href = 'mailto:$email';");

#         push(@ml,$self->getParent->T("W5Base Mail"),
#                  "window.location.href = 'mailto:$email';");
      }
      my $office_phone=$rec->[0]->{office_phone};
      if ($office_phone ne ""){
         push(@ml,$office_phone,"alert('call $office_phone');");
      }
      my $office_mobile=$rec->[0]->{office_mobile};
      if ($office_mobile ne ""){
         push(@ml,$office_mobile,"alert('call $office_mobile');");
      }
   }
   return(@ml);
}





1;
