package itil::systemsoftwarematrix;
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
use kernel::Field;
use itil::system;
@ISA=qw(itil::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'swinstproducer',
                readonly      =>1,
                searchable    =>1,
                htmldetail    =>0,
                onPreProcessFilter=>\&calcFieldListInMatrix,
                label         =>'Software producer',
                onRawValue    =>\&calcProducer),
      new kernel::Field::Dynamic(
                name          =>'swinstmatrix',
                readonly      =>1,
                htmldetail    =>0,
                depend        =>['software'], 
                group         =>'swinstmatrix',
                label         =>'Software',
                onPreProcessFilter=>\&calcFieldListInMatrix,
                fields        =>\&addSWInstallMatrix),

      insertafter=>'location'
   );
   foreach my $fldname ($self->getFieldList("collectively")){
      my $fldobj=$self->getField($fldname);
      if (defined($fldobj)){
         next if ($fldobj->Name eq "name");
         next if ($fldobj->Name eq "cistatus");
         next if ($fldobj->Name eq "systemid");
         next if ($fldobj->Name eq "location");
         next if ($fldobj->Name eq "asset");
         next if ($fldobj->Name eq "conumber");
         next if ($fldobj->Name eq "applications");
         next if ($fldobj->Name eq "adminteam");
         next if ($fldobj->Name eq "swinstproducer");
         next if ($fldobj->Name eq "swinstmatrix");
         $fldobj->{searchable}=0;
      }
   }

   $self->setDefaultView(qw(name systemid swinstmatrix));

   return($self);
}

sub SetFilter
{
   my $self=shift;

   $self->getField("swinstmatrix")->{'SWFIELDS'}=[];
   return($self->SUPER::SetFilter(@_));
}

sub calcFieldListInMatrix
{
   my $self=shift;
   my $hflt=shift;


   my %f=();

   if (defined($hflt->{swinstproducer}) ||
       defined($hflt->{swinstmatrix})){
      if (defined($hflt->{swinstproducer})){
         $f{producer}=$hflt->{swinstproducer};
         delete($hflt->{swinstproducer});
      }
      if (defined($hflt->{swinstmatrix})){
         $f{name}=$hflt->{swinstmatrix};
         delete($hflt->{swinstmatrix});
      }
      $f{cistatusid}=[3,4,5];
      my $p=$self->getParent();
      my $sw=getModuleObject($p->Config,"itil::software");
      $sw->SecureSetFilter(\%f);
      $sw->Limit(105);
      my @l=$sw->getHashList(qw(name id));
      if ($#l>100){
         return(0,"too many software columns");
      }
      $p->getField("swinstmatrix")->{'SWFIELDS'}=\@l;
   }
   return(0,undef);
}

sub calcProducer
{
   my $self=shift;
   return("- this field is only searchable! -");
}

sub addSWInstallMatrix
{
   my $self=shift;
   my %param=@_;
   my @dyn=();
   my $p=$self->getParent();
   my $current=$param{current};
   return() if (!defined($current));

   my $il=$p->getField("software")->RawValue($current);
   my %instlist=();
   foreach my $i (@$il){ 
      $instlist{$i->{'softwareid'}}++;
   }
   foreach my $sw (@{$self->{'SWFIELDS'}}){
      my $inst=0;
      $inst=1 if ($instlist{$sw->{id}});
      push(@dyn,$self->getParent->InitFields(
           new kernel::Field::Boolean(
              name       =>"SWINST".$sw->{id},
              label      =>"Software: ".$sw->{name},
              align      =>'center',
              group      =>'swinstmatrix',
              htmldetail =>0,
              onRawValue =>sub {
                               return("$inst");
                            },
              ),
          ));
   }
  
   return(@dyn);
}

sub isViewValid
{
   my $self=shift;
   my @l=$self->SUPER::isViewValid(@_);
   if (in_array(\@l,[qw(ALL default)])){
      push(@l,"swinstmatrix");
   }
   return(@l);
}









1;
