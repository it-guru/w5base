package base::w5stat;
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
use kernel::date;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use DateTime;
use DateTime::Span;
use DateTime::SpanSet;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'w5stat.id'),
                                                  
      new kernel::Field::Select(
                name          =>'sgroup',
                label         =>'Statistic Group',
                value         =>['Group','Application','Location','User',
                                 'Contract'],
                dataobjattr   =>'w5stat.statgroup'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Statistic Name',
                dataobjattr   =>'w5stat.name'),

      new kernel::Field::Link(
                name          =>'nameid',
                label         =>'Statistic Name last ID',
                dataobjattr   =>'w5stat.nameid'),

      new kernel::Field::Text(
                name          =>'month',
                label         =>'Month',
                dataobjattr   =>'w5stat.month'),


      new kernel::Field::Container(
                name          =>'stats',
                group         =>'stats',
                desccolwidth  =>'200',
                uivisible     =>1,
                selectfix     =>1,
                label         =>'Statistic Data',
                dataobjattr   =>'w5stat.stats'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'w5stat.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'w5stat.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'w5stat.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'w5stat.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'w5stat.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'w5stat.modifydate'),


   );
   $self->LoadSubObjs("ext/w5stat","w5stat");
   $self->LoadSubObjs("ext/w5workflowstat","w5workflowstat");
   $self->setDefaultView(qw(linenumber month sgroup fullname mdate));
   $self->setWorktable("w5stat");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
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
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","stats","source");
}


sub recreateStats
{
   my $self=shift;
   my $mode=shift;
   my $monthstamp=shift;
   my ($year,$mon,$day, $hour,$min,$sec) = Today_and_Now("GMT");
   my $currentmonth=sprintf("%04d%02d",$year,$mon);
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;


   $self->{stats}={};
   msg(INFO,"processData handler Status:");
   msg(INFO,"===========================");
   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processData")){
         msg(INFO,"found processData handler in %s",$obj->Self);
      }
   }
   msg(INFO,"processRecord handler Status:");
   msg(INFO,"=============================");
   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processRecord")){
         msg(INFO,"found processRecord handler in %s",$obj->Self);
      }
   }
   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processData")){
         $obj->processData($monthstamp,$currentmonth);
      }
   }

   my $d1=new DateTime(year=>$year, month=>$month, day=>1,
                       hour=>0, minute=>0, second=>0);
   my $dm=DateTime::Duration->new( months=>1);
   my $d2=$d1+$dm;
   my $basespan;
   eval('$basespan=DateTime::Span->from_datetimes(start=>$d1,end=>$d2);');
   my $baseduration=CalcDateDuration($d1,$d2);
   foreach my $group (keys(%{$self->{stats}})){
      foreach my $name (keys(%{$self->{stats}->{$group}})){
         foreach my $v (keys(%{$self->{stats}->{$group}->{$name}})){
            if (ref($self->{stats}->{$group}->{$name}->{$v})){
               my $spanobj=$self->{stats}->{$group}->{$name}->{$v};
               $spanobj=$spanobj->intersection($basespan);
               my $vv=$v.".count";
               my @splist=$spanobj->as_list();
               $self->{stats}->{$group}->{$name}->{$vv}=$#splist+1;
               my $minsum=0;
               my $minmax=0;
               foreach my $span (@splist){ 
                  my $d=CalcDateDuration($span->start,$span->end);
                  $minsum+=$d->{totalminutes};
                  $minmax=$d->{totalminutes} if ($minmax<$d->{totalminutes});
               }
               my $vv=$v.".total";
               $self->{stats}->{$group}->{$name}->{$vv}=sprintf('%.4f',$minsum);
               my $vv=$v.".max";
               $self->{stats}->{$group}->{$name}->{$vv}=sprintf('%.4f',$minmax);
               my $vv=$v.".base";
               $self->{stats}->{$group}->{$name}->{$vv}=sprintf('%.4f',
                                                $baseduration->{totalminutes});
               delete($self->{stats}->{$group}->{$name}->{$v});
            }
         }
         my $statrec={stats=>$self->{stats}->{$group}->{$name},
                      sgroup=>$group,
                      month=>$monthstamp,
                      fullname=>$name};
         $self->ValidatedInsertOrUpdateRecord($statrec,
                                            {sgroup=>\$statrec->{sgroup},
                                             month=>\$monthstamp,
                                             fullname=>\$statrec->{fullname}});
      }
   }
}

sub processRecord
{
   my $self=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;

   foreach my $obj (values(%{$self->{w5stat}}),
                    values(%{$self->{w5workflowstat}})){
      if ($obj->can("processRecord")){
         $obj->processRecord($module,$month,$rec,$self->{stats}); 
      }
   }
}

sub storeStatVar
{
   my $self=shift;
   my $group=shift;
   my $key=shift;
   my $param=shift;
   my $var=shift;
   my @val=@_;
   my $method=$param->{method};
   my $maxlevel=$param->{maxlevel};
   my $keyid=$param->{key};
   $method="count" if (!defined($method));

   my @key=($key);
   @key=@$key if (ref($key) eq "ARRAY");
   my %key=();
   foreach my $k (@key){  # make all keys unique
     if ($k ne ""){
        $key{$k}=1;
     }
   }
   @key=keys(%key);

   %isAlreadyCounted=(); 
   foreach my $key (@key){
      my $level=0;
      if ($var ne ""){
         while(1){
            if ($key ne "" && !defined($isAlreadyCounted{$key})){
               if (defined($keyid)){
                  $self->{stats}->{$group}->{$key}->{keyid}=$keyid;
               }
               if (lc($method) eq "count"){
                  $self->{stats}->{$group}->{$key}->{$var}+=$val[0];
               }
               elsif (lc($method) eq "tspan.union"){

                  if ((my ($Y1,$M1,$D1,$h1,$m1,$s1)=$val[0]=~
                       m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
                      (my ($Y2,$M2,$D2,$h2,$m2,$s2)=$val[1]=~
                       m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
                     my $d1=new DateTime(year=>$Y1, month=>$M1, day=>$D1,
                                         hour=>$h1, minute=>$m1, second=>$s1);
                     my $d2=new DateTime(year=>$Y2, month=>$M2, day=>$D2,
                                         hour=>$h2, minute=>$m2, second=>$s2);
                     my $span;
                     eval('$span=DateTime::Span->from_datetimes(start=>$d1,
                                                                end=>$d2);');
                     if ($@ eq ""){
                        my $v=$var.".tspan.union";
                        if (!defined($self->{stats}->{$group}->{$key}->{$v})){
                           $self->{stats}->{$group}->{$key}->{$v}=
                               DateTime::SpanSet->from_spans(spans=>[$span]);
                        }
                        else{
                           $self->{stats}->{$group}->{$key}->{$v}=
                           $self->{stats}->{$group}->{$key}->{$v}->union($span);
                        }
                     }
                     else{
                        printf STDERR ("ERROR: %s\n",$@);
                        printf STDERR ("ERROR: eventstart=$val[0]\n");
                        printf STDERR ("ERROR: eventend  =$val[1]\n");
                        printf STDERR ("ERROR: key       =$key\n");
                        printf STDERR ("ERROR: group     =$group\n");
                       # exit(1);
                     }
                  }
               }
               $isAlreadyCounted{$key}++;
            }
            if ((!$param->{nosplit}) && $key=~m/\.[^\.]+$/){
               $key=~s/\.[^\.]+$//;
               $level++;
            }
            else{
               last;
            }
            last if (defined($maxlevel) && $level>$maxlevel);
         }
      }
   }
}




1;
