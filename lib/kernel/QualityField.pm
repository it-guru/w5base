package kernel::QualityField;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use kernel;

sub loadQualityCheckResult
{
   my $self=shift;
   my $parent=shift;
   my $current=shift;
   my $name=$self->Name();
   my $context=$parent->Context();
   my $idobj=$parent->IdField();
   my $idname=$idobj->Name();

   return(undef) if (!exists($current->{$idname}));
   my $id=$current->{$idname};
   if (!defined($context->{QualityResult}->{$id})){
      my $obj=getModuleObject($parent->Config,$parent->Self);
      $obj->SetFilter({$idname=>\$id});
      my ($chkrec,$msg)=$obj->getOnlyFirst(qw(ALL));
      my $result={};
      if (defined($chkrec)){
         my $qc=getModuleObject($parent->Config,"base::qrule");
         $qc->setParent($parent);
         my $compat=$parent->getQualityCheckCompat($chkrec);
         my %checksession=(checkstart=>time(),checkmode=>'field');
         if ($obj->getField("allowifupdate") && $chkrec->{allowifupdate}==1){
            $checksession{autocorrect}=1;
         }
         $result=$qc->nativQualityCheck($compat,$chkrec,\%checksession);
      }
      $context->{QualityResult}->{$id}=$result;
   }
   return($context->{QualityResult}->{$id});
}

1;
