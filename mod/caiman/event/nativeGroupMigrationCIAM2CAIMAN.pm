package caiman::event::nativeGroupMigrationCIAM2CAIMAN;
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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
use List::Util qw(min);
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterEvent("nativeGroupMigrationCIAM2CAIMAN",
                        "nativeGroupMigrationCIAM2CAIMAN",timeout=>3600);
   return(1);
}

sub mapMigConstToLev1Mig
{
   my $self=shift;
   my $migConst=shift;
   my $lev1mig=shift;
   my $oldrec=shift;
   my $newrec=shift;


   ######################################################################
   #
   # processing forced $migConst table
   #
   foreach my $k (keys(%{$migConst})){
      foreach my $lev1mig (@{$lev1mig}){
         if (!exists($lev1mig->{new}) && $k eq $lev1mig->{old}){
            if (exists($migConst->{$k}->{srcid}) &&
                exists($newrec->{srcid}->{$migConst->{$k}->{srcid}})){
               $lev1mig->{new}=
                  $newrec->{srcid}->{$migConst->{$k}->{srcid}}->{fullname}
            }
            elsif (exists($migConst->{$k}->{fullname})){
               $lev1mig->{new}=$migConst->{$k}->{fullname};
            }
         }
      }
   }

}

sub tryAutoMapMissingMigConstMap
{
   my $self=shift;
   my $migConst=shift;
   my $lev1mig=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
   my $cuser=getModuleObject($self->Config,"caiman::user");
   my $corg=getModuleObject($self->Config,"caiman::organisation");
   foreach my $lev1mig (@{$lev1mig}){
      if (!exists($lev1mig->{new})){
         msg(INFO,"try to find emails for $lev1mig->{old}");
         $lnkgrp->ResetFilter();
         $lnkgrp->SetFilter({group=>'"'.$lev1mig->{old}.".*".'" '.
                                    '"'.$lev1mig->{old}.'"'});
         $lnkgrp->SetCurrentView(qw(email));
         my $i=$lnkgrp->getHashIndexed(qw(email));
         #print STDERR Dumper($i);
         my %sisnumber;
         if (ref($i) eq "HASH" && ref($i->{email}) eq "HASH"){
            my @email=keys(%{$i->{email}});
            @email=@email[0..min(100,$#email)];
            msg(INFO,"found ".join(",",@email));
            my $emailcnt=$#email+1;
            foreach my $email (@email){
               $cuser->ResetFilter();
               $cuser->SetFilter({email=>\$email});
               my @l=$cuser->getHashList(qw(office_sisnumber));
               foreach my $urec (@l){
                  if ($urec->{office_sisnumber} ne ""){
                     $sisnumber{$urec->{office_sisnumber}}++;
                  }
               }
            }
            msg(INFO,"sisnumber mapping after check $lev1mig->{old}: ".
                      Dumper(\%sisnumber));
         }
         my $emailmax;
         my $target_sisnumber;
         foreach my $k (keys(%sisnumber)){
            my $n=$sisnumber{$k};
            if ($n>$emailmax){
               $target_sisnumber=$k;
               $emailmax=$n;
            }
         }
         if (defined($target_sisnumber)){
            msg(INFO,"using sisnumber $target_sisnumber for $lev1mig->{old}");
            $corg->ResetFilter();
            $corg->SetFilter({sisnumber=>$target_sisnumber});
            my @l=$corg->getHashList(qw(torgoid));
            if ($#l==0){
               msg(INFO,"using torgoid=$l[0]->{torgoid} for $lev1mig->{old}");
               $migConst->{$lev1mig->{old}}={
                   srcid=>$l[0]->{torgoid}
               };
            }
         }
      }
   }
}

sub nativeGroupMigrationCIAM2CAIMAN
{
   my $self=shift;



   { # activate IO-Maps from state "reserved" 
      my $iomap=getModuleObject($self->Config,"base::iomap");
      my $op=$iomap->Clone();

      $iomap->SetFilter({cistatusid=>\'1'});

      foreach my $rec ($iomap->getHashList(qw(ALL))){
         if ($op->ValidatedUpdateRecord(
                  $rec,{cistatusid=>'4'},{id=>$rec->{id}})){
            msg(INFO,"IOMap Rule $rec->{id} migrated");
         }
      }
   }

   my $grp=getModuleObject($self->Config,"base::grp");
   my $mandator=getModuleObject($self->Config,"base::mandator");

   #######################################################################
   $grp->ResetFilter();
   $grp->SetFilter([
      {
        cistatusid=>\'4',
        srcsys=>\'CIAM'
      } ,
      {
        cistatusid=>\'4',
        srcsys=>\'TS::vou'
      } 
   ]);
   $grp->SetCurrentView(qw(grpid fullname parentid parent srcsys));
   my $oldrec=$grp->getHashIndexed(qw(grpid fullname parentid));
   #######################################################################
   $grp->ResetFilter();
   $grp->SetFilter([
      {
        cistatusid=>\'4',
        srcsys=>\'CAIMAN'
      } 
   ]);
   $grp->SetCurrentView(qw(grpid fullname name parentid parent srcsys srcid));
   my $newrec=$grp->getHashIndexed(qw(grpid fullname parentid srcid));
   #######################################################################


   my @lev1mig;

   #######################################################################
   $mandator->ResetFilter();
   $mandator->SetFilter([
      {
        cistatusid=>\'4',
      } 
   ]);
   my @l=$mandator->getHashList(qw(id name grpid groupname));

   foreach my $rec (@l){
      msg(INFO,"checking $rec->{groupname} (at $rec->{name})");
      if (exists($oldrec->{fullname}->{$rec->{groupname}})){
         msg(INFO,"adding mandator group $rec->{groupname} (at $rec->{name})");
         push(@lev1mig,{
            old=>$rec->{groupname}
         });
      }
   }

   my %migConst=(
    'DTAG.GHQ.VTI.DTIT'     =>{fullname=>'EC.DTIT'},
    'DTAG.TSY.INT.DTIT_SK'  =>{srcid=>'eae720f8-c543-4430-bdcb-fe68b4fd5174'},
    'DTAG.TSY.INT.DTIT_HU'  =>{srcid=>'27d1cf81-fb12-4acc-9f92-5c8fa3ff6e8e'},
    'DTAG.TSY.INT.HU'       =>{fullname=>'EC.DT_HU'},
    'DTAG.TSY.INT.UKD'      =>{},
    'DTAG.GHQ.VTS.TSI'      =>{fullname=>'EC.TSI'},
    'DTAG.T-Mobile_AT'      =>{fullname=>'EC.TMA'},
    'DTAG.MMS'              =>{srcid=>'eb8bafea-181e-4933-bc66-50e8cd62c906'},
    'DTAG.GHS.Service.PASM' =>{},
    'DTAG.GHQ.V_F.DTA'      =>{},
    'DTAG.DTSE_CZ'          =>{},
    'DTAG.Congstar'         =>{fullname=>'EC.congstar'},
    'DTAG.MT'               =>{srcid=>'e5e22e2b-8e7d-41f0-a283-2cf5b55e7123'},
    'DTAG.MKT'              =>{},
    'DTAG.DTUK'             =>{},
    'DTAG.GHQ.VD.TDG'       =>{srcid=>'e303f6e4-0ed8-45a4-8a4b-f6844aff4ab2'},
    'DTAG.GHQ.VTI.T_u_I'    =>{},
    'DTAG.GHQ.VD.TDG.T.DTT' =>{fullname=>'EC.DTT'},
    'DTAG.TSY.T3-TS_OS.3-GF'=>{},
    'DTAG.GHQ.VD.TDG.GK.DT_SEC'                                             =>
       {},
    'DTAG.GHQ.VD.TDG.TService.DTS'                                          =>
       {},
    'DTAG.GHQ.VD.TDG.T.DT_A_GmbH'                                           =>
       {srcid=>'6773beb0-0b1a-4cc7-b324-13d4ac5cf62e'},
    'DTAG.TSY.INT.DTIT_HU.E.E-IIT03'                                        =>
       {srcid=>'73c2a3ad-050e-43c1-aa7c-3f5d69b69745'},
    'DTAG.TSY.INT.DTIT_SK.SK-IT.SK-IT-LA1.SK-IT-LA1-01'                     =>
       {srcid=>'666fdded-9166-4db8-a280-28f7ffadaa48'},
    'DTAG.GHQ.VTI.DTIT.IT.IT-SC4-1'                                         =>
       {srcid=>'2f5c1552-f82c-4f29-9740-33ce288ce6b6'},
    'DTAG.Deutsche_Telek-old01.DTCS_GR'                                     =>
       {},
    'DTAG.GHQ.VTS.TSI.T.T-CSI.T-CSICH.T-CSICH04.T-CSICH04_CB'               =>
       {srcid=>'2ab06b15-b1a6-4410-b061-b10ab9ae6e51'},
   );

   foreach my $c (keys(%migConst)){
      if (!in_array([map({$_->{old}} @lev1mig)],$c)){
         push(@lev1mig,{old=>$c});
      }
   }

  

   ######################################################################
   # pass 1 mapping
   $self->mapMigConstToLev1Mig(\%migConst,\@lev1mig,$oldrec,$newrec);

   # try to find missing mappings by user (emails)
   $self->tryAutoMapMissingMigConstMap(\%migConst,\@lev1mig,$oldrec,$newrec);

   # pass 2 mapping
   $self->mapMigConstToLev1Mig(\%migConst,\@lev1mig,$oldrec,$newrec);

   ######################################################################


   #######################################################################
   #
   # Check for missing maps
   #
   #######################################################################
   my $fail=0;
   foreach my $lev1mig (@lev1mig){
     if (!exists($lev1mig->{new})){
        msg(ERROR,"missing migConst for $lev1mig->{old}");
        $fail++;
     }
   }

   #######################################################################
   #
   # Check for double targets
   #
   #######################################################################
   my %targetName;
   foreach my $lev1mig (@lev1mig){
      my $target=$lev1mig->{new};
      $targetName{$target}=[] if (!exists($targetName{$target}));
      push(@{$targetName{$target}},$lev1mig->{old});
   }
   foreach my $k (keys(%targetName)){
      if ($#{$targetName{$k}}>0){
         $fail++;
        my $src=join(",",@{$targetName{$k}});
        msg(ERROR,"bad mapping from $src to $k");
      }
   }

   #######################################################################
   if ($fail){
      return({exitcode=>1,exitmsg=>"bad $fail migConst entries"});
   }
   #######################################################################


   foreach my $migrec (@lev1mig){
      msg(INFO,"migrate $migrec->{old} to $migrec->{new}");
      $grp->ResetFilter();
      $grp->SetFilter({fullname=>\$migrec->{old}});
      my ($ogrprec,$msg)=$grp->getOnlyFirst(qw(ALL));
      $grp->ResetFilter();
      $grp->SetFilter({fullname=>\$migrec->{new}});
      my ($ngrprec,$msg)=$grp->getOnlyFirst(qw(ALL));
      if (defined($ogrprec) && defined($ngrprec)){
         my $oldgrpid=$ogrprec->{grpid};
         my $newgrpid=$ngrprec->{grpid};
         my $tmpgrpid="12345678912344";
         my @cmds=(
            "set autocommit=off;",
            "START TRANSACTION;",
            "update grp set grpid='$tmpgrpid'    where grpid='$oldgrpid';",
            "update grp set parentid='$tmpgrpid' where parentid='$oldgrpid';",
            "update grp set grpid='$oldgrpid'    where grpid='$newgrpid';",
            "update grp set parentid='$oldgrpid' where parentid='$newgrpid';",
            "update grp set grpid='$newgrpid'    where grpid='$tmpgrpid';",
            "update grp set parentid='$newgrpid' where parentid='$tmpgrpid';",
            "COMMIT;",
            "set autocommit=on;"
         );
         foreach my $cmd (@cmds){
            $grp->{DB}->do($cmd);
         }


         #
         # It is not a good Idea, to modify mandator grpid
         #
        # $mandator->ResetFilter();
        # $mandator->SetFilter({grpid=>\$ogrprec->{grpid}});
        # my @l=$mandator->getHashList(qw(ALL));
        # foreach my $rec (@l){
        #    my $oldgrpid=
        #    my $op=$mandator->Clone();
        #    $op->ValidatedUpdateRecord(
        #       $rec,
        #       {grpid=>$ngrprec->{grpid}},
        #       {id=>\$rec->{id}}
        #    );
        # }
      }
   }




   #######################################################################
   # 1st Migrate Hub Groups
   $grp->ResetFilter();
   $grp->SetFilter({fullname=>'EC.DTIT',cistatusid=>4});
   my ($telitorgrec,$msg)=$grp->getOnlyFirst(qw(ALL));

   if (defined($telitorgrec)){
      $grp->ResetFilter();
      $grp->SetFilter({fullname=>'DTAG.*.Hub DTAG.*.ConfigMgmtClearing',cistatusid=>4});
      my @l=$grp->getHashList(qw(ALL));
      foreach my $mig (@l){
         if (exists($migConst{$mig->{parent}})){
            my $mc=$migConst{$mig->{parent}};
            #printf STDERR ("fifi mig %s p=%s\n",$mig->{fullname},$mig->{parent});
            #printf STDERR Dumper($mc);
            my $grp2=$grp->Clone();
            $grp2->SetFilter($mc);
            my ($newprec,$msg)=$grp2->getOnlyFirst(qw(ALL));
            if (defined($newprec)){
               my $newparent=$newprec->{fullname};
               my $op=$grp->Clone();
               if ($op->ValidatedUpdateRecord(
                     $mig, { parent=>$newparent },
                     {grpid=>\$mig->{grpid}}
                  )){
               }
            }
         }

      }
   }

   # Deaktivate old DTAG Groups
   #
   $grp->ResetFilter();
   $grp->SetFilter({fullname=>'EC.*',cistatusid=>4});
   my $n=$grp->CountRecords();
   if ($n>3700){ # most of new EC groups exists
      $grp->ResetFilter();
      #$grp->SetFilter({fullname=>'DTAG.*',srcsys=>'CIAM',cistatusid=>4});
      $grp->SetFilter({fullname=>'DTAG.*',cistatusid=>[4,5]});
      my @l=$grp->getHashList(qw(ALL));
      foreach my $rec (@l){
         msg(INFO,"deaktivate $rec->{fullname}");
         my $op=$grp->Clone();
         if ($op->ValidatedUpdateRecord(
               $rec, { cistatusid=>'6' },
               {grpid=>\$rec->{grpid}}
            )){
         }
      }
   }

   return({exitcode=>0,msg=>'ok'});
}




1;
