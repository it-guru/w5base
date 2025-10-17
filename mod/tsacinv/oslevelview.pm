package tsacinv::oslevelview;
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

# This tool is to allow public information access to asset center from
# the system commandline via wget f.e.:
# wget -q --header='Accept-Language: de' -O - \
# 'http://darwin.telekom.de/w5base2/public/tsacinv/'\
# 'oslevelview/Main?systemname='`uname -n`
# 
use strict;
use vars qw(@ISA);
use kernel;
use kernel::App::Web;
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main));
}

sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/plain");
   my $sys=$self->getPersistentModuleObject("tsacinv::system");
   my $group=$self->getPersistentModuleObject("tsacinv::group");

   my %flt;
   my $format='%-25s %s'."\n";

   my $name=Query->Param("systemname");
   if ($name ne "" && !($name=~m/[\*\?]/)){
      $flt{systemname}=\$name;
   }
   my $systemid=Query->Param("systemid");
   if ($systemid ne "" && !($systemid=~m/[\*\?]/)){
      $flt{systemid}=\$systemid;
   }
   if (keys(%flt)>=1){
      $sys->ResetFilter();
      $sys->SetFilter(\%flt);
      my @fields=qw(systemname systemid systemola conumber
                    assignmentgroup controlcenter
                    w5base_appl w5base_tsm w5base_sem
                    assetassetid assetserialno);
      my $found=0;
      foreach my $rec ($sys->getHashList(@fields)){
         $found++;
         foreach my $field (@fields){
            my $fo=$sys->getField($field,$rec);
            if (defined($fo)){
               my $label=$fo->Label();
               my $val=$fo->FormatedResult($rec,"AscV01");
               if ($val ne ""){
                  if ($field eq "controlcenter" ||
                      $field eq "assignmentgroup"){
                     $group->ResetFilter();
                     $group->SetFilter({name=>\$val});
                     my ($grec,$msg)=$group->getOnlyFirst(qw(phone));
                     if (defined($grec) && $grec->{phone} ne ""){
                        $val.=" (".$grec->{phone}.")";
                     }
                  } 
                  printf($format,$label.":",$val);
               }
            }
         }
      }
      if (!$found){
         printf($self->T("query not found")."\n");
      }
   }
}


1;
