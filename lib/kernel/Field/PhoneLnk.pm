package kernel::Field::PhoneLnk;
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
use kernel::Field::SubList;
use Data::Dumper;
@ISA    = qw(kernel::Field::SubList);


sub new
{
   my $type=shift;
   my %self=@_;
   $self{vjointo}="base::phonenumber"   if (!defined($self{vjointo}));
   $self{vjoinon}=['id'=>'refid']      if (!defined($self{vjoinon}));
   $self{allowcleanup}=1               if (!defined($self{allowcleanup}));
   if (!defined($self{vjoindisp})){
      $self{vjoindisp}=['phonenumber','name','shortedcomments'];
   }

   my $self=bless($type->SUPER::new(%self),$type);
   return($self);
}

sub vjoinobjInit
{
   my $self=shift;
   my $p=$self->getParent()->Self();
   $self->{vjoinbase}=[{'parentobj'=>\$p}] if (!defined($self->{vjoinbase}));
   return($self->SUPER::vjoinobjInit());
}

sub FormatForHtmlPublicDetail
{
   my $self=shift;
   my $rec=shift;
   my $ntypes=shift;
   my $app=$self->getParent();

   my $k=$self->{name};
   my $d="";

   if (exists($rec->{$k}) && ref($rec->{$k}) eq "ARRAY"){
      foreach my $prec (@{$rec->{$k}}){
         if (grep(/^$prec->{name}$/,@$ntypes)){
            my $phonelabel=$prec->{shortedcomments};
            if ($phonelabel=~m/^\s*$/){
               $phonelabel=$app->T($prec->{name},
                              $app->Self,"base::phonelnk");
            }
            if (ref($app->{PhoneLnkUsage}) eq "CODE"){
               my %tr=&{$app->{PhoneLnkUsage}}($app);
               if (exists($tr{$phonelabel})){
                  $phonelabel=$tr{$phonelabel};
               }
            }
            $d.="<tr><td valign=top>$phonelabel</td>";
            $d.="<td valign=top>$prec->{phonenumber}</td></tr>";
         }
      }
   }
   if ($d ne ""){
      $d="<tr height=1><td height=1><img src=\"../../base/load/empty.gif\" ".
          "width=180 height=1></td><td height=1></td></tr>".$d;
   }
   return($d);
}










1;
