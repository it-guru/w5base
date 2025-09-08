package itil::event::cleanup;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterEvent("Cleanup","CleanupServiceAndSupport");

   $self->RegisterEvent("ITIL_Cleanup","CleanupServiceAndSupport");
   $self->RegisterEvent("CleanupServiceAndSupport","CleanupServiceAndSupport");

   $self->RegisterEvent("CleanupMgmtItemGroup","CleanupMgmtItemGroup");
   $self->RegisterEvent("ITIL_Cleanup","CleanupMgmtItemGroup");
   return(1);
}


sub CleanupMgmtItemGroup
{
   my $self=shift;
   my $n=0;
   msg(INFO,"CleanupMgmtItemGroup");
   my $obj=getModuleObject($self->Config,"itil::lnkmgmtitemgroup");

   $obj->SetFilter({lnkto=>'<now-3M'});
   # drop Records with from and to older then three months
   my @l=$obj->getHashList(qw(ALL));

   my $n=$#l+1;
   if ($n>0){
      my $op=$obj->Clone();
      foreach my $rec (@l){
         $op->ValidatedDeleteRecord($rec);
      }
   }

   return({exitcode=>0,exitmsg=>"CleanupMgmtItemGroup count=$n"});
}


sub CleanupServiceAndSupport
{
   my $self=shift;
   msg(INFO,"ServiceAndSupport");


   my $obj=getModuleObject($self->Config,"itil::servicesupport");
   my $objop=$obj->Clone();


   my %flt;
   %flt=(mdate=>"<now-2M",cdate=>"<now-2M",cistatusid=>'4');

   my @fields=$obj->getFieldObjsByView([qw(ALL)]);

   foreach my $fld (@fields){
      if ($fld->{name}=~m/^usecount/){
         $flt{$fld->{name}}=\'0';
      }
   }

   msg(INFO,"Cleanup itil::servicesupport filter:".Dumper(\%flt)); 

   $obj->SetFilter(\%flt);
   $obj->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$obj->getFirst(unbuffered=>1);
   my $c=0;
   my %o;
   my $deletecount=0;
   if (defined($rec)){
      do{
         $W5V2::HistoryComments="marked as disposed of wasted ".
                                "because all usecounts are 0";
         if ($objop->ValidatedUpdateRecord($rec,{cistatusid=>'6'},{
                id=>$rec->{id}
             })){
            $deletecount++;
         }
         $W5V2::HistoryComments=undef;
         ($rec,$msg)=$obj->getNext();
      } until(!defined($rec));
   }


   return({exitcode=>0,msg=>"deletecount=>$deletecount"});
}



1;
