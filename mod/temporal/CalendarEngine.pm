package temporal::CalendarEngine;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use kernel::date;
use kernel::App::Web;
use CGI;
use JSON;
@ISA=qw(kernel::App::Web);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->LoadSubObjs("Calendar","Calendar");
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main EventList HolidayList));
}

sub EventList
{
   my $self=shift;

   print $self->HttpHeader("text/javascript",charset=>'UTF-8');
   my %e=(
      id     =>   '001',
      start  =>   '2016-01-01T00:00:00',
      end    =>   '2017-01-01T00:00:00',
      title  =>   'Sample Event',
   );
   my $l=[\%e];

   eval("use JSON;");
   if ($@ eq ""){
      my $json;
      eval('$json=to_json($l, {ascii => 1});');
      print STDERR $json;
      print $json;
   }
   else{
      printf STDERR ("ERROR: ganz schlecht: %s\n",$@);
   }
}


sub HolidayList
{
   my $self=shift;

   print $self->HttpHeader("text/javascript",charset=>'UTF-8');

   my $timezone=Query->Param("timezone");
   if ($timezone eq ""){
      $timezone=$self->getFrontendTimezone();
   }
   my $s=Query->Param("start");
   my $e=Query->Param("end");
   my $trange="";

   if ($e ne "" && $s ne ""){
      $trange="\"${s} 00:00:00/${e} 23:59:59\"";
   }
   my @l=();

   my $o=getModuleObject($self->Config,"temporal::tspan");
   $o->SecureSetFilter({
      trange=>$trange,
      subsys=>\'HOLIDAY'
   });
   foreach my $ev ($o->getHashList(qw(id tfrom tto name planid 
                                      color subsys
                                      mgmtitemgroupname mgmtitemgroupid))){
      my $start=$self->ExpandTimeExpression($ev->{tfrom},"en","GMT",$timezone);
      my $end=$self->ExpandTimeExpression($ev->{tto},"en","GMT",$timezone);
      my %e=(
         title=>$ev->{name},
         start=>$start,
         subsys=>$ev->{subsys},
         start_formated=>$start,
         holiday=>'1',
         color=>'#DFEEDE',
         textColor => '#000000',
         end=>$end,
         end_formated=>$end,
         id=>$ev->{id},
      );
      push(@l,\%e);
      print STDERR Dumper($ev);

   }
   eval("use JSON;");
   if ($@ eq ""){
      my $json;
      eval('$json=to_json(\@l, {ascii => 1});');
      print STDERR $json."\n";
      print $json;
   }
   else{
      printf STDERR ("ERROR: ganz schlecht: %s\n",$@);
   }
}


sub getExMenuWidth
{
   my $self=shift;

   return("150");

}

sub getFrontendTimezone
{
   my $self=shift;

   my $timezone=$self->UserTimezone();
   if (!defined($timezone)){
      $timezone="GMT";
   }
   return($timezone);
}

sub getDataDetailCode
{
   my $self=shift;
   my $d="function showDataDetail(e){alert('NOT IMPLEMENTED');}";
   return($d);
}


sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html",charset=>'UTF-8');

   my $getAppTitleBar=$self->getAppTitleBar();

   my $dataobj=Query->Param("dataobj");
   my $dataobjid=Query->Param("dataobjid");
   my $lang=$self->Lang();
   my $objlist="var objlist=";
   my @objlist;
   foreach my $sobj (values(%{$self->{Calendar}})){
      my $d;
      if ($sobj->can("getObjectInfo")){
         $d=$sobj->getObjectInfo($self,$lang);
      }
      if (defined($d)){
         push(@objlist,"{name:'$d->{name}',label:'$d->{label}',".
                       "prio:'$d->{prio}'}");
      }
   }
   $objlist=$objlist."[".join(",\n",@objlist)."];";
   my $fullname=$self->T("Fullname");
   my $name=$self->T("Name");
   my $objecttype=$self->T("ObjectType");


   my $ExMenuWidth=$self->getExMenuWidth();
   my $ExMenu="<div id=ExMenu style=\"width:${ExMenuWidth}px\"></div>";
   $ExMenu="" if ($ExMenuWidth eq "");

   my $timezone=$self->getFrontendTimezone();
   my ($Y,$M,$D,$h,$m,$s)=Today_and_Now($timezone);

   my $nowstamp=sprintf("%04d-%02d-%02d",$Y,$M,$D);

   my $datadetailcode=$self->getDataDetailCode();

   my $modalDiv=$self->HtmlSubModalDiv();

   my $opt={
      skinbase=>'temporal',
      static=>{
          LANG      => $lang,
          DATAOBJ   => $dataobj,
          DATAOBJID => $dataobjid,
          OBJLIST   => $objlist,
          TITLEBAR  => $getAppTitleBar,
          NAME      => $name,
          FULLNAME  => $fullname,
          EXMENUDIV => $ExMenu,
          NOWSTAMP  => $nowstamp,
          TIMEZONE  => $timezone,
          MODALDIV  => $modalDiv,
          DATADETAILCODE  => $datadetailcode,
          OBJECTTYPE=> $objecttype,
      }
   };



   my $prog=$self->getParsedTemplate("tmpl/temporal.CalendarEngineMain",$opt);
   utf8::encode($prog);
   print($prog);
}


1;
