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
use kernel::FlashChart;
use DateTime;
use DateTime::Span;
use DateTime::SpanSet;
use kernel::MenuTree;
use POSIX qw(floor);
use IO::File;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::FlashChart);

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
                label         =>'W5BaseID',
                dataobjattr   =>'w5stat.id'),
                                                  
      new kernel::Field::Text(
                name          =>'sgroup',
                label         =>'Statistic Group',
                selectfix     =>1,
               # value         =>['Mandator','Group',
               #                  'Application','Location','User',
               #                  'Contract','Costcenter'],
                dataobjattr   =>'w5stat.statgroup'),

      new kernel::Field::Text(
                name          =>'statstream',
                label         =>'Statistic Stream',
                selectfix     =>1,
               # value         =>['Mandator','Group',
               #                  'Application','Location','User',
               #                  'Contract','Costcenter'],
                dataobjattr   =>'w5stat.statstream'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Statistic Name',
                selectfix     =>1,
                dataobjattr   =>'w5stat.name'),

      new kernel::Field::Link(
                name          =>'nameid',
                label         =>'Statistic Name last ID',
                dataobjattr   =>'w5stat.nameid'),

      new kernel::Field::Text(
                name          =>'dstrange',
                label         =>'Month',
                selectfix     =>1,
                preparseSearch=>sub{
                   my $self=shift;
                   my $fltref=shift;

                   if (ref($fltref) eq "SCALAR"){
                      my $search=trim($$fltref);
                      if ($search=~m/^currentmonth$/i){
                         my ($year,$mon,$day)=Today_and_Now("GMT");
                         my $currentmonth=sprintf("%04d%02d",$year,$mon);
                         $$fltref=$currentmonth;
                      }
                      if ($search=~m/^currentweek$/i){
                         my ($year,$mon,$day)=Today_and_Now("GMT");
                         my ($week,$wyear)=Week_of_Year($year,$mon,$day);
                         my $currentweek=sprintf("%04dKW%02d",$wyear,$week);
                         $$fltref=$currentweek;
                      }
                   }
                },
                dataobjattr   =>'w5stat.monthkwday'),

      new kernel::Field::Link(
                name          =>'descdstrange',
                sqlorder      =>'desc',
                label         =>'Month',
                dataobjattr   =>'w5stat.monthkwday'),


      new kernel::Field::Container(
                name          =>'stats',
                group         =>'stats',
                desccolwidth  =>'200',
                uivisible     =>1,
                selectfix     =>1,
                label         =>'Statistic Data',
                dataobjattr   =>'w5stat.stats'),


      new kernel::Field::SubList(
                name          =>'statstreams',
                label         =>'StatStreams',
                readonly      =>1,
                group         =>'statstreams',
                htmldetail    =>'NotEmpty',
                vjointo       =>'base::w5stat',
                vjoinon       =>['fullname'=>'fullname'],
                vjoinonfinish =>sub{
                   my $self=shift;
                   my $flt=shift;
                   my $current=shift;
                   my $mode=shift;

                   my $sgroup=$current->{sgroup};
                   my $dstrange=$current->{dstrange};
                   my $fullname=$current->{fullname};
                   $flt->{sgroup}=\$sgroup;
                   $flt->{dstrange}=\$dstrange;
                   $flt->{fullname}=\$fullname;
                   $flt->{statstream}="!default";

                   return($flt);
                },
                vjoindisp     =>['statstream','stats'],
                vjoininhash   =>['statstream','stats','sgroup','mdate']),


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

      new kernel::Field::Link(
                name          =>'nameid',
                group         =>'source',
                label         =>'NameID',
                dataobjattr   =>'w5stat.nameid'),

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
   $self->LoadSubObjs("w5stat","w5stat");
   $self->setDefaultView(qw(statstream 
                            dstrange sgroup fullname mdate));
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

   my @groups=("header","default","source");

   if ($self->IsMemberOf(["admin",
                          "w5base.w5stat.read","w5base.base.w5stat.read"])){
      push(@groups,"stats");
   }
   if ($rec->{statstream} eq "default"){
      push(@groups,"statstreams");
   }
   return(@groups)
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
   return("header","default","stats","statstreams","source");
}


sub loadLateModifies
{
   my $self=shift;
   my $statstream=shift;
   my $excldst=shift;

   msg(INFO,"==== load late master overwrite data ====");
   my $stat=getModuleObject($self->Config,"base::w5stat");
   my $mst=getModuleObject($self->Config,"base::w5statmaster");
   $mst->SetFilter({mdate=>">now-3d"});
   $mst->SetCurrentView(qw(dstrange sgroup fullname dataname dataval));
   delete($self->{stats});
   my $olddstrange;
   my ($rec,$msg)=$mst->getFirst();
   if (defined($rec)){
      do{
         my $qdstrange=quotemeta($rec->{dstrange});
         if (!grep(/^$qdstrange$/,@$excldst)){
            if ($olddstrange ne $rec->{dstrange}){
               if (defined($self->{stats})){
                  $self->_storeStats($olddstrange);
                  delete($self->{stats});
               }
               $olddstrange=$rec->{dstrange};
            }
            if (!defined($self->{stats}) || 
                !exists($self->{stats}->{$rec->{sgroup}}->{$rec->{fullname}})){
               $stat->ResetFilter();
               $stat->SetFilter({dstrange=>\$rec->{dstrange},
                                 fullname=>\$rec->{fullname},
                                 sgroup=>\$rec->{sgroup}});
               my ($oldrec,$msg)=$stat->getOnlyFirst(qw(ALL));
               if (defined($oldrec)){
                  my %stats=Datafield2Hash($oldrec->{stats});
                  my $stats=CompressHash(\%stats);
                  $self->{stats}->{$oldrec->{sgroup}}->{$oldrec->{fullname}}=
                                          $stats;
               }
           
            }
            $self->storeStatVar($rec->{sgroup},$rec->{fullname},
                                {maxlevel=>0,method=>'set'},
                                $rec->{dataname},$rec->{dataval});
         }
         ($rec,$msg)=$mst->getNext();
      } until(!defined($rec));
   }
   if (defined($self->{stats})){
      #printf STDERR ("stats=%s\n",Dumper($self->{stats}));
      $self->_storeStats($statstream,$olddstrange);
      delete($self->{stats});
   }
}


