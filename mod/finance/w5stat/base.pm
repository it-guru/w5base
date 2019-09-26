package finance::w5stat::base;
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
use Data::Dumper;
use kernel;
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getPresenter
{
   my $self=shift;

   my @l=(
          'custcontract'=>{
                         opcode=>\&displayCustContract,
                         overview=>\&overviewCustContract,
                         group=>['Group'],
                         prio=>2000,
                      }
         );

}



sub overviewCustContract
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my $keyname='FIN.CustContract.Count';
   if (defined($primrec->{stats}->{$keyname})){
      my $color="black";
      my $delta=$app->calcPOffset($primrec,$hist,$keyname);
      push(@l,[$app->T('Count of Customer Contract Config-Items'),
               $primrec->{stats}->{$keyname}->[0],$color,$delta]);
   }

   return(@l);
}

sub displayCustContract
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"FIN.CustContract.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcCustCon",$data,
                   employees=>$user,
                   label=>$app->T('Customer contracts'),
                   legend=>$app->T('count of customer contracts'));
   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.custcontract",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'finance'
                              });
   return($d);
}



sub processData
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my ($year,$month)=$dstrange=~m/^(\d{4})(\d{2})$/;
   my $count;

   return() if ($statstream ne "default");


   my $appl=getModuleObject($self->getParent->Config,"finance::custcontract");
   $appl->SetCurrentView(qw(ALL));
   $appl->SetFilter({cistatusid=>'<=4'});
   $appl->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of finance::custcontract");$count=0;
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'finance::custcontract',
                                         $dstrange,$rec,%param);
         ($rec,$msg)=$appl->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of finance::custcontract  $count records");

}


sub processRecord
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $monthstamp=shift;
   my $rec=shift;
   my %param=@_;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;

   return() if ($statstream ne "default");

   if ($module eq "finance::custcontract"){
      my $name=$rec->{name};
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{responseteam}],{},
                                        "FIN.CustContract.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "FIN.Total.CustContract.Count",1);
      }
   }
}


1;
