package itil::ext::infoabo;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub getControlData
{
   my $self=shift;
   my $app=$self->getParent();

   return({
           'crm::businessprocess'=>{target=>'selector',
                                 mode  =>[
                                 ],
                                },
           'itil::appl'    =>   {target=>'name',
                                 mode  =>[
                                     'genborderchange'=>'itil::appl',
                                     'changenotify'=>'itil::appl',
                                     'daily_modified_appldiary'=>'itil::appl',
                                     'daily_modified_appldevreq'=>'itil::appl',
                                     'daily_modified_applbuisreq'=>'itil::appl'
                                 ],
                                },
           'base::grp'=>        {target=>'fullname',
                                 mode  =>[
                                 ],
                                },
           'base::location'=>   {target=>'name',
                                 mode  =>[],
                                },
           'crm::businessprocess'=>{target=>'selector',
                                 mode  =>['genborderchange'=>'itil::appl'],
                                },
           'itil::network'=>    {target=>'name',
                                 mode  =>[],
                                },
           'itil::businessservice'=>{target=>'fullname',
              mode  =>[
                 'genborderchange'=>'itil::businessservice',
              ]}
          });

}

sub dailywfreportCompare
{
   my $self=shift;
   my $irec=shift;
   my $wfrec=shift;

   if ($irec->{parentobj}=~m/::appl$/ &&
       $irec->{mode} eq "daily_modified_appldiary"){
      if (ref($wfrec->{affectedapplicationid}) eq "ARRAY"){
         if ($wfrec->{class}=~m/^.*::diary$/ &&
             grep(/^$irec->{refid}$/,@{$wfrec->{affectedapplicationid}})){
            return(1);
         }
      }
   }
   if ($irec->{parentobj}=~m/::appl$/ &&
       $irec->{mode} eq "daily_modified_appldevreq"){
      if (ref($wfrec->{affectedapplicationid}) eq "ARRAY"){
         if ($wfrec->{class}=~m/^.*::devrequest$/ &&
             grep(/^$irec->{refid}$/,@{$wfrec->{affectedapplicationid}})){
            return(1);
         }
      }
   }
   if ($irec->{parentobj}=~m/::appl$/ &&
       $irec->{mode} eq "daily_modified_applbuisreq"){
      if (ref($wfrec->{affectedapplicationid}) eq "ARRAY"){
         if ($wfrec->{class}=~m/^.*::businesreq$/ &&
             grep(/^$irec->{refid}$/,@{$wfrec->{affectedapplicationid}})){
            return(1);
         }
      }
   }

   return(0);
}






1;
