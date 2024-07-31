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
   return(undef,undef) if ($rec->{cistatusid}<3);
   return(undef,undef) if ($rec->{cistatusid}>5);

   my $now=NowStamp("en");

   my $netarea={};
   my $net=getModuleObject($dataobj->Config(),"itil::network");
   if (defined($net)){
      $netarea=$net->getTaggedNetworkAreaId();
   }


   my $parobj=getModuleObject($dataobj->Config,"tsotc::appagileurl");

   my $namespace=$rec->{fullname}; 

   $parobj->SetFilter({namespaceid=>\$namespace,isdnsnamevalid=>\'1'});

   my @l=$parobj->getHashList(qw(ALL));


   my %url;
   my $srcsys=$self->Self();

   foreach my $urlrec (@l){
      my @suburl;
      if ($urlrec->{ishttp}){
         if ($urlrec->{name} ne ""){
            push(@suburl,{
               urltype=>$urlrec->{urltype},
               name=>"http://".$urlrec->{name},
               port=>80
            });
         }
      }
      if ($urlrec->{ishttps}){
         if ($urlrec->{name} ne ""){
            push(@suburl,{
               urltype=>$urlrec->{urltype},
               name=>"https://".$urlrec->{name},
               port=>443
            });
         }
      }
      foreach my $suburl (@suburl){
         my $tag=$suburl->{urltype};
         $tag="CNDTAG";
         if ($suburl->{urltype} eq "INTERNET_URL"){
            $tag="INTERNET";
         }
         if (exists($netarea->{$tag})){
            $url{$suburl->{name}.";".$tag}={
               name=>$suburl->{name},
               networkid=>$netarea->{$tag},
               applid=>$rec->{applid},
               srcid=>$urlrec->{id}.":".$suburl->{port},  # TODO! 
               srcsys=>$srcsys                            # Problem, wenn eine
            };                                            # Anwendung mehrere
         }                                                # Areas hat!
      }
   }
   my @url=sort({$a->{name} cmp $b->{name}} values(%url));


   if ($#url!=-1){
      if (!$dataobj->validateCloudAreaImportState(
                                          "CLOUDAREA: ".$rec->{fullname},
                                          undef,$rec,undef)){
         my $msg="invalid CloudArea or application state for import";
         push(@qmsg,$msg);
      }
   }
   if ($#qmsg==-1){
      my $itilurl=getModuleObject($dataobj->Config,"itil::lnkapplurl");

      my %focusids=();
      foreach my $urlrec (@url){
         $focusids{$urlrec->{srcid}}++;
      }
     
      my $fltset=[
         {
             name=>join(" ",map({'"'.$_->{name}.'"'} @url)),
             applid=>[$rec->{applid}],
             networkid =>[$netarea->{CNDTAG},$netarea->{INTERNET}]
         },
         {
             name=>join(" ",map({'"'.$_->{name}.'/*"'} @url)),
             applid=>[$rec->{applid}],
             networkid =>[$netarea->{CNDTAG},$netarea->{INTERNET}]
         },
         {
             srcsys=>\$srcsys,
             srcid=>[keys(%focusids)]
         },
         {
             itcloudareaid=>$rec->{id},
             applid=>[$rec->{applid}]
         }
      ];

      { # update posible already synced records - because OTC have 
        # changed thinking
         $itilurl->ResetFilter();
         $itilurl->SetFilter($fltset);
         my @curl=$itilurl->getHashList(qw(ALL));
         my @opList;
         my $res=OpAnalyse(
                    sub{  # comperator 
                       my ($a,$b)=@_;
                       my $eq;
                       my $blen=length($b->{name});
                       if ($a->{srcid} eq $b->{srcid} &&
                           $a->{srcsys} eq $b->{srcsys}){
                          $eq=0;
                          if ($a->{srcid} eq $b->{srcid} &&
                              $a->{srcsys} eq $b->{srcsys} &&
                              $a->{applid} eq $b->{applid} &&
                              $a->{networkid} eq $b->{networkid} &&
                              lc($b->{name}) eq lc(substr($a->{name},0,$blen))){
                             $eq=1;
                          }
                       }
                       return($eq);
                    },
                    sub{  # oprec generator
                       my ($mode,$oldrec,$newrec,%p)=@_;
                       if ($mode eq "update"){
                          my $oprec={
                             OP=>"delete",
                             MSG=>"remove url $oldrec->{id} ",
                             DATAOBJ=>'itil::lnkapplurl',
                          };
                          $oprec->{IDENTIFYBY}=$oldrec->{id};
                          return($oprec);
                       }
                    },
                    \@curl,\@url,\@opList,
                    refid=>$rec->{id});
         if (!$res){
            my $opres=ProcessOpList($self->getParent,\@opList);
         }
      }
     


      # fine set
      $itilurl->ResetFilter();
      $itilurl->SetFilter($fltset);
      my @curl=$itilurl->getHashList(qw(ALL));
     
      my @opList;
      my $res=OpAnalyse(
                 sub{  # comperator 
                    my ($a,$b)=@_;
                    my $eq;
                    my $blen=length($b->{name});
                    if ((lc($b->{name}) eq lc(substr($a->{name},0,$blen))) &&
                        ($a->{networkid} eq $b->{networkid})){
                       $eq=0;
                       if ($a->{srcid} eq $b->{srcid} &&
                           $a->{srcsys} eq $b->{srcsys} &&
                           $a->{networkid} eq $b->{networkid} &&
                           lc($b->{name}) eq lc(substr($a->{name},0,$blen))){
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
                             networkid     =>$newrec->{networkid},
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
                          my $newlen=length($newrec->{name});
                          if ($newrec->{name} ne 
                              substr($oldrec->{name},0,$newlen)){
                             $oprec->{DATA}->{name}=$newrec->{name};
                          }
                       }
                       if ($mode eq "insert"){
                          $oprec->{DATA}->{is_userfrontend}=1;
                          $oprec->{DATA}->{is_onshproxy}=1;
                          $oprec->{DATA}->{name}=$newrec->{name};
                       }
                       return($oprec);
                    }
                    elsif ($mode eq "delete"){
                       return(undef); # wegen colision der Löschoperation mit der
                                      # qrule an der URLselbst (vielleicht wäre
                                      # es gut, bei URLs auch einen CI-Status
                                      # einzuführen
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
     
      #
      # Validate, if new URLs are already registered by other applications
      #
      foreach my $oprec (@opList){
         if ($oprec->{OP} eq "insert"){
            if (!($oprec->{DATA}->{name}=~m/\./)){
               my $msg="invalid hostname part in url - missing FQDN";
               push(@qmsg,"URL: ".$oprec->{DATA}->{name});
               push(@qmsg,$msg);
               $errorlevel=2 if ($errorlevel<2);
               $oprec->{OP}="invalid";
            }
         }
         if ($oprec->{OP} eq "insert"){
            $itilurl->ResetFilter();
            my $url=$oprec->{DATA}->{name};
            my $networkid=$oprec->{DATA}->{networkid};
            my $applid=$oprec->{DATA}->{applid};
            $itilurl->SetFilter({name=>'"'.$url.'"',networkid=>\$networkid});
            my @l=$itilurl->getHashList(qw(name applid appl));
            foreach my $failrec (@l){
               my $msg="this URL is already registed by outer application: ".
                       $failrec->{appl};
               push(@qmsg,"URL: ".$failrec->{name});
               push(@qmsg,$msg);
               $errorlevel=2 if ($errorlevel<2);
               $oprec->{OP}="invalid";
            }
            if (!$dataobj->validateCloudAreaImportState(
                    "URL: ".$url,undef,$rec,undef)){
               my $msg="invalid CloudArea or application state for import: ".
                       "URL: ".$url;
               push(@qmsg,$msg);
               $errorlevel=2 if ($errorlevel<2);
               $oprec->{OP}="invalid";
            }
         }
      }
     
      if (!$res){
         my $opres=ProcessOpList($self->getParent,\@opList);
         push(@qmsg,map({$_->{MSG}} grep({$_->{OP} ne "invalid"} @opList)));
      }
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
