package itil::appladv;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use itil::appldoc;
@ISA=qw(itil::appldoc);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   $param{Worktable}='appladv';
   $param{doclabel}='-ADV';
   my $self=bless($type->SUPER::new(%param),$type);

   my $ic=$self->getField("isactive");
   $ic->{label}="active ADV";
   $ic->{translation}='itil::appladv';

   my @allmodules=$self->getAllPosibleApplModules();
   $self->{allModules}=[];
   while(my $k=shift(@allmodules)){
      shift(@allmodules);
      push(@{$self->{allModules}},$k);
   }


   $self->AddFields(
      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>"appl.sem"),
                insertafter=>'mandator'
        
   );
   $self->AddFields(
      new kernel::Field::Link(
                name          =>'sem2id',
                dataobjattr   =>"appl.sem2"),
                insertafter=>'databossid'
        
   );
   $self->AddFields(
      new kernel::Field::Databoss(
                uploadable    =>0),
                insertafter=>'mandator'
        
   );
   $self->AddFields(
      new kernel::Field::Select(
                name          =>'modules',
                label         =>'Modules',
                group         =>'advdef',
                multisize     =>'5',
                #value         =>$self->{allModules},
                getPostibleValues=>sub{
                   $self=shift;
                   return($self->getParent->getAllPosibleApplModules());
                },
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),

      new kernel::Field::Select(
                name          =>'normodelbycustomer',
                label         =>'customer NOR Model definiton wish',
                group         =>'nordef',
                allowempty    =>1,
                vjointo       =>'itil::itnormodel',
                vjoinon       =>['normodelbycustomerid'=>'id'],
                vjoindisp     =>'name',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                searchable    =>0),

      new kernel::Field::Link(
                name          =>'normodelbycustomerid',
                label         =>'customer NOR Model definiton wish ID',
                group         =>'nordef',
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),

      new kernel::Field::Select(
                name          =>'itnormodel',
                label         =>'NOR Model to use',
                group         =>'nordef',
                searchable    =>0,
                vjoinon       =>['itnormodelid'=>'id'],
                vjointo       =>'itil::itnormodel',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'itnormodelid',
                label         =>'NOR Model to use ID',
                group         =>'nordef',
                searchable    =>0,
                dataobjattr   =>"appladv.itnormodel"),

      new kernel::Field::Boolean(
                name          =>'processingpersdata',
                label         =>'processing of person related data',
                group         =>'nordef',
                searchable    =>0,
                useNullEmpty  =>1,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),
      new kernel::Field::Boolean(
                name          =>'scddata',
                label         =>'processing of Sensitive Customer Data (SCD)',
                group         =>'nordef',
                useNullEmpty  =>1,
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>"additional"),
   );


   foreach my $module (@{$self->{allModules}}){
      $self->AddFields(
         new kernel::Field::Text(
                   name          =>$module."CountryRest",  # ISO 3166 kürzel
                   label         =>"Country restriction",
                   group         =>$module,
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
      );
   }



   return($self);
}

sub getAllPosibleApplModules
{
   my $self=shift;

   my @moduletags=qw(
     MAppl                      
     MSystemOS MHardwareOS
     MSystemMF MHardwareMF
     MWebSrv 
     MDB 
     MBackupRestore 
     MAdmVirtHost
     MAdmVPN
     MAdmNAS
     MAdmSAN
     MAdmFW
   );
   my @l;
   foreach my $m (@moduletags){
      push(@l,$m,$self->T("fieldgroup.$m"));
   }
   return(@l);
}



sub autoFillAutogenField
{
   my $self=shift;
   my $fld=shift;
   my $current=shift;

   if ($fld->{name} eq "normodelbycustomer"){
      return("S");
   }
   if ($fld->{name} eq "processingpersdata"){
      return("1");
   }
   if ($fld->{name} eq "processingscddata"){
      return("0");
   }
   if ($fld->{name} eq "modules"){
      return(["MAppl","MSystemOS","MHardwareOS"]);
   }
   return($self->SUPER::autoFillAutogenField($fld,$current));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $c=getModuleObject($self->Config,"base::isocountry");
   foreach my $k (keys(%$newrec)){
      if (defined($newrec->{$k}) &&
          ($k=~m/^.*CountryRest$/)){
         $newrec->{$k}=uc($newrec->{$k}); 
         my @l=split(/[,;\s]\s*/,$newrec->{$k});
         foreach my $lid (@l){
            if (!($c->getCountryEntryByToken(1,$lid))){
               $self->LastMsg(ERROR,"invalid country code");
               return(0);
            }
         }
         $newrec->{$k}=join(", ",sort(@l));
      }
   }

   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isViewValid($rec);

   if ($rec->{dstate}>=10){
      my @modules=($rec->{modules});
      @modules=@{$modules[0]} if (ref($modules[0]) eq "ARRAY");
      push(@l,"nordef","advdef",@modules);
   }
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{dstate}<30){
      my @l;
      my @modules=($rec->{modules});
      @modules=@{$modules[0]} if (ref($modules[0]) eq "ARRAY");
      push(@l,"nordef","advdef",@modules);

      my $userid=$self->getCurrentUserId();
      return(@l) if ($rec->{databossid} eq $userid ||
                     $rec->{sem2id} eq $userid ||
                     $self->IsMemberOf("admin"));
      if ($rec->{responseteamid} ne ""){
         return(@l) if ($self->IsMemberOf($rec->{responseteamid}));
      }
   }
   return();
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default advdef nordef),@{$self->{allModules}},qw(source));
}











1;
