package tsacinv::qrule::compareAppl;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base application and its AssetManager 
counterpart and updates the defined fields if necessary. 
Automatic imports are only done if the field 
"Allow automatic interface updates" is set to "yes".

=head3 IMPORTS

The fields CO-Number, ApplicationID, Application Number, CurrentVersion, 
CHM Approvergroup, INM Assignmentgroup and Description 
are imported from AssetManager. The Fields SeM and TSM are only imported 
if the import of the related contacts was successful.

=head3 HINTS

[en:]

Ensure that the data are correct and up-to-date in both 
Darwin and AssetManager, and are identical in both databases.

[de:]

Vergewissern Sie sich, dass die Daten in Darwin und AssetManager 
richtig und aktuell sind und in beiden Datenbaken übereinstimmen.


=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
   return(["itil::appl","AL_TCom::appl"]);
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

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"tsacinv::appl");
   my $user=getModuleObject($self->getParent->Config(),"base::user");

   #
   # Level 0
   #
   if ($rec->{applid} ne ""){   # pruefen ob APPLID von AssetManager
      $par->SetFilter({applid=>\$rec->{applid},
                       deleted=>\'0'});
      ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         if ($rec->{applid} ne $rec->{id}){
            # hier koennte u.U. noch eine Verbindung zu AM über
            # den Namen aufgebaut werden
         }
      }
   }

   #
   # Level 1
   #
   if (!defined($parrec)){      # pruefen ob wir bereits nach AM geschrieben
      # try to find parrec by srcsys and srcid
      $par->ResetFilter();
      $par->SetFilter({srcsys=>\'W5Base',srcid=>\$rec->{id}});
      ($parrec)=$par->getOnlyFirst(qw(ALL));
   }

   #
   # Level 2
   #
   if (defined($parrec)){
      if ($dataobj->getField("acinmassignmentgroupid",$rec)){
         if ($rec->{acinmassignmentgroupid} ne "" &&
             lc($rec->{srcsys}) eq "assetmanager"){
            $forcedupd->{acinmassignmentgroupid}=undef;
         }
      }
      if ($rec->{applid} ne $parrec->{applid}){
         $forcedupd->{applid}=$parrec->{applid};
      }
      if ($parrec->{srcsys} eq "W5Base"){
         if ($rec->{srcsys} ne "w5base"){
            $forcedupd->{srcsys}="w5base";
         }
         if ($rec->{srcid} ne ""){
            $forcedupd->{srcid}=undef;
         }
      }
      else{
         if ($rec->{srcsys} ne "AssetManager"){
            $forcedupd->{srcsys}="AssetManager";
         }
         if ($rec->{srcid} ne $parrec->{applid}){
            $forcedupd->{srcid}=$parrec->{applid};
         }
         $forcedupd->{srcload}=NowStamp("en");
      }
   }

   #
   # Level 3
   #
   return(0,undef) if ($rec->{applid} eq $rec->{id});
   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "AssetManager"){
         if (!defined($parrec)){
            push(@qmsg,
                 'given applicationid not found as active in AssetManager');
            push(@dataissue,
                 'given applicationid not found as active in AssetManager');
            $errorlevel=3 if ($errorlevel<3);
         }
         else{
            if ($rec->{srcsys} eq "AssetManager"){
               my $sys=getModuleObject($self->getParent->Config(),"itil::system");
               #
               # Filter for conumbers, which are allowed to use in darwin
               #
               if (defined($parrec->{conumber})){
                  if ($parrec->{conumber} eq ""){
                     $parrec->{conumber}=undef;
                  }
                  if (defined($parrec->{conumber})){
                     #
                     # hier muß der Check gegen die SAP P01 rein für die 
                     # Umrechnung auf PSP Elemente
                     #
                     if ($parrec->{conumber}=~m/^\S{10}$/){
                        my $sappsp=getModuleObject($self->getParent->Config,
                                                   "tssapp01::psp");
                        my $psp=$sappsp->CO2PSP_Translator($parrec->{conumber});
                        $parrec->{conumber}=$psp if (defined($psp));
                     }

                     ##############################################################
                     my $co=getModuleObject($self->getParent->Config,
                                            "finance::costcenter");
                     if (defined($co)){
                        if (!($co->ValidateCONumber(
                              $dataobj->SelfAsParentObject,"conumber", $parrec,
                              {conumber=>$parrec->{conumber}}))){ 
                           $parrec->{conumber}=undef; # simulierter newrec
                        }
                     }
                     else{
                        $parrec->{conumber}=undef;
                     }
                  }
               }

               $self->IfComp($dataobj,
                             $rec,"conumber",
                             $parrec,"conumber",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'native');
               if (!$rec->{haveitsem}){
                  if ($parrec->{sememail} ne ""){
                     my $semid=$user->GetW5BaseUserID($parrec->{sememail},"email",
                                                      {quiet=>1});
                     if (defined($semid)){
                        $self->IfComp($dataobj,
                                      $rec,"semid",
                                      {semid=>$semid},"semid",
                                      $autocorrect,$forcedupd,$wfrequest,
                                      \@qmsg,\@dataissue,\$errorlevel,
                                      mode=>'native');
                     }
                  }
               }

               if ($parrec->{tsmemail} ne ""){
                  my $tsmid=$user->GetW5BaseUserID($parrec->{tsmemail},"email",
                                                   {quiet=>1});
                  if (defined($tsmid)){
                     $self->IfComp($dataobj,
                                   $rec,"tsmid",
                                   {tsmid=>$tsmid},"tsmid",
                                   $autocorrect,$forcedupd,$wfrequest,
                                   \@qmsg,\@dataissue,\$errorlevel,
                                   mode=>'native');
                  }
               }
               if ($parrec->{tsm2email} ne ""){
                  my $tsmid=$user->GetW5BaseUserID($parrec->{tsm2email},"email",
                                                   {quiet=>1});
                  if (defined($tsmid)){
                     $self->IfComp($dataobj,
                                   $rec,"tsm2id",
                                   {tsmid=>$tsmid},"tsmid",
                                   $autocorrect,$forcedupd,$wfrequest,
                                   \@qmsg,\@dataissue,\$errorlevel,
                                   mode=>'native');
                  }
               }
               if ($parrec->{opmemail} ne ""){
                  my $opmid=$user->GetW5BaseUserID($parrec->{opmemail},"email",
                                                   {quiet=>1});
                  if (defined($opmid)){
                     $self->IfComp($dataobj,
                                   $rec,"opmid",
                                   {opmid=>$opmid},"opmid",
                                   $autocorrect,$forcedupd,$wfrequest,
                                   \@qmsg,\@dataissue,\$errorlevel,
                                   mode=>'native');
                  }
               }
               if ($parrec->{opm2email} ne ""){
                  my $opmid=$user->GetW5BaseUserID($parrec->{opm2email},"email",
                                                   {quiet=>1});
                  if (defined($opmid)){
                     $self->IfComp($dataobj,
                                   $rec,"opm2id",
                                   {opmid=>$opmid},"opmid",
                                   $autocorrect,$forcedupd,$wfrequest,
                                   \@qmsg,\@dataissue,\$errorlevel,
                                   mode=>'native');
                  }
               }
               $self->IfComp($dataobj,
                             $rec,"description",
                             $parrec,"description",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'text');
               { 
                  my $comprec={name=>$parrec->{name}}; # in AM spaces in app
                  $comprec->{name}=~s/\s/_/g;          # names are allowed
                  $self->IfComp($dataobj,
                                $rec,"name",
                                $comprec,"name",
                                $autocorrect,$forcedupd,$wfrequest,
                                \@qmsg,\@dataissue,\$errorlevel,
                                mode=>'text');
               }

               $self->IfComp($dataobj,
                             $rec,"currentvers",
                             $parrec,"version",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'text');
               if ($dataobj->getField("scapprgroup")){
                  $self->IfComp($dataobj,
                                $rec,"scapprgroup",
                                $parrec,"capprovergroup",
                                $autocorrect,$forcedupd,$wfrequest,
                                \@qmsg,\@dataissue,\$errorlevel,
                                mode=>'native',
                                AllowEmpty=>0);
               }
               if ($dataobj->Self eq "AL_TCom::appl"){  # only for AL DTAG
                  $self->IfComp($dataobj,
                                $rec,"acinmassingmentgroup",
                                $parrec,"iassignmentgroup",
                                $autocorrect,$forcedupd,$wfrequest,
                                \@qmsg,\@dataissue,\$errorlevel,
                                mode=>'native',
                                AllowEmpty=>0);
               }
               if ($rec->{allowifupdate}){
                  # keys are in rec= systemsystemid
                  # and in parrec  = systemid
                  my @opList;
                  my $res=OpAnalyse(
                             sub{  # comperator 
                                my ($a,$b)=@_;
                                my $eq;
                                if (uc($a->{systemsystemid}) 
                                       eq uc($b->{systemid})){
                                   $eq=1;
                                }
                                return($eq);
                             },
                             sub{  # oprec generator
                                my ($mode,$oldrec,$newrec,%p)=@_;
                                if ($mode eq "insert" || $mode eq "update"){
                                   my $identifyby=undef;
                                   if ($mode eq "update"){
                                      $identifyby=$oldrec->{id};
                                   }
                                   my $systemid;
                                   if ($newrec->{systemid} ne ""){
                                      $sys->ResetFilter();
                                      $sys->SetFilter({systemid=>
                                                       \$newrec->{systemid},
                                                       cistatusid=>"!6"});
                                      my ($sysrec,$msg)=$sys->getOnlyFirst(qw(id));
                                      if (defined($sysrec)){
                                         $systemid=$sysrec->{id};
                                      }
                                      else{
                                         $mode="nop";
                                         my $m="can not create relation to ".
                                               "not existing/active system: ".
                                               $newrec->{systemid};
                                         push(@qmsg,$m);
                                         push(@dataissue,$m);
                                         $errorlevel=3 if ($errorlevel<3);
                                      }
                                   }
                                   my $srcsys="AM";
                                   if ($newrec->{srcsys} eq "W5Base"){
                                      if (!($newrec->{srcid}=~m/^SAPLNK-.*/)){
                                         # prevent loop imports
                                         return(undef);
                                      }
                                      else{
                                         $srcsys="AM-SAPLNK";
                                      }
                                   }
                                   
                                   return({OP=>$mode,
                                           MSG=>"$mode systemlink ".
                                                "$newrec->{systemid} ".
                                                "in W5Base",
                                           IDENTIFYBY=>$identifyby,
                                           DATAOBJ=>'itil::lnkapplsystem',
                                           DATA=>{
                                              srcsys    =>$srcsys,
                                              applid    =>$p{refid},
                                              systemid  =>$systemid
                                              }
                                           });
                                }
                                elsif ($mode eq "delete"){
                                   return({OP=>$mode,
                                           MSG=>"delete system ".
                                                "$oldrec->{systemsystemid} ".
                                                "from W5Base",
                                           DATAOBJ=>'itil::lnkapplsystem',
                                           IDENTIFYBY=>$oldrec->{id},
                                           });
                                }
                                return(undef);
                             },
                             $rec->{systems},$parrec->{systems},\@opList,
                             refid=>$rec->{id},sys=>$sys);
                   if (!$res){
                      my $opres=ProcessOpList($self->getParent,\@opList);
                   }
               }
            }
         }

         if ($rec->{mandator} eq "Extern" && $rec->{allowifupdate}){
            # forced updates on External Data
            if (!defined($parrec)){
               if ($par->Ping()){
                  $forcedupd->{cistatusid}=5;
               }
            }
            else{
               $forcedupd->{cistatusid}=4 if ($rec->{cistatusid}!=4);
               my $databossid;
               my $acgroup=getModuleObject($self->getParent->Config,
                                           "tsacinv::group");
               $acgroup->SetFilter({lgroupid=>\$parrec->{lassignmentid}});
               my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
               if (defined($acgrouprec)){
                  if ($acgrouprec->{supervisorldapid} ne "" ||
                      $acgrouprec->{supervisoremail} ne ""){
                     my $importname=$acgrouprec->{supervisorldapid};
                     if ($importname eq ""){
                        $importname=$acgrouprec->{supervisoremail};
                     }
                  }
               }
            }
         }
      }
      else{
        # makes no sense, becaus this is often not suggestible by the databoss
        # if ($rec->{mandator} ne "Extern"){
        #    push(@qmsg,'no applicationid specified');
        #    $errorlevel=3 if ($errorlevel<3);
        # }
      }
   }



   if (keys(%$forcedupd)>0){
      #msg(INFO,sprintf("forceupd=%s\n",Dumper($forcedupd)));
      if ($dataobj->ValidatedUpdateRecord($rec,$forcedupd,{id=>\$rec->{id}})){
         my @fld=grep(!/^srcload$/,keys(%$forcedupd));
         if ($#fld!=-1){
            push(@qmsg,"all desired fields has been updated: ".join(", ",@fld));
         }
      }
      else{
         push(@qmsg,$self->getParent->LastMsg());
         $errorlevel=3 if ($errorlevel<3);
      }
   }
  if (keys(%$wfrequest)){
      my $msg="different values stored in AssetManager: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }

   #######################################################################
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}



1;
