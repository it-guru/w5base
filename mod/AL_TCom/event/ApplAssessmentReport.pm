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

   #msg(INFO,"start Report to %s",join(", ",@{$param{'filename'}}));

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   my $appl=getModuleObject($self->Config,"AL_TCom::appl");

#   $asset->AddFields(
#      new kernel::Field::Date(
#                name          =>'deprend',
#                label         =>'Deprecation End',
#                translation   =>'tsacinv::asset',
#                vjointo       =>'tsacinv::asset',
#                vjoinon       =>['name'=>'assetid'],
#                vjoindisp     =>'deprend'),
#      new kernel::Field::Text(
#                name          =>'applco',
#                label         =>'Anwendungs CO-Number',
#                onRawValue    =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   if ($current->{applicationnames} ne ""){
#                      my $appl=$self->getParent->getPersistentModuleObject(
#                                                 "itil::appl");
#                      $appl->SetFilter({name=>\$current->{applicationnames}});
#                      my ($WfRec)=$appl->getOnlyFirst(qw(conumber));
#                     
#                      return($WfRec->{conumber});
#                   }
#                   return(undef);
#                }),
#   );
 
   

   my @control=(
                {DataObj=>$appl,
                 sheet=>'ApplAssessmentReport',
                 filter=>{
                          mandator=>'Telekom*',
                          ictono=>'!""',
                          cistatusid=>'4'
                         },
                 order=>'name',
                 lang=>'de',
                 view=>[qw(name cistatus ictono icto criticality 
                           servicesupport drclass rtolevel rpolevel drc )]
                },
               );


   $out->Process(@control);
   msg(INFO,"end Report to $param{'filename'}");

   return({exitcode=>0,msg=>"OK"});
}





1;
