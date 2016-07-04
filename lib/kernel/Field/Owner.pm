package kernel::Field::Owner;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{vjointo}="base::user";
   $self->{vjoinon}=[$self->Name()=>'userid'];
   $self->{vjoindisp}="fullname";
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $name=$self->Name();
   my $userid;

   if (!defined($newrec->{$name}) || !($newrec->{$name}=~m/^\d+$/)){
      return({}) if ($W5V2::OperationContext eq "QualityCheck");
      return({}) if ($W5V2::OperationContext eq "Kernel");
      my $userid=$self->getDefaultValue();
      return({}) if (!defined($userid));
      return({$name=>$userid});
   }
   my $userid=$newrec->{$name};
   $userid=undef if ($userid eq "0");
   return({$name=>$userid});
}

sub getDefaultValue
{
   my $self=shift;
   my $userid;

   my $UserCache=$self->getParent->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{tz})){
      $userid=$UserCache->{userid};
   }
   return($userid);
}

sub Unformat
{
   my $self=shift;
   return({$self->Name()=>$self->getDefaultValue()});
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $fobj=$self;
   my $field=$self->Name();
   my $changed=0;
   my $err;

   if ($hflt->{$field} eq "*"){
      delete($hflt->{$field});
   }

   if (!ref($hflt->{$field}) && $hflt->{$field} ne ""){
      if (!($hflt->{$field}=~m/^\d+$/)){
         my $u=getModuleObject($self->getParent->Config,"base::user");
         $u->SetFilter({fullname=>$hflt->{$field}});
         $hflt->{$field}=[map({$_->{userid}} $u->getHashList(qw(userid)))];
         $changed++;
      }
   }

   return($changed,$err);
}




sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   my $app=$self->getParent();

   my $target="base::user";
   my $app=$self->getParent;
   if (!defined($self->{joinobj})){
      $self->{joinobj}=getModuleObject($app->Config,"base::user");
   }
   $target=~s/::/\//g;
   $target="../../$target/Detail";
   my $targetid=$d;
   return("NONE") if (!defined($targetid));
   if (defined($self->{joinobj})){
      my $c=$self->getParent->Context();
      $c->{"UserFullnameCache"}={} if (!defined($c->{"UserFullnameCache"}));
      my $targetval=$c->{"UserFullnameCache"}->{$targetid};
      if (!defined($targetval)){
         $self->{joinobj}->ResetFilter();
         $self->{joinobj}->SetFilter(
                   {$self->{joinobj}->IdField->Name()=>\$targetid});
         my ($rec)=$self->{joinobj}->getOnlyFirst(qw(fullname));
         if (ref($rec) eq "HASH"){
            my $fobj=$self->{joinobj}->getField("fullname",$rec);
            $targetval=$fobj->RawValue($rec);
         }
         if ($targetval ne ""){
            $c->{"UserFullnameCache"}->{$targetid}=$targetval;
         }
      }
      return("NONE") if ($targetval eq "");
      my $detailx=$app->DetailX();
      my $detaily=$app->DetailY();
      if ($mode eq "HtmlDetail"){
         my $UserCache=$self->getParent->Cache->{User}->{Cache};
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
         }
         my $winsize="normal";
         if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
            $winsize=$UserCache->{winsize};
         }
         my $winname="_blank";
         if (defined($UserCache->{winhandling}) &&
             $UserCache->{winhandling} eq "winonlyone"){
            $winname="W5BaseDataWindow";
         }
         if (defined($UserCache->{winhandling})
             && $UserCache->{winhandling} eq "winminimal"){
            $winname="W5B_base::user_".$targetval;
            $winname=~s/[^a-z0-9]/_/gi;
         }
         my $onclick="custopenwin('$target?AllowClose=1&userid=$targetid',".
                    "'$winsize',".
                     "$detailx,$detaily,'$winname')";
         $d="<a class=sublink href=JavaScript:$onclick>".$targetval."</a>";
      }
      else{
         $d=$targetval;
      }
   }
   if ($mode eq "SOAP"){
      $d=~s/&/&amp;/g;;
   }

   return($d);
}

sub Uploadable
{
   my $self=shift;

   return(0);
}





1;
