package tsacinv::qrule::syncApplSystemsSAPInst;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This rule checks an application in CI-Status "installed/active" or "available"
with managed item group "SAP".
It detects all systems in state 'in operation' of related SAP-Instances
in AssetManager and synchronizes the system relations
of the application automatically.

Not yet existing assets and systems will be previously automatically created.

If an automatic action fails, it produces an error.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

If an automatic action has failed, please try to do it manually.
If necessary, please contact the W5Base/Darwin 1st level support.

Possible actions are:

- Add or remove of a system relation

- Create an asset

- Create a logical system

[de:]

Wenn eine automatische Aktion fehlgeschlagen ist,
versuchen Sie diese bitte manuell durchzuführen.
Falls nötig, kontaktieren Sie bitte den W5Base/Darwin 1st Level Support.

Mögliche Aktionen sind:

- Hinzufügen oder entfernen einer Verknüpfung mit einem System

- Anlegen eines Assets

- Anlegen eines logischen Systems

=cut

#######################################################################
#
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
   return(["TS::appl"]);
}


sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   #my $newCIDataboss='12808977330001'; # Marek M.
   my $newCIDataboss='15301885190001'; # (fmb_tel-it_sacm_sap@t-systems.com)
   my $sapAdminGroup='14462097390001';

   my @sapAdmins=$dataobj->getMembersOf($sapAdminGroup);
   $self->{newCIDataboss}=$newCIDataboss if (!defined($self->{newCIDataboss}));
   $self->{sapAdmins}=\@sapAdmins if (!defined($self->{sapAdmins}));

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   return(0,undef) if (!in_array($rec->{mgmtitemgroup},'SAP'));

   return(undef) if ($rec->{applid} eq "");
   my $acapplappl=getModuleObject($self->getParent->Config,
                                  "tsacinv::lnkapplappl");
   $acapplappl->SetFilter({parent_applid=>$rec->{applid},
                           type=>\'SAP',
                           deleted=>\'0'});
   my @sapappls=$acapplappl->getHashList(qw(lchildid));

   return(0,undef) if ($#sapappls==-1);

   my @qmsg;
   my @dataissue;
   my $errorlevel=0;
   my @notifymsg;

   my $acapplsys=getModuleObject($self->getParent->Config,
                                 "tsacinv::lnkapplsystem");
   my $applsys=getModuleObject($self->getParent->Config,
                               "itil::lnkapplsystem");

   # Systems in SAP-Relations
   my @sapapplids=map {$_->{lchildid}} @sapappls;
   $acapplsys->SetFilter({lparentid=>\@sapapplids,
                          sysstatus=>\'in operation'});
   my @sapsys=$acapplsys->getHashList(qw(systemid child sysstatus));

   # Systems in W5Base application; ignores systems without systemid
   $applsys->SetFilter({applid=>\$rec->{id}});
   my @w5sys=$applsys->getHashList(qw(systemsystemid system systemcistatusid));
   @w5sys=grep({$_->{systemsystemid} ne ''} @w5sys);

   my %allsys;

   foreach my $sys (@sapsys) {
      my $name=lc(trim($sys->{child}));

      if (length($name)<3 || haveSpecialChar($name) ||
          $name=~m/^\d+$/) {
         $errorlevel=3 if ($errorlevel<3);
         my $m="invalid system name detected: ".$sys->{child};
         push(@qmsg,$m);
         push(@dataissue,$m);
      }
      else {
         $allsys{$sys->{systemid}}{is_sap}++;
         $allsys{$sys->{systemid}}{name}=$name;
      }
   }
   foreach my $sys (@w5sys) {
      $allsys{$sys->{systemsystemid}}{is_w5}++;
      $allsys{$sys->{systemsystemid}}{name}=$sys->{system};
      $allsys{$sys->{systemsystemid}}{w5cistatusid}=$sys->{systemcistatusid};
   }
   my @missingsys=grep {$allsys{$_}{is_sap} && !$allsys{$_}{is_w5}}
                       keys(%allsys);

   my @disusedsys=grep {$allsys{$_}{is_w5} && !$allsys{$_}{is_sap}}
                       keys(%allsys);

   if ($#missingsys!=-1 || $#disusedsys!=-1) {
      my @cc=@{$self->{sapAdmins}};
      $dataobj->NotifyWriteAuthorizedContacts($rec,undef,{
         emailcc=>\@cc,
       #  emailbcc=>['11634953080001','11634955120001'], # hv,mz
      },{
         autosubject=>1,
         autotext=>1,
         mode=>'QualityCheck',
         datasource=>'SAP-Instances in AssetManager'
      },sub {
         my $sysobj=getModuleObject($self->getParent->Config,"itil::system");

         # add missing system-relations to application
         foreach my $sys2add (@missingsys) {
            $sysobj->ResetFilter();
            $sysobj->SetFilter({systemid=>\$sys2add});
            my ($w5s,$msg)=$sysobj->getOnlyFirst(qw(id));
            my $w5id;
            $w5id=$w5s->{id} if (defined($w5s->{id}));

            if (!defined($w5id)) {
               my $databoss=$self->getNewCIDataboss;
               $databoss=$rec->{databossid} if (!defined($databoss));
               my $newrec={name=>$allsys{$sys2add}{name},
                           systemid=>$sys2add,
                           databossid=>\$databoss,
                           mandatorid=>$rec->{mandatorid},
                           srcsys=>'AssetManager',
                           srcid=>$sys2add,
                           allowifupdate=>1,
                           cistatusid=>4};
               my $assetid=$self->chkAsset($newrec,$rec,
                                           \$errorlevel,
                                           \@qmsg,\@dataissue,\@notifymsg);
               if (defined($assetid)) {
                  $newrec->{assetid}=$assetid;

                  # make sure, that systemname not yet exists
                  # with another systemid, caused of invalid 
                  # data in AM
                  $sysobj->ResetFilter();
                  $sysobj->SetFilter({name=>$allsys{$sys2add}{name},
                                      cistatusid=>\'<=5'});
                  my ($s,$msg)=$sysobj->getOnlyFirst(qw(id));

                  if (!defined($s)) {
                     $sysobj->SetFilter({
                        srcsys=>\'AssetManager',
                        srcid=>\$newrec->{srcid},
                     });
                     my ($chkrec,$msg)=$sysobj->getOnlyFirst(qw(ALL));
                     if (defined($chkrec)){
                        $w5id=$chkrec->{id};
                        my $fixrec={};
                        if ($chkrec->{cistatusid} ne "4"){
                           $fixrec->{cistatusid}='4';
                        }
                        if (keys(%$fixrec)){
                           $sysobj->ValidatedUpdateRecord($chkrec,$fixrec,{
                              id=>\$w5id
                           });
                        }
                     }
                     else{
                        $w5id=$sysobj->ValidatedInsertRecord($newrec);
                     }
                  }

                  if (defined($w5id)) {
                     ($w5s,$msg)=$sysobj->getOnlyFirst(qw(urlofcurrentrec));
                     my $m='System created';
                     push(@qmsg,$m.': '.$newrec->{name});

                     my $nmsg=$self->T($m);
                     $nmsg.=": ";
                     $nmsg.=$newrec->{name};
                     $nmsg.="\n";
                     $nmsg.=$w5s->{urlofcurrentrec};                 
                     push(@notifymsg,$nmsg);
                  }
                  else {
                     $errorlevel=3 if ($errorlevel<3);
                     my $m="Automatic creation of a System failed: ".
                           $newrec->{name};
                     push(@qmsg,$m);
                     push(@dataissue,$m);
                  }
               }
            }

            if (defined($w5id)) {
               my $newrec={systemid=>$w5id,
                           applid=>$rec->{id},
                           comments=>'automatic added by qrule'};

               if ($applsys->ValidatedInsertRecord($newrec)) {
                  ($w5s,$msg)=$sysobj->getOnlyFirst(qw(cistatusid));
                  $allsys{$sys2add}{is_w5}++;
                  $allsys{$sys2add}{w5cistatusid}=$w5s->{cistatusid};
                  my $m='Relation to system added';
                  push(@qmsg,$m.': '.$allsys{$sys2add}{name});
                  push(@notifymsg,$self->T($m).': '.$allsys{$sys2add}{name});
               }
               else {
                  my $m="Automatic relation with system failed: ".
                        $allsys{$sys2add}{name};
                  $errorlevel=3 if ($errorlevel<3);
                  push(@qmsg,$m);
                  push(@dataissue,$m);
               }
            }
         } 

         # remove unused system-relations from application
         foreach my $sys2del (@disusedsys) {
            $applsys->ResetFilter();
            $applsys->SetFilter({systemsystemid=>\$sys2del,
                                 applapplid=>\$rec->{applid}});
            my ($lnk,$msg)=$applsys->getOnlyFirst(qw(id reltyp));
            next if ($lnk->{reltyp} ne 'direct');

            my $lnkid=$applsys->ValidatedDeleteRecord($lnk);
            if (defined($lnkid)) {
               my $m='Relation to system removed';
               push(@qmsg,$m.': '.$allsys{$sys2del}{name});
               push(@notifymsg,$self->T($m).': '.$allsys{$sys2del}{name});
               delete($allsys{$sys2del});
            }
            else {
               my $m="Automatic removal of relation to system failed: ".
                     $allsys{$sys2del}{name};
               $errorlevel=3 if ($errorlevel<3);
               push(@qmsg,$m);
               push(@dataissue,$m);
            }
         } 

         if ($#notifymsg!=-1) {
            return($rec->{name},join("\n\n",map({"- ".$_} @notifymsg)));
         }
         return(undef,undef);
      });
   }


   #######################################################################
   # switch cistate of system to installed/active if not yet is,
   # but only if databoss is member of SAP_ADMINS,
   # otherwise create a data issue

   my $sysobj=getModuleObject($self->getParent->Config,"itil::system");
   foreach my $sysid (keys(%allsys)) {
      if ($allsys{$sysid}{is_sap} &&
          $allsys{$sysid}{is_w5}  &&
          $allsys{$sysid}{w5cistatusid}!=4) {
         $sysobj->ResetFilter;
         $sysobj->SetFilter({systemid=>\$sysid});
         my ($sysrec,$msg)=$sysobj->getOnlyFirst(qw(id name databossid));
         if (in_array($self->{sapAdmins},$sysrec->{databossid})) {
            if ($sysobj->ValidatedUpdateRecord($sysrec,{cistatusid=>4},
                                               {id=>\$sysrec->{id}})) {
               ($sysrec,$msg)=$sysobj->getOnlyFirst(qw(ALL));
               my @cc=@{$self->{sapAdmins}};
               $sysobj->NotifyWriteAuthorizedContacts($sysrec,undef,{
                   emailcc=>\@cc,
                   emailbcc=>['11634953080001','11634955120001'], # hv,mz
                  },{
                   autosubject=>1,
                   autotext=>1,
                   mode=>'QualityCheck',
                   datasource=>'SAP-Instances in AssetManager'
                  },sub {
                     my $msg="- ".$sysrec->{name}.": ";
                     $msg.=sprintf($self->T("CI-State switched from %s to %s"),
                                   $allsys{$sysid}{w5cistatusid},
                                   $sysrec->{cistatusid});
                     return($sysrec->{name},$msg);
                  });

               my $m='switched CI-State to installed/active';
               push(@qmsg,$m.': '.$sysrec->{name});
            }
         }
         else {
            $errorlevel=3 if ($errorlevel<3);
            my $m="CI-State ambiguous: ".$allsys{$sysid}{name};
            push(@qmsg,$m);
            push(@dataissue,$m);
         }
      }
   }
   #######################################################################
   return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@dataissue});
}


