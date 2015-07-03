package tssc::chm_pso;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use tssc::lib::io;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->AddFields(
      new kernel::Field::Linenumber(
               name           =>'linenumber',
               label          =>'No.'),

      new kernel::Field::Date(
               name           =>'plannedstart',
               timezone       =>'CET',
               label          =>'Planned Start',
               translation    =>'tssc::chmtask',
               dataobjattr    =>'cm3tm1.planned_start'),

      new kernel::Field::Date(
               name           =>'plannedend',
               timezone       =>'CET',
               label          =>'Planned End',
               translation    =>'tssc::chmtask',
               dataobjattr    =>'cm3tm1.planned_end'),

      new kernel::Field::Text(
               name           =>'tasknumber',
               label          =>'Task No.',
               translation    =>'tssc::chmtask',
               dataobjattr    =>'cm3tm1.numberprgn'),

      new kernel::Field::Text(
               name           =>'taskstatus',
               label          =>'Task Status',
               dataobjattr    =>'cm3tm1.status'),

      new kernel::Field::Text(
               name           =>'changenumber',
               label          =>'Change No.',
               translation    =>'tssc::chmtask',
               dataobjattr    =>'cm3tm1.parent_change'),

      new kernel::Field::Text(
               name           =>'changestatus',
               label          =>'Change Status',
               vjointo        =>'tssc::chm',
               vjoinon        =>['changenumber'=>'changenumber'],
               vjoindisp      =>[qw(status)]),

      new kernel::Field::Text(
               name           =>'appl',
               label          =>'Application',
               dataobjattr    =>'screlationm1.depend'),

      new kernel::Field::Text(
               name           =>'applname',
               label          =>'Application name',
               searchable     =>0,
               dataobjattr    =>'devicem1.system_name'),

      new kernel::Field::Select(
               name           =>'opmode',
               label          =>'operation mode',
               translation    =>'itil::appl',
               transprefix    =>'opmode.',
               vjointo        =>'itil::appl',
               vjoinon        =>['appl'=>'applid'],
               vjoindisp      =>[qw(opmode)]),

   );

   $self->{use_distinct}=0;
   $self->setDefaultView(qw(plannedstart plannedend applname
                            tasknumber changenumber));
   return($self);
}   

sub SetFilter
{
   my $self=shift;
   my $flt=$_[0];

   if (ref($flt) eq "HASH" && exists($flt->{appl}) &&
       !ref($flt->{appl})) {
      my $appl=getModuleObject($self->Config,'itil::appl');
      $appl->SetFilter({ name       =>$flt->{appl},
                         cistatusid =>'<6' });
      my @applids=$appl->getVal('applid');
      @applids=grep({defined $_} @applids);
      if ($#applids >= 150) {
         $self->LastMsg(ERROR,
            "Limited number of applications exceeded (max. 150)");
         return(undef);
      }
      $_[0]->{appl}=join(' ',@applids);
   }

   return($self->SUPER::SetFilter(@_));
}

sub isQualityCheckValid
{
   return(undef);
}

sub isUploadValid
{
   return(undef);
}

sub initSearchQuery
{
   my $self=shift;
   my $nowlabel=$self->T("today","kernel::App");

   if (!defined(Query->Param("search_plannedstart"))){
     Query->Param("search_plannedstart"=>">$nowlabel AND <$nowlabel+5d");
   }
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="scadm1.screlationm1,scadm1.cm3tm1,scadm1.devicem1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="cm3tm1.ci_down='t' AND ".
             "screlationm1.source=cm3tm1.numberprgn AND ".
             "screlationm1.depend=devicem1.id AND ".
             "devicem1.device_name='APPLICATION'";
   return($where);
}






1;
