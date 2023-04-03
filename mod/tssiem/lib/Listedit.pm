package tssiem::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB );

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   if (defined($self->{DB})){
      $self->{DB}->do("alter session set cursor_sharing=force");
   }
   if (defined($self->{DB})){
      $self->{DB}->{db}->{LongReadLen}=1024*1024*15;    #15MB
   }

   return(1) if (defined($self->{DB}));
   return(0);
}


sub getPerspectiveDecodeSQL
{
   my $self=shift;
   my $pref=shift;

   my $pCreate="reverse(".
                  "replace(".
                    "regexp_substr(".
                       "reverse(${pref}title),'_[^_]+_',1),'_',''".
                  ")".
               ")";

   my $pDecoded="decode($pCreate,".           # fixup for buggy namings
                "'vLAN','SharedVLAN',".
                "'vFWI','SharedVLAN',".
                "$pCreate)";
   my $PerspectiveDecode="case ".
                         "when $pDecoded like 'ICTO-%' ".  #ganz alte Convention
                         "then 'CNDTAG' ".
                         "else $pDecoded ".
                         "end";
   return($PerspectiveDecode);
}



sub getSecscanFromSQL
{
   my $self=shift;

   my $PerspectiveDecode=$self->getPerspectiveDecodeSQL("W5SIEM_secscan.");
   my $d="select W5SIEM_secscan.*,".
         #"decode(rank() over (partition by ictoid||($PerspectiveDecode) ".
         "decode(rank() over (partition by decode(w5baseid_appl,NULL,ictoid,w5baseid_appl)||($PerspectiveDecode) ".
         "order by launch_datetime desc),1,1,0) islatest,".
         "($PerspectiveDecode) scanperspective ".
         "from W5SIEM_secscan ".
         "where importdate is not null and ".  #only secscans with fine data
         "launch_datetime>current_date-100 ".  #Scan needs from last 100d
         "order by ictoid";

   return($d);
}


sub getMsgTrackingFlagSQL
{
   my $self=shift;
   my $PerspectiveDecode=$self->getPerspectiveDecodeSQL("secscan.");

   my $sql="(case ".
           "when ($PerspectiveDecode)='Internet' ".
           "then (case when (W5SIEM_secent.severity=3 OR ".
                           "W5SIEM_secent.severity=4 OR ".
                           "W5SIEM_secent.severity=5) AND  ".
                           "W5SIEM_secent.pci_vuln like 'yes' ".
                      "then '1' ".
                      "else '0' ".
                  "end) ".
           "else (case when (W5SIEM_secent.severity=4 OR ".
                           "W5SIEM_secent.severity=5) AND ".
                           "W5SIEM_secent.pci_vuln like 'yes' ".
                      "then '1' ".
                      "else '0' ".
                  "end) ".
           "end) ";
    return($sql);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}



sub addICTOSecureFilter
{
   my $self=shift;
   my $addflt=shift;



   my $userid=$self->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->IsMemberOf([qw(admin w5base.tssiem.secscan.read
                                 support)],
          "RMember")){
         my %pgrps=();
         my %grp=$self->getGroupsOf($ENV{REMOTE_USER},[orgRoles()],"both");
         my @grpid=grep(/^[0-9]+/,keys(%grp),keys(%pgrps));
         @grpid=qw(-99) if ($#grpid==-1);

         my $appl=$self->getPersistentModuleObject("w5appl","TS::appl");

         my @flt=();
         push(@flt,{cistatusid=>[3,4,5],databossid=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],applmgrid=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],tsmid=>\$userid});
         push(@flt,{cistatusid=>[3,4,5],tsm2id=>\$userid});


         push(@flt,{
            cistatusid=>[3,4,5],
            sectargetid=>\$userid,
            sectarget=>\'base::user',
            secroles=>"*roles=?applmgr2?=roles*"
         });


         $appl->SetFilter(\@flt);
         $appl->SetCurrentView(qw(ictono id));
         my $i=$appl->getHashIndexed("ictono","id");

         my @ictoid=keys(%{$i->{ictono}});
         @ictoid=qw(-1) if ($#ictoid==-1);
         my @applid=keys(%{$i->{id}});
         @applid=qw(-1) if ($#applid==-1);

         my %ictono=();
         map({$ictono{$_}++ } @ictoid);
         if ($ENV{REMOTE_USER} ne "anonymous" && (keys(%ictono)>0 || 
                                                  $#applid!=-1)){
            push(@$addflt,
                       {ictono=>[keys(%ictono)]}
            );
            push(@$addflt,
                       {applid=>\@applid}
            );
         }
         else{
            push(@$addflt,
                       {ictono=>['-99']}
            );
         }
      }
   }
}
1;