sub getNewCIDataboss
{
   my $self=shift;

   my $uobj=getModuleObject($self->getParent->Config,"base::user");
   $uobj->SetFilter({userid=>$self->{newCIDataboss},cistatusid=>[3,4]});
   my ($user,$msg)=$uobj->getOnlyFirst(qw(userid));

   return($user->{userid}) if (defined($user));

   $uobj->ResetFilter;
   $uobj->SetFilter({userid=>$self->{sapAdmins},cistatusid=>[3,4]});
   my @user=$uobj->getHashList(qw(userid fullname));

   if ($#user!=-1) {
      @user=sort({$a->{fullname} cmp $b->{fullname}} @user);
      return($user[0]->{userid});
   }

   return(undef);
}


sub chkAsset {
   my $self=shift;
   my $sysdata=shift;
   my $rec=shift;
   my $errorlevel=shift;
   my $qmsg=shift;
   my $dataissue=shift;
   my $notifymsg=shift;

   my $acsys=getModuleObject($self->getParent->Config,"tsacinv::system");
   my $acasset=getModuleObject($self->getParent->Config,"tsacinv::asset");
   my $asset=getModuleObject($self->getParent->Config,"itil::asset");

   $acsys->SetFilter({systemid=>$sysdata->{systemid}});
   my ($sysasset,$msg)=$acsys->getOnlyFirst('lassetid');
   return(undef) if (!defined($sysasset->{lassetid}));

   $acasset->SetFilter({lassetid=>$sysasset->{lassetid},status=>\'in work'});
   my ($assetasset,$msg)=$acasset->getOnlyFirst('assetid');
   return(undef) if (!defined($assetasset->{assetid}));

   $asset->SetFilter([{srcid=>$assetasset->{assetid}},
                      {name=>$assetasset->{assetid}}]);
   my @foundassets=$asset->getHashList(qw(id name srcid srcsys 
                                          cistatus cistatusid));
   my $id;

   if ($#foundassets==-1) {
      my $databoss=$self->getNewCIDataboss;
      my $newrec={name=>$assetasset->{assetid},
                  databossid=>\$databoss,
                  mandatorid=>$rec->{mandatorid},
                  allowifupdate=>1,
                  srcsys=>'AssetManager',
                  srcid=>$assetasset->{assetid},
                  cistatusid=>4};
      $id=$asset->ValidatedInsertRecord($newrec);

      if (defined($id)) {
         $asset->ResetFilter();
         $asset->SetFilter({id=>\$id});
         my ($w5a,$msg)=$asset->getOnlyFirst(qw(urlofcurrentrec));

         my $m='Asset created';
         push(@$qmsg,$m.': '.$newrec->{name});

         my $nmsg=$self->T($m);
         $nmsg.=": ";
         $nmsg.=$newrec->{name};
         $nmsg.="\n";
         $nmsg.=$w5a->{urlofcurrentrec};
         push(@$notifymsg,$nmsg);
      }
      else {
         $$errorlevel=3 if ($errorlevel<3);
         my $m="Automatic creation of an asset failed: ".$newrec->{name};
         push(@$qmsg,$m);
         push(@$dataissue,$m);
         return(undef);
      }
   }
   elsif ($#foundassets==0) {
      $id=$foundassets[0]->{id};
      if ($foundassets[0]->{srcsys} ne "AssetManager" ||
          $foundassets[0]->{srcid} ne $assetasset->{assetid} ||
          $foundassets[0]->{cistatusid} ne "4"){
         # fix parameters of already existing asset
         $asset->ValidatedUpdateRecord($foundassets[0],{
            cistatusid=>'4',
            srcsys=>'AssetManager',
            srcid=>$assetasset->{assetid}
         },{id=>\$id});
      }
   }
   else {
      msg(ERROR,"multiple assets found by qrule 'syncApplSystemsSAPInst':\n".
                Dumper(\@foundassets));
   }
   
   return($id);
}



1;



