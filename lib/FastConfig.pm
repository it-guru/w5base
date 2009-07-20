package FastConfig;
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

use strict;
use vars(qw(@ISA));

sub new
{
   my $type=shift;
   my %param=@_;
   my $self={};
   $self->{currrentconfig}={};
   $self->{configname}=undef;
   bless($self,$type);
}

sub getCurrentConfigName
{
   my $self=shift;

   return($self->{configname});
}


sub readconfig
{
   my $self=shift;
   my $instdir=shift;
   my $configfile=shift;
   my $basemod=shift;
   my $sub=shift;

   if (!$sub){
      $self->{configname}=$configfile;
   }
   $configfile.=".conf" if (!($configfile=~m/\.conf$/));
   if (!$sub){
      my $config=$self->{configname};
      if ($config=~m/\//){
         $config=~s/\.[^\.]*$//;
         $config=~s/^.*\///;
      }
      $self->{currrentconfig}={CONFIG=>$config,INSTDIR=>$instdir};
      if ( -f "$instdir/etc/w5base/$basemod/default.conf"){
         $self->LoadIntoCurrentConfig($self->{currrentconfig},
                      "$instdir/etc/w5base/$basemod/default.conf");
      }
      if ( -f "$instdir/etc/w5base/default.conf"){
         $self->LoadIntoCurrentConfig($self->{currrentconfig},
                      "$instdir/etc/w5base/default.conf");
      }
   }

   my $back=$self->LoadIntoCurrentConfig($self->{currrentconfig},$configfile);
   if ($back){
      if ( -f "/etc/w5base/$self->{currrentconfig}->{CONFIG}/$basemod.conf"){
         $self->LoadIntoCurrentConfig($self->{currrentconfig},
                "/etc/w5base/$self->{currrentconfig}->{CONFIG}/$basemod.conf");

      }
      if ( -f "/etc/w5base/$self->{currrentconfig}->{CONFIG}/global.conf"){
         $self->LoadIntoCurrentConfig($self->{currrentconfig},
                "/etc/w5base/$self->{currrentconfig}->{CONFIG}/global.conf");

      }
      delete($self->{conffile});
   }
   return($back);
}

sub debug
{
   my $self=shift;

   return(1) if (-f "/etc/w5base/DEBUG");
   return(0);
}

sub LoadIntoCurrentConfig
{
   my $self=shift;
   my $currentconfig=shift;
   my $configfile=shift;
   my $back=1;
   local (*F);


   if ($configfile ne ""){
      if ($configfile=~m/^\// || $configfile=~m/^\.+\// ){
         $self->{conffile}=$configfile;
      }
      else{
         if ( -f "/etc/w5base/".$configfile ){
            $self->{conffile}="/etc/w5base/".$configfile;
         }
         else{
            $self->{conffile}="../../etc/w5base/".$configfile;
         }
      }
   }
   if (open(F,$self->{conffile})){
      while(<F>){
         chomp;
         my ($myvar,$mykey,$myval)=();
         if ( ! /^\s*\#.*$/ ){
            if (my ($incl)=/^INCLUDE\s+(.*)$/){
               my $bk;
               $bk=$self->LoadIntoCurrentConfig($currentconfig,$incl);
               if (!$bk){
                  printf STDERR ("ERROR: can't read Include ".
                                 "'$incl' in '$configfile'\n");
                  return($bk);
               }
            }
            if (defined($_)){
               if (($myvar,$mykey,$myval)=
                    m/^(.+?)\[([0-9]+?)\]\s*=\s*[\",'](.*)[\",'].*$/){
                  $myvar=~tr/[a-z]/[A-Z]/;
                  if (!defined($currentconfig->{$myvar})){
                     $currentconfig->{$myvar}=[];
                  }
                  ${$currentconfig->{$myvar}}[$mykey]="$myval";
               }
               elsif (($myvar,$mykey,$myval)=
                       m/^(.+?)\[(.+?)\]\s*=\s*[\",'](.*)[\",'].*$/){
                  $myvar=~tr/[a-z]/[A-Z]/;
                  if (!defined($currentconfig->{$myvar})){
                     $currentconfig->{$myvar}={};
                  }
                  $currentconfig->{$myvar}->{$mykey}="$myval";
               }
               elsif (($myvar,$myval)=m/^(.+?)\s*=\s*[\",'](.*)[\",'].*$/){
                  $myvar=~tr/[a-z]/[A-Z]/;
                  $currentconfig->{$myvar}="$myval";
               }
            }
         }
         #printf STDERR ("READ $myvar from $configfile\n");
      }
      close(F);
   }
   else{
      $back=0;    
   }
   return($back);
}



=item w5lib::config::var()
 
Access method to get the value of a variable
from the configuration set.

=cut

sub Param($)
{
   
   my $self=shift;
   my $name=shift;
   my $varset;
   $name=uc($name);

   if (exists($self->{currrentconfig}->{$name})){
      $varset=$self->{currrentconfig};
   }

   if (wantarray() && 
       (ref($varset->{$name}) eq "ARRAY" || ref($varset->{$name}) eq "HASH") ){
      return(@{$varset->{$name}});
   }
   else{
      return($self->ExpandConfigVariables($varset->{$name}));
   }
}


sub VarList
{
   my $self=shift;
   my %list=();

   $list{$_}=1 for (keys(%{$self->{currrentconfig}}));

   return(keys(%list));
}

sub ExpandConfigVariables
{
   my $self=shift;
   my $mask=shift;


   if (defined($mask)){
      while(my ($variname)=$mask=~m/\$([a-z,A-Z,_,\.]+)/m){

         my $varival=$self->var($variname);
         $mask=~s/\$$variname/$varival/m;
      }
   }
   return($mask);

}





1;
