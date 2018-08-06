package ewu2::qrule::compareAsset;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base physical system to an ewu2 
physical system (Asset) and updates the defined fields if necessary. 
Automated imports are only done if the field "Allow automatic interface updates"
is set to "yes".
Only assets in W5Base/Darwin with the CI-State "installed/active" are synced!


=head3 HINTS

[en:]

If the asset is maintained in ewu2 by the EWU2 and only mirrored 
to W5Base/Darwin, set the field "allow automatic updates by interfaces"
in the block "Control-/Automationinformations" to "yes". 
The data will be synced automatically.

[de:]

Falls das Asset in ewu2 durch die EWU2 gepflegt wird, sollte 
das Feld "automatisierte Updates durch Schnittstellen zulassen" im Block 
"Steuerungs-/Automationsdaten" auf "ja" gesetzt werden.


=cut

#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
   return(["itil::asset","OSY::asset","AL_TCom::asset"]);
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


   return(undef,undef) if ($rec->{srcsys} ne "EWU2");


   #return(0,undef) if ($rec->{cistatusid}!=4);

   my ($parrec,$msg);
   my $par=getModuleObject($self->getParent->Config(),"ewu2::asset");



   return(undef,undef); # is noch nicht fertig

   #
   # Level 0
   #
   if ($rec->{name} ne ""){   # pruefen ob ASSETID von ewu2
      $par->SetFilter({assetid=>\$rec->{name},
                       status=>'"!wasted"'});
      ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
      return(undef,undef) if (!$par->Ping());
      if (!defined($parrec)){
         if ($rec->{name} ne $rec->{id}){
            # hier koennte u.U. noch eine Verbindung zu AM �ber
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
      if ($rec->{name} ne $parrec->{assetid}){
         $forcedupd->{name}=$parrec->{assetid};
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
         if ($rec->{srcsys} ne "ewu2"){
            $forcedupd->{srcsys}="ewu2";
            $forcedupd->{allowifupdate}="1"; # Beim Switch auf ewu2
         }                                   # autoUpdate auf Ja
         if ($rec->{srcid} ne $parrec->{assetid}){
            $forcedupd->{srcid}=$parrec->{assetid};
         }
         $forcedupd->{srcload}=NowStamp("en");
      }
   }

   #
   # Level 3
   #
   #return(0,undef) if ($rec->{name} eq $rec->{id});
   #
   # Das zur�cksetzen der srcid bei veraltet/gel�schten Elementen ist
   # vielleicht doch keine so gute Idee
   #
   #if ($rec->{cistatusid}>5){
   #   if ($rec->{srcid} ne ""){
   #      $forcedupd->{srcid}=undef;
   #      $forcedupd->{srcload}=undef;
   #   }
   #}
   if ($rec->{cistatusid}==4 || $rec->{cistatusid}==3 ||
       $rec->{cistatusid}==5){
      if ($rec->{srcid} ne "" && $rec->{srcsys} eq "ewu2"){
         if (!defined($parrec)){
            push(@qmsg,'given assetid not found as active in ewu2');
            push(@dataissue,
                       'given assetid not found as active in ewu2');
            $errorlevel=3 if ($errorlevel<3);
         }
         else{
             if ($rec->{srcsys} eq "ewu2"){
                # hack f�r die Spezialisten, die die AssetID in Kleinschrift
                # erfasst haben.
                if ($parrec->{assetid} ne $rec->{name}){
                   msg(INFO,"force rename of $rec->{name} to ".$parrec->{assetid});
                   $forcedupd->{name}=$parrec->{assetid};   
                }
                ################################################################
                my $acroom=$parrec->{room};
                my $acloc=$parrec->{ewu2_locationfullname};
                if ($acroom=~m/^\d{1,2}\.\d{3}$/){
                   if (my ($geb)=$acloc=~m#^/[^/]+/([A-Z]{1})/#){
                      $acroom=$geb.$acroom;
                   }
                }

                # fix serialno with whitespaces in AM
                my $acserialno=$parrec->{serialno};
                $acserialno=~s/^\s+|\s+$//g;

                $self->IfComp($dataobj,
                              $rec,"room",
                              {room=>$acroom},"room",
                              $autocorrect,$forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,
                              mode=>'string');

                $self->IfComp($dataobj,
                              $rec,"place",
                              $parrec,"place",
                              $autocorrect,$forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,
                              mode=>'string');

                $self->IfComp($dataobj,
                              $rec,"rack",
                              $parrec,"rack",
                              $autocorrect,$forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,
                              mode=>'string');

                $self->IfComp($dataobj,
                              $rec,"slotno",
                              $parrec,"slotno",
                              $autocorrect,$forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,
                              mode=>'string');

                $self->IfComp($dataobj,
                              $rec,"serialno",
                              {serialno=>$acserialno},"serialno",
                              $autocorrect,$forcedupd,$wfrequest,
                              \@qmsg,\@dataissue,\$errorlevel,mode=>'string');

               $self->IfComp($dataobj,
                             $rec,"memory",
                             $parrec,"memory",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             tolerance=>5,mode=>'integer');

               $self->IfComp($dataobj,
                             $rec,"cpucount",
                             $parrec,"cpucount",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');

               $self->IfComp($dataobj,
                             $rec,"hwmodel",
                             $parrec,"modelname",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             onCreate=>sub{
                                my $self=shift;
                                my $rec=shift;
                                my $parrec=shift;
                                my $newval=shift;
                                if (length($newval)<3 ||
                                    length($newval)>40 ||
                                    ($newval=~m/^(.)\1{3}/)){
                                   return(undef);
                                }
                                return({name=>$newval,cistatusid=>4});
                             },
                             mode=>'leftouterlinkcreate');

               if ($parrec->{acqumode} eq "1"){
                  $parrec->{acqumode}="RENTAL";
               }
               elsif ($parrec->{acqumode} eq "2"){
                  $parrec->{acqumode}="LEASE";
               }
               elsif ($parrec->{acqumode} eq "3"){
                  $parrec->{acqumode}="LOAN";
               }
               elsif ($parrec->{acqumode} eq "4"){
                  $parrec->{acqumode}="PROVISION";
               }
               elsif ($parrec->{acqumode} eq "6"){
                  $parrec->{acqumode}="FREE";
               }
               else{
                  $parrec->{acqumode}="PURCHASE";
               }
               $self->IfComp($dataobj,
                             $rec,"acqumode",
                             $parrec,"acqumode",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'string');
               if ($autocorrect || $parrec->{acqumode} eq $rec->{acqumode}){
                  if ($parrec->{acqumode} ne "PURCHASE"){
                     $self->IfComp($dataobj,
                                   $rec,"startacqu",
                                   $parrec,"startacquisition",
                                   $autocorrect,$forcedupd,$wfrequest,
                                   \@qmsg,\@dataissue,\$errorlevel,
                                   mode=>'day');
                  }
                  else{
                     $self->IfComp($dataobj,
                                   $rec,"deprstart",
                                   $parrec,"deprstart",
                                   $autocorrect,$forcedupd,$wfrequest,
                                   \@qmsg,\@dataissue,\$errorlevel,
                                   mode=>'day');

                     $self->IfComp($dataobj,
                                   $rec,"deprend",
                                   $parrec,"deprend",
                                   $autocorrect,$forcedupd,$wfrequest,
                                   \@qmsg,\@dataissue,\$errorlevel,
                                   mode=>'day');
                  }
               }

               $self->IfComp($dataobj,
                             $rec,"corecount",
                             $parrec,"corecount",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');

               $self->IfComp($dataobj,
                             $rec,"cpuspeed",
                             $parrec,"cpuspeed",
                             $autocorrect,$forcedupd,$wfrequest,
                             \@qmsg,\@dataissue,\$errorlevel,
                             mode=>'integer');

               my $w5aclocation;

      #=$self->getW5ACLocationname($parrec->{locationid},
      #                          "QualityCheck of $rec->{name}");
      #         msg(INFO,"rec location=$rec->{location}");
      #         msg(INFO,"ac  location=$w5aclocation");
               if ($parrec->{locationid} ne ""){
                  my $acloc=getModuleObject($self->getParent->Config(),
                                            "ewu2::location");
                  if (defined($acloc)){
                     $acloc->SetFilter({locationid=>\$parrec->{locationid}});
                     my ($aclocrec,$msg)=$acloc->getOnlyFirst(qw(w5loc_name));
                     if (defined($aclocrec)){
                        my $r=$aclocrec->{w5loc_name};
                        $r=[$r] if (ref($r) ne "ARRAY");
                        $r=[sort(@$r)];
                        if (defined($r->[0]) && $r->[0] ne ""){
                           $w5aclocation=$r->[0];
                        }
                     }
                  }
                  else{
                     msg(ERROR,"fail to create ewu2::location object");
                  }
               }


               if (defined($w5aclocation)){ # only if a valid W5Base Location found
                  $self->IfComp($dataobj,
                                $rec,"location",
                                {location=>$w5aclocation},"location",
                                $autocorrect,$forcedupd,$wfrequest,
                                \@qmsg,\@dataissue,\$errorlevel,
                                mode=>'string');
               }

               #
               # Filter for conumbers, which are allowed to use in darwin
               #
               if (defined($parrec->{conumber})){
                  if ($parrec->{conumber} eq ""){
                     $parrec->{conumber}=undef;
                  }
                  if (defined($parrec->{conumber})){
                     #
                     # hier mu� der Check gegen die SAP P01 rein f�r die 
                     # Umrechnung auf PSP Elemente
                     #
                     if ($parrec->{conumber}=~m/^\S{10}$/){
                        my $sappsp=getModuleObject($self->getParent->Config,
                                                   "tssapp01::psp");
                        my $psp=$sappsp->CO2PSP_Translator($parrec->{conumber});
                        $parrec->{conumber}=$psp if (defined($psp));
                     }

                     ###############################################################
                     my $co=getModuleObject($self->getParent->Config,
                                            "finance::costcenter");
                     if (defined($co)){
                        if (!($co->ValidateCONumber(
                              $dataobj->SelfAsParentObject,"conumber", $parrec,
                              {conumber=>$parrec->{conumber}}))){ # simulierter newrec
                           $parrec->{conumber}=undef;
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
                             mode=>'string');

               return(undef,undef) if (!$par->Ping());
            }
         }
      }
   }

   if (keys(%$forcedupd)){
      #printf STDERR ("fifi request a forceupd=%s\n",Dumper($forcedupd));
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
      my $msg="different values stored in ewu2: ";
      push(@qmsg,$msg);
      push(@dataissue,$msg);
      $errorlevel=3 if ($errorlevel<3);
   }
   return($self->HandleWfRequest($dataobj,$rec,
                                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest));
}


sub getW5ACLocationname
{
   my $self=shift;
   my $aclocationid=shift;
   my $hint=shift;

   msg(INFO,"start getW5ACLocationname");
   return(undef) if ($aclocationid eq "" || $aclocationid==0);
   my $acloc=$self->getPersistentModuleObject('ewu2::location');
   my $w5loc=$self->getPersistentModuleObject('base::location');
   $acloc->SetFilter({locationid=>\$aclocationid}); 
   my ($aclocrec,$msg)=$acloc->getOnlyFirst(qw(ALL));
   my %lrec;

   msg(INFO,"req  ac location=$aclocrec->{fullname}");
   $lrec{label}=$aclocrec->{label};
   $lrec{address1}=$aclocrec->{address1};
   $lrec{location}=$aclocrec->{location};
   $lrec{zipcode}=$aclocrec->{zipcode};
   $lrec{country}=$aclocrec->{country};
   $lrec{cistatusid}=4;

   return(undef) if ($lrec{zipcode} eq "0");
   return(undef) if ($lrec{location} eq "0");
   return(undef) if ($lrec{address1} eq "0");
   #
   # pre process aclocation 
   #
   delete($lrec{country}) if ($lrec{country} eq ""); 
   delete($lrec{zipcode}) if ($lrec{zipcode} eq ""); 
   $lrec{label}=""        if (!defined($lrec{label}));

   if (!defined($lrec{country})){
      if ($aclocrec->{fullname}=~m/^\/DE[_-]/){
         $lrec{country}="DE";
      }
   }

#   msg(INFO,"requestrec=%s",Dumper(\%lrec));
   

#   my $w5locid=$w5loc->getLocationByHash(%lrec);

   my $debug;
   my $w5locid=$w5loc->getIdByHashIOMapped("ewu2::location",\%lrec,
                                           DEBUG=>\$debug,
                                           ForceLikeSearch=>1);
   if (!defined($w5locid)){
      $w5loc->Log(ERROR,"basedata",
           "Fail to request base::location\n".
           "queried by ewu2::location\n".
           "for AC location $aclocrec->{fullname}\n".
           "while $hint. Contact Admin to add\n".
           "Location:\n".
           join("\n",map({sprintf(" * %-10s='%s'",$_,$lrec{$_})} keys(%lrec))).
           "\n-");
   }

   return(undef) if (!defined($w5locid));
   $w5loc->SetFilter({id=>\$w5locid}); 
   my ($w5locrec,$msg)=$w5loc->getOnlyFirst(qw(name));
   return(undef) if (!defined($w5locrec));
   msg(INFO,"used w5 location=$w5locrec->{name}");
   return($w5locrec->{name});

}


1;