sub recreateStats
{
   my $self=shift;
   my $statstream=shift;
   my $mode=shift;
   my $module=shift;
   my $dstrangestamp=shift;
   my ($year,$mon,$day, $hour,$min,$sec) = Today_and_Now("GMT");
   my $currentmonth=sprintf("%04d%02d",$year,$mon);
   my ($week,$wyear)=Week_of_Year($year,$mon,$day);
   my $currentweek=sprintf("%04dKW%02d",$wyear,$week);


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

   msg(INFO,"starting recreateStats for:");
   msg(INFO,"===========================");
   msg(INFO,"current=$currentmonth,$currentweek");
   msg(INFO,"dsttirange=$dstrangestamp");
   delete($self->{stats});
   #return(1);

   my $basespan;
   my $baseduration;
   if (my ($year,$month)=$dstrangestamp=~m/^(\d{4})(\d{2})$/){
      my $d1=new DateTime(year=>$year, month=>$month, day=>1,
                          hour=>0, minute=>0, second=>0,
                          time_zone=>'GMT');
      my $dm=DateTime::Duration->new( months=>1);
    
      my $d2=$d1+$dm;
      eval('$basespan=DateTime::Span->from_datetimes(start=>$d1,end=>$d2);');
      if ($@ eq ""){
         $baseduration=CalcDateDuration($d1,$d2);
      }
   }
   elsif (my ($wyear,$week)=$dstrangestamp=~m/^(\d{4})[CK]W(\d{2})$/){
      my ($syear,$smon,$sday)=Monday_of_Week($week,$wyear);
      my $d1=new DateTime(year=>$syear, month=>$smon, day=>$sday,
                          hour=>0, minute=>0, second=>0,
                          time_zone=>'GMT');
      my $dm=DateTime::Duration->new( days=>7);
    
      my $d2=$d1+$dm;
      eval('$basespan=DateTime::Span->from_datetimes(start=>$d1,end=>$d2);');
      if ($@ eq ""){
         $baseduration=CalcDateDuration($d1,$d2);
      }
   }

   msg(INFO,"w5stat statstream: $statstream");
   msg(INFO,"w5stat mode: $mode");
   msg(INFO,"registered w5stat Modules: ".
            join(", ",sort(keys(%{$self->{$mode}}))));


   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processDataInit")){
         my %param;
         if ($obj->Self eq $module || $module eq "*" || !defined($module)){
            if (!$obj->{InitIsDone}){
               $obj->processDataInit($statstream,$dstrangestamp,%param);
            }
            $obj->{InitIsDone}++;
         }
      }
   }
   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processData")){
         my %param;
         $param{currentmonth}=$currentmonth if (defined($currentmonth));
         $param{currentweek}=$currentweek if (defined($currentweek));
         $param{basespan}=$basespan if (defined($basespan));
         $param{baseduration}=$baseduration if (defined($baseduration));
         if ($obj->Self eq $module || $module eq "*" || !defined($module)){
            $obj->processData($statstream,$dstrangestamp,%param);
         }
      }
   }
   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processDataFinish")){
         my %param;
         if ($obj->Self eq $module || $module eq "*" || !defined($module)){
            if ($obj->{InitIsDone}){
               $obj->processDataFinish($statstream,$dstrangestamp,%param);
            }
         }
      }
   }
   #
   # insert overwrite data
   #
   msg(INFO,"==== load master overwrite data ====");
   my $mst=getModuleObject($self->Config,"base::w5statmaster");
   $mst->SetFilter({dstrange=>\$dstrangestamp});
   $mst->SetCurrentOrder(qw(NONE));
   $mst->SetCurrentView(qw(dstrange sgroup fullname dataname dataval));
   my ($rec,$msg)=$mst->getFirst();
   if (defined($rec)){
      do{
         #print STDERR ("fifi rec=%s\n",Dumper($rec));
         $self->storeStatVar($rec->{sgroup},$rec->{fullname},
                             {maxlevel=>0,method=>'set'},
                             $rec->{dataname},$rec->{dataval});

         ($rec,$msg)=$mst->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"====================================");
   $self->_storeStats($statstream,$dstrangestamp,$baseduration,$basespan);

   


   return(1);
}


