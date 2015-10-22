package tsacinv::qrule::syncApplSystemsSAPInst;
#######################################################################
=pod

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

use constant {
   NEW_CI_DATABOSS =>'12808977330001', # Marek M.
   SAP_ADMINS      =>[qw(12808977330001 12236427680001 11634955120001)]
};


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


sub getNewCIDataboss
{
   my $self=shift;

   my $uobj=getModuleObject($self->getParent->Config,"base::user");
   $uobj->SetFilter({userid=>NEW_CI_DATABOSS,cistatusid=>[4]});
   my ($user,$msg)=$uobj->getOnlyFirst(qw(userid));

   return($user) if (defined($user));

   $uobj->ResetFilter;
   $uobj->SetFilter({userid=>SAP_ADMINS,cistatusid=>[4]});
   ($user,$msg)=$uobj->getOnlyFirst(qw(userid));

   return($user);
}


sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   ##################################################################
   # mz 2015-08-18 
   # while testing under production conditions
   # only these applications will be considered:
   my @appl2chk=(qw(12199294360024 12199302380006 12962281170017
                    13355257150001 14157032310001 250
                    14446417290001 14446378280003 5271));
   return(0,undef) if (!in_array(\@appl2chk,$rec->{id}));
   ##################################################################

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   return(0,undef) if (!in_array($rec->{mgmtitemgroup},'SAP'));

   my $acapplappl=getModuleObject($self->getParent->Config,
                                  "tsacinv::lnkapplappl");
   $acapplappl->SetFilter({parent_applid=>$rec->{applid},type=>\'SAP'});
   my @sapappls=$acapplappl->getHashList(qw(lchildid));

   return(0,undef) if ($#sapappls==-1);

   my $acapplsys=getModuleObject($self->getParent->Config,
                                 "tsacinv::lnkapplsystem");
   my $applsys=getModuleObject($self->getParent->Config,
                               "itil::lnkapplsystem");

   # Systems in SAP-Relations
   my @sapapplids=map {$_->{lchildid}} @sapappls;
   $acapplsys->SetFilter({lparentid=>\@sapapplids,
                          sysstatus=>\'in operation'});
   my @sapsys=$acapplsys->getHashList(qw(systemid child sysstatus));

   # Systems in W5Base application
   $applsys->SetFilter({applid=>\$rec->{id}});
   my @w5sys=$applsys->getHashList(qw(systemsystemid system systemcistatusid));
   my %allsys;
   foreach my $sys (@sapsys) {
      $allsys{$sys->{systemid}}{is_sap}++;
      $allsys{$sys->{systemid}}{name}=lc($sys->{child});
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

   my @qmsg;
   my @dataissue;
   my $errorlevel=0;
   my @notifymsg;

   # switch cistate of system to installed/active if not yet is
   # only if databoss is member of SAP_ADMINS, otherwise create a data issue
   foreach my $sysid (keys(%allsys)) {
      if ($allsys{$sysid}{is_sap} &&
          $allsys{$sysid}{is_w5}  &&
          $allsys{$sysid}{w5cistatusid}!=4) {

         my $sysobj=getModuleObject($self->getParent->Config,"itil::system");
         $sysobj->SetFilter({systemid=>\$sysid});
         my ($sysrec,$msg)=$sysobj->getOnlyFirst(qw(id name databossid));

         if (in_array(SAP_ADMINS,$sysrec->{databossid})) {
            if ($sysobj->ValidatedUpdateRecord($sysrec,{cistatusid=>4},
                                               {id=>\$sysrec->{id}})) {
               ($sysrec,$msg)=$sysobj->getOnlyFirst(qw(ALL));
               $sysobj->NotifyWriteAuthorizedContacts($sysrec,undef,{
                   emailcc=>SAP_ADMINS,
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


   if ($#missingsys==-1 && $#disusedsys==-1) {
      return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@dataissue})
   }

   $dataobj->NotifyWriteAuthorizedContacts($rec,undef,{
      emailcc=>SAP_ADMINS,
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
                        allowifupdate=>1,
                        cistatusid=>4};
            my $assetid=$self->chkAsset($newrec,$rec,
                                        \$errorlevel,
                                        \@qmsg,\@dataissue,\@notifymsg);
            if (defined($assetid)) {
               $newrec->{asset}=$assetid;
               $w5id=$sysobj->ValidatedInsertRecord($newrec);

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
         my ($lnk,$msg)=$applsys->getOnlyFirst('id');
         my $lnkid=$applsys->ValidatedDeleteRecord($lnk);
         if (defined($lnkid)) {
            my $m='Relation to system removed';
            push(@qmsg,$m.': '.$allsys{$sys2del}{name});
            push(@notifymsg,$self->T($m).': '.$allsys{$sys2del}{name});
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

   return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@dataissue});
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

   $asset->SetFilter({name=>$assetasset->{assetid}});

   if ($asset->CountRecords()==0) {
      my $databoss=$self->getNewCIDataboss;
      my $newrec={name=>$assetasset->{assetid},
                  databossid=>\$databoss,
                  mandatorid=>$rec->{mandatorid},
                  allowifupdate=>1,
                  cistatusid=>4};
      if ($asset->ValidatedInsertRecord($newrec)) {
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

   return($assetasset->{assetid});
}



1;



