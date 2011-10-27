package TS::topapplgroups;
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
use kernel::Field;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(      name     =>'name',
                                  align    =>'left', 
                                  selectfix=>1,
                                  label    =>'Customer Group Name'),
      new kernel::Field::Text(    name     =>'label',
                                  selectfix=>1,
                                  label    =>'Label'),
      new kernel::Field::Text(    name     =>'cistatusid',
                                  selectfix=>1,
                                  label    =>'CI-StatusID'),
      new kernel::Field::Text(    name     =>'customerprio',
                                  selectfix=>1,
                                  label    =>'CustomerPrio'),
      new kernel::Field::Text(    name     =>'customer',
                                  selectfix=>1,
                                  label    =>'Customer'),
      new kernel::Field::Text(    name     =>'applids',
                                  group    =>'applstat',
                                  searchable=>0,
                                  htmldetail=>'0',
                                  label    =>'W5BaseIDs of applications',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my %flt=(
                                          cistatusid=>$current->{cistatusid},
                                          customer=>$current->{customer},
                                          customerprio=>$current->{customerprio}
                                     );
                                     my $appl=$self->getParent->
                                           getPersistentModuleObject(
                                              $self->getParent->Config,
                                              "itil::appl");
                                     $appl->SetFilter(\%flt);
                                     $appl->SetCurrentView("id");
                                     my @ids=$appl->getVal("id");
                                     return(\@ids);
                                  }),
      new kernel::Field::Number(  name     =>'applcount',
                                  group    =>'applstat',
                                  searchable=>0,
                                  label    =>'Count of applications',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $ids=$self->getParent->
                                        getField('applids')->RawValue($current);
                                     my $n=($#{$ids})+1;
                                     return($n);
                                  }),
      new kernel::Field::Percent( name     =>'fillment_custname',
                                  group    =>'applstat',
                                  searchable=>0,
                                  label    =>'customer portal: '.
                                          'fillment customer applicationname',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $ids=$self->getParent->
                                        getField('applids')->RawValue($current);
                                     my $n=($#{$ids})+1;
                                     my $custappl=getModuleObject(
                                              $self->getParent->Config,
                                              "itcrm::custappl");
                                     $custappl->SetFilter({id=>$ids,
                                                           custname=>'!""'});
                                     $custappl->SetCurrentView("id");
                                     my $nok=$custappl->SoftCountRecords(); 
                                     my $p=undef;
                                     $p=$nok*100/$n if ($n>0);
                                     
                                     return($p);
                                  }),
      new kernel::Field::Percent( name     =>'fillment_custnameid',
                                  group    =>'applstat',
                                  searchable=>0,
                                  label    =>'customer portal: '.
                                        'fillment customer applicationname id',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $ids=$self->getParent->
                                        getField('applids')->RawValue($current);
                                     my $n=($#{$ids})+1;
                                     my $custappl=getModuleObject(
                                              $self->getParent->Config,
                                              "itcrm::custappl");
                                     $custappl->SetFilter({id=>$ids,
                                                           custnameid=>'!""'});
                                     $custappl->SetCurrentView("id");
                                     my $nok=$custappl->SoftCountRecords(); 
                                     my $p=undef;
                                     $p=$nok*100/$n if ($n>0);
                                     
                                     return($p);
                                  }),
      new kernel::Field::Percent( name     =>'fillment_itmanagerid',
                                  group    =>'applstat',
                                  searchable=>0,
                                  label    =>'customer portal: '.
                                        'fillment IT-Manager contact',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $ids=$self->getParent->
                                        getField('applids')->RawValue($current);
                                     my $n=($#{$ids})+1;
                                     my $custappl=getModuleObject(
                                              $self->getParent->Config,
                                              "itcrm::custappl");
                                     $custappl->SetFilter({id=>$ids,
                                                           itmanagerid=>'!""'});
                                     $custappl->SetCurrentView("id");
                                     my $nok=$custappl->SoftCountRecords(); 
                                     my $p=undef;
                                     $p=$nok*100/$n if ($n>0);
                                     
                                     return($p);
                                  }),
      new kernel::Field::Text(    name     =>'systemids',
                                  group    =>'systemstat',
                                  searchable=>0,
                                  htmldetail=>'0',
                                  label    =>'W5BaseIDs of active systems',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $ids=$self->getParent->
                                        getField('applids')->RawValue($current);
                                     my $lnk=getModuleObject(
                                              $self->getParent->Config,
                                              "itil::lnkapplsystem");
                                     my %flt=(applid=>$ids,
                                              systemcistatusid=>\'4');
                                     
                                     $lnk->SetFilter(\%flt);
                                     $lnk->SetCurrentView("systemid");
                                     my $res=$lnk->getHashIndexed("systemid");
                                     return([keys(%{$res->{systemid}})]);
                                  }),

      new kernel::Field::Number(  name     =>'systemcount',
                                  group    =>'systemstat',
                                  searchable=>0,
                                  label    =>'Count of active systems',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $ids=$self->getParent->
                                      getField('systemids')->RawValue($current);
                                     my $n=($#{$ids})+1;
                                     return($n);
                                  }),
      new kernel::Field::Percent( name     =>'fillment_systemid',
                                  group    =>'systemstat',
                                  searchable=>0,
                                  label    =>'IT-Inventar: '.
                                        'fillment systemid',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $ids=$self->getParent->
                                      getField('systemids')->RawValue($current);
                                     my $n=($#{$ids})+1;
                                     my $o=getModuleObject(
                                              $self->getParent->Config,
                                              "itil::system");
                                     $o->SetFilter({id=>$ids,
                                                    systemid=>'!""'});
                                     $o->SetCurrentView("id");
                                     my $nok=$o->SoftCountRecords(); 
                                     my $p=undef;
                                     $p=$nok*100/$n if ($n>0);
                                     return($p);
                                  }),
      new kernel::Field::Percent( name     =>'fillment_systemip',
                                  group    =>'systemstat',
                                  searchable=>0,
                                  label    =>'IT-Inventar: '.
                                        'fillment systems with ip adresses',
                                  onRawValue=>sub{
                                     my $self=shift;
                                     my $current=shift;
                                     my $ids=$self->getParent->
                                      getField('systemids')->RawValue($current);
                                     my $n=($#{$ids})+1;
                                     my $o=getModuleObject(
                                              $self->getParent->Config,
                                              "itil::ipaddress");
                                     $o->SetFilter({systemid=>$ids,
                                                    cistatusid=>\'4'});
                                     $o->SetCurrentView("systemid");
                                     my $res=$o->getHashIndexed("systemid");
                                     my $nok=keys(%{$res->{systemid}});
                                     my $p=undef;
                                     $p=$nok*100/$n if ($n>0);
                                     return($p);
                                  }),
   );
   $self->{'data'}=[ 
                 {
                  name=>'TDG',
                  label=>'TDG (THO und TMO)',
                  cistatusid=>'4',
                  customerprio=>'1',
                  customer=>'DTAG.TDG DTAG.TDG.*'
                 },
                 {
                  name=>'GHS',
                  label=>'GHS (incl. CIT)',
                  cistatusid=>'4',
                  customerprio=>'1',
                  customer=>'DTAG.GHS DTAG.GHS.*'
                 },
                 {
                  name=>'TSI',
                  label=>'T-Systems (PQIT)',
                  cistatusid=>'4',
                  customerprio=>'1',
                  customer=>'DTAG.TSI DTAG.TSI.*'
                 },
                 {
                  name=>'TSG',
                  label=>'TSG',
                  cistatusid=>'4',
                  customerprio=>'1',
                  customer=>'DTAG.TSG DTAG.TSG.*'
                 }

                   ];
   $self->setDefaultView(qw(name label customer cistatusid customerprio));
   return($self);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  
   



1;
