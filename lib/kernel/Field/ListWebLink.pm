package kernel::Field::ListWebLink;
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
   my %self=@_;
   $self{readonly}=1 if (!exists($self{readonly}));
   my $self=bless($type->SUPER::new(%self),$type);
   $self->{webparams}=[qw(weblink webtarget webtitle webjs)];
   foreach my $v (@{$self->{webparams}}){
      $self->{_permitted}->{$v}=1;
   }
   $self->{searchable}=0;
   $self->{htmldetail}=0;
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();
   my $C=$self->getParent->Cache();
   my $d=$self->RawValue($current);
   my $lang=$self->getParent->Lang();
   my $site=$ENV{SCRIPT_URI};
   my $idname=$self->getParent->IdField->Name();
   my $id=$current->{$idname};

   my %web=();
   foreach my $v (@{$self->{webparams}}){
      $web{$v}=$self->{$v};
      if (ref($web{$v}) eq "CODE"){
         $web{$v}=&{$web{$v}}($self,$current);
      }
   }
   $web{webtarget}="work" if (!defined($web{webtarget}));
   my $linkstart="";
   my $linkend="";
   if (defined($web{weblink})){
      $linkstart="<a href=\"$web{weblink}\" ".
            "target=\"$web{webtarget}\" title=\"$web{webtitle}\">";
      $linkstart.="<img src=\"../../../public/base/load/listweblink.gif\"".
                  " border=0>";
      $linkend="</a>";
   }

   if ($mode=~m/^Html.*$/){
      $d=<<EOF;
<div style=\"text-align:center\">${linkstart}${linkend}</div><script language="JavaScript">$web{webjs}</script>
EOF
   }
   else{
      $d="-only visible in HTML-";
   }
   return($d);
}








1;
