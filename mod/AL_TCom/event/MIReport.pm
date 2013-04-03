package AL_TCom::event::MIReport;
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
use kernel::Event;
use kernel::date;
use kernel::XLSReport;

@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub MIReport
{
   my $self=shift;
   my %param=@_;
   my %flt;
   $ENV{LANG}="de";


   if ($param{'timezone'} eq ""){
      $param{'timezone'}="CET"
   }
   if ($param{'year'} eq ""){
      my ($year,$month,$day, $hour,$min,$sec)=Today_and_Now($param{'timezone'});
      $param{'year'}=$year;
   }

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $mi=getModuleObject($self->Config,"itil::lnkmgmtitemgroup");
   $wf->SetFilter({eventend=>'>"01.01.2013 00:00:00"',
                   class=>['AL_TCom::workflow::eventnotify'],
                   isdeleted=>\'0'});

   my %sheet=();
   foreach my $wfrec ($wf->getHashList(qw(wffields.eventmode 
                                  wffields.affecteditemgroup id))){
      my $top=$wfrec->{affecteditemgroup};
      $top="NONE" if (!defined($top) || $top eq "");
      $top=[split(/\s*;\s*/,$top)] if (ref($top) ne "ARRAY");
      foreach my $t (@$top){
         push(@{$sheet{$t}},$wfrec->{id});
      }
   }

   if ($param{'filename'} eq ""){
      $param{'filename'}="/tmp/MIReport.xls";
   }
#   msg(INFO,"start Report to $param{'filename'}");
#   my $t0=time();
   my @control;
   foreach my $s (sort(keys(%sheet))){
      push(@control,{
         sheet=>$s,
         DataObj=>'base::workflow',
         filter=>{id=>$sheet{$s}},
         view=>[qw(name detaildescription createdate id)]}
      );
   }

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();


   $out->Process(@control);
   return({exitcode=>0,msg=>'OK'});
}





1;
