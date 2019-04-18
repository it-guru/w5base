package kernel::Field::Vector;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{uivisible}=0 if (!defined($self->{uivisible}));
   $self=bless($type->SUPER::new(%$self),$type);
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $name=$self->Name();
   if (exists($newrec->{$name})){
      my $koorstr="0 0,0 0";
      if (ref($newrec->{$name}) eq "ARRAY"){
         my @p=@{$newrec->{$name}};
         for(my $c=0;$c<=3;$c++){
            $p[$c]="0" if (!defined($p[$c]));
         }
         $koorstr=sprintf("%s %s,%s %s",@p);
      }
      else{
         if (my ($x1,$y1,$x2,$y2)=$newrec->{$name}=~
            m/^LINESTRING\(\s*(\d+)\s+(\d+)\s*,\s*(\d+)\s+(\d+)\)$/i){
            $koorstr=sprintf("%s %s,%s %s",$x1,$y1,$x2,$y2);
         }
      }
      return({$name=>\"GeomFromText(\"LINESTRING($koorstr)\")"});
   }
   return({});
}

sub getBackendName
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;
   my $ordername=shift;

   return(undef) if (!defined($self->{dataobjattr}));
   return(undef) if (ref($self->{dataobjattr}) eq "ARRAY");
   if ($mode eq "select"){
      return("AsText($self->{dataobjattr})");
   }
#   if ($mode eq "order"){
#      $_=$db->DriverName();
#      case: {
#         /^oracle$/i and do {
#            return("to_char($self->{dataobjattr},'YYYY-MM-DD HH24:MI:SS')");
#         };
#      }
#   }
   return($self->SUPER::getBackendName($mode,$db,$ordername));
}



sub RawValue
{
   my $self=shift;
   my $d=$self->SUPER::RawValue(@_);
   if (defined($d)){;
      if (my ($x1,$y1,$x2,$y2)=$d=~m/^LINESTRING\(\s*(\d+)\s+(\d+)\s*,\s*(\d+)\s+(\d+)\)$/i){
         return([$x1,$y1,$x2,$y2]);
      }
   }
   return($d);
}




1;
