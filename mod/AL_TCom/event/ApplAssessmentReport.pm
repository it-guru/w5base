package AL_TCom::event::ApplAssessmentReport;
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
use kernel::Event;
use kernel::XLSReport;
use kernel::Field;

@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterEvent("ApplAssessmentReport",
                        "ApplAssessmentReport");
   return(1);
}

sub ApplAssessmentReport
{
   my $self=shift;
   my %param=@_;
   my %flt;

   %param=kernel::XLSReport::StdReportParamHandling($self,%param);

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   my $appl=getModuleObject($self->Config,"AL_TCom::appl");

   my @control=(
                {DataObj=>$appl,
                 sheet=>'ApplAssessmentReport',
                 unbuffered=>0,  
                       # unbuffered führt zu Problemen, wenn ein gefitertes
                       # feld gleichzeitig in der Ausgabe view steht!
   #              recPreProcess=>\&recPreProcess,
                 filter=>{
                          mandator=>'Telekom* Extern',
                          opmode=>['prod','cbreakdown'],
                          ictono=>'!""',
                          cistatusid=>'4'
                         },
                 order=>'name',
                 lang=>'de',
                 view=>[qw(name mandator 
                           cistatus ictono icto criticality 
                           itsem
                           servicesupport drclass rtolevel rpolevel 
                           opmode id maintwindow)]
                },
               );


   $out->Process(@control);
   msg(INFO,"end Report to $param{'filename'}");

   return({exitcode=>0,msg=>"OK"});
}

sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;

   print Dumper($rec);

   return(0);
}





1;
