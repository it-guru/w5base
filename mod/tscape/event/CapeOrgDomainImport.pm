package tscape::event::CapeOrgDomainImport;
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
use kernel::QRule;
@ISA=qw(kernel::Event kernel::QRule);



sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub CapeOrgDomainImport
{
   my $self=shift;
   my $start=NowStamp("en");


   my $c=0;

   my $i=getModuleObject($self->Config,"tscape::archappl");
   return({}) if ($i->isSuspended());

   if (!($i->Ping())){
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      if ($infoObj->NotifyInterfaceContacts($i)){
         return({exitcode=>0,exitmsg=>'Interface notified'});
      }
      return({exitcode=>1,exitmsg=>'not all dataobjects available'});
   }


   my $vou=getModuleObject($self->Config,"TS::vou");
   return({}) if ($vou->isSuspended());

   my $orgdomo=getModuleObject($self->Config,"TS::orgdom");
   return({}) if ($orgdomo->isSuspended());

   my $lnkorgdom=getModuleObject($self->Config,"TS::lnkorgdomappl");
   return({}) if ($lnkorgdom->isSuspended());


   $vou->SetFilter({cistatusid=>"<6"});
   $vou->SetCurrentView(qw( id shortname ));
   my $v=$vou->getHashIndexed(qw(shortname));

   $orgdomo->SetFilter({cistatusid=>"<6"});
   $orgdomo->SetCurrentView(qw( id orgdomid name lseg cistatusid ));
   my $orgdom=$orgdomo->getHashIndexed(qw(orgdomid));

   my $norgdom={};

   my $iname=$i->Self();
   $i->SetFilter({status=>'"!Retired"'});

   my @capeData=$i->getHashList(qw(archapplid id
                                   respvorg orgarea orgareaid organisation
                                   lorgdomainseg orgdomainid orgdomainname)
   );
   foreach my $irec (@capeData){
      next if (!($irec->{orgdomainid}=~m/^DOM/)); # C is rotz
      next if ($irec->{orgdomainid} eq "");


      my $domrec={
         cistatusid=>'4',
         lseg=>$irec->{lorgdomainseg},
         name=>$irec->{orgdomainname},
         orgdomid=>$irec->{orgdomainid}
      };
      if (!defined($norgdom->{$irec->{orgdomainid}})){
         $norgdom->{$irec->{orgdomainid}}=$domrec;
      }
      if ($irec->{orgareaid} ne ""){
         $norgdom->{$irec->{orgdomainid}}->{orgareaid}->{$irec->{orgareaid}}++;
      }
   }

   my @opList;
   my $res=OpAnalyse(
         sub{  # comperator
            my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
            my $eq;
            if ($a->{orgdomid}  eq $b->{orgdomid}){
               $eq=0;
               # eq=0 = Satz gefunden und es wird ein Update gemacht
               if ($a->{cistatusid} eq $b->{cistatusid} &&
                   $a->{lseg} eq $b->{lseg}){
                  $eq=1;
                  # eq=1 = alles super - kein Update notwendig
               }
            }
            return($eq);
         },
         sub{  # oprec generator
           my ($mode,$oldrec,$newrec,%p)=@_;
           if ($mode eq "insert" || $mode eq "update"){
              my $oprec={
                 OP=>$mode,
                 MSG=>"$mode  $newrec->{orgdomid} in W5Base",
                 DATAOBJ=>'TS::orgdom',
                 DATA=>{
                    name      =>$newrec->{name},
                    cistatusid=>$newrec->{cistatusid},
                    lseg      =>$newrec->{lseg},
                    orgdomid  =>$newrec->{orgdomid}
                 }
              };
              if ($mode eq "update"){
                 $oprec->{IDENTIFYBY}=$oldrec->{id};
              }
              return($oprec);
           }
           elsif ($mode eq "delete"){
               my $id=$oldrec->{id};
               return(undef) if ($oldrec->{cistatusid}>4);
               return({OP=>"update",
                       DATA=>{
                          cistatusid=>'6'
                       },
                       MSG=>"delete ip $oldrec->{name} ".
                            "from W5Base",
                       DATAOBJ=>'TS::orgdom',
                       IDENTIFYBY=>$oldrec->{id},
                       });
            }
            return(undef);
         },
         [values(%{$orgdom->{orgdomid}})],[values(%$norgdom)],\@opList
   );
   if (!$res){
      my $opres=ProcessOpList($orgdomo,\@opList);
   }

   $orgdomo->ResetFilter();
   $orgdomo->SetFilter({cistatusid=>"<6"});
   $orgdomo->SetCurrentView(qw( id orgdomid name lseg cistatusid ));
   my $orgdom=$orgdomo->getHashIndexed(qw(orgdomid));

   my $lnkod=$lnkorgdom->getHashList(qw(ALL));








#      $c++;
#      my $icto=$irec->{archapplid};
#      my $ictoid=$irec->{id};
#      my $orgdomorgstr=$irec->{orgdom};
#      #my $orgdomorgstr="TSI / ".$irec->{orgdom};  # test with section
#
#      # remove posible existing Sektion (TSI,oder anderes Gerotz)
#      my $orgdomstr=$orgdomorgstr; 
#      $orgdomstr=~s/^[a-z0-9 ]{1,6}\s*\/\s*//i;
#     
#      my ($orgdomidstr)=$orgdomstr=~m/^(\S{1,6})\s+/;
#      my ($hubshort)=$irec->{organisation}=~m/^E-HUB-[0-9]+\s+(\S{2,4})\s+/;
#      if ($hubshort eq ""){
#         ($hubshort)=$irec->{organisation}=~m/^(\S{3})\s+/;
#      }
#      my $vouid;
#      if (exists($v->{shortname}->{$hubshort})){
#         $vouid=$v->{shortname}->{$hubshort}->{id};
#      }
#      my $orgdomid;
#      if (exists($orgdom->{orgdomid}->{$orgdomidstr})){
#         $orgdomid=$orgdom->{orgdomid}->{$orgdomidstr}->{id};
#      }
#      if (0){
#         printf STDERR ("orgdom:'$orgdomorgstr' idstr='$orgdomidstr' ".
#                        "w5baseid='$orgdomid'\n");
#      }
#      
#      if (0){
#         printf STDERR (
#             "%03d %-8s %-8s %-3s hub=%-3s vou=%s orgdom=%s\n",
#             $c,$icto,$ictoid,$orgdomidstr,$hubshort,$vouid,$orgdomid
#         );
#         printf STDERR ("rec[$c]=%s\n",Dumper($irec));
#      }
#
#      my $newrec={
#         ictoid=>$ictoid,
#         vouid=>$vouid,
#         orgdomid=>$orgdomid,
#         srcsys=>$iname,
##         srcload=>NowStamp("en")
#      };
#
#      $lnkorgdom->ResetFilter();
#      $lnkorgdom->SetFilter({ictoid=>\$newrec->{ictoid}});
#      my @l=$lnkorgdom->getHashList(qw(ALL));
#      if ($#l>0){
#         msg(WARN,"something went wron - somebody has ass manuell entries");
#         msg(WARN,"to lnkorgdom for ICTO $newrec->{ictoid}");
#         foreach my $oldrec (@l){
#            $lnkorgdom->ValidatedDeleteRecord($oldrec,{id=>\$oldrec->{id}});
#         }
#      }
#      if ($orgdomid ne ""){
#         $lnkorgdom->ResetFilter();
#         $lnkorgdom->ValidatedInsertOrUpdateRecord($newrec,{
#            ictoid=>\$newrec->{ictoid}
#         });
#      }
#      # manuell erstellte Einträge werden gelöscht bzw. überschrieben 
#      # da Cape aktuell als Master angesehen werden soll
#   }
   #$lnkorgdom->BulkDeleteRecord({'srcload'=>"<\"$start\"",srcsys=>\$iname});
   return({exitcode=>0});
}


1;
