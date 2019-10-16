package tssm::process;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use tssm::lib::io;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'id',
                label         =>'id',
                dataobjattr   =>'id'),

      new kernel::Field::Text(
                name          =>'dataobj',
                label         =>'dataobj',
                dataobjattr   =>'dataobj'),

      new kernel::Field::Text(
                name          =>'ciflt',
                label         =>'Config-Item',
                dataobjattr   =>'ciflt'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'name-Name',
                dataobjattr   =>'name'),

      new kernel::Field::Date(
                name          =>'s',
                label         =>'Begin',
                dataobjattr   =>'dtstart'),

      new kernel::Field::Date(
                name          =>'e',
                label         =>'End',
                dataobjattr   =>'dtend'),
   );
   $self->setDefaultView(qw(s e id name));
   return($self);
}

sub validateSearchQuery
{
   my $self=shift;
   my $range=Query->Param("search_range");
   my $context=$self->Context;
   my $tstart=$self->ExpandTimeExpression($range,"en");
   if (!defined($tstart)){
      return(0);
   }
   $context->{tstart}=$tstart;
   Query->Delete("search_range");

   my $ciflt=Query->Param("search_ciflt");
   Query->Param("search_ciflt"=>'*'.$ciflt.'*');

   return($self->SUPER::validateSearchQuery());
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $tstart=$self->Context->{tstart};

   if ($tstart ne ""){
      $tstart=~s/[^0-9: -]//g;
      $tstart="to_date('$tstart','YYYY-MM-DD HH24:MI:SS')";
   }
   else{
      $tstart="current_date";

   }

   my $from=<<EOF;
(
   select id, dataobj,name,dtstart,dtend,ciflt
   from (
      select dh_number id,'tssm::inm' dataobj,
             brief_description name,
             tsi_ci_name ciflt,
             downtime_start dtstart,downtime_end dtend
      from SMREP1.DH_probsummarym1
      where 
            (downtime_start<current_date and downtime_start>$tstart) or
            (downtime_end<current_date and 
             (downtime_end>$tstart or  downtime_end is null)) or
            (downtime_start<current_date and 
             (downtime_end>$tstart or downtime_end is null))
   ) inmbase

   union all

   select id,dataobj,name,dtstart,dtend,ciflt
   from (
      select dh_number id,'tssm::chm' dataobj,
             brief_description name,depend ci,
             depend ciflt,
             planned_start dtstart,planned_end dtend
      from SMREP1.DH_cm3rm1
      join DH_screlationm1
        on DH_screlationm1.source=DH_cm3rm1.dh_number
           and depend_filename='device'
      where 
            (planned_start<current_date and planned_start>$tstart) or
            (planned_end<current_date and 
             (planned_end>$tstart or  planned_end is null)) or
            (planned_start<current_date and 
             (planned_end>$tstart or planned_end is null))
   ) chmbase
) wfbase
EOF
   return($from);
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

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}




1;
