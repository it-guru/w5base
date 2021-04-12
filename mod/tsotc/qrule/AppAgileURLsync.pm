package tsotc::qrule::AppAgileURLsync;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Syncronizes all URL in AppAgile namespaces with communication URLs
on related application.

=head3 IMPORTS

NONE

=head3 HINTS
No english hint

[de:]

Alle aus den DNS-Pfaden am betreffenden AppAgile Namespace,
werden mit den Kommunikations-URLs der dem Nameapces 
zugeordneten Anwendung synchronisiert.

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
   return(["itil::itcloudarea"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(undef,undef) if ($rec->{srcsys} ne "tsotc::appagilenamespace");
   return(undef,undef) if ($rec->{cistatusid}<4);
   return(undef,undef) if ($rec->{cistatusid}>5);

   my $now=NowStamp("en");

   my $netarea={};
   my $net=getModuleObject($dataobj->Config(),"itil::network");
   if (defined($net)){
      $netarea=$net->getTaggedNetworkAreaId();
   }


   my $parobj=getModuleObject($dataobj->Config,"tsotc::appagileurl");

   my $namespace=$rec->{fullname}; 

   $parobj->SetFilter({namespaceid=>\$namespace});

   my @l=$parobj->getHashList(qw(ALL));


   my %url;
   my $srcsys=$self->Self();

   foreach my $urlrec (@l){
      my @suburl;
      if ($urlrec->{ishttp}){
         if ($urlrec->{name} ne ""){
            push(@suburl,{
               name=>"http://".$urlrec->{name},
               port=>80
            });
         }
      }
      if ($urlrec->{ishttps}){
         if ($urlrec->{name} ne ""){
            push(@suburl,{
               name=>"https://".$urlrec->{name},
               port=>443
            });
         }
      }
      foreach my $suburl (@suburl){
         $url{$suburl}={
            name=>$suburl->{name},
            applid=>$rec->{applid},
            srcid=>$urlrec->{id}.":".$suburl->{port},  # TODO! 
            srcsys=>$srcsys                            # Problem, wenn eine
         };                                            # Anwendung mehrere
      }                                                # Areas hat!
   }
   my @url=sort({$a->{name} cmp $b->{name}} values(%url));

   my $itilurl=getModuleObject($dataobj->Config,"itil::lnkapplurl");

   $itilurl->SetFilter([{
       name=>join(" ",map({'"'.$_->{name}.'"'} @url)),
       applid=>[$rec->{applid}],
       networkid =>$netarea->{CNDTAG}
   },
   {
       itcloudareaid=>$rec->{id},
       applid=>[$rec->{applid}]
   }]);

   my @curl=$itilurl->getHashList(qw(ALL));

   my @opList;
   my $res=OpAnalyse(
              sub{  # comperator 
                 my ($a,$b)=@_;
                 my $eq;
                 my $blen=length($b->{name});
                 if (($b->{name} eq substr($a->{name},0,$blen)) ||
                     ($a->{srcid} eq $b->{srcid} &&
                      $a->{srcsys} eq $b->{srcsys})){
                    $eq=0;
                    if ($a->{srcid} eq $b->{srcid} &&
                        $a->{srcsys} eq $b->{srcsys} &&
                        $b->{name} eq substr($a->{name},0,$blen)){
                       $eq=1;
                    }
                 }
                 return($eq);
              },
              sub{  # oprec generator
                 my ($mode,$oldrec,$newrec,%p)=@_;
                 if ($mode eq "insert" || $mode eq "update"){
                    my $oprec={
                       OP=>$mode,
                       MSG=>"$mode url $newrec->{name} ",
                       DATAOBJ=>'itil::lnkapplurl',
                       DATA=>{
                          name          =>$newrec->{name},
                          networkid     =>$netarea->{CNDTAG},
                          itcloudareaid =>$rec->{id},
                          applid        =>$newrec->{applid},
                          srcid         =>$newrec->{srcid},
                          srcsys        =>$newrec->{srcsys},
                       }
                    };
                    if ($mode eq "update"){
                       $oprec->{IDENTIFYBY}=$oldrec->{id};
                       if ($oldrec->{srcsys} ne $newrec->{srcsys}){
                          $oprec->{DATA}->{is_onshproxy}=1;
                       }
                    }
                    if ($mode eq "insert"){
                       $oprec->{DATA}->{is_userfrontend}=1;
                       $oprec->{DATA}->{is_onshproxy}=1;
                    }
                    return($oprec);
                 }
                 elsif ($mode eq "delete"){
                    return(undef) if ($oldrec->{srcsys} ne $srcsys);
                    return({OP=>$mode,
                            MSG=>"delete url $oldrec->{name} ",
                            DATAOBJ=>'itil::lnkapplurl',
                            IDENTIFYBY=>$oldrec->{id},
                            });
                 }
                 return(undef);
              },
              \@curl,\@url,\@opList,
              refid=>$rec->{id});
   if (!$res){
      my $opres=ProcessOpList($self->getParent,\@opList);
      push(@qmsg,map({$_->{MSG}} @opList));
   }

   #print STDERR Dumper($rec);
   #print STDERR Dumper(\@url);
   #print STDERR Dumper(\@curl);
   #print STDERR Dumper(\@opList);

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
