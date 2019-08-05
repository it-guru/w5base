package kernel::Field::Import;
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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $parent=shift;
   my %param=@_;
   if (!exists($param{manglednames})){
      $param{manglednames}=1;
   }
   if (!defined($param{vjointo})){
      msg(ERROR,"can't Import field without vjointo");
      return()
   }
  # if (!defined($param{vjoinon})){
  #    msg(ERROR,"can't Import field without vjoinon");
  #    return()
  # }
   my $vjointo=$param{vjointo};
   $vjointo=$$vjointo if (ref($vjointo) eq "SCALAR");

   if (!defined($param{prefix})){
      $param{prefix}=$vjointo;
      $param{prefix}=~s/::/_/g;
   }

   
   my $obj=getModuleObject($parent->Config,$vjointo);
   if (!defined($obj)){
      msg(ERROR,"can't create vjoinobj '$vjointo'");
      return()
   }
   my @res;
   my $pname=$parent->Self();
   foreach my $field (@{$param{fields}}){
      my $fo=$obj->getField($field);
      if (!defined($fo)){
         msg(ERROR,"can't Import '$field' from '$vjointo' in $pname");
         next;
      }
      my %fo=%{$fo};
      foreach my $fkey (qw(uploadable readonly)){
         if (defined($param{$fkey})){   
            $fo{$fkey}=$param{$fkey};
         }
      }
      delete($fo{vjoinbase});   # vjoinbase kann nicht importiert werden!
      if (defined($param{vjoinon})){   
         $fo{vjointo}=$param{vjointo};
         $fo{vjoinon}=$param{vjoinon};
      }
      if (defined($param{weblinkon})){
         $fo{weblinkto}=$param{weblinkto};
         $fo{weblinkon}=$param{weblinkon};
      }
      if (defined($param{async})){
         $fo{async}=$param{async};
      }
      if (defined($param{htmldetail})){
         $fo{htmldetail}=$param{htmldetail};
      }
      $fo{vjoinconcat}=$param{vjoinconcat} if (defined($param{vjoinconcat}));
      $fo{depend}=$param{depend}           if (defined($param{depend}));
      if (!defined($param{group})){
         $fo{group}=$param{prefix}.$fo{group} if (defined($fo{group}));
      }
      else{
         $fo{group}=$param{group};
      }
      if (!defined($fo{translation})){
         my ($package,$filename, $line, $subroutine)=caller(1);
         if ($subroutine=~m/^kernel/){
            ($package,$filename, $line, $subroutine)=caller(2);
         }
         $subroutine=~s/::[^:]*$//;
         msg(INFO,"caller=$package sub=$subroutine"); 
         $fo{translation}=$subroutine;
      }

      if (defined($param{vjoinon})){    # only if a real vjoin dataobjattr del
         $fo{vjoindisp}=$field;
         delete($fo{dataobjattr});
      }
      if ($param{'dontrename'}){
         $fo{name}=$field;
      }
      else{
         $fo{name}=$param{prefix}.$field;
      }
      my ($type)=$fo=~m/^(.*)=.*$/;
      my $newfield=bless(\%fo,$type);
      push(@res,$newfield);
   }
   return(@res);
}







1;
