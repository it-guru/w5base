package caas::qrule::CaaS_Project_URLsync;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Syncronizes all URL in CaaS project with communication URLs
on related application.
The rule only adds/updates urls! The cleanup/delete is done
by a seperate rule on the urls self.

=head3 IMPORTS

NONE

=head3 HINTS
No english hint

[de:]

keine Hinweise

=cut
#######################################################################
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

   return(undef,undef) if ($rec->{srcsys} ne "caas::event::CaaS_CloudAreaSync");
   return(undef,undef) if ($rec->{cistatusid}<3);
   return(undef,undef) if ($rec->{cistatusid}>5);

   my $now=NowStamp("en");

   my $netarea={};
   my $net=getModuleObject($dataobj->Config(),"itil::network");
   if (defined($net)){
      $netarea=$net->getTaggedNetworkAreaId();
   }


   my $parobj=getModuleObject($dataobj->Config,"caas::url");

   my $projectid=$rec->{srcid}; 

   $parobj->SetFilter({projectid=>\$projectid});

   my @l=$parobj->getHashList(qw(ALL));



   my %url;
   my $srcsys=$self->Self();

   foreach my $urlrec (@l){
      $url{$urlrec->{name}}={
         name=>$urlrec->{name},
         applid=>$rec->{applid},
         srcid=>$urlrec->{id}.'@'.$projectid,
         srcsys=>$srcsys                            # Problem, wenn eine
      };                                            # Anwendung mehrere
      
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
     
      my $fltset=[
         {
             name=>join(" ",map({'"'.$_->{name}.'"'} @url)),
             applid=>[$rec->{applid}],
             networkid =>$netarea->{CNDTAG}
         },
         {
             name=>join(" ",map({'"'.$_->{name}.'/*"'} @url)),
             applid=>[$rec->{applid}],
             networkid =>$netarea->{CNDTAG}
         },
         {
             itcloudareaid=>$rec->{id},
             applid=>[$rec->{applid}]
         }
      ];
     
      $itilurl->SetFilter($fltset);
      my @curl=$itilurl->getHashList(qw(ALL));

      #printf STDERR ("shouldList=%s\n",Dumper(\@url));
      #printf STDERR ("curul=%s\n",Dumper(\@curl));
     
      my @opList;
      my $res=OpAnalyse(
                 sub{  # comperator 
                    my ($a,$b)=@_;
                    my $eq;
                    my $blen=length($b->{name});
                    if ((lc($b->{name}) eq lc(substr($a->{name},0,$blen))) ||
                        ($a->{srcid} eq $b->{srcid} &&
                         $a->{srcsys} eq $b->{srcsys})){
                       $eq=0;
                       if ($a->{srcid} eq $b->{srcid} &&
                           $a->{srcsys} eq $b->{srcsys} &&
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
#
#   #print STDERR Dumper($rec);
   #print STDERR Dumper(\@url);
   #print STDERR Dumper(\@curl);
   #print STDERR Dumper(\@opList);

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}




1;
