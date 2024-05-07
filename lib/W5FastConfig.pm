package W5FastConfig;
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
use File::Temp qw(tempfile);
use vars(qw(@ISA));

sub new
{
   my $type=shift;
   my %param=@_;
   my $self={};
   if (ref($param{'preload'}) eq "ARRAY"){
      $self->{'preload'}=$param{'preload'};
   }
   if ($param{'sysconfdir'} ne ""){
      $self->{'sysconfdir'}=$param{'sysconfdir'};
   }
   $self->{currrentconfig}={};
   $self->{configname}=undef;
   $self->{reareadinterval}=undef;
   bless($self,$type);
}

sub setRereadInterval
{
   my $self=shift;
   my $t=shift;
   $self->{reareadinterval}=$t;
   return($t);
}

sub getRereadInterval
{
   my $self=shift;
   return($self->{reareadinterval});
}

sub setPreLoad
{
   my $self=shift;
   if (ref($_[0]) eq "ARRAY"){
      $self->{'preload'}=$_[0];
   }
   else{
      $self->{'preload'}=[@_];
   }
}

sub setPostLoad
{
   my $self=shift;
   if (ref($_[0]) eq "ARRAY"){
      $self->{'postload'}=$_[0];
   }
   else{
      $self->{'postload'}=[@_];
   }
}

sub getCurrentConfigName
{
   my $self=shift;

   return($self->{configname});
}


sub readconfig
{
   my $self=shift;
   my $configfile=shift;
   my $sub=shift;

   if (!$sub){
      $self->{configname}=$configfile;
   }
   if (!exists($self->{currrentconfig})){
      $self->{currrentconfig}={
         ConfigRereadCount=>0
      };
   }

   my $bk=$self->genericReadConfig($self->{currrentconfig});

   #
   # Check, if Config is complete - if not, do a second genericReadConfig
   #

   return($bk);
}




sub genericReadConfig
{
   my $self=shift;
   my $targetConfig=shift;
   my $configfile=$self->{configname};
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
      %{$targetConfig}=( 
         CONFIG=>$config,
         ConfigLastReadTime=>time()
      );
      if (ref($self->{preload}) eq "ARRAY"){
         foreach my $f (@{$self->{preload}}){
            if (ref($f) eq "CODE"){
               &{$f}($self,$targetConfig);
            }
            else{
               if ( -f $f ){
                  $self->LoadIntoCurrentConfig($targetConfig,$f);
               }
            }
         }
      }
   }

   my $back=$self->LoadIntoCurrentConfig($targetConfig,$configfile);
   if ($back){
      if ($self->{sysconfdir} ne ""){
         my $gconfdir=$self->{sysconfdir}."/".$targetConfig->{CONFIG};
         if ( -f "$gconfdir/global.conf"){
            $self->LoadIntoCurrentConfig($targetConfig,"$gconfdir/global.conf");
         }
      }
      foreach my $f (@{$self->{postload}}){
         if (ref($f) eq "CODE"){
            &{$f}($self,$targetConfig);
         }
         else{
            if ( -f $f ){
               $self->LoadIntoCurrentConfig($targetConfig,$f);
            }
         }
      }
      delete($self->{conffile});
   }
   return($back);
}

sub debug
{
   my $self=shift;

   if ($self->{sysconfdir} ne ""){
      return(1) if (-f "$self->{sysconfdir}/DEBUG");
   }
   return(0);
}

