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
      $param{vjoineditbase}={'cistatusid'=>[3,4,5]};
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
   my @ml=($self->getParent->T("Contact Detail")=>$onclick);
   my $rec=$self->getLastVjoinRec();
   if (!defined($rec)){
      my $parent=$self->getParent()->Self();
      if ($parent eq "base::user"){
         if (ref($param{current}) eq "HASH"){
            $rec=[$param{current}];
         }
      }
   }
   if (defined($rec) && ref($rec) eq "ARRAY"){
      my $email=$rec->[0]->{email};
      if ($email ne ""){
         push(@ml,$self->getParent->T("send a mail"),
                  "window.location.href = 'mailto:$email';");
         my $subject;
         if (defined($param{current}->{fullname})){
            $subject=$param{current}->{fullname};
         }
         if ($subject eq "" && defined($param{current}->{name})){
            $subject=$param{current}->{name};
         }
         my $id;
         my $idobj=$self->getParent->IdField();
         if (defined($idobj)){
            $id=$idobj->RawValue($param{current});
         }
         my $qs=kernel::cgi::Hash2QueryString(to=>$email,
                                  id=>$id,
                                  subject=>$subject,
                                  parent=>$self->getParent->Self());
         my $onclick="openwin('../../base/workflow/externalMailHandler?$qs',".
                     "'_blank',".
                     "'height=$detaily,width=$detailx,toolbar=no,status=no,".
                     "resizable=yes,scrollbars=no')";

         push(@ml,$self->getParent->T("W5Base Mail"),$onclick);
      }
      my $office_phone=$rec->[0]->{office_phone};
      my $UserCache=$self->getParent-> 
                    Cache->{User}->{Cache}->{$ENV{REMOTE_USER}};
      if (ref($UserCache) eq "HASH" && $UserCache->{rec}->{dialermode} ne ""){
         if ($office_phone ne ""){
            my $jsdialcall=FormatJsDialCall($UserCache->{rec}->{dialermode},
                                            $UserCache->{rec}->{dialeripref},
                                            $UserCache->{rec}->{dialerurl},
                                            $office_phone);
            if (defined($jsdialcall)){
               push(@ml,$office_phone,$jsdialcall);
            }
         }
         my $office_mobile=$rec->[0]->{office_mobile};
         if ($office_mobile ne ""){
            my $jsdialcall=FormatJsDialCall($UserCache->{rec}->{dialermode},
                                            $UserCache->{rec}->{dialeripref},
                                            $UserCache->{rec}->{dialerurl},
                                            $office_mobile);
            if (defined($jsdialcall)){
               push(@ml,$office_mobile,$jsdialcall);
            }
         }
      }
   }
   return(@ml);
}





1;
