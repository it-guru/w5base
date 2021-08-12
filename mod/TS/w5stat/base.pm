package TS::w5stat::base;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
          'canvas'=>{
                         overview=>\&overviewCanvas,
                         group=>['Canvas'],
                         prio=>1000,
                      }
         );

}


sub getStatSelectionBox
{
   my $self=shift;
   my $selbox=shift;
   my $dstrange=shift;
   my $altdstrange=shift;
   my $app=$self->getParent();

   my $userid=$app->getCurrentUserId();
   my %groups=$app->getGroupsOf($userid,['REmployee','RBoss'],'direct');
   my @grpids=keys(%groups);

   if ($#grpids==-1){
      @grpids=(-99);
   }

   my $canvas=getModuleObject($app->Config,"TS::canvas");

   my @flt=(
      {
         cistatusid=>'3 4 5',
         databossid=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         leaderitid=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         leaderid=>\$userid
      },
   );


   $canvas->SetFilter(\@flt);
   my @l=$canvas->getHashList(qw(id name fullname));
   my @canvasname;
   my @canvasid;
   foreach my $r (@l){
      push(@canvasid,$r->{id});
      push(@canvasname,$r->{fullname});
      if (!exists($selbox->{'Canvas:'.$r->{fullname}})){
         $selbox->{'Canvas:'.$r->{fullname}}={
            prio=>'20000'
         };   
      }
   }

   $app->ResetFilter();
   $app->SetFilter([
                           {dstrange=>\$dstrange,sgroup=>\'Canvas',
                            fullname=>\@canvasname,statstream=>\'default'},
                           {dstrange=>\$dstrange,sgroup=>\'Canvas',
                            nameid=>\@canvasid,statstream=>\'default'},
                          ]);
   my @statnamelst=$app->getHashList(qw(fullname id));


   if ($#statnamelst==-1){   # seems to be the first day in month
      $app->ResetFilter();
      $app->SecureSetFilter([
                              {dstrange=>\$altdstrange,sgroup=>\'Canvas',
                               fullname=>\@canvasname},
                              {dstrange=>\$altdstrange,sgroup=>\'Canvas',
                               nameid=>\@canvasid},
                             ]);
      @statnamelst=$app->getHashList(qw(fullname id));
   }
   my $c=0;
   foreach my $r (sort({$a->{fullname} cmp $b->{fullname}} @statnamelst)){
      $c++;
      if (exists($selbox->{'Canvas:'.$r->{fullname}})){
         $selbox->{'Canvas:'.$r->{fullname}}->{fullname}=$r->{fullname};
         $selbox->{'Canvas:'.$r->{fullname}}->{id}=$r->{id};
         $selbox->{'Canvas:'.$r->{fullname}}->{prio}+=$c;
      }
   }
}


sub overviewCanvas
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;


   if ($primrec->{sgroup} eq "Canvas"){
      my $k="Appl.Count";
      my $label="Application Count";
      if (defined($primrec->{stats}->{$k})){
         my $val=$primrec->{stats}->{$k}->[0];
         my $color="black";
         push(@l,[$app->T($label),$val,$color,undef]);
      }
   }
   return(@l);
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


   my $canvas=getModuleObject($self->getParent->Config,"TS::canvas");
   $canvas->SetCurrentView(qw(ALL));
   $canvas->SetFilter({cistatusid=>'<=4'});
   $canvas->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of TS::canvas");$count=0;
   my ($rec,$msg)=$canvas->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'TS::canvas',$dstrange,$rec,%param);
         ($rec,$msg)=$canvas->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::canvas  $count records");

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

   if ($module eq "TS::canvas"){
      my $name=$rec->{name};
      if ($rec->{cistatusid}==4){
         my $applcount=$#{$rec->{applications}}+1;
         $self->getParent->storeStatVar("Canvas",[$rec->{fullname}],
                                        {nosplit=>1,
                                         nameid=>$rec->{id}},
                                        "Exist",1);
         $self->getParent->storeStatVar("Canvas",[$rec->{fullname}],
                                        {nosplit=>1,
                                         nameid=>$rec->{id}},
                                        "Appl.Count",$applcount);
      }
   }
}


1;
