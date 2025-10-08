package kernel::date;
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
use vars qw(@EXPORT @ISA);
use Date::Calc;
use DateTime;
use DateTime::Span;
use DateTime::SpanSet;
use POSIX;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&Today_and_Now &Mktime &Localtime &Date_to_Time &Date_to_String &Time_to_Date &Delta_DHMS &Add_Delta_YM &Add_Delta_YMD &Add_Delta_YMDHMS &Days_in_Month &Day_of_Week &Week_of_Year &Monday_of_Week &Day_of_Week_to_Text &Month_to_Text &Decode_Language &Language);


sub BEGIN
{
   if (defined($ENV{MOD_PERL})){
      eval('use Env::C;');
      eval('Env::C::setenv("TZ","GMT",1);');
   }
   POSIX::tzset();   
}


sub _tzset
{
   my $newtz=shift;
   my $oldtz=$ENV{TZ};
   $ENV{TZ}=$newtz;                   # compatible for none Env::C Enviroments
   if (defined($ENV{MOD_PERL})){
      eval('Env::C::setenv("TZ",$newtz,1);');  # needed for mod_perl2
      if ($@){
         die("ERROR: perl module Env::C not installed - ".
             "this causes maybee problems!");
      }
   }
   POSIX::tzset();   
   return($oldtz);
}



sub Localtime($@)
{
   my $tz=shift;
   my $oldtz=_tzset($tz);
   my ($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst);
   if ((POSIX::mktime(0,0,0,1, 0, 2050-1900))>0){
      ($sec,$min,$hour,$day,$month,$year,$doy, $dow, $dst)=POSIX::localtime(@_);
      $month+=1;
      $year+=1900
   }
   else{
      ($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst)=
         Date::Calc::Localtime(@_);
   }
   _tzset($oldtz);
   if (wantarray()){
      return($year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst);
   }
   return(sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                  $year, $month, $day, $hour, $min, $sec));
}

sub Mktime($@)
{
   my $tz=shift;
   my $oldtz=_tzset($tz);

   my $bk;
   if (($bk=POSIX::mktime(0,0,0,1, 0, 2050-1900))>0){
      my ($year,$month,$day, $hour,$min,$sec)=@_;
      $month-=1;
      $year-=1900;
      eval('$bk=POSIX::mktime($sec,$min,$hour,$day,$month,$year);');
   }
   else{
      eval('$bk=Date::Calc::Mktime(@_);');
   }
   _tzset($oldtz);
   return($bk);
}


sub Today_and_Now($)
{
   my $tz=shift;
   my $oldtz=_tzset($tz);

   my @bk;
   eval('@bk=Date::Calc::Today_and_Now(@_);');
   _tzset($oldtz);
   return(@bk);
}

sub Date_to_Time($@)
{
   my $tz=shift;
   my $oldtz=_tzset($tz);
   if ($#_==0){
      @_=$_[0]=~m/^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/;
   }
   my $bk;
   eval('$bk=Date::Calc::Mktime(@_);');
   _tzset($oldtz);
   return($bk);
}

