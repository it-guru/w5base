package AL_TCom::event::SCM_EmergencyPlan_Rep;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
use kernel::XLSReport;

@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

#
# Request ...
# https://darwin.telekom.de/darwin/auth/base/workflow/ById/16982275560075
#

sub attachHandler
{
   my $self=shift;
   my $current=shift;
   my $dataobj=$self->getParent();

   my $attfld=$dataobj->getField("attachments",$current);
   my $attlst=$attfld->RawValue($current);

   my $name=$self->Name();


   my $frec;

   my $rec=$current;

   foreach my $filerec (sort({$a->{mdate} cmp $b->{mdate}} @{$attlst})){
      if ($name=~m/^sysoverview/ &&
          ($filerec->{name}=~m/^$rec->{ictono}_.+_SystemOverview_\d{8}\.pdf$/)){
         $frec=$filerec; 
      }
      if ($name=~m/^emergencyplan/ &&
          (($filerec->{name}
              =~m/^SCM_Emergency_Plan_$rec->{ictono}_.+_\d{8}\.pdf/)||
           ($filerec->{name}
              =~m/^SCM_Notfallplan_$rec->{ictono}_.+_\d{8}\.pdf$/))){
         $frec=$filerec; 
      }
   }
   if (defined($frec)){
      if ($name=~m/file$/){
         return($frec->{name});
      }
      if ($name=~m/date$/){
         return($frec->{mdate});
      }
      if ($name=~m/isprivate$/){
         return($frec->{isprivate});
      }

   }
   return(undef);

}

sub SCM_EmergencyPlan_Rep
{
   my $self=shift;
   my %param=@_;
   my %flt;
   my @userid=qw(-1);
   $ENV{LANG}="en";
   $param{'defaultFilenamePrefix'}=
         "webfs:/Reports/SCM_Report/EmergencyPlan";
   msg(INFO,"start Report");
   my $t0=time();
 
   $flt{'cistatusid'}=\'4';
   $flt{'opmode'}=['prod'];
   $flt{'mandator'}="TelekomIT*";

   %param=kernel::XLSReport::StdReportParamHandling($self,%param);
   my $out=new kernel::XLSReport($self,$param{'filename'});
   
   $out->initWorkbook();

   my @view=qw(name id mandator opmode ictono 
               emergencyplanfile emergencyplandate emergencyplanisprivate
               sysoverviewfile   sysoverviewdate   sysoverviewisprivate);

   my $dataobj=getModuleObject($self->Config,"AL_TCom::appl");
   my $attfld=$dataobj->getField("attachments");
   $attfld->{selectfix}=1;

   # set constant column names
   $dataobj->getField("name")->{label}="name";
   $dataobj->getField("id")->{label}="w5baseid";
   $dataobj->getField("mandator")->{label}="mandator";
   $dataobj->getField("ictono")->{label}="ictono";

   $dataobj->AddFields(
      new kernel::Field::Text(
                name          =>'emergencyplanfile',
                label         =>'emergencyplanfile',
                onRawValue    =>\&attachHandler),
      new kernel::Field::Date(
                name          =>'emergencyplandate',
                label         =>'emergencyplandate',
                onRawValue    =>\&attachHandler),
      new kernel::Field::Number(
                name          =>'emergencyplanisprivate',
                label         =>'emergencyplanisprivate',
                onRawValue    =>\&attachHandler),
   );

   $dataobj->AddFields(
      new kernel::Field::Text(
                name          =>'sysoverviewfile',
                label         =>'sysoverviewfile',
                onRawValue    =>\&attachHandler),
      new kernel::Field::Date(
                name          =>'sysoverviewdate',
                label         =>'sysoverviewdate',
                onRawValue    =>\&attachHandler),
      new kernel::Field::Number(
                name          =>'sysoverviewisprivate',
                label         =>'sysoverviewisprivate',
                onRawValue    =>\&attachHandler),
   );

   my @control;

   push(@control,{
      sheet=>"FileAttachReport",
      DataObj=>$dataobj,
      unbuffered=>0,
      filter=>{%flt},
      view=>[@view]
   });

   $out->Process(@control);
   my $trep=time()-$t0;
   msg(INFO,"end Report to $param{'filename'} ($trep sec)");
   return({exitcode=>0,msg=>'OK'});
}





1;
