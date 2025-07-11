package tsacinv::qrule::ResolvAddCI;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Try to find additional CIs for communication URLs

=head3 IMPORTS

NONE

=head3 HINTS

Find additional Config-Items by search in AssetManager

[de:]

Ermittlung zusätzlicher Config-Items über AssetManager

=cut
#######################################################################
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
use kernel;
use kernel::QRule;
use itil::lib::Listedit;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::lnkapplurl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   my @ipl;

   if (ref($rec->{lastipaddresses}) eq "ARRAY"){
      foreach my $iprec (@{$rec->{lastipaddresses}}){
         if ($iprec->{name} ne ""){
            push(@ipl,$iprec->{name});
         }
      }
   }
   if ($#ipl!=-1){
      my $aip=getModuleObject($dataobj->Config,"tsacinv::autodiscipaddress");
      if (!$aip->Ping()){
         return(undef);
      }
      $aip->SetFilter({
         address=>\@ipl,
         usage=>\'LOADBALANCER',
         scandate=>">now-14d"
      });
      my @cis=$aip->getHashList(qw(ALL));
      my $srcsys=$aip->SelfAsParentObject();

      my $acis=getModuleObject($dataobj->Config,"itil::lnkadditionalci");
      $acis->SetFilter({accessurlid=>\$rec->{id}});
      my @acis=$acis->getHashList(qw(ALL));

      my @opList;

      #printf STDERR ("cis=%s\n",Dumper(\@cis));
      #printf STDERR ("acis=%s\n",Dumper(\@acis));

      my $res=OpAnalyse(
         sub{  # comperator 
            my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
            my $eq;
            if ($a->{srcsys} eq $srcsys &&
                $a->{name} eq $b->{systemname}." (".$b->{systemid}.")"){
               $eq=0;
              # eq=0 = Satz gefunden und es wird ein Update gemacht
              # eq=1 = alles super - kein Update notwendig
              #
              # # da srcload geschrieben werden muss, mach ich immer eq=0
              # $eq=1 if ($a->{ciusage} eq "LOADBALANCER" &&
              #           $a->{srcsys} eq $srcsys &&
              #           $a->{srcid} eq $b->{id} &&
              #           $a->{name} eq $b->{systemname}.
              #              " (".$b->{systemid}.")");
            }
            return($eq);
         },
         sub{  # oprec generator
            my ($mode,$oldrec,$newrec,%p)=@_;
            if ($mode eq "insert" || $mode eq "update"){
               my $oprec={
                  OP=>$mode,
                  MSG=>"$mode  $newrec->{systemname} ".
                       "in W5Base",
                  DATAOBJ=>'itil::lnkadditionalci',
                  DATA=>{
                     name   =>$newrec->{systemname}.
                              " (".$newrec->{systemid}.")",
                     ciusage=>"LOADBALANCER",
                     srcload   =>NowStamp("en"),
                     srcsys    =>$srcsys,
                     accessurlid=>$rec->{id}
                  }
               };
               if ($mode eq "update"){
                  $oprec->{IDENTIFYBY}=$oldrec->{id};
               }
               if ($mode eq "insert"){
                  $checksession->{EssentialsChangedCnt}++;
                  push(@{$desc->{qmsg}},"add: ".$oprec->{DATA}->{name});
               }
               return($oprec);
            }
            elsif ($mode eq "delete"){
               my $id=$oldrec->{id};
               push(@{$desc->{qmsg}},"remove: ".$oldrec->{name});
               $checksession->{EssentialsChangedCnt}++;
               return({OP=>$mode,
                       MSG=>"delete ip $oldrec->{name} ".
                            "from W5Base",
                       DATAOBJ=>'itil::lnkadditionalci',
                       IDENTIFYBY=>$oldrec->{id},
                       });
            }
            return(undef);
         },
         \@acis,\@cis,\@opList,
         refid=>$rec->{id}
      );

      #printf STDERR ("fifi opList=%s\n",Dumper(\@opList));
      if (!$res){
         my $opres=ProcessOpList($self->getParent,\@opList);
      }
   }




