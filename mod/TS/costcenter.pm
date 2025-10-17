package TS::costcenter;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use itil::costcenter;
@ISA=qw(itil::costcenter);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::SubList(
                name          =>'sappspentries',
                group         =>'saprelation',
                label         =>'TS SAP P01 PSP Entries',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>\'tssapp01::psp',
                vjoinon       =>['name'=>'name'],
                vjoinonfinish =>sub{
                   my $self=shift;
                   my $flt=shift;
                   my $current=shift;
                   my $f=$flt->{name};
                   if (ref($f) eq "SCALAR"){
                      $f=$$f;
                   }
                   $f=~s/\[.*\]$//;
                   if ($f=~m/\S-[a-z0-9]+/){
                      $flt->{name}=join(" ",map({'"'.$_.'"'}
                                  $f,
                                  $f."-*"));
                   }
                   elsif ($f=~m/[a-z0-9]+/){
                      $flt->{name}=join(" ",map({'"'.$_.'"'}
                                  "?-".$f,
                                  "?-".$f."-*",
                                  $f));
                   }
                   return($flt);
                },
                vjoindisp     =>['name','status','description'],
                vjoininhash   =>['name','status','description','saphier']),
      insertafter=>'itsemid'
   );
   $self->AddFields(
      new kernel::Field::SubList(
                name          =>'sapcoentries',
                group         =>'saprelation',
                label         =>'TS SAP P01 CostCenter Entries',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>\'tssapp01::costcenter',
                vjoinon       =>['name'=>'name'],
                vjoinonfinish =>sub{
                   my $self=shift;
                   my $flt=shift;
                   if (ref($flt) ne "HASH"){
                      Stacktrace();
                   }
                   my $current=shift;
                   my $f=$flt->{name};
                   $f=~s/\[.*\]$//;
                   if ($f=~m/\d+/){
                      $flt->{name}=sprintf("%d %010d",$f,$f);
                   }
                   return($flt);
                },
                vjoininhash     =>['name','description','saphier'],
                vjoindisp     =>['name','description']),
      insertafter=>'itsemid'
   );
   $self->AddGroup("saprelation",translation=>'TS::costcenter');

   return($self);
}


sub isViewValid
{
   my $self=shift;
   my @l=$self->SUPER::isViewValid(@_);
   my $rec=shift;

   if (defined($rec) && $rec->{cistatusid}>2 && $rec->{cistatusid}<6){
      if (grep(/^(default|ALL)$/,@l)){
         push(@l,"saprelation");
      }
   }
   return(@l);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "control");
   }
   splice(@l,$inserti,$#l-$inserti,("saprelation",@l[$inserti..($#l+-1)]));
   return(@l);

}










1;
