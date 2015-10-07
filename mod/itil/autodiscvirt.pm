package itil::autodiscvirt;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'autodiscvirt.id'),

      new kernel::Field::Text(
                name          =>'elementname',
                label         =>'Elementname',
                dataobjattr   =>'autodiscvirt.elementname'),

      new kernel::Field::Text(
                name          =>'section',
                label         =>'Section',
                dataobjattr   =>'autodiscvirt.section'),

      new kernel::Field::Text(
                name          =>'scanname',
                label         =>'Scanname',
                dataobjattr   =>'autodiscvirt.scanname'),

      new kernel::Field::Text(
                name          =>'scanextra1',
                label         =>'ScanExtra1',
                dataobjattr   =>'autodiscvirt.scanextra1'),

      new kernel::Field::Text(
                name          =>'scanextra2',
                label         =>'ScanExtra2',
                dataobjattr   =>'autodiscvirt.scanextra2'),

      new kernel::Field::Text(
                name          =>'scanextra3',
                label         =>'ScanExtra3',
                dataobjattr   =>'autodiscvirt.scanextra3'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'autodiscvirt.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Update-Date',
                dataobjattr   =>'autodiscvirt.modifydate'),

   );
   $self->setDefaultView(qw(elementname section scanname scanextra1 
                            scanextra2  mdate));
   $self->setWorktable("autodiscvirt");
   return($self);
}


sub extractAutoDiscData      # SetFilter Call ist Job des Aufrufers
{
   my $self=shift;
   my @res=();

   $self->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         my %e=(
            section=>$rec->{section},
            scanname=>$rec->{scanname},
            quality=>$rec->{quality},
            processable=>1
         );
         foreach my $ename (qw(scanextra1 scanextra2 scanextra3)){
            if (exists($rec->{$ename}) &&
                defined($rec->{$ename})){
               $e{$ename}=$rec->{$ename};
            }
         }
         push(@res,\%e);
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   return(@res);
}



sub isCopyValid
{
   my $self=shift;

   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}





1;