#   my $host=$rec->{hostname};
#
#   my $applid=$rec->{applid};
#   my $appok=0;
#   if ($applid ne ""){
#      $appok=1;
#      $appl->SetFilter({id=>\$applid});
#      my ($arec)=$appl->getOnlyFirst(qw(id cistatusid));
#      if (!defined($arec)){
#         $appok=0;
#      }
#      else{
#         if ($arec->{cistatusid}==6){
#            $appok=0;
#         }
#      }
#   }
#   if (!$appok){
#      if ($rec->{expiration} eq ""){
#         $dataobj->ValidatedUpdateRecord($rec,{
#               expiration=>scalar($dataobj->ExpandTimeExpression("now+28d"))
#            },{id=>\$rec->{id}});
#      }
#      my $d=CalcDateDuration(NowStamp("en"),$rec->{expiration});
#      if (defined($d)){
#         if ($d->{totalminutes}<0){
#            $dataobj->ValidatedDeleteRecord($rec);
#            $desc->{qmsg}=['URL deleted'];
#            return($exitcode,$desc);
#         }
#      }
#
#      $desc->{qmsg}=['Application inactive'];
#      return($exitcode,$desc);
#   }
#   else{
#      if ($rec->{expiration} ne ""){
#         $dataobj->ValidatedUpdateRecord($rec,{
#               expiration=>undef
#            },{id=>\$rec->{id}});
#      }
#   }
#
#
#   if ($rec->{network} eq "Telekom Product and Inovation Net"){
#      $desc->{qmsg}=['ignoring Telekom Product and Inovation Net'];
#      return($exitcode,$desc);
#   }
#
#
#   my $url=$rec->{'name'};
#   my $networkid=$rec->{networkid};
#   my $res=itil::lib::Listedit::probeUrl($dataobj,$url,[qw(DNSRESOLV)],
#                                         $networkid);
#   if (defined($res) && ref($res) eq "HASH"){
#      if ($res->{exitcode} eq "0"){
#         if (ref($res->{dnsresolver}) eq "HASH" &&
#             $res->{dnsresolver}->{exitcode} eq "0"){
#            @ipl=@{$res->{dnsresolver}->{ipaddress}};
#         }
#      }
#      elsif ($res->{exitcode} eq "101"){
#         my $msg="can not resolv hostname";
#         return(3,{qmsg=>$msg,dataissue=>$msg});
#      }
#      else{
#         return(undef,{
#            qmsg=>"ERROR: unknon problem while itil::lib::Listedit::probeUrl"
#         });
#      }
#   }
#   else{
#      return(undef,{
#         qmsg=>"ERROR: interal itil::lib::Listedit::probeUrl problem"
#      });
#   }
#
#
#
#   my $lastip=getModuleObject($self->getParent->Config,"itil::lnkapplurlip");
#   my $srcload=NowStamp("en");
#   foreach my $ip (@ipl){
#      $lastip->ValidatedInsertOrUpdateRecord({
#         name=>$ip,
#         srcload=>$srcload,
#         lnkapplurlid=>$rec->{id}
#      },{name=>\$ip,lnkapplurlid=>\$rec->{id}});
#   }
#   $lastip->BulkDeleteRecord({'srcload'=>"<'$srcload-7d GMT' OR [EMPTY]",
#                              lnkapplurlid=>\$rec->{id}});
#
#   $lastip->ResetFilter();
#   $lastip->SetFilter({lnkapplurlid=>\$rec->{id}});
#   my @l=$lastip->getHashList(qw(id));
#
#   if ($#l==-1){
#      $exitcode=3 if ($exitcode<3);
#      my $msg="unable to resolv hostname part of url in DNS";
#      push(@{$desc->{qmsg}},$msg);
#      push(@{$desc->{dataissue}},$msg);
#   }
   return($exitcode,$desc);
}




1;