sub LoadIntoCurrentConfig
{
   my $self=shift;
   my $currentconfig=shift;
   my $configfile=shift;
   my $back=1;
   #local (*F);
   my $F;


   if ($configfile ne ""){
      if ($configfile=~m/^\// || $configfile=~m/^\.+\// ||
          $configfile=~m/^(http|https):\//){
         $self->{conffile}=$configfile;
      }
      else{
         if ($self->{sysconfdir} ne ""){
            if ( -f "$self->{sysconfdir}/".$configfile ){
               $self->{conffile}="$self->{sysconfdir}/".$configfile;
            }
            elsif( -f "../$self->{sysconfdir}/".$configfile){
               $self->{conffile}="../$self->{sysconfdir}/".$configfile;
            }
            else{
               $self->{conffile}="../../$self->{sysconfdir}/".$configfile;
            }
         }
      }
   }

   my $pfilename;
   if ($self->{conffile}=~m/^(http|https):\//){
      my $ua;
      $F = tempfile();
      eval('
         use JSON;
         use LWP::UserAgent;
         $ua=new LWP::UserAgent(env_proxy=>0,ssl_opts=>{verify_hostname=>1});
      ');
      if ($@ ne ""){
         printf STDERR ("ERROR: %s\n",$@);
         return(1);
      }
      if ($self->{conffile}=~m/^https:/){
         my $SSL_cert_file=$currentconfig->{SSL_CERT_FILE};
         my $SSL_key_file=$currentconfig->{SSL_KEY_FILE};
         my $SSL_passwd_cb=$currentconfig->{SSL_KEY_PASS};
         my %ssl_opts=();

         if (ref($SSL_cert_file) eq "HASH"){
            $SSL_cert_file=$SSL_cert_file->{w5config};
         }
         if (ref($SSL_key_file) eq "HASH"){
            $SSL_key_file=$SSL_key_file->{w5config};
         }
         if (ref($SSL_passwd_cb) eq "HASH"){
            $SSL_passwd_cb=$SSL_passwd_cb->{w5config};
         }
         if (defined($SSL_cert_file) && $SSL_cert_file ne ""){
            $ssl_opts{SSL_cert_file}=$SSL_cert_file;
         }
         if (defined($SSL_key_file) && $SSL_key_file ne ""){
            $ssl_opts{SSL_key_file}=$SSL_key_file;
         }
         if (defined($SSL_passwd_cb) && $SSL_passwd_cb ne ""){
            $ssl_opts{SSL_passwd_cb}=sub{return($SSL_passwd_cb);};
         }
         if (keys(%ssl_opts)){
            #$ssl_opts{SSL_verify_mode}=0;
            $ua->ssl_opts(%ssl_opts);
         }
      }

      my $res=$ua->get($self->{conffile});
      if (defined($res) && $res->is_success()){
         print $F $res->decoded_content();
      }
      else{
         my $msg="WARN: can not fetch '".$self->{conffile}."'";
         if (defined($res)){
            $msg.=" - ".$res->status_line;
         }
         print STDERR  $msg."\n";
         return(1); # Maybe a process for mandatory includes needs to be
      }             # defined. At now a missing include only produces a WARN
      seek($F,0,0);
   }
   else{
      $pfilename="<".$self->{conffile};
      if (!open($F,$pfilename)){
         printf STDERR ("open $pfilename failed\n");
         return(0);
      }
   }
   while(my $line=<$F>){
      chomp;
      my ($myvar,$mykey,$myval)=();
      if ( ! ($line=~m/^\s*\#.*$/) ){
         if (my ($incl)=$line=~m/^\s*INCLUDE\s+(.*)$/){
            my $bk;
            $bk=$self->LoadIntoCurrentConfig($currentconfig,$incl);
            if (!$bk){
               printf STDERR ("ERROR: can't read Include ".
                              "'$incl' in '$configfile'\n");
               return($bk);
            }
         }
         if (defined($line)){
            # Syntax:
            #   SCALAR:
            #
            #   AbCdEf="xxxxxx"
            #   abcdef='xxxxxx'
            #   ABCDEF='xxxxxx'
            #
            #   ARRAY:
            #
            #   AbCdEf[0]="xxxxxx"
            #   abcdef[5]='xxxxxx'
            #   ABCDEF[23]='xxxxxx'
            #
            #   HASH:
            #
            #   AbCdEf[hello]="xxxxxx"
            #   abcdef[World]='xxxxxx'
            #   ABCDEF[ThisIsATest]='xxxxxx'
            #
            #   MultiLine:
            #   AbCdEf="
            #   BalBla1
            #   BalBla2
            #   BalBla3
            #   "
            if (my ($varstr,$datastr)=$line=~m/^\s*([^=]+)\s*=\s*(.*)\s*$/){

               my $datatarget=undef;
               if (($myvar,$mykey)=$varstr=~m/^(.+?)\[([0-9]+?)\]\s*$/){
                  $myvar=~tr/[a-z]/[A-Z]/;
                  if (!defined($currentconfig->{$myvar})){
                     $currentconfig->{$myvar}=[];
                  }
                  if (ref(${$currentconfig->{$myvar}}) eq "ARRAY"){
                     $datatarget=\$currentconfig->{$myvar}->[$mykey];
                  }
               }
               elsif (($myvar,$mykey)=$varstr=~m/^(.+?)\[(.+?)\]\s*$/){
                  $myvar=~tr/[a-z]/[A-Z]/;
                  if (!defined($currentconfig->{$myvar})){
                     $currentconfig->{$myvar}={};
                  }
                  if (ref($currentconfig->{$myvar}) eq "HASH"){
                     $datatarget=\$currentconfig->{$myvar}->{$mykey};
                  }
               }
               elsif (($myvar,$myval)=$line=~
                       m/^(.+?)\s*=\s*[\",'](.*)[\",'].*$/){
                  $myvar=~tr/[a-z]/[A-Z]/;
                  $datatarget=\$currentconfig->{$myvar};
               }
               if (defined($datatarget)){
                  my $quote;
                  if ($datastr=~m/^"/){
                     $quote='"';
                     $datastr=~s/^"(.*)"$/$1/;
                  }
                  elsif ($datastr=~m/^'/){
                     $quote="'";
                     $datastr=~s/^'(.*)'$/$1/;
                  }
                  if ($datastr=~m/^\s*$quote\s*$/s){  # MulitLine handling
                     $datastr="";
                     while(my $line=<$F>){
                        if ($line=~m/^\s*$quote\s*$/s){
                           last;
                        }
                        $datastr.=$line;
                     }
                     $$datatarget=$datastr;
                  }
                  else{
                     $datastr=~s/^"(.*)"\s*(#.*)?$/$1/;
                     $datastr=~s/^'(.*)'\s*(#.*)?$/$1/;
                     $$datatarget=$datastr;
                  }
               }



            }
         }
      }
      #printf STDERR ("READ $myvar from $configfile\n");
   }
   close($F);
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

   if (defined($self->{reareadinterval})){
      if (exists($self->{currrentconfig}->{ConfigLastReadTime}) &&
          $self->{currrentconfig}->{ConfigLastReadTime}+
           $self->{reareadinterval}<time()){
         my %tempConfig=(
            ConfigRereadCount=>$self->{currrentconfig}->{ConfigRereadCount}+1
         );
         my $bk=$self->genericReadConfig(\%tempConfig);
         if ($bk){ # reread seems to be OK
            $self->{currrentconfig}=\%tempConfig;
         }
         $self->{currrentconfig}->{ConfigLastReadTime}=time();
      }
   }

   if (exists($self->{currrentconfig}->{$name})){
      $varset=$self->{currrentconfig};
   }

   if (wantarray()){
      if (ref($varset->{$name}) eq "ARRAY"){
         return(@{$varset->{$name}});
      }
      if (ref($varset->{$name}) eq "HASH"){
         return(%{$varset->{$name}});
      }
   }
   else{
      if (ref($varset->{$name}) eq "HASH"){
         return($varset->{$name});
      }
      if (ref($varset->{$name}) eq "ARRAY"){
         return($varset->{$name});
      }
      return($self->ExpandConfigVariables($varset->{$name}));
   }
}

sub setParam
{
   my $self=shift;
   my $name=shift;
   my $value=shift;
   $self->{currrentconfig}->{$name}=$value;
}


sub VarList
{
   my $self=shift;
   my %list=();

   $list{$_}=1 for (keys(%{$self->{currrentconfig}}));

   return(keys(%list));
}


sub Dumper
{
   my $self=shift;

   my $d="Dumper($self):\n";
   my @vl=$self->VarList();
   my $maxlen=5;
   foreach my $v (@vl){
      $maxlen=length($v) if ($maxlen<length($v));
   }
   foreach my $varname (sort(@vl)){
      my $val=$self->Param($varname);
      if (ref($val)){
         my @vvl=sort(keys(%$val));
         foreach my $vv (@vvl){
            $d.=sprintf("%-${maxlen}s %-12s = \"%s\"\n",
                        $varname,"[".$vv."]",$val->{$vv});
            
          
         }
      }
      else{
         $d.=sprintf("%-${maxlen}s = \"%s\"\n",$varname,$val);
      }
   }
   return($d);
}

sub ExpandConfigVariables
{
   my $self=shift;
   my $mask=shift;


   if (defined($mask)){
      while(my ($variname)=$mask=~m/\$([a-z,A-Z,_,\.]+)/m){

         my $varival=$self->Param($variname);
         $mask=~s/\$$variname/$varival/m;
      }
   }
   return($mask);

}





1;