sub _storeStats
{
   my $self=shift;
   my $statstream=shift;
   my $dstrangestamp=shift;
   my $baseduration=shift;
   my $basespan=shift;

   foreach my $group (keys(%{$self->{stats}})){
      foreach my $name (keys(%{$self->{stats}->{$group}})){
         if (defined($baseduration) && defined($basespan)){
            foreach my $v (keys(%{$self->{stats}->{$group}->{$name}})){
               if (ref($self->{stats}->{$group}->{$name}->{$v}) eq "ARRAY"){
                  # use as is
               }
               elsif (ref($self->{stats}->{$group}->{$name}->{$v}) eq "HASH"){
                  my $method=$self->{stats}->{$group}->{$name}->{$v}->{method};
                  if ($method eq "avg"){
                     my @l;
                     if (ref($self->{stats}->{$group}->{$name}->{$v}->{data}) 
                         eq "ARRAY"){
                        @l=@{$self->{stats}->{$group}->{$name}->{$v}->{data}};
                     }
                     my $n=$#l+1;
                     my $s=0;
                     map({$s+=$_;} @l);
                     if ($n>0){
                        $self->{stats}->{$group}->{$name}->{$v}=$s/$n;
                     }
                     else{
                        $self->{stats}->{$group}->{$name}->{$v}=0;
                     }
                  }
                  elsif ($method eq "ucount"){
                     my $n="?";
                     my $data=$self->{stats}->{$group}->{$name}->{$v}->{data};
                     if (ref($data) eq "HASH"){
                        $n=keys(%{$data});
                     }
                     $self->{stats}->{$group}->{$name}->{$v}=$n;
                  }
                  else{
                     $self->{stats}->{$group}->{$name}->{$v}="bad data";
                  }
               }
               elsif (ref($self->{stats}->{$group}->{$name}->{$v})){
                  my $spanobj=$self->{stats}->{$group}->{$name}->{$v};
                  if (!defined($spanobj) || !ref($spanobj)){
                     #printf STDERR ("spanobj=$spanobj\n");
                     Stacktrace();
                  }
                  eval('$spanobj=$spanobj->intersection($basespan);');
                  if ($@ ne ""){
                     printf STDERR ("error=%s\n",$@);
                     printf STDERR ("spanobj=%s\n",Dumper($spanobj));
                     Stacktrace();
                  } 
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
                  $self->{stats}->{$group}->{$name}->{$vv}=
                                                        sprintf('%.4f',$minsum);
                  my $vv=$v.".max";
                  $self->{stats}->{$group}->{$name}->{$vv}=
                                                        sprintf('%.4f',$minmax);
                  my $vv=$v.".base";
                  $self->{stats}->{$group}->{$name}->{$vv}=sprintf('%.4f',
                                                $baseduration->{totalminutes});
                  delete($self->{stats}->{$group}->{$name}->{$v});
               }
            }
         }
         my $nameid;
         if (defined($self->{stats}->{$group}->{$name}->{nameid})){
            $nameid=$self->{stats}->{$group}->{$name}->{nameid};
            delete($self->{stats}->{$group}->{$name}->{nameid});
         }
         my $statrec={stats=>$self->{stats}->{$group}->{$name},
                      sgroup=>$group,
                      statstream=>$statstream,
                      dstrange=>$dstrangestamp,
                      nameid=>$nameid,
                      fullname=>$name};
         $self->Trace("Store w5stat-Record:");
         $self->Trace(" dstrange: ".$statrec->{dstrange});
         $self->Trace(" fullname: ".$statrec->{fullname});
         $self->Trace(" sgroup  : ".$statrec->{sgroup});
         foreach my $k (sort(keys(%{$statrec->{stats}}))){
            next if (ref($statrec->{stats}->{$k}));
            $self->Trace("   stat($k) = $statrec->{stats}->{$k}");
         }
         my $flt={sgroup=>\$statrec->{sgroup},
                  dstrange=>\$dstrangestamp,
                  statstream=>\$statstream,
                  fullname=>\$statrec->{fullname}};
         $self->SetFilter($flt);
         my ($oldrec,$msg)=$self->getOnlyFirst(qw(ALL));
         if (defined($oldrec)){
            $self->ValidatedUpdateRecord($oldrec,$statrec,$flt);
         }
         else{
            $self->ValidatedInsertRecord($statrec);
         }
      }
   }
   delete($self->{stats});
}


sub processRecord
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;
   my %param=@_;

   foreach my $obj (values(%{$self->{w5stat}})){
      if ($obj->can("processRecord")){
         $obj->processRecord($statstream,$module,$month,$rec,%param); 
      }
   }
}

sub setTraceFile
{
   my $self=shift;
   my $filename=shift;
   if ($filename ne ""){
      $self->{TRACEFILE}=$filename;
   }
   else{
      delete($self->{TRACEFILE});
   }
}

