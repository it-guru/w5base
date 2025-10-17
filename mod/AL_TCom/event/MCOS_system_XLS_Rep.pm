package AL_TCom::event::MCOS_system_XLS_Rep;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
# https://darwin.telekom.de/darwin/auth/base/workflow/ById/17002314090005
#

sub MCOS_system_XLS_Rep
{
   my $self=shift;
   my %param=@_;
   my %flt;
   my @userid=qw(-1);
   $ENV{LANG}="en";
   $param{'defaultFilenamePrefix'}=
         "webfs:/Reports/MCOS-System-Status/MCOS_Systems";
   msg(INFO,"start Report");
   my $t0=time();
 
   $flt{'cistatusid'}=\'4';
   $flt{'alltags'}='0="isMCOS" AND 1="1"';

   %param=kernel::XLSReport::StdReportParamHandling($self,%param);
   my $out=new kernel::XLSReport($self,$param{'filename'});
   
   $out->initWorkbook();

   my @view=qw(name systemid cistatus id);

   my $dataobj=getModuleObject($self->Config,"AL_TCom::system");


   my @control;

   push(@control,{
      sheet=>"all MCOS Systems",
      DataObj=>$dataobj,
      unbuffered=>0,
      filter=>{%flt},
      view=>[@view]
   });
   my %bugflt=%flt;
   $bugflt{srcsys}="!AssetManager";
   $bugflt{cdate}="<now-7d";

   push(@view,qw(srcsys cdate));
   
   push(@control,{
      sheet=>"bad MCOS Systems",
      DataObj=>$dataobj,
      unbuffered=>0,
      filter=>{%bugflt},
      view=>[@view]
   });




   $out->Process(@control);
   my $trep=time()-$t0;
   msg(INFO,"end Report to $param{'filename'} ($trep sec)");
   return({exitcode=>0,msg=>'OK'});
}





1;