sub Date_to_String
{
   my $lang=shift;
   my ($Y,$M,$D,$h,$m,$s,$timezone)=@_;

   my $d="???";
   if ($lang eq "de"){
      $d=sprintf("%02d.%02d.%04d %02d:%02d:%02d",$D,$M,$Y,$h,$m,$s);
   }
   elsif ($lang eq "DateTime"){
      $timezone="GMT" if ($timezone eq "");
      $d=new DateTime(year=>$Y,month=>$M,day=>$D,hour=>$h,minute=>$m,
                      second=>$s,time_zone=>$timezone);
   }
   elsif ($lang eq "unixtime"){
      eval('$d=Mktime($timezone,$Y,$M,$D,$h,$m,$s);');
   }
   elsif ($lang eq "ISO8601"){ # eigentlich muss da noch "+00:00" ran?!
      $d=sprintf("%04d-%02d-%02dT%02d:%02d:%02d",$Y,$M,$D,$h,$m,$s);
   }
   elsif ($lang eq "RFC822"){ 
      my $uxt;
      eval('$uxt=Mktime($timezone,$Y,$M,$D,$h,$m,$s);');
      my $oldtz=_tzset($timezone);
      $d=POSIX::strftime("%a, %d %b %Y %H:%M:%S %z",localtime($uxt));
      _tzset($oldtz);
   }
   elsif ($lang eq "SOAP" || $lang eq "ISO"){
      $d=sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",$Y,$M,$D,$h,$m,$s);
   }
   elsif ($lang eq "EDM"){
      $d=sprintf("%04d-%02d-%02dT%02d:%02d:%02d",$Y,$M,$D,$h,$m,$s);
   }
   elsif ($lang eq "ICS"){
      $d=sprintf("%04d%02d%02dT%02d%02d%02dZ",$Y,$M,$D,$h,$m,$s);
   }
   elsif($lang eq "ultrashort"){
      my ($nY,$nM,$nD,$nh,$nm,$ns)=Today_and_Now($timezone);
      if ($Y==$nY && $M==$nM && $D==$nD){
         $d=sprintf("%02d:%02d",$h,$m);
      }
      else{
         $Y-=2000 if ($Y>=2000);
         $d=sprintf("%02d.%02d.%02d",$D,$M,$Y);
      }
   }
   elsif($lang eq "deday"){
      my ($nY,$nM,$nD,$nh,$nm,$ns)=Today_and_Now($timezone);
      $Y-=2000 if ($Y>=2000);
      $d=sprintf("%02d.%02d.%02d",$D,$M,$Y);
   }
   elsif($lang eq "enday"){
      my ($nY,$nM,$nD,$nh,$nm,$ns)=Today_and_Now($timezone);
      $d=sprintf("%04d-%02d-%02d",$Y,$M,$D);
   }
   elsif(defined($lang) && $lang ne "stamp"){
      $d=sprintf("%04d-%02d-%02d %02d:%02d:%02d",$Y,$M,$D,$h,$m,$s);
   }
   else{
      $d=sprintf("%04d%02d%02d%02d%02d%02d",$Y,$M,$D,$h,$m,$s);
   }

   return($d);
}

sub Time_to_Date($@)
{
   my $tz=shift;
   my $oldtz=_tzset($tz);

   my @bk;
   eval('@bk=Date::Calc::Localtime(@_);');
   splice(@bk,6); 
   _tzset($oldtz);
   return(@bk);
}

sub Delta_DHMS
{
   my $tz=shift;
   my $oldtz=_tzset($tz);

   my @bk;
   eval('@bk=Date::Calc::Delta_DHMS(@_);');
   _tzset($oldtz);
   return(@bk);
}

sub Add_Delta_YM
{
   my $tz=shift;
   my $oldtz=_tzset($tz);

   my @bk;
   eval('@bk=Date::Calc::Add_Delta_YM(@_);');
   _tzset($oldtz);
   return(@bk);
}

sub Add_Delta_YMD
{
   my $tz=shift;
   my $oldtz=_tzset($tz);

   my @bk;
   eval('@bk=Date::Calc::Add_Delta_YMD(@_);');
   _tzset($oldtz);
   return(@bk);
}

sub Add_Delta_YMDHMS
{
   my $tz=shift;
   my $oldtz=_tzset($tz);

   my @bk;
   eval('@bk=Date::Calc::Add_Delta_YMDHMS(@_);');
   _tzset($oldtz);
   return(@bk);
}

sub Days_in_Month
{
   return(Date::Calc::Days_in_Month(@_));
}

sub Week_of_Year
{
   return(Date::Calc::Week_of_Year(@_));
}

sub Monday_of_Week
{
   return(Date::Calc::Monday_of_Week(@_));
}

sub Day_of_Week_to_Text
{
   return(Date::Calc::Day_of_Week_to_Text(@_));
}

sub Day_of_Week
{
   return(Date::Calc::Day_of_Week(@_));
}

sub Month_to_Text
{
   return(Date::Calc::Month_to_Text(@_));
}

sub Language
{
   return(Date::Calc::Language(@_));
}

sub Decode_Language
{
   return(Date::Calc::Decode_Language(@_));
}








1;
