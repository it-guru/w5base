package tsacinv::lib::tools;
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

sub addAltBCSetFilter
{
   my $self=shift;
   my @flt=@_;

   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");

   my $MandatorCache=$self->Cache->{Mandator}->{Cache};
   my %altbc=();
   foreach my $grpid (@mandators){
      if (defined($MandatorCache->{grpid}->{$grpid})){
         my $mc=$MandatorCache->{grpid}->{$grpid};
         if (defined($mc->{additional}) &&
             ref($mc->{additional}->{acaltbc}) eq "ARRAY"){
            map({if ($_ ne ""){$altbc{$_}=1;}} @{$mc->{additional}->{acaltbc}});
         }
      }
   }
   my @altbc=keys(%altbc);

   if (!$self->IsMemberOf("admin")){
      my @wild;
      my @fix;
      if ($#altbc!=-1){
         @wild=("\"\"");
         @fix=(undef);
         foreach my $altbc (@altbc){
            if ($altbc=~m/\*/ || $altbc=~m/"/){
               push(@wild,$altbc);
            }
            else{
               push(@fix,$altbc);
            }
         }
      }
      if ($#wild==-1 && $#fix==-1){
         @fix=("NONE");
      }
      my @addflt=();
      if ($#fix!=-1){
         push(@addflt,{altbc=>\@fix});
      }
      if ($#wild!=-1){
         foreach my $wild (@wild){
            push(@addflt,{altbc=>$wild});
         }
      }
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}



1;
