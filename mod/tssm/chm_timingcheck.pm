package tssm::chm_timingcheck;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::date;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'tslot',
                label         =>'Timeslot',
                sqlorder      =>'desc',
                dataobjattr   =>'tcheck.t'),

      new kernel::Field::Text(
                name          =>'modcount',
                label         =>'count of modified changes',
                dataobjattr   =>'tcheck.n'),

      new kernel::Field::Text(
                name          =>'processed',
                label         =>'interface processed',
                dataobjattr   =>'tcheck.p'),
   );

   $self->setDefaultView(qw(linenumber tslot modcount processed));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->{use_distinct}=0;
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getSqlFrom
{
   my $self=shift;
   my ($year,$month,$day,$hour,$min,$sec)=Today_and_Now("CET");

   my $hourcheck=500;
   my $wf=getModuleObject($self->Config,"base::workflow");
   $wf->SetFilter(srcsys=>'tssm::event::scchange',
                  srcload=>">now-${hourcheck}h");
   my $focus="undefined";
   my ($wfrec,$msg)=$wf->getOnlyFirst(qw(srcload));
   if (defined($wfrec)){
      $focus=$wfrec->{srcload};
   }


   my @from;
   for(my $c=0;$c<$hourcheck;$c++){
      my ($year0,$month0,$day0,$hour0,$min0,$sec0)=
         Add_Delta_YMDHMS("CET",$year,$month,$day,$hour,$min,$sec,
                          0,0,0,-1,0,0);
      my $cmd=sprintf("select '%04d%02d%02d %02dh-%02dh' t,".
                      "count(numberprgn) n,".
                      "'$focus' p ".
                      "from cm3rm1 ".
                      "where sysmodtime>to_date('%04d-%02d-%02d %02d:00:00',".
                      "'YYYY-MM-DD HH24:MI:SS') ".
                      "and sysmodtime<to_date('%04d-%02d-%02d %02d:00:00',".
                      "'YYYY-MM-DD HH24:MI:SS')",$year0,$month0,$day0,
                                                 $hour0,$hour,
                                                 $year0,$month0,$day0,$hour0,
                                                 $year,$month,$day,$hour);
      push(@from,$cmd);
      ($year,$month,$day,$hour,$min,$sec)=
         ($year0,$month0,$day0,$hour0,$min0,$sec0);

   }
   my $from="(".join(" union ",@from).") tcheck";
   return($from);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}





1;
