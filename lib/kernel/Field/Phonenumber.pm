package kernel::Field::Phonenumber;
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
@ISA    = qw(kernel::Field::Text);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{nowrap}=1;
   if (!exists($self->{onClick})){
      $self->{onClick}=sub{
         my $self=shift;
         my $output=shift;
         my $app=shift;
         my $rec=shift;

         my $d=$rec->{$self->{name}};

         my $UserCache=$app->Cache->{User}->{Cache}->{$ENV{REMOTE_USER}};
         my $jsdialcall;
         if (ref($UserCache) eq "HASH"){
            $jsdialcall=FormatJsDialCall($UserCache->{rec}->{dialermode},
                             $UserCache->{rec}->{dialeripref},
                             $UserCache->{rec}->{dialerurl},
                             $d);
         }
         return($jsdialcall);
      };
   }
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return({}) if (!exists($newrec->{$self->Name()}));
   my $newvalreq=$newrec->{$self->Name()};
   return({$self->Name()=>undef}) if ($newvalreq eq "");
   my $newvallist=$newvalreq;
   $newvallist=[$newvallist] if (ref($newvallist) ne "ARRAY");

   my $defPrefix="";
   my $intdialprefix="";
   my $country="US";
   my %prefixlist=();
   my $UserCache=$self->getParent->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      if (defined($UserCache->{country}) && $UserCache->{country} ne ""){
         $country=$UserCache->{country};
      }
   }
   if ($country ne ""){
      my $o=getModuleObject($self->getParent->Config,"base::isocountry");
      if (defined($o)){
         $o->SetFilter({token=>\$country});
         my ($crec,$msg)=$o->getOnlyFirst(qw(token dialprefix intdialprefix));
         if (defined($crec)){
            $defPrefix=$crec->{dialprefix};
            $intdialprefix=$crec->{intdialprefix};
         }
         $o->ResetFilter();
         $o->SetFilter({dialprefix=>'!""'});
         my @l=$o->getHashList(qw(dialprefix));
         foreach my $rec (@l){
            $prefixlist{$rec->{dialprefix}}++;
         }
      }
   }
   # msg(INFO,"validating using country-Base $country ".
   #          "with devprefix=$defPrefix");


   my $newvallist=[map({
         my $m=trim($_);
         if ($m ne ""){
            if (!($m=~m/^\s*[0-9\+\/)(-\s]*$/) ||
                 ($m=~m/\+.*\+/)){                # allow +xxx only once!
               $self->getParent->LastMsg(ERROR,
                            "invalid phonenumber format '%s'",$m);
               return(undef);
            }
            # normalice
            $m=~s/\s+/ /g;  #remove double spaces
            $m=~s/-+/-/g;   #remove double - signs

            # remove spaces and - in the first 4 signs (+ with 3 char int pref)
            if (my ($cleaned,$rest)=$m=~m/(^.{4})(.*$)/){
               $cleaned=~s/[- ]//g;
               $m=$cleaned.$rest;
            }

            if ($intdialprefix ne ""){
               $m=~s/^${intdialprefix}/+/x;
            }
            if ($m=~m/^0[^0]/){
               $m=~s/^0/${defPrefix}/x;
            }
            my $foundIntPrefix=0;
            foreach my $pref (keys(%prefixlist)){
               my $qpref=$pref;
               $qpref=~s/\+/\\+/g;
               if ($m=~m/^${qpref}\s*/x){
                  $m=~s/^${qpref}\s*/${pref} /x;
                  $foundIntPrefix++;
                  last;
               }
            }
            if (!$foundIntPrefix){
               $self->getParent->LastMsg(ERROR,
                            "unknown international phonenumber prefix '%s'",$m);
               return(undef);
            }

            my $mchk=$m;
            $mchk=~s/^\+//;
            $mchk=~s/[\s-]//g;
            #msg(INFO,"check number='$mchk'");
            if (($mchk=~m/^(.)(\1)*$/) || 
                ($mchk=~m/(.)(\1){6}/) ||
                ($mchk=~m/23456/) ||
                ($mchk=~m/56789/) ||
                length($mchk)<8){
               $self->getParent->LastMsg(ERROR,
                            "senseless phonenumber '%s'",$m);
               return(undef);
            }
            if (!($m=~m/^\+/)){
               $self->getParent->LastMsg(ERROR,
                            "no international phonenumber notation '%s'",$m);
               return(undef);
            }
         }
         $m=lc($m);
         $m=undef if ($m eq "");
         $_=$m;
      } @{$newvallist})];
   if (ref($newvalreq) eq "ARRAY"){
      return({$self->Name()=>$newvallist});
   }
   return({$self->Name()=>$newvallist->[0]});
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);

   if ($mode=~m/^HtmlDetail/){
      if ($d ne ""){
         my $dformfine="";
         my $dlist=$d;
         $dlist=[$d] if (ref($d) ne "ARRAY");
         foreach my $d (@$dlist){
            my $dform=$d;
            my $UserCache=$self->getParent-> 
                       Cache->{User}->{Cache}->{$ENV{REMOTE_USER}};
            if (ref($UserCache) eq "HASH"){
               my $jsdialcall=FormatJsDialCall($UserCache->{rec}->{dialermode},
                                   $UserCache->{rec}->{dialeripref},
                                   $UserCache->{rec}->{dialerurl},
                                   $d);
               if (defined($jsdialcall)){
                  my $t="click to dial with ".$UserCache->{rec}->{dialermode};
                  $dform="<span title=\"$t\" ".
                         "onclick=\"$jsdialcall\" class=sublink>".
                         $dform."</span>";
               }
            }
            $dformfine.="; " if ($dformfine ne "");
            $dformfine.=$dform;
         }
         return($dformfine);
      } 
      return($d);
   }
   else{
      return($self->SUPER::FormatedDetail($current,$mode));
   }
}







1;
