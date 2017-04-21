package tsacinv::Reporter::SAP_InstanceApplCheck;
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
use kernel::Reporter;
use File::Temp qw(tempfile);

@ISA=qw(kernel::Reporter);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{name}="AMCDS: Check SAP Instanz-Applications Parent References";
   $self->{fieldlist}=[qw(applid name pappl pvalidcnt)];
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(60,['6:30']);
}


sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;

   my $o=getModuleObject($self->Config,"tsacinv::appl");
   my $lnk=getModuleObject($self->Config,"tsacinv::lnkapplappl");

   $o->SetFilter({assignmentgroup=>'C.SAP C.SAP.*',
                  tenant=>\'CS',
                  status=>'!"out of operation"',
                  customer=>'DTAG.TEL-IT DTAG.TEL-IT.*'});
   my @fieldlist=grep(!/^p/,@{$self->{fieldlist}});
   my @l=$o->getHashList(@fieldlist);
   foreach my $arec (@l){
      $lnk->ResetFilter();
      $lnk->SetFilter({child_applid=>\$arec->{applid},
                       type=>\'SAP'}); 
      my @ll=$lnk->getHashList(qw(parent parent_applid));
      my @okll;
      if ($#ll!=-1){
         $o->ResetFilter();
         $o->SetFilter({applid=>[map({$_->{parent_applid}} @ll)],
                        srcsys=>\'W5Base'});
         @okll=$o->getHashList(qw(name));
      }
      $arec->{pappl}=join(", ",map({$_->{name}} @okll));
      $arec->{pvalidcnt}=$#okll+1;
   }


   foreach my $arec (@l){
      print(join(";",map({$arec->{$_}} @{$self->{fieldlist}}))."\n");
   } 
   return(0);
}

sub onChange
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $msg="";
   my $old=CSV2Hash($oldrec->{textdata},"applid");
   my $new=CSV2Hash($newrec->{textdata},"applid");
#   foreach my $applid (keys(%{$old->{applid}})){
#      next if ($new->{applid}->{$applid}->{pvalidcnt}>0);
#      if (!exists($new->{applid}->{$applid})){
#         my $m=$self->T('- not linked "%s" (ApplicationID:%s) has left the list');
#         $msg.=sprintf($m."\n",$old->{applid}->{$applid}->{name},$applid);
#         #$msg.="  ".join(",",
#         #    map({$_=$old->{id}->{$id}->{$_}} keys(%{$old->{id}->{$id}})));
#      }
#   }
   foreach my $applid (keys(%{$new->{applid}})){
      next if ($new->{applid}->{$applid}->{pvalidcnt}>0);
      if (!exists($old->{applid}->{$applid})){
         my $m=$self->T('+ not linked "%s" (ApplicationID:%s) has been added to the list');
         $msg.=sprintf($m."\n",$new->{applid}->{$applid}->{name},$applid);
      }
   }
   if ($msg ne ""){
      $msg="Dear W5Base User,\n\n".
           "the following changes where detected in the report:\n\n".
           $msg;
   }

   return($msg);
}

sub isViewValid
{
   my $reporter=shift;
   my $self=shift;
   my $rec=shift;

   return(1) if ($self->IsMemberOf("admin"));
   return(1) if ($self->IsMemberOf("DTAG.GHQ.VTI.DTIT",
                                   [qw(RCFManager RCFManager2
                                       RCHManager RCHManager2)],
                                   "up"));

   return(0);
}





1;
