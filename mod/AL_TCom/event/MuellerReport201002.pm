package AL_TCom::event::MuellerReport201002;
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

   $self->RegisterEvent("MuellerReport201002",
                        "MuellerReport201002");
   return(1);
}

sub MuellerReport201002
{
   my $self=shift;
   my %param=@_;
   my %flt;

   %param=kernel::XLSReport::StdReportParamHandling($self,%param);

   #msg(INFO,"start Report to %s",join(", ",@{$param{'filename'}}));

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   my $asset=getModuleObject($self->Config,"itil::asset");

   $asset->AddFields(
      new kernel::Field::Date(
                name          =>'deprend',
                label         =>'Deprecation End',
                translation   =>'tsacinv::asset',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['name'=>'assetid'],
                vjoindisp     =>'deprend'),
      new kernel::Field::Text(
                name          =>'applco',
                label         =>'Anwendungs CO-Number',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $appl=$self->getParent->getPersistentModuleObject(
                                              "itil::appl");
                   $appl->SetFilter({name=>\$current->{applicationnames}});
                   my ($WfRec)=$appl->getOnlyFirst(qw(conumber));
           
                   return($WfRec->{conumber});
                }),
   );
 
   

   my @control=(
                {DataObj=>$asset,
                 unbuffered=>0,
                 sheet=>'Assets',
                 filter=>{
                          cistatusid=>'4'
                         },
                 order=>'name',
                 lang=>'de',
                 recPreProcess=>\&recPreProcess,
                 view=>[qw(name systemnames 
                           deprend
                           applicationnames 
                           applco
                           customer
                           conumber
                           customernames)]
                },
                {DataObj=>$asset,
                 unbuffered=>0,
                 sheet=>'Databoss',
                 filter=>{
                          cistatusid=>'4'
                         },
                 order=>'name',
                 lang=>'de',
                 view=>[qw(name databoss systemnames deprend applicationnames 
                           customernames)]
                }
               );


   $out->Process(@control);
   msg(INFO,"end Report to $param{'filename'}");

   return({exitcode=>0,msg=>"OK"});
}

sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;

   ########################################################################
   # modify record view
   my @newrecview;
   foreach my $fld (@$recordview){
      my $name=$fld->Name;
      next if ($name eq "customer");
      push(@newrecview,$fld);
   }
   @{$recordview}=@newrecview;
   ########################################################################

printf STDERR ("fifi applicationnames=%s\n",Dumper($rec->{applicationnames}));
printf STDERR ("fifi customernames=%s\n",Dumper($rec->{customer}));
   if (!defined($self->{buffer})){
      #####################################################################
      # create buffer   
      my %u;
      foreach my $r (@{$rec->{customer}}){
         $u{$r->{appl}.";".$r->{applcustomer}}=$r;
      }
      $self->{buffer}=[];
      foreach my $r (sort(keys(%u))){
         push(@{$self->{buffer}},$u{$r});
      }
   }
   if (defined($self->{buffer})){
      #####################################################################
      # reprocess buffer
      my $r=shift(@{$self->{buffer}});
      $rec->{customernames}=$r->{applcustomer};
      $rec->{applicationnames}=$r->{appl};
      if ($#{$self->{buffer}}==-1){
         delete($self->{buffer});
      }
      else{
         return(2); 
      }
   }
   return(1);
}





1;