sub Trace
{
   my $self=shift;
   my $text=shift;

   if ($self->{TRACEFILE}){
      if (!exists($self->{TRACEFILE_fh})){
         my $fh=new IO::File();
         if (! -f $self->{TRACEFILE}){
            if ($fh->open(">".$self->{TRACEFILE})){
               $fh->autoflush();
               $self->{TRACEFILE_fh}=$fh;
            }
         }
         else{
            if ($fh->open(">>".$self->{TRACEFILE})){
               $fh->autoflush();
               $self->{TRACEFILE_fh}=$fh;
            }
         }
      }
      my $FH=$self->{TRACEFILE_fh};
      $text=~s/\n/\r\n/gs;
      printf $FH ("%-10s %s\r\n",$text);
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
   my $nameid=$param->{nameid};
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

   my %isAlreadyCounted=(); 
   foreach my $key (@key){
      my $level=0;
      if ($var ne ""){
         while(1){
            if ($key ne "" && !defined($isAlreadyCounted{$key})){
               if (defined($nameid) && $level==0){
                  $self->{stats}->{$group}->{$key}->{nameid}=$nameid;
               }
               if (lc($method) eq "set"){
                  $self->{stats}->{$group}->{$key}->{$var}=$val[0];
               }
               if (lc($method) eq "count"){
                  $self->Trace("$group:$key $var +=$val[0]");
                  $self->{stats}->{$group}->{$key}->{$var}+=$val[0];
               }
               if (lc($method) eq "gavg"){
                  $self->{stats}->{$group}->{$key}->{$var}+=$val[0];
                  if ($self->{stats}->{$group}->{$key}->{$var}>0){
                     $self->{stats}->{$group}->{$key}->{$var}=
                        ($self->{stats}->{$group}->{$key}->{$var}+$val[0])/2;
                  }
                  else{
                     $self->{stats}->{$group}->{$key}->{$var}=$val[0];
                  }
               }
               if (lc($method) eq "avg"){
                  if (ref($self->{stats}->{$group}->{$key}->{$var}) ne "HASH"){
                     $self->{stats}->{$group}->{$key}->{$var}={};
                  }
                  $self->{stats}->{$group}->{$key}->{$var}->{method}="avg";
                  if (ref($self->{stats}->{$group}->{$key}->{$var}->{data}) ne
                      "ARRAY"){
                     $self->{stats}->{$group}->{$key}->{$var}->{data}=[];
                  }
                  push(@{$self->{stats}->{$group}->{$key}->{$var}->{data}},
                       $val[0]);
               }
               if (lc($method) eq "concat"){
                  if ($self->{stats}->{$group}->{$key}->{$var} ne ""){
                     $self->{stats}->{$group}->{$key}->{$var}.=", ";
                  }
                  $self->{stats}->{$group}->{$key}->{$var}.=$val[0];
               }
               if (lc($method) eq "ucount"){
                  if (!defined($self->{stats}->{$group}->{$key}->{$var})){
                     $self->{stats}->{$group}->{$key}->{$var}={
                        method=>'ucount',
                        data=>{}
                     };
                  }
                  $self->{stats}->{$group}->{$key}->{$var}->{data}->{$val[0]}++;
               }
               if (lc($method) eq "add"){
                  if (!defined($self->{stats}->{$group}->{$key}->{$var})){
                     $self->{stats}->{$group}->{$key}->{$var}=[];
                  }
                  if (ref($self->{stats}->{$group}->{$key}->{$var}) ne 
                      "ARRAY"){
                     $self->{stats}->{$group}->{$key}->{$var}=[
                        $self->{stats}->{$group}->{$key}->{$var}];
                  }
                  push(@{$self->{stats}->{$group}->{$key}->{$var}},$val[0]);
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

sub getValidWebFunctions
{
   my $self=shift;
   return("Presenter","ShowEntry",
          $self->SUPER::getValidWebFunctions());
}


sub ShowEntry
{
   my $self=shift;
   my $id=shift;
   my $tag=shift;

   my $requestid;
   my $requesttag;
   if ($id ne ""){
      $requestid=$id;
      if (defined($tag)){
         $requesttag=$tag;
      }
   }
   else{
      my $FunctionPath=Query->Param("FunctionPath");
      if ($FunctionPath ne ""){
         if (my ($requestid,$requesttag)=$FunctionPath=~m/\/(\d+)\/(.*)$/){
            $self->HtmlGoto("../../ShowEntry",
                            post=>{
                               id=>$requestid,
                               tag=>$requesttag
                            });
            return();
         }
      }
      $requestid=Query->Param("id");
      $requesttag=Query->Param("tag");
   }


   my ($rmod,$rtag)=$requesttag=~m/^(.*)::([^:]+)$/;
   my $title=$self->T("W5Base Statistic Presenter");
   my $subtitle=$self->T($requesttag."::LONG",$rmod);
   if ($subtitle eq $requesttag."::LONG"){
      $subtitle=$self->T($requesttag,$rmod);
   }
   $subtitle="" if ($requesttag eq "ALL");
   $title.=" - ".$subtitle;
   my $MinReportUserGroupCount=$self->Config->Param("MinReportUserGroupCount");
   $MinReportUserGroupCount=int($MinReportUserGroupCount);
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','w5stat.css'],
                           js=>['toolbox.js','subModal.js','OutputHtml.js',
                                'jquery.js','jquery.segbar.js',
                                'Chart.min.js',
                                'sortabletable.js',
                                'sortabletable_sorttype_idate.js'],
                           body=>1,form=>1,
                           title=>$title);

   my ($primrec,$hist)=$self->LoadStatSet(id=>$requestid);

   if (defined($primrec)){
      my $load=$self->findtemplvar({current=>$primrec,
                                    mode=>"HtmlV01"},"mdate","formated");
      my $month=$primrec->{dstrange};
      my $condition=$self->T("condition");
      my $label;
      if (my ($Y,$M)=$month=~m/^(\d{4})(\d{2})$/){
         $label="$M/$Y";
      }
      elsif (my ($Y,$W)=$month=~m/^(\d{4})KW(\d{2})$/){
         $label="$Y/KW$W";
      }

      print(<<EOF);
<input type=hidden name=id value="$requestid">
<input type=hidden name=tag value="$requesttag">
EOF
      my $ucnt;
      $ucnt=$primrec->{stats}->{User} if (ref($primrec) eq "HASH" &&
                                    ref($primrec->{stats}) eq "HASH");
      $ucnt=$ucnt->[0] if (ref($ucnt) eq "ARRAY");

      my $htmlReport="";


      if (defined($ucnt) && $ucnt<$MinReportUserGroupCount &&
          $primrec->{nameid}>=2 &&
          !$self->IsMemberOf("admin")){
         $htmlReport.=sprintf("<br><hr><b>");
         $htmlReport.=sprintf($self->T("Access to this report is not granted, ".
                         "because the minimum count of analysed ".
                         "users of %d is not reached."),
                $MinReportUserGroupCount);
         $htmlReport.=sprintf("</b><hr>");
      }
      else{
         if ($requesttag ne ""){
            my @Presenter;
            foreach my $obj (values(%{$self->{w5stat}})){
               if ($obj->can("getPresenter")){
                  my %P=$obj->getPresenter();
                  foreach my $p (values(%P)){
                     $p->{module}=$obj->Self();
                     $p->{obj}=$obj;
                  }
                  push(@Presenter,%P);
               }
            }
            my %P=@Presenter;

     
            foreach my $p (sort({$P{$a}->{prio} <=> $P{$b}->{prio}} keys(%P))){
               if ((in_array($P{$p}->{group},$primrec->{sgroup}) ||
                    $p eq "overview") &&
                   defined($P{$p}->{opcode}) && 
                   ($rtag eq $p || $requesttag eq "ALL")){
                  my ($d,$ovdata)=
                         &{$P{$p}->{opcode}}($P{$p}->{obj},$primrec,$hist,$p);
                  if ($requesttag eq "ALL"){
                      my $requesttag=$P{$p}->{module}."::".$p;
                      if ($requesttag ne "base::w5stat::overview::overview" &&
                          $d ne ""){
                         my ($rmod,$rtag)=$requesttag=~m/^(.*)::([^:]+)$/;
                         my $subtitle=$self->T($requesttag."::LONG",
                                          $P{$p}->{module});
                         if ($subtitle eq $requesttag."::LONG"){
                            $subtitle=$self->T($requesttag,$P{$p}->{module});
                         }
            
                         $htmlReport.="<hr style=\"width:50%;margin-top:40px;".
                                      "margin-bottom:20px;page-break-before:always\">".
                                      "<div class=chartsublabel ".
                                      "style=\"margin-bottom:20px\">".
                                      $subtitle."</div>";
                      }
                  }
                  $htmlReport.=$d;
               }
            }
         }
      }
      if ($htmlReport ne ""){
         print("<div id=reportFrame>".
               "<div class=chartlabel>".
               "Quality Report $label - $primrec->{fullname}".
               "</div>".
               "<div class=chartsublabel>".
               "<a href=\"ShowEntry/$requestid/$requesttag\" target=_blank>".
               "$subtitle".
               "</a>".
               "</div>");
         print $htmlReport;
         if ($requesttag eq "base::w5stat::overview::overview" ||
             $requesttag eq "ALL"){
            print("<div class=condition>$condition: $load</div>");
         }
         print("</div>");
      }
   }
   my $d="";
   $d.="<script language=JavaScript>\n";
   $d.="function InitSortTables(){\n";
   $d.=" var elements=document.getElementsByClassName('sortableTable');\n";
   $d.=" for(var i=0;i<elements.length;i++){\n";
   $d.="  var cols=['String','String','String','String','String'];\n";
   $d.="  var s=SortTableResultTable=new SortableTable(elements[i],cols);\n";
   $d.=" }\n";
   $d.="}\n";
   $d.="addEvent(window,\"load\",InitSortTables);";
   $d.="</script>\n";
   $d.="<script language=JavaScript>\n";
   $d.="addEvent(window,\"load\",add_clipIconFunc);\n";
   $d.="</script>\n";
   print $d;
#   $d.="
#         $d.="function InitTabResultTable(){\n";
#      $d.="SortTableResultTable=new SortableTable(".
#          "document.getElementById(\"ResultTable\"), [$sortline]);\n";

   print $self->HtmlBottom(body=>1,form=>1);
}


sub LoadStatSet
{
   my $self=shift;
   my $type=shift;
   my $id=shift;
   my $month=shift;

   $self->ResetFilter();
   if ($type eq "id"){
      $self->SecureSetFilter({id=>\$id});
   }
   if ($type eq "grpid"){
      $self->SecureSetFilter({
         sgroup=>\'Group',
         nameid=>\$id,
         statstream=>\'default',
         dstrange=>\$month
      });
   }
   my ($primrec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (defined($primrec)){
      if (ref($primrec->{stats}) ne "HASH"){
         $primrec->{stats}={Datafield2Hash($primrec->{stats})};
      }
      my $dstrange=$primrec->{dstrange};




      my $lastrange=undef;
      my @histrange=();


      my ($Y,$M,$D,$year,$week,$baseRange);

      if (($Y,$M)=$dstrange=~m/^(\d{4})(\d{2})$/){
         ($week,$year)=Week_of_Year($Y,$M,1);
         $week++;
         $baseRange="M";
      }
      else{
         if (($year,$week)=$dstrange=~m/^(\d{4})KW(\d{2})$/){
            $week--;
            ($Y,$M,$D)=Monday_of_Week($week,$year);
            $baseRange="W";
         }
      }
      if (defined($baseRange)){
         my ($Y1,$M1)=($Y,$M);
         for(my $c=0;$c<=6;$c++){
            $M1++;
            if ($M1>12){
               $Y1++;
               $M1=1;
            }
            push(@histrange,sprintf("%04d%02d",$Y1,$M1));
         }
         my $minweek=$week-8;
         my $maxweek=$week+8;
         $minweek=1 if ($minweek<1);
         $maxweek=56 if ($maxweek>56);
         for(my $kw=$minweek;$kw<=$maxweek;$kw++){
            push(@histrange,sprintf("%04dKW%02d",$Y,$kw));
         }
         if ($baseRange eq "M"){
            $M--;
         }
         if ($M<=0){
            $M=12;
            $Y--;
         }
         $lastrange=sprintf("%04d%02d",$Y,$M);
         push(@histrange,$lastrange);
         for(my $l=0;$l<6;$l++){
            $M--;
            if ($M<=0){
               $M=12;
               $Y--;
            }
            push(@histrange,sprintf("%04d%02d",$Y,$M));
         }
      }
      push(@histrange,$dstrange);

      my @fltlist=({fullname=>\$primrec->{'fullname'},
                    sgroup=>\$primrec->{'sgroup'},
                    statstream=>\'default',
                    dstrange=>\@histrange});

      if (defined($primrec->{'nameid'})){
         push(@fltlist,{
            nameid=>\$primrec->{'nameid'},
            sgroup=>\$primrec->{'sgroup'},
            statstream=>\'default',
            dstrange=>\@histrange
         });
      }

      my $r=ObjectRecordCodeResolver(\@fltlist);
      #print STDERR Dumper($r);

      my %srec;
      my $hist={area=>[]};
      my $cntrec=0;
      foreach my $flt (@fltlist){
         $self->ResetFilter();
         $self->SecureSetFilter($flt);
         $self->SetCurrentOrder("NONE");
         foreach my $srec ($self->getHashList(qw(ALL))){
            $cntrec++;
            if (!exists($srec{$srec->{id}})){
               if (ref($srec->{stats}) ne "HASH"){
                  $srec->{stats}={Datafield2Hash($srec->{stats})};
               }
               push(@{$hist->{area}},$srec);
               if (defined($lastrange)){
                  if ($lastrange eq $srec->{dstrange}){
                     $hist->{lastdstrange}=$srec;
                  }
               }
               $srec{$srec->{id}}++;
            }
         }
      }
      if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
         msg(INFO,"loaded $cntrec records for $id");
      }
      return($primrec,$hist);

   }
   return($primrec,[]);
}


   sub getLabelString
   {
      my $histid=shift;
      my $M1=shift;
      my $Y1=shift;
      my $curM=shift;
      my $curY=shift;
      my $KWyear=shift;
      my $KWweek=shift;
      my $k=sprintf("%04d%02d",$Y1,$M1);
      my $style="";
      my $cw;

      if ($M1==$curM && $Y1==$curY){
         $style="border-color:black;border-width:1px;border-style:solid";
         my ($sY,$sM,$sD)=Add_Delta_YMD("GMT",$curY,$curM,1,0,0,-30);
         for(my $w=0;$w<10;$w++){
            my $wstyle;
            ($sY,$sM,$sD)=Add_Delta_YMD("GMT",$sY,$sM,$sD,0,0,7);
            my ($week,$year)=Week_of_Year($sY,$sM,$sD);
            if ($week==$KWweek && $year==$KWyear){
               $wstyle=$style;
            }
            $cw.=" - " if ($cw ne "");
            my $tag=sprintf("%04dKW%02d",$year,$week);
            my $frond=sprintf("KW%02d",$week);
            if (defined($histid->{$tag})){
               $cw.="<a class=sublink style=\"$wstyle\" ".
                    "href=javascript:refreshTag($histid->{$tag})>$frond</a>";
            }
            else{
               $cw.="<font color=silver>$frond</font>";
            }
         }
      }
      my $ms;
      if (defined($histid->{$k})){
         $ms=sprintf("<td align=center style=\"$style\">".
                 "<a class=sublink href=javascript:refreshTag($histid->{$k})>".
                 "%02d/%4d</a></td>",$M1,$Y1);
      }
      else{
         $ms=sprintf("<td align=center><font color=silver>%02d/%4d</font></td>",
                     $M1,$Y1);
      }
      return($ms,$cw);
      
   }


sub Presenter
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   my $rootpath=Query->Param("RootPath");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['menu.css','default.css'],
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1,action=>'../ShowEntry',
                           prefix=>$rootpath,
                           title=>"W5Base Statistik Presenter");
   print $self->HtmlSubModalDiv(prefix=>$rootpath);
   print("<style>body{overflow:hidden}</style>");

   my $requestid=$p;
   $requestid=~s/[^\d]//g;
   my $search_name=Query->Param("search_name");
   if ($search_name ne ""){
      my $name=$search_name;
      my $statname;
      my $statgrp;
      if (my ($g,$n)=$name=~m/^([^:]+)\s*:\s*(.*$)/){
         $statname=$n;
         $statgrp=$g;
      }
      else{
         $statgrp="Group";
         $statname=$name;
      }
      $statname=~s/[\*\?]//g;
      $statgrp=~s/[\*\?]//g;
      $self->ResetFilter();
      if ($statname=~m/\s/){
         $statname='"'.$statname.'"';
      }
      $self->SetFilter({
         fullname=>$statname,
         sgroup=>$statgrp,
         dstrange=>"!*KW*",
         statstream=>\'default'
      });
      $self->Limit(10);
      my @l=$self->getHashList(qw(-dstrange sgroup id));
      if ($#l!=-1){
         $requestid=$l[0]->{id};
      }
   }
   if (Query->Param("id") ne ""){
      my $id=Query->Param("id");
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($srec,$msg)=$self->getOnlyFirst(qw(id sgroup dstrange statstream
                                             fullname));
      if (defined($srec)){
         if ($srec->{statstream} ne "default"){
            $self->ResetFilter();
            $self->SetFilter({dstrange=>\$srec->{dstrange},
                              fullname=>\$srec->{fullname},
                              statstream=>\'default'});
            ($srec,$msg)=$self->getOnlyFirst(qw(id sgroup dstrange statstream
                                                fullname));
         }
         if (defined($srec)){
            $requestid=$srec->{id};
         }
      }
   }
   if ($requestid ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$requestid});
      my ($srec,$msg)=$self->getOnlyFirst(qw(id sgroup dstrange 
                                             statstream fullname));
      if (defined($srec)){
         Query->Param("search_name"=>$srec->{sgroup}.":".$srec->{fullname});
      }
   }
   my ($primrec,$hist)=$self->LoadStatSet(id=>$requestid);


   if (!defined($primrec) && $requestid ne ""){
      print "Requested Record '$requestid' not found";
      print $self->HtmlBottom(body=>1,form=>1);
      return();
   }
   print(<<EOF);
<script language="JavaScript">
function doPrint()
{
   window.frames['entry'].focus();
   window.frames['entry'].print();
}
</script>
EOF

   print("<table width=\"100%\" height=\"100%\" ".
         "cellspacing=0 cellpadding=0 border=0>");

   printf("<tr height=1%><td>");
   print $self->getAppTitleBar(prefix=>$rootpath,
                               title=>'W5Base Statistik Presenter');
   printf("</td></tr>");


   my %histid;
   my @ol;
   my ($Y,$M,$dstrange,$altdstrange);
   if (defined($primrec)){
      push(@ol,$primrec->{id},$primrec->{fullname});
      $dstrange=$primrec->{dstrange};
      ($Y,$M)=$dstrange=~m/^(\d{4})(\d{2})$/;
   }
   else{
      my ($year,$mon,$day) = Today_and_Now("GMT");
      my ($altyear,$altmon)= Add_Delta_YMD("GMT",$year,$mon,$day,0,-1,0);
      
      $Y=$year;
      $M=$mon;

      $dstrange=sprintf("%04d%02d",$year,$mon);
      $altdstrange=sprintf("%04d%02d",$altyear,$altmon);
      if (1){   # check if a group stat record is available for cherren month
         $self->ResetFilter();
         $self->SecureSetFilter({
            sgroup=>"Group",
            dstrange=>\$dstrange,
            statstream=>\'default'
         });
         $self->Limit(3);
         my @l=$self->getHashList(qw(-dstrange sgroup id));
         if ($#l==-1){
            $self->ResetFilter();
            $self->SecureSetFilter({
               sgroup=>"Group",
               dstrange=>"!*KW*",
               mdate=>'>now-3M',
               statstream=>\'default'
            });
            my @l=$self->getHashList(qw(-dstrange sgroup id));
            if ($#l==-1){
               print "<tr><td valign=top><br><b>".
                     $self->T("No statistic informations recorded").
                     "</b></td></tr>";
               print "</table>";
               print $self->HtmlBottom(body=>1,form=>1);
               return();
            }
            else{
               $dstrange=$l[0]->{dstrange};
               $altdstrange=$l[0]->{dstrange};
            }
         }
      }
   }


   my %StatSelBox;


   foreach my $obj (values(%{$self->{w5stat}})){
      if ($obj->can("getStatSelectionBox")){
         $obj->getStatSelectionBox(\%StatSelBox,$dstrange,$altdstrange);
      }
   }
   foreach my $k (keys(%StatSelBox)){
      if ( (!exists($StatSelBox{$k}->{prio})) ||
           (!exists($StatSelBox{$k}->{fullname})) ||
           (!exists($StatSelBox{$k}->{id}))){
         delete($StatSelBox{$k});
      }
   }

   my @StatSelBox=sort({
      $StatSelBox{$a}->{prio}<=>$StatSelBox{$b}->{prio}
   } keys(%StatSelBox));

   if (!defined($primrec) && $#StatSelBox!=-1){
      $requestid=$StatSelBox{$StatSelBox[0]}->{id};
      ($primrec,$hist)=$self->LoadStatSet(id=>$requestid);
   }

   print("<tr height=1%><td>");
   print("<table border=0 width=\"100%\" border=0><tr>\n");
   if ($self->IsMemberOf("admin")){
      print("<td width=320>");
      print("<table width=320 border=0 cellspacing=0 cellpadding=0><tr><td>");
      my $oldval=Query->Param("search_name"); 
      if ($oldval eq ""){
         $oldval=$primrec->{fullname};
      }
      print("<input type=text size=30 name=search_name value=\"$oldval\" ".
            "style=\"width:100%\">");
      print("</td><td width=1%><input type=submit value=\"find\" ".
            "onclick=\"refreshTag('');\"></td></tr>");
      print("</table>");
   }
   else{
      print("<td width=1%>");
      print("<select name=selid onchange=\"changeid(this);\" ".
            "style=\"width:320px\">");
      foreach my $k (@StatSelBox){
         my $label=$k;
         $label=~s/^Group://;
         my $sel="";
         if ($requestid eq $StatSelBox{$k}->{id}){
            $sel=" selected";
         }
         printf("<option value=\"%s\"%s>%s</option>",
                $StatSelBox{$k}->{id},$sel,$label);
      }
      print("</select>");
   }
   print("</td>");
   
   my $mstr="";
   my $cstr="";
   if (defined($primrec)){
      if (ref($hist) eq "HASH" && ref($hist->{area}) eq "ARRAY"){
         foreach my $h (@{$hist->{area}}){
            $histid{$h->{dstrange}}=$h->{id};
         }
      }
   }
   my ($KWyear,$KWweek);
   if (($KWyear,$KWweek)=$dstrange=~m/^(\d{4})KW(\d{2})$/){
      my ($yy,$mm,$dd)=Monday_of_Week($KWweek,$KWyear);
      $M=$mm;
      $Y=$yy;
   }
   my ($Y1,$M1)=($Y,$M);
   for(my $c=0;$c<=6;$c++){
      my ($ms,$cw)=getLabelString(\%histid,$M1,$Y1,$M,$Y,$KWyear,$KWweek);
      $mstr.=$ms;
      $cstr.=$cw;
      $M1++;
      if ($M1>12){
         $Y1++;
         $M1=1;
      }
   }
   my ($Y1,$M1)=($Y,$M);
   for(my $c=0;$c<6;$c++){
      $M1--;
      if ($M1<1){
         $Y1--;
         $M1=12;
      }
      my ($ms,$cw)=getLabelString(\%histid,$M1,$Y1,$M,$Y);
      $mstr=$ms.$mstr;
      $cstr=$cw.$cstr;
   }

   print($mstr."</tr></table>");
   printf("</td></tr>");


   printf("<tr><td valign=top>");

   print("<table width=\"100%\" height=\"100%\" ".
         "border=0 cellspacing=0 cellpadding=0>");
   printf("<tr height=1%%>");
   printf("<td valign=top></td>");
   printf("<td valign=top>");
   print("<table border=0 width=\"100%\" cellspacing=0 ".
         "cellpadding=0 border=0><tr>\n");
   printf("<td>".
          "<span class=sublink>".
          "<img border=0 style=\"margin-bottom:2px\" onclick=doPrint() ".
          "src=\"../../../../public/base/load/miniprint.gif\"></span>".
          "</td><td align=right>$cstr&nbsp;</td>");
   print("</tr></table>");

   printf("</td>");
   printf("</tr>");

   printf("<tr>");
   printf("<td valign=top width=1%>");

   my @Presenter;
   my $oldtag=Query->Param("tag");
   if (defined($primrec)){
      foreach my $obj (values(%{$self->{w5stat}})){
         if ($obj->can("getPresenter")){
            my %P=$obj->getPresenter();
            foreach my $p (values(%P)){
               $p->{module}=$obj->Self();
            }
            push(@Presenter,%P);
         }
      }
      $oldtag="base::w5stat::overview::overview" if ($oldtag eq "");
      my %P=@Presenter;

      my @ml;
      my $mid=0;
      my %dirindex;
      foreach my $p (sort({$P{$a}->{prio} <=> $P{$b}->{prio}} keys(%P))){
         if (exists($P{$p}->{group})){
            my $grprest=$P{$p}->{group};
            $grprest=[$grprest] if (ref($grprest) ne "ARRAY");
            if (!in_array($grprest,$primrec->{sgroup})){
               next;
            }
         }

         my $parent;
         if (defined($P{$p}->{opcode})){
            my $prec=$P{$p};
            my $opcode=$P{$p}->{opcode};
            my $show=&{$opcode}($self->{w5stat}->{$prec->{module}},
                                $primrec,undef,$p);
            if ($show){
               my %mrec;
               my $tag=$prec->{module}."::".$p;
           #    $mrec{fullname}=$self->T($tag,$prec->{module});
               $mrec{label}=$self->T($tag,$prec->{module});
               my @path=split(/;/,$mrec{label});
               my $targetml=\@ml;
               if ($#path>0){
                  $mrec{label}=$path[$#path];
                  for(my $l=0;$l<$#path;$l++){
                     my $fullpath=join(";",@path[0 .. $l]);
                     if (!defined($dirindex{$fullpath})){ 
                        my %pmrec=(label=>$path[$l],menuid=>$mid++,
                                   tree=>[],fullpath=>$fullpath);
                        $pmrec{label}=~s/ /&nbsp;/g;
                        $pmrec{label}.="&nbsp";
                        if (defined($parent)){
                           $pmrec{parent}=$parent;
                        }
                        push(@$targetml,\%pmrec);
                        $parent=\%pmrec;
                        $targetml=$pmrec{tree};
                        $dirindex{$fullpath}=\%pmrec;
                     }
                     else{
                        $parent=$dirindex{$fullpath};
                        $targetml=$dirindex{$fullpath}->{tree};
                     }
                  }
               }
               if (defined($parent)){
                  $mrec{parent}=$parent;
               }
               $mrec{label}=~s/ /&nbsp;/g;
               $mrec{label}.="&nbsp";
               $mrec{href}="javascript:setTag($requestid,\"$tag\")";
               $mrec{menuid}=$mid++;
               push(@$targetml,\%mrec);
            }
         }
      }
      print kernel::MenuTree::BuildHtmlTree(tree     => \@ml,
                     rootimg  =>'miniw5stat.gif',
                     hrefclass=>'menulink',
                     rootlink =>"javascript:setTag($requestid,\"ALL\")");
      

   }

   printf("</td>");
   print("<td valign=top style=\"padding-right:5px\">".
        "<iframe name=entry width=\"100%\" height=\"100%\" ".
        "src=\"../ShowEntry?id=$requestid&tag=$oldtag\">".
        "</iframe></td>");
   print ("</tr></table>");
   print ("</td></tr>");
   print ("</table>");
   print(<<EOF);
<input type=hidden name=id value="$requestid">
<input type=hidden name=tag value="$oldtag">
<script language="JavaScript">
function setTag(id,tag)
{
   document.forms[0].elements['id'].value=id;
   if (tag){
      document.forms[0].elements['tag'].value=tag;
   }
   document.forms[0].target="entry";
   document.forms[0].submit();
}
function refreshTag(id)
{
   if (id!=""){
      if (document.forms[0].elements['search_name']){
         document.forms[0].elements['search_name'].value="";
      }
      document.forms[0].elements['id'].value=id;
      document.forms[0].action="Presenter";
   }
   else{
      document.forms[0].elements['id'].value="";
      document.forms[0].action="Main"
   }
   document.forms[0].target="_self";
   document.forms[0].submit();
}
function changeid(bo)
{
   refreshTag(bo.value);
}
</script>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}


sub extractYear
{
   my $self=shift;
   my $primrec=shift;
   my $hist=shift;
   my $name=shift;    # if in name are more then one name (arrayref), there
   my %param=@_;      # will be checked in sequence of specified and first
                      # is used

   $name=[$name] if (ref($name) ne "ARRAY");

   my ($Y,$M)=$primrec->{dstrange}=~m/^(\d{4})(\d{2})$/;

   my %p;
   foreach my $hrec (@{$hist->{area}}){
      if ($hrec->{dstrange}=~m/^$Y/){
         $p{$hrec->{dstrange}}=$hrec;
      }
   }
   my @d;
   for(my $m=1;$m<=12;$m++){
      my $k=sprintf("%04d%02d",$Y,$m);
      if ($m<=$M){
         my $foundKpi=0;
         foreach my $nameChk (@$name){
            if (defined($p{$k}) && 
                ref($p{$k}->{stats}->{$nameChk}) eq "ARRAY" &&
                $p{$k}->{stats}->{$nameChk}->[0] ne ""){
               push(@d,$p{$k}->{stats}->{$nameChk}->[0]);
               $foundKpi++;
               last;
            }
         }
         if (!$foundKpi){
            if ($param{setUndefZero}){
               push(@d,0);
               
            }
            else{
               push(@d,undef);
            }
         }
      }
      else{
         push(@d,undef);
      }
   }
   return(\@d);
}

sub calcPOffset
{
   my $self=shift;
   my ($primrec,$hist,$name)=@_;
   my $delta;


   if (defined($hist->{lastdstrange})){
      $name=[$name] if (ref($name) ne "ARRAY");
      my $lst;
      my $cur;
      foreach my $keyname (@$name){
         my $curval;
         my $histval;
        
         my $curval=$primrec->{stats}->{$keyname};
         $curval=$curval->[0] if (ref($curval) eq "ARRAY"); 
         $cur+=$curval if ($curval>0);
         
         my $histval=$hist->{lastdstrange}->{stats}->{$keyname};
         $histval=$histval->[0] if (ref($histval) eq "ARRAY");
         $lst+=$histval if ($histval>0);
      }
      if (defined($lst) && defined($cur)){
         $delta=floor(($cur-$lst)*100.0/$lst);
         if ($delta!=0){
            if ($delta<0){
               $delta="$delta".'%'; 
            }
            else{
               $delta="+$delta".'%';
            }
         }
         else{
            $delta=undef;
         }
      }
   }
   return($delta);
}

sub getRecordImageUrl
{  
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/w5stat.jpg?".$cgi->query_string());
}
   
   







1;
