package w5v1inv::event::loadfromv1;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use Data::Dumper;
use kernel;
use kernel::Event;
use kernel::database;
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


   $self->RegisterEvent("loadfromv1","LoadUser",timeout=>4000);  # seems OK
   $self->RegisterEvent("loaduser","LoadUser",timeout=>4000);  # seems OK

   $self->RegisterEvent("loadcust","LoadCustomer"); 
   $self->RegisterEvent("loadproto","LoadProto");
   $self->RegisterEvent("loadfaq","LoadFaq");
   $self->RegisterEvent("loadcustcontract","LoadCustContract");
   $self->RegisterEvent("loadapp","LoadApp");
   $self->RegisterEvent("loadsystem","LoadSystem",timeout=>12000);
   $self->RegisterEvent("loadosysystem","LoadOsySystems");
   $self->RegisterEvent("loadlocation","LoadLocation");
   $self->RegisterEvent("loadv1location","LoadLocation");
   $self->RegisterEvent("loadappcontract","LoadAppContract");
   $self->RegisterEvent("loadliccontract","LoadLicContract");
   $self->RegisterEvent("loadsoftware","LoadSoftware");
   $self->RegisterEvent("loadproducer","LoadProducer");
   $self->RegisterEvent("loadplatform","LoadPlatform");
   $self->RegisterEvent("loadosrelease","LoadOsrelease");
   $self->RegisterEvent("loadinterfaces","LoadInterfaces",timeout=>900);
   $self->RegisterEvent("loadmodel","LoadModel");
   $self->RegisterEvent("loadcostcenter","LoadCostCenter");
   $self->RegisterEvent("loadcontact","LoadContact");
   $self->RegisterEvent("loadbtb","LoadBTB",timeout=>12000);
   $self->RegisterEvent("loadip","LoadIP");
   $self->RegisterEvent("loadaccno","LoadAccNo");
   return(1);
}

sub LoadCustomer
{
   my $self=shift;
   my $bcapp=getModuleObject($self->Config,"w5v1inv::application");

   $self->ImportGroup("usergroup.tsi-kunde.t-com");
   $self->VerifyMembers("usergroup.tsi-kunde.t-com");
   $bcapp->ResetFilter();
   foreach my $rec ($bcapp->getHashList(qw(name kndorgarea cistatusid))){
      next if ($rec->{cistatusid}>4);
      next if ($rec->{kndorgarea}==0);
      my $grp=$self->ImportOrgarea($rec->{kndorgarea}); 
      print Dumper($rec) if (!defined($grp));
   }
}

sub ImportGroup
{
   my $self=shift;
   my $groupname=shift;

   my $grp=getModuleObject($self->Config,"base::grp");
   my $newid=$grp->TreeCreate($groupname);
   $grp->SetFilter({fullname=>\$groupname});
   my @l=$grp->getHashList(qw(grpid parentid name fullname));
   return($l[0]) if ($#l>=0);
   return(undef);
}

sub VerifyMembers
{
   my $self=shift;
   my $groupname=shift;

   my $grp=getModuleObject($self->Config,"base::grp");
   $grp->SetFilter({fullname=>\$groupname});

   my $grpid; 
   my ($grp)=$grp->getHashList(qw(grpid users));
   my @cusers=();
   my @susers=();
   if (defined($grp)){
      $grpid=$grp->{grpid};
      my $l=$grp->{users};
      $l=[] if (!defined($l));
      foreach my $urec (@$l){
         my $uid=$urec->{userid};
         push(@cusers,$uid) if (defined($uid) && !grep(/^$uid$/,@cusers));
      }
   }
   if ($grpid eq ""){
      msg(ERROR,"no grpid for $groupname");
      return(undef);
   }
   # select grp.id,user.account from grp,lnkgrpuser,user where grp.name="uploader" and lnkgrpuser.grp=grp.id and lnkgrpuser.user=user.id;


   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      msg(ERROR,"cant connect to db");
      return(undef);
   }
   my $cmd="select user.id from grp,lnkgrpuser,user ".
           "where grp.name=\"$groupname\" and lnkgrpuser.grp=grp.id ".
           "and lnkgrpuser.user=user.id";
   if (!$db->execute($cmd)){
      msg(ERROR,"cant execute statement");
      return(undef);
   }
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      my $uid=$self->getUserIdByV1($rec->{id});
      push(@susers,$uid) if (defined($uid) && !grep(/^$uid$/,@susers));
   }
   #printf STDERR ("c=%s",Dumper(\@cusers));
   #printf STDERR ("s=%s",Dumper(\@susers));
   my $grpuser=getModuleObject($self->Config,"base::lnkgrpuser");
   foreach my $uid (@susers){
      if (!grep/^$uid$/,@cusers){
         $grpuser->ValidatedInsertOrUpdateRecord({userid=>$uid,
                                                  grpid=>$grpid,
                                                  roles=>['RMember']},
                                                 {userid=>$uid,
                                                  grpid=>$grpid});
      }
   }
}

sub ImportOrgarea
{
   my $self=shift;
   my $oaid=shift;

   my $grp=getModuleObject($self->Config,"base::grp");
   $grp->SetFilter({grpid=>$oaid});
   my @l=$grp->getHashList(qw(grpid parentid name fullname));
   return($l[0]) if ($#l>=0);
   my $oa=getModuleObject($self->Config,"w5v1inv::orgarea");
   $oa->SetFilter({id=>$oaid});
   $oa->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$oa->getFirst();
   if (defined($rec) && $rec->{id}!=0){
      my $parentid=$rec->{parentid};
      my %newgrp=(name=>$rec->{name},grpid=>$rec->{id},
                  cistatusid=>4,
                  comments=>'Import from W5BaseV1');
      if ($parentid>0){
         my $prec=$self->ImportOrgarea($parentid);
         if (defined($prec)){
            $newgrp{parentid}=$parentid
         }
      }
      msg(DEBUG,"Write=%s",Dumper(\%newgrp));
      my $back=$grp->ValidatedInsertRecord(\%newgrp);
      msg(DEBUG,"ValidatedInsertRecord returned=$back");
   }
   my @l=$grp->getHashList(qw(grpid parentid name fullname));
   return($l[0]) if ($#l>=0);
   
   return(undef);
}

sub LoadUser
{
   my $self=shift;
   my $account=shift;

   my $v1usr=getModuleObject($self->Config,"w5v1inv::user");
   my $user=getModuleObject($self->Config,"base::user");
   my $acc=getModuleObject($self->Config,"base::useraccount");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $grpuser=getModuleObject($self->Config,"base::lnkgrpuser");

   if (!defined($v1usr) ||
       !defined($grpuser)||
       !defined($user)   ||
       !defined($acc)   ||
       !defined($grp)){
      return({msg=>'shit'});
   }
   my %flt=(emailchecked=>1,lockwarncount=>0,email=>'!""');
   $flt{account}=$account if (defined($account) && $account ne "");
   $v1usr->SetFilter(\%flt,{email=>'!null@null.com'},{email=>'!*.sk'});
   $v1usr->SetCurrentView(qw(ALL));
   $v1usr->ForeachFilteredRecord(sub{
         my $v1rec=$_;
         $user->SetFilter({email=>$v1rec->{email}});
         my @transfer=qw(
                 office_street office_zipcode office_location office_phone 
                 private_street private_zipcode private_location private_phone 
                 email givenname surname);
         $user->SetCurrentView(qw(userid),@transfer);
         my ($rec,$msg)=$user->getFirst();
         die('hard') if (defined($msg));
         my $userid;
         my %newusr;
         foreach my $v (@transfer){
            $newusr{$v}=$v1rec->{$v};
         }
         $newusr{cistatusid}=4;
         $newusr{email}=lc($v1rec->{email});
         if ($newusr{email}=~m/^\s*$/){
            msg(ERROR,"no email found vor insert");
         }
         else{
            if (!defined($rec)){
               $userid=$user->ValidatedInsertRecord(\%newusr);
            }
            else{
               $userid=$rec->{userid};
               $user->ValidatedUpdateRecord($rec,\%newusr,{userid=>$userid});
            }
            if (defined($userid)){
               foreach my $account ($v1rec->{account},
                                    $v1rec->{alias1},
                                    $v1rec->{alias2},
                                    $v1rec->{alias3}){
                  next if ($account=~m/^\s*$/);
                  $account=trim($account);
                  $acc->SetFilter({account=>$account});
                  $acc->SetCurrentView(qw(userid));
                  my ($accrec,$msg)=$acc->getFirst();
                  if (!defined($accrec)){
                     my %newacc=(account=>$account,userid=>$userid);
                     my $accid=$acc->ValidatedInsertRecord(\%newacc);
                  }
               }
            }
            my $acc=$v1rec->{account};
            if (!($acc=~m/^\s*$/)){
           
               my $bk=$self->W5ServerCall("rpcCallEvent","UserVerified",
                                          $v1rec->{account});
               if (!defined($bk->{AsyncID})){
                  msg(ERROR,"can't call UserVerified Event");
                  msg(ERROR,"%s",Dumper($bk));
                  exit(1);
               }
               else{
                  my $st;
                  my $n=10;
                  do{ 
                     $n--;
                     sleep(1);
                     $st=$self->W5ServerCall("rpcProcessState",$bk->{AsyncID});
                     print Dumper($st);
                  }while(!(defined($st->{process}->{exitcode}) ||
                          $st->{exitcode}!=0 ||
                          $n==0));
               }
            }
         }
         1;
   });
   return({msg=>'done'});
}


sub LoadFaq
{
   my $self=shift;
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   my %catmap=('Adresse/Telefonnummer'      =>'Organisation.Adressen',
               'Anwendung ARA'              =>'Anwendung.ARA',
               'Anwendung ITO'              =>'Anwendung.ITO',
               'Anwendung KUBE-BUEPLAF'     =>'Anwendung.KUBE-BUEPLAF',
               'Anwendung PMN'              =>'Anwendung.PMN',
               'Anwendung Rebell/Ironman'   =>'Anwendung.Rebell-Ironman',
               'Anwendung TGN'              =>'Anwendung.TGN',
               'Anwendungen Allgemein'      =>'Anwendung',
               'Betriebssystem BS2000'      =>'Betriebssystem.BS2000',
               'Betriebssystem HPUX'        =>'Betriebssystem.HPUX',
               'Betriebssystem Linux'       =>'Betriebssystem.Linux',
               'Betriebssystem OS/390'      =>'Betriebssystem.OS390',
               'Betriebssystem Solaris'     =>'Betriebssystem.Solaris',
               'Betriebssystem Tandem'      =>'Betriebssystem.Tandem',
               'Betriebssystem Windows'     =>'Betriebssystem.Windows',
               'Betriebssysteme allgemein'  =>'Betriebssystem',
               'Comercial Order Management' =>'ComercialOrderManagement',
               'Datenbank Oracle'           =>'Software.Datenbank.Oracle',
               'Datenbanken'                =>'Software.Datenbank',
               'Backupsoftware'             =>'Software.Backup',
               'Development'                =>'Development',
               'Hardware allgemein'         =>'Hardware',
               'Interne Organisation'       =>'Organisation.T-Systems',
               'Linux Autoinstall'          =>'Betriebssystem.Linux.Autoinstall',
               'Netzwerktechnik'            =>'Netzwerktechnik',
               'Projekt-AppCom'             =>'Projekt.AppCom',
               'Software allgemein'         =>'Software',
               'Software Tivoli'            =>'Software.Tivoli',
               'Software X11'               =>'Software.X11',
               'Sonstiges'                  =>'Sonstiges',
               'Storage'                    =>'Hardware.Storage',
               'T-Archiv'                   =>'NULL',
               'T-Systems CoD'         =>'Organisation.T-Systems.CoD',
               'Teaminfos AOC T-Com'   =>'Organisation.T-Systems.Team.AOC',
               'Teaminfos ST2'         =>'Organisation.T-Systems.Team.ST2',
               'Teaminfos STDB-Oracle' =>'Organisation.T-Systems.Team.STDB-Oracle',
               'W5Base Helpsystem'     =>'NULL',
               'WEB/HTML'              =>'Development.WEB_HTML');
   my @newcat=(values(%catmap),
               "Software.Datenbank.Informix","Software.Datenbank.DB2",
               "Development.Perl","Projekt");
   @newcat=grep(!/^NULL$/,sort(@newcat));
   my %faqcatid=();
   my $faqcat=getModuleObject($self->Config,"faq::category");
   foreach my $cat (@newcat){
      my $parentname;
      foreach my $sub (split(/\./,$cat)){
         my $fullname=$parentname;
         $fullname.="." if ($fullname ne "");
         $fullname.=$sub;
         msg(DEBUG,"try to create $fullname ($cat)");
         my %n=(name=>$sub);
         $n{parent}=$parentname if ($parentname ne "");
         my @l=$faqcat->ValidatedInsertOrUpdateRecord(\%n,
                                                   {fullname=>\$fullname});
         my $catid=$l[0];
         $faqcatid{$fullname}=$catid;
         $parentname.="." if ($parentname ne "");
         $parentname.=$sub;
      }
   }

   msg(DEBUG,"faqcat=%s",Dumper(\%faqcatid));
   $self->ImportGroup("uploader");
   my %usedgroups=("uploader"=>1);
   #return();
   my $faq1=getModuleObject($self->Config,"w5v1inv::faq");
   my $faq=getModuleObject($self->Config,"faq::article");
   my $faqacl=getModuleObject($self->Config,"faq::acl");
   $faq1->SetCurrentView(qw(ALL));
   #$faq1->SetFilter(id=>[qw(4256 4201)]);
   #$faq1->SetFilter(id=>[qw(4201)]);
   #$faq1->SetFilter(id=>[qw(4697)]);
   my ($rec,$msg)=$faq1->getFirst();

   do{
      
      msg(DEBUG,"loading %d '%s'",$rec->{id},$rec->{name});
      my $keywords=$rec->{kwords};
      $keywords=$rec->{name} if ($keywords eq "");
      $keywords=~s/[:;,\/()]//;
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));
   #msg(DEBUG,"faqrec=%s ownerid=$ownerid",Dumper($rec));exit(0);
      my $data=$rec->{data};
      if ($rec->{content}=~m/plain/){
         $data=~s/\n/\n<br>/g;
      }
      my $md=undef;
      if ($rec->{mdate} ne "00000000000000"){
         $md=$self->getParent->ExpandTimeExpression($rec->{mdate},"en","GMT");
      }
      my %newrec=(srcsys=>'W5Base1',srcid=>$rec->{id},
                  srcload=>$loadstart,
                  editor=>$rec->{owner},
                  owner=>$ownerid,
                  mdate=>$md,
                  cdate=>$md,
                  data=>$data,
                  kwords=>$keywords,
                  name=>$rec->{name});
      if ($rec->{content}=~m/pdf/){
         $newrec{kwords}="PDF";
         $newrec{data}="PDF could not be loaded";
      }
      my $newcat=$catmap{$rec->{class}};
      $newcat="Sonstiges" if (!defined($faqcatid{$newcat}));
      $newrec{faqcat}=$faqcatid{$newcat};
      if ($rec->{owner} ne "outlook-scz-sued-t5"){
         my @id=$faq->ValidatedInsertOrUpdateRecord(\%newrec,
                              {srcid=>\$rec->{id}, srcsys=>\'W5Base1'});
         my $faqid=$id[0];
         if ($faqid){
            my $editgroup=$rec->{admingroup};
            my $viewgroup=$rec->{viewgroup};
            if ($viewgroup ne "" && $viewgroup ne $editgroup){
               $usedgroups{$viewgroup}=1;
               my $g=$self->ImportGroup($viewgroup);
               if (defined($g)){
                  my %newacl=(refid=>$faqid,aclparentobj=>'faq::article',
                              acltarget=>'base::grp',
                              acltargetid=>$g->{grpid},
                              aclmode=>'read');
                  $faqacl->ValidatedInsertOrUpdateRecord(\%newacl,
                           {acltarget=>\$newacl{acltarget},
                            acltargetid=>\$newacl{acltargetid},
                            aclparentobj=>\$newacl{aclparentobj},
                            refid=>\$newacl{refid}});
               }
            }
            if ($editgroup ne ""){
               $usedgroups{$editgroup}=1;
               my $g=$self->ImportGroup($editgroup);
               if (defined($g)){
                  my %newacl=(refid=>$faqid,aclparentobj=>'faq::article',
                              acltarget=>'base::grp',
                              acltargetid=>$g->{grpid},
                              aclmode=>'write');
                  $faqacl->ValidatedInsertOrUpdateRecord(\%newacl,
                           {acltarget=>\$newacl{acltarget},
                            acltargetid=>\$newacl{acltargetid},
                            aclparentobj=>\$newacl{aclparentobj},
                            refid=>\$newacl{refid}});
               }
            }
         }
      }
      ($rec,$msg)=$faq1->getNext();
   } until(!defined($rec));
   foreach my $grp (sort(keys(%usedgroups))){
      msg(DEBUG,"usercheck on group %s",$grp);
      $self->VerifyMembers($grp);
   }
 
   return();

}


sub LoadProto
{
   my $self=shift;
   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from protokoll_header";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   my $wf=getModuleObject($self->Config,"base::workflow");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      $self->ProcessChange($wf,$rec) if ($rec->{prott} eq "proto_change");
   }
}

sub Normal
{
   return(undef) if (!defined($_[0]));
   return($_[0]->[0]) if (ref($_[0]) eq "ARRAY");
   return($_[0]);
}

sub ProcessChange
{
   my $self=shift;
   my $wf=shift;
   my $rec=shift;
   my $app=$self->getParent();
   msg(INFO,"Process Change: %s",$rec->{filename});
   #msg(INFO,"Rec\n%s",Dumper($rec));
   my %ref=Datafield2Hash($rec->{referenz});
   $wf->SetFilter(id=>$rec->{id});
   $wf->ForeachFilteredRecord(sub{
      $wf->ValidatedDeleteRecord($_);
   });
   my %wfrec;
   $wfrec{id}=$rec->{id};
   $wfrec{name}=$rec->{filename};
   $wfrec{changedescription}=Normal($ref{auswirkungen});
   $wfrec{changefallback}=Normal($ref{fallback});
   $wfrec{eventstart}=$app->ExpandTimeExpression(Normal($ref{planed_from}),
                                             "en","CET");
   $wfrec{eventend}=$app->ExpandTimeExpression(Normal($ref{planed_to}),
                                           "en","CET");
   $wfrec{closedate}=$app->ExpandTimeExpression(Normal($ref{close_time}),
                                           "en","CET");
   $wfrec{state}=21;
   $wfrec{state}=4 if (!$rec->{state});
   $wfrec{mdate}=$app->ExpandTimeExpression($rec->{mdate},"en","CET");
   $wfrec{createdate}=$app->ExpandTimeExpression($rec->{odate},"en","CET");
   if (defined($ref{anwendungsname}) && $#{$ref{anwendungsname}}!=-1){
      $wfrec{affectedapplication}=$ref{anwendungsname};
   }
   if (defined($ref{bcappw5baseid}) && $#{$ref{bcappw5baseid}}!=-1){
      $wfrec{affectedapplicationid}=$ref{bcappw5baseid};
   }

   $wfrec{additional}={
      W5BaseV1load=>"yes",
      ServiceCenterChangeNumber=>Normal($ref{changenumber}),
      ServiceCenterState=>Normal($ref{extstatus}),
      ServiceCenterRisk=>Normal($ref{sc_risk}),
      ServiceCenterCategory=>Normal($ref{sc_category}),
      ServiceCenterUrgency=>Normal($ref{sc_urgency}),
      ServiceCenterReason=>Normal($ref{reason}),
      ServiceCenterPriority=>Normal($ref{sc_priority}),
      ServiceCenterImpact=>Normal($ref{sc_impact}),
      ServiceCenterChangeLocation=>Normal($ref{changelocation}),
      ServiceCenterRequestedBy=>$rec->{owner}
   };
   $wfrec{class}='AL_TCom::workflow::change';
   $wfrec{step}='itil::workflow::change::extauthority';
   $wfrec{srcid}=Normal($ref{changenumber});

   my $id=$wf->ValidatedInsertRecord(\%wfrec);
   msg(DEBUG,"Workflow inserted at id '$id'");
}


sub LoadCustContract
{
   my $self=shift;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select bccontract.*,bcbereiche.name as orgareaname ".
           "from bccontract left outer join bcbereiche on ".
           "bccontract.orgarea=bcbereiche.id";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   my $custcontract=getModuleObject($self->Config,"itil::custcontract");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      next if (defined($rec->{valid_to}) && $rec->{valid_to} ne "");
      next if ($rec->{cistatus}!=4);
      msg(INFO,"======= process contract $rec->{id} =======================");
      next if ($rec->{name}=~m/^BC-Admin.*/);
      next if ($rec->{name}=~m/^Text CON.*/);
      next if ($rec->{name}=~m/^Test010101/);
      next if ($rec->{name}=~m/^Test020202/);
      next if ($rec->{name}=~m/^Test030303/);
      if (my %newrec=$self->PrepareContract($rec)){
         $custcontract->ValidatedInsertOrUpdateRecord(\%newrec,
                             {name=>\$newrec{name}});
      }
      #exit(0);
   }
   # cleanup
   $custcontract->SetFilter({srcload=>"\"<$loadstart\"",srcsys=>\'W5BaseV1'});
   $custcontract->ForeachFilteredRecord(sub{
       $custcontract->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}

sub PrepareContract
{
   my $self=shift;
   my $rec=shift;
   my %newrec=();
 
   $rec->{vertnr}=~s/\s/_/g; 
   $newrec{srcsys}="W5BaseV1";
   $newrec{srcid}=$rec->{id};
   $newrec{srcload}=$self->getParent->ExpandTimeExpression("now","en","GMT");
   $newrec{id}=$rec->{id};
   $newrec{name}=$rec->{vertnr};
   $newrec{name}=~s/ä/ae/g;
   $newrec{fullname}=$rec->{name};
   $newrec{responseteamid}=$self->TranslateOrg($rec->{orgarea});
   $newrec{cistatusid}=$rec->{cistatus};
   $newrec{editor}=$rec->{owner};
   $newrec{comments}=$rec->{info};
   $newrec{databossid}=$self->getUserIdByV1($rec->{sem});
   $newrec{semid}=$self->getUserIdByV1($rec->{sem});
   $newrec{sem2id}=$self->getUserIdByV1($rec->{sem2});
   if (my ($Y,$M,$D)=$rec->{laufzbegin}=~m/^(\d{4})(\d{2})(\d{2})/){
      $newrec{durationstart}=$self->getParent->ExpandTimeExpression(
                                              "$Y-$M-$D","en","CET");
   }
   if (my ($Y,$M,$D)=$rec->{laufzende}=~m/^(\d{4})(\d{2})(\d{2})/){
      $newrec{durationend}=$self->getParent->ExpandTimeExpression(
                                              "$Y-$M-$D","en","CET");
   }
   if ($rec->{orgareaname}=~m/\.ILTMU.*T-Com.*/i){
      $newrec{mandatorid}=200; # AL-TCom
   }
   else{
      $newrec{mandatorid}=12; #extern
   }
   return(%newrec);
}


sub getUserIdByV1
{
   my $self=shift;
   my $dest=shift;
   if (!defined($self->{userv1})){
      $self->{userv1}=getModuleObject($self->Config,"w5v1inv::user");
   }
   if (!defined($self->{userv2})){
      $self->{userv2}=getModuleObject($self->Config,"base::user");
   }
   my $account;
   if ($dest=~m/^\d+$/ && $dest!=0){
      $self->{userv1}->SetFilter(id=>\$dest);
      my ($rec,$msg)=$self->{userv1}->getOnlyFirst(qw(account));
      $dest=$rec->{account};
      return(undef) if ($dest eq "");
   }
   
   $self->{userv2}->SetFilter(accounts=>\$dest);
   my ($rec,$msg)=$self->{userv2}->getOnlyFirst(qw(userid));
   if (defined($rec)){
      return($rec->{userid});
   }
   return(undef);
}


sub LoadApp
{
   my $self=shift;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $dbcall=new kernel::database($self->getParent,"w5v1");
   if (!$dbcall->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select bcapp.*,bcbereiche.name as orgarea ".
           "from bcapp left outer join bcbereiche ".
           "on bcapp.vieworgarea=bcbereiche.id";
   #$cmd.=" where bcapp.id=279";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   my $app=getModuleObject($self->Config,"AL_TCom::appl");
   my $mandator=getModuleObject($self->Config,"base::mandator");
   my $phone=getModuleObject($self->Config,"base::phonenumber");
   $self->{mandator}=$mandator->getHashIndexed(qw(grpid id));
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      next if ($rec->{cistatus}!=4);
      if (my %newrec=$self->PrepareApp($rec)){
         $app->ValidatedInsertOrUpdateRecord(\%newrec,
                             {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
         $cmd="select * from contactcall where app='bcapp' ".
              "and ref='$rec->{id}'";
         if (!$dbcall->execute($cmd)){
            return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
         }
         else{
            while(my ($callrec,$msg)=$dbcall->fetchrow()){
               last if (!defined($callrec));
               if (!($callrec->{tnumber}=~m/^\s*$/) && $newrec{srcid} ne ""){
                  my $name="phoneMISC";
                  $name="phoneRB"  if ($callrec->{tnumbertyp}=~m/rufbereit/i);
                  $name="phoneDEV" if ($callrec->{tnumbertyp}=~m/entwickler/i);
                  $phone->ValidatedInsertOrUpdateRecord(
                             {parentobj=>'itil::appl',
                              refid=>$newrec{srcid},
                              name=>$name,
                              comments=>$callrec->{tnumbertyp}."\n".
                                        $callrec->{info},
                              srcsys=>'W5BaseV1',
                              phonenumber=>$callrec->{tnumber}},
                             {parentobj=>\'itil::appl',refid=>\$newrec{srcid},
                              phonenumber=>\$callrec->{tnumber},
                              srcsys=>'W5BaseV1'});
               }
            }
         }
      }
      msg(INFO,"%s",Dumper($rec));
      #exit(0);
   }
   # cleanup
   $app->SetFilter(srcload=>"\"<$loadstart\"");
   $app->ForeachFilteredRecord(sub{
       $app->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub PrepareApp
{
   my $self=shift;
   my $rec=shift;
   my %newrec=();

   my $mandator=$rec->{vieworgarea};
   return(undef) if ($rec->{orgarea}=~m/^TSI.CS-Unit5\..*/);
   $mandator=351 if ($rec->{name}=~m/^SAP_/);
   $mandator=200 if ($mandator==415);  # falls ILTMU dann SSM.ILS
   $mandator=200 if ($mandator==230);  # falls ILTMU dann CSS.T-COM verwenden
   $mandator=12  if ($mandator==0);    # alle nicht definierten auf Extern
   $mandator=351 if ($rec->{orgarea}=~m/\.SAP\./); # alles was AL SAP ist
   $mandator=200 if ($rec->{orgarea}=~m/\.CS-Unit7\./); # alles was alt CSU7
   $mandator=200 if ($rec->{orgarea}=~m/^DTAG\.TSI\.ES\.ITO\.CSS/);
   $mandator=200 if ($rec->{orgarea}=~m/^DTAG\.TSI\.ES\.SSM\.ILTMU/);
   $mandator=200 if ($rec->{orgarea}=~m/^DTAG\.TSI$/);
   $mandator=12  if ($rec->{orgarea}=~m/^DTAG$/);
   $mandator=12  if ($rec->{orgarea}=~m/^DTAG\.T-Com$/);
   $mandator=12  if ($rec->{orgarea}=~m/^DTAG.Sireo$/);
   $mandator=12  if ($rec->{orgarea}=~m/^Kunde$/);
   #$mandator=200 if ($rec->{orgarea} eq "");  # falls kein Bereich - dann T-Com
   if (!defined($self->{mandator}->{grpid}->{$mandator})){
   #   msg(ERROR,"can't find mandator for app '%s' in area '%s'(%d)",
   #             $rec->{name},$rec->{orgarea},$rec->{vieworgarea});
      $mandator=12;
   #   return(undef);
   }
   $newrec{id}=$rec->{id};
   $newrec{name}=$rec->{name};
   $newrec{cistatusid}=$rec->{cistatus};
   $newrec{currentvers}=$rec->{wirkvers};
   $newrec{maintwindow}=$rec->{wartfenster};
   $newrec{maintwindow}=~s/<br>/\n/gi;
   $newrec{customerprio}=$rec->{kndprio};
   $newrec{responseteamid}=$self->TranslateOrg($rec->{bcbereich});
   $newrec{businessteamid}=$self->TranslateOrg($rec->{teamorgarea});
   $newrec{mandatorid}=$mandator;
   $newrec{conumber}=$rec->{conummer};
   $newrec{customerid}=$rec->{kndorgarea};
   $newrec{description}=$rec->{appdoku};
   $newrec{isnosysappl}=$rec->{is_licapp};
   if ($rec->{agnummer}=~m/^\d+$/ && $rec->{agnummer} ne "" &&
       $rec->{agnummer} ne "0"){
      $newrec{applnumber}=$rec->{agnummer};
   }
   else{
      $newrec{applnumber}="";
   }
   $newrec{databossid}=$self->getUserIdByV1($rec->{databoss});;
   $newrec{semid}=$self->getUserIdByV1($rec->{sem});;
   $newrec{sem2id}=$self->getUserIdByV1($rec->{sem2});;
   $newrec{tsmid}=$self->getUserIdByV1($rec->{tsm});;
   $newrec{tsm2id}=$self->getUserIdByV1($rec->{tsm2});;
   $newrec{creator}=$self->getUserIdByV1($rec->{owner});;
   $newrec{owner}=$self->getUserIdByV1($rec->{owner});;
   $newrec{allowoncall}=$rec->{is_herbeiruf};
   $newrec{slacontroltool}=$rec->{slatooltype};
   if ($newrec{slacontroltool} eq "bigbrother"){
      $newrec{slacontroltool}="BigBrother";
   }
   if ($newrec{slacontroltool} eq "tivolli"){
      $newrec{slacontroltool}="Tivoli";
   }
   if ($newrec{slacontroltool} eq "none"){
      $newrec{slacontroltool}="no SLA control";
   }
   if ($newrec{slacontroltool} eq "sap_reporter"){
      $newrec{slacontroltool}="SAP-Reporter";
   }
   $newrec{slacontravail}=$rec->{slaverfueg};
   $newrec{slacontravail}=undef if ($newrec{slacontravail}==0.0);
   $newrec{srcsys}="W5BaseV1";
   $newrec{srcid}=$rec->{id};
   $newrec{srcload}=$self->getParent->ExpandTimeExpression("now","en","GMT");
   return(%newrec);
}

sub TranslateOrg
{
   my $self=shift;
   my $oaid=shift;

   my $oa=getModuleObject($self->Config,"w5v1inv::orgarea");
   $oa->SetFilter({id=>$oaid});
   $oa->SetCurrentView(qw(ldapid fullname));
   my ($rec,$msg)=$oa->getFirst();
   msg(INFO,"TranslateOrg:oldrec=%s",Dumper($rec));
   if (defined($rec) && $rec->{fullname} ne ""){
      my $grp=getModuleObject($self->Config,"base::grp");
      $grp->SetFilter({fullname=>\$rec->{fullname}});
      $grp->SetCurrentView(qw(grpid));
      my ($grec,$msg)=$grp->getFirst();
      msg(INFO,"TranslateOrg:newrec=%s",Dumper($grec));
      if (defined($grec)){
         return($grec->{grpid});
      }
   } 
   elsif (defined($rec) && $rec->{ldapid} ne ""){
      msg(INFO,"TranslateOrg:loading=%s",$rec->{ldapid});
      my $grp=getModuleObject($self->Config,"base::grp");
      $grp->SetFilter({srcid=>\$rec->{ldapid}});
      $grp->SetCurrentView(qw(grpid));
      my ($grec,$msg)=$grp->getFirst();
      msg(INFO,"TranslateOrg:newrec=%s",Dumper($grec));
      if (defined($grec)){
         return($grec->{grpid});
      }
   }
   return($oaid);
}

sub LoadAppContract
{
   my $self=shift;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from lnkbcappbccontract";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{contract}=getModuleObject($self->Config,"itil::custcontract");
   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   my $lnk=getModuleObject($self->Config,"itil::lnkapplcustcontract");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      if (my %newrec=$self->PrepareAppContract($rec)){
         $lnk->ValidatedInsertOrUpdateRecord(\%newrec,
                             {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      }
      print Dumper($rec);
      #exit(0);
   }
   # cleanup
   $lnk->SetFilter(srcload=>"\"<$loadstart\"");
   $lnk->ForeachFilteredRecord(sub{
       $lnk->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub PrepareAppContract
{
   my $self=shift;
   my $rec=shift;
   my %newrec=();

   $self->{contract}->SetFilter({id=>\$rec->{bccontract}});
   my ($chkrec,$msg)=$self->{contract}->getOnlyFirst("id");
   return() if (!defined($chkrec));

   $self->{appl}->SetFilter({id=>\$rec->{bcapp}});
   my ($chkrec,$msg)=$self->{appl}->getOnlyFirst("id");
   return() if (!defined($chkrec));

   $newrec{applid}=$rec->{bcapp};
   $newrec{custcontractid}=$rec->{bccontract};
   $newrec{fraction}=$rec->{fraction};
   $newrec{srcsys}="W5BaseV1";
   $newrec{srcid}=$rec->{id};
   $newrec{srcload}=$self->getParent->ExpandTimeExpression("now","en","GMT");
   return(%newrec);
}


sub LoadLicContract
{
   my $self=shift;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from bcmwcont";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{contract}=getModuleObject($self->Config,"itil::liccontract");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      $rec->{cistatus}=4 if (!defined($rec->{cistatus}));
      my %newrec=(name=>$rec->{name},
                  id=>$rec->{id},
                  semid=>$rec->{bccontact},
                  softwareid=>$rec->{bcmw},
                  mandatorid=>200,   # AL-T-Com
                  responseteamid=>$self->TranslateOrg($rec->{orgarea}),
                  cistatusid=>$rec->{cistatus},
                  srcload=>$loadstart,
                  owner=>$self->getUserIdByV1($rec->{owner}),
                  creator=>$self->getUserIdByV1($rec->{owner}),
                  srcid=>$rec->{id},
                  srcsys=>"W5BaseV1",
                 );
      print Dumper($rec);
      $self->{contract}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      #exit(0);
   }
   # cleanup
   $self->{contract}->SetFilter(srcload=>"\"<$loadstart\"");
   $self->{contract}->ForeachFilteredRecord(sub{
       $self->{contract}->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}

sub LoadSoftware
{
   my $self=shift;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $lnkdb=new kernel::database($self->getParent,"w5v1");
   if (!$lnkdb->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from mw";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{software}=getModuleObject($self->Config,"itil::software");
   $self->{lnks}=getModuleObject($self->Config,"itil::lnksoftwaresystem");
   $self->{prod}=getModuleObject($self->Config,"itil::producer");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      $rec->{cistatus}=4 if (!defined($rec->{cistatus}));
      $self->{prod}->SetFilter(name=>\$rec->{herstel});
      my ($p,$msg)=$self->{prod}->getOnlyFirst("id");
      my $herstel=$p->{id};
      $herstel=0 if (!defined($herstel));
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));
      my %newrec=(name=>$rec->{name},
                  id=>$rec->{id},
                  cistatusid=>$rec->{cistatus},
                  producerid=>$herstel,
                  releaseexp=>$rec->{relexp},
                  srcload=>$loadstart,
                  owner=>$ownerid,
                  creator=>$ownerid,
                  srcid=>$rec->{id},
                  srcsys=>"W5BaseV1",
                 );
      print Dumper($rec);
      $self->{software}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      my $lnkcmd="select lnkmwbchw.* from lnkmwbchw,bchw where ".
                 "lnkmwbchw.bchw=bchw.id and lnkmwbchw.mw='$rec->{id}' ".
                 "and bchw.cistatus<=4";
      foreach my $lnk ($lnkdb->getHashList($lnkcmd)){
         my $owner=$self->getUserIdByV1($lnk->{owner});
         my %newrec=(srcsys=>'W5BaseV1',srcid=>$lnk->{id},srcload=>$loadstart,
                     creator=>$owner,owner=>$owner,
                     quantity=>$lnk->{licencecount},
                     version=>$lnk->{version},
                     mdate=>scalar($self->getParent->ExpandTimeExpression(
                            $lnk->{mdate},"en","GMT")),
                     softwareid=>$rec->{id},systemid=>$lnk->{bchw}); 
         $self->{lnks}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      }

      #exit(0);
   }
   # cleanup
   $self->{software}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\'W5BaseV1');
   $self->{software}->ForeachFilteredRecord(sub{
       $self->{software}->ValidatedDeleteRecord($_);
   });
   $self->{lnks}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\'W5BaseV1');
   $self->{lnks}->ForeachFilteredRecord(sub{
       $self->{lnks}->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub LoadProducer
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from dropbox_herstell where name like 'i%'";
   my $cmd="select * from dropbox_herstell";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{prod}=getModuleObject($self->Config,"itil::producer");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      $rec->{cistatus}=4 if (!defined($rec->{cistatus}));
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));
      my %newrec=(
           name=>$rec->{name},
           id=>$rec->{id},
           cistatusid=>$rec->{cistatus},
           srcload=>$loadstart,
           owner=>$ownerid,
           creator=>$ownerid,
           mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
           srcid=>$rec->{id},
           srcsys=>"W5BaseV1",
           );
      print Dumper($rec);
      $self->{prod}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      #exit(0);
   }
   # cleanup
   $self->{prod}->SetFilter(srcload=>"\"<$loadstart\"");
   $self->{prod}->ForeachFilteredRecord(sub{
       $self->{prod}->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub LoadPlatform
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from dropbox_platform";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{platform}=getModuleObject($self->Config,"itil::platform");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      $rec->{cistatus}=4 if (!defined($rec->{cistatus}));
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));
      my %newrec=(name=>$rec->{name},
          id=>$rec->{id},
          cistatusid=>$rec->{cistatus},
          hwbits=>$rec->{hwbits},
          srcload=>$loadstart,
          owner=>$ownerid,
          creator=>$ownerid,
          mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
          srcid=>$rec->{id},
          srcsys=>"W5BaseV1",
                 );
      print Dumper($rec);
      $self->{platform}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      #exit(0);
   }
   # cleanup
   $self->{platform}->SetFilter(srcload=>"\"<$loadstart\"");
   $self->{platform}->ForeachFilteredRecord(sub{
       $self->{platform}->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub LoadOsrelease
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from dropbox_osrelease";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{osrelease}=getModuleObject($self->Config,"itil::osrelease");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      $rec->{cistatus}=4 if (!defined($rec->{cistatus}));
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));
      my %newrec=(name=>$rec->{name},
                  id=>$rec->{id},
                  cistatusid=>$rec->{cistatus},
                  srcload=>$loadstart,
                  owner=>$ownerid,
                  creator=>$ownerid,
                  mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                  srcid=>$rec->{id},
                  srcsys=>"W5BaseV1",
                 );
      print Dumper($rec);
      $self->{osrelease}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      #exit(0);
   }
   # cleanup
   $self->{osrelease}->SetFilter(srcload=>"\"<$loadstart\"");
   $self->{osrelease}->ForeachFilteredRecord(sub{
       $self->{osrelease}->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub LoadInterfaces
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from bcappconnect";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{lnkapplappl}=getModuleObject($self->Config,"itil::lnkapplappl");
   my $appl=getModuleObject($self->Config,"itil::appl");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));

      $appl->SetFilter(id=>\$rec->{bcappfrom});
      my ($chkrec,$msg)=$appl->getOnlyFirst(qw(id));
      next if (!defined($chkrec));

      $appl->SetFilter(id=>\$rec->{bcappto});
      my ($chkrec,$msg)=$appl->getOnlyFirst(qw(id));
      next if (!defined($chkrec));
      $rec->{conprot}="unknown" if ($rec->{conprot} eq "");

      my %newrec=(fromapplid=>$rec->{bcappfrom},
                  toapplid=>$rec->{bcappto},
                  conproto=>$rec->{conprot},
                  conmode=>$rec->{modus},
                  contype=>$rec->{contype},
                  comments=>$rec->{info},
                  id=>$rec->{id},
                  srcload=>$loadstart,
                  owner=>$ownerid,
                  creator=>$ownerid,
                  mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},
                                "en","GMT")),
                  cdate=>scalar($app->ExpandTimeExpression($rec->{mdate},
                                "en","GMT")),
                  srcid=>$rec->{id},
                  srcsys=>"W5BaseV1",
                 );
      $newrec{conproto}="DB-Link"   if ($newrec{conproto} eq "DB-Lin");
      $newrec{conproto}="MQSeries"  if ($newrec{conproto} eq "xml(MQ");
      $newrec{conproto}="Netegrity" if ($newrec{conproto} eq "Netegr");
      $newrec{conproto}="pkix-cmp"  if ($newrec{conproto} eq "pkix-c");
      delete($newrec{conmode}) if ($newrec{conmode} eq "");
      #print Dumper($rec);
      $self->{lnkapplappl}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
   }
   # cleanup
   $self->{lnkapplappl}->SetFilter(srcsys=>\"W5BaseV1",
                                   srcload=>"\"<$loadstart\"");
   $self->{lnkapplappl}->ForeachFilteredRecord(sub{
       $self->{lnkapplappl}->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub LoadSystem
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   my $osydb=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   if (!$osydb->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from bchw where srcsys='w5base' and cistatus=4";
   #my $cmd="select * from bchw where srcsys='w5base' and cistatus=4 and name like 'g8nzbwb%'";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{lnksys}=getModuleObject($self->Config,"itil::lnkapplsystem");
   $self->{sys}=getModuleObject($self->Config,"itil::system");
   $self->{hw}=getModuleObject($self->Config,"itil::asset");
   $self->{model}=getModuleObject($self->Config,"itil::hwmodel");
   $self->{os}=getModuleObject($self->Config,"itil::osrelease");
   $self->{prod}=getModuleObject($self->Config,"itil::producer");
   $self->{oldloc}=getModuleObject($self->Config,"w5v1inv::location");
   $self->{newloc}=getModuleObject($self->Config,"base::location");
   $self->{con}=getModuleObject($self->Config,"base::lnkcontact");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   my %lnkoldnew=();
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));

      my $prod;
      $self->{prod}->SetFilter(name=>\$rec->{herstel});
      my ($chkrec,$msg)=$self->{prod}->getOnlyFirst(qw(id));
      if (defined($chkrec)){
         $prod=$chkrec->{id};
      }
      my %sys_mandatorenv=(mandatorid=>200);
      my %ass_mandatorenv=(mandatorid=>200);

      my $osycmd="select hw.*,grp.name as editgroupname from hw ".
                 "left outer join grp on hw.editgroup=grp.id ".
                 "where hw.name like '$rec->{name}'";
      if (!$osydb->execute($osycmd)){
         return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$osycmd)});
      }
      while(my ($osyrec,$msg)=$osydb->fetchrow()){
         last if (!defined($osyrec));
         next if (!defined($osyrec->{editgroup}) ||
                   $osyrec->{editgroup}==0 || $osyrec->{editgroup} eq "");
         my $g=$self->ImportGroup($osyrec->{editgroupname});
         if (defined($g)){
            $sys_mandatorenv{mandatorid}=1168;
            $sys_mandatorenv{adminteamid}=$g->{grpid};
            $ass_mandatorenv{mandatorid}=1168;
            $ass_mandatorenv{guardianteamid}=$g->{grpid};
         }
      }
      my $assetid;
      if (defined($rec->{ager}) && $rec->{ager} ne ""){
         my $oldloc=$rec->{loc};
         $self->{oldloc}->SetFilter({id=>\$oldloc});
         my ($lrec)=$self->{oldloc}->getOnlyFirst(qw(ALL));
         my $newloc=$self->{newloc}->getLocationByHash(label=>$lrec->{name},
                                                    address1=>$lrec->{address1},
                                                    location=>$lrec->{location},
                                                    srcsys=>"W5BaseV1",
                                                    srcid=>$lrec->{id},
                                                    country=>'DE',
                                                    zipcode=>$lrec->{zipcode});
         my $ager=uc($rec->{ager});
         $ager=~s/\s//g;
         my %newrec=(
                %ass_mandatorenv,              # AL-TCom is default
                name=>$ager,
                serialno=>$rec->{snr},
                room=>$rec->{raumnr},
                cistatusid=>4,
                srcload=>$loadstart,
                owner=>$ownerid,
                creator=>$ownerid,
                mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                cdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                srcid=>$rec->{id},
                srcsys=>"W5BaseV1",
               );
         $newrec{locationid}=$newloc if ($newloc!=0);
         my $hwmodel=$rec->{model}; 
         if ($hwmodel ne ""){
            $self->{model}->SetFilter({name=>\$hwmodel});
            my ($rec,$msg)=$self->{model}->getOnlyFirst(qw(id));
            if (defined($rec)){
               $newrec{hwmodelid}=$rec->{id};
            }
         }
         ($assetid)=$self->{hw}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {name=>$newrec{name}});
         msg(INFO,"W5BaseID of asset=%d",$assetid);
         if ($newrec{guardianteamid}!=0){
            my $con={target=>'base::grp',refid=>$assetid,
                     parentobj=>'itil::system',
                     targetid=>$newrec{guardianteamid},
                     srcsys=>'W5BaseV1'};
            if (!defined($self->{con}->ValidatedInsertOrUpdateRecord($con,
                                  {target=>\'base::grp',
                                   refid=>\$assetid,
                                   parentobj=>\'itil::system',
                                   targetid=>\$newrec{guardianteamid}}))){
               msg(ERROR,"failed to insert guardianteam=%s",Dumper($con));
            }
         }
      }
      my $os;
      $self->{os}->SetFilter(name=>\$rec->{osrelease});
      my ($chkrec,$msg)=$self->{os}->getOnlyFirst(qw(id));
      if (defined($chkrec)){
         $os=$chkrec->{id};
      }
      my %newrec=(name=>$rec->{name},
                  id=>$rec->{id},
                  %sys_mandatorenv,            
                  shortdesc=>$rec->{keywords},
                  kwords=>$rec->{keywords},
                  comments=>$rec->{info},
                  cpucount=>$rec->{cpucount},
                  memory=>$rec->{memory},
                  assetid=>uc($assetid),
                  systemid=>uc($rec->{sger}),
                  osreleaseid=>$os,
                  cistatusid=>4,

                  isprod=>$rec->{is_prod},
                  istest=>$rec->{is_test},
                  isdevel=>$rec->{is_entw},
                  iseducation=>$rec->{is_schul},
                  isapprovtest=>$rec->{is_abna},
                  isreference=>$rec->{is_referenz},

                  isworkstation=>$rec->{is_ws},
                  isprinter=>$rec->{is_printer},
                  isbackupsrv=>$rec->{is_back},
                  isdatabasesrv=>$rec->{is_db},
                  iswebserver=>$rec->{is_web},
                  ismailserver=>$rec->{is_mail},
                  isrouter=>$rec->{is_router},
                  isterminalsrv=>$rec->{is_ts},

                  srcload=>$loadstart,
                  owner=>$ownerid,
                  creator=>$ownerid,
                  mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                  cdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                  srcid=>$rec->{id},
                  srcsys=>"W5BaseV1",
                 );
      #msg(INFO,Dumper($rec));
      my ($w5sysid)=$self->{sys}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      $lnkoldnew{$rec->{id}}=$w5sysid;
      if ($newrec{adminteamid}!=0){
         my $con={target=>'base::grp',refid=>$w5sysid,
                  parentobj=>'itil::system',
                  roles=>['write'],
                  targetid=>$newrec{adminteamid},
                  srcsys=>'W5BaseV1'};
         if (!defined($self->{con}->ValidatedInsertOrUpdateRecord($con,
                               {target=>\'base::grp',
                                refid=>\$w5sysid,
                                parentobj=>\'itil::system',
                                targetid=>\$newrec{adminteamid}}))){
            msg(ERROR,"failed to insert adminteam=%s",Dumper($con));
         }
      }
   }
   #msg(DEBUG,"lnkoldnew=%s",Dumper(\%lnkoldnew));
   foreach my $oldid (keys(%lnkoldnew)){
      msg(INFO,"loading application system relation for hwid $oldid");
      my $newid=$lnkoldnew{$oldid};
      my $cmd="select *,lnkbcappbchw.id as lnkid from lnkbcappbchw,bcapp ".
              "where lnkbcappbchw.bcapp=bcapp.id and bcapp.cistatus<=4 and ".
              "lnkbcappbchw.bchw='$oldid'";
      if (!$db->execute($cmd)){
         return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
      }
      while(my ($rec,$msg)=$db->fetchrow()){
         last if (!defined($rec));
         my $ownerid=$self->getUserIdByV1($rec->{owner});
         $ownerid=0 if (!defined($ownerid));
         my %newrec=(applid=>$rec->{bcapp},
                     systemid=>$newid,
                     creator=>$ownerid,
                     srcsys=>'W5BaseV1',
                     srcload=>$loadstart,
                     srcid=>$rec->{lnkid},
                     fraction=>$rec->{fraction});
         $self->{lnksys}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {applid=>\$newrec{applid},
                             systemid=>\$newrec{systemid}});
      }
   }

   #
   # Handle OSY Tables
   #


   $self->LoadOsySystems($loadstart);



   # cleanup
   $self->{sys}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\"W5BaseV1");
   $self->{sys}->ForeachFilteredRecord(sub{
       $self->{sys}->ValidatedDeleteRecord($_);
   });
   $self->{hw}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\"W5BaseV1");
   $self->{hw}->ForeachFilteredRecord(sub{
       $self->{hw}->ValidatedDeleteRecord($_);
   });
   $self->{lnksys}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\"W5BaseV1");
   $self->{lnksys}->ForeachFilteredRecord(sub{
       $self->{lnksys}->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub LoadIP
{
   my $self=shift;

   my $srcload;
   if ($srcload eq ""){
      $srcload=$self->getParent->ExpandTimeExpression("now","en","GMT");
   }
   my $ip=$self->getParent->getPersistentModuleObject("itil::ipaddress");
   my $net=$self->getParent->getPersistentModuleObject("itil::network");

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   $net->ResetFilter();
   $net->SetCurrentView(qw(ALL));
   my $net=$net->getHashIndexed("id","name");


   my @apps=qw(bchw hw);
   #my @apps=qw(bchw);

   foreach my $app (@apps){
      my $cmd;
      if ($app eq "bchw"){
         $cmd="select *,bchw.name as systemname ".
              "from ip,bchw where ip.app='$app' ".
              "and ip.hardware=bchw.id and bchw.name like '%'";
      }
      if ($app eq "hw"){
         $cmd="select *,hw.name as systemname ".
              "from ip,hw where ip.app='$app' ".
              "and ip.hardware=hw.id";
      }
     
      if (!$db->execute($cmd)){
         return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
      }
      while(my ($iprec,$msg)=$db->fetchrow()){
         last if (!defined($iprec));
         msg(INFO,"load ip=%s app=%s systemname=%s netname=%s",
                  $iprec->{addr},$iprec->{app},$iprec->{systemname},
                  $iprec->{netname});
         my $name=$iprec->{addr};
         $name=~s/\s//g;
         $name=~s/^[0]+([1-9])/$1/g;
         $name=~s/\.[0]+([1-9])/.$1/g;
         my $newip={name=>$name,cistatusid=>4,
                    addresstyp=>$iprec->{typ}, 
                    iscontrolpartner=>0,
                    editor=>$iprec->{owner},
                    realeditor=>$iprec->{owner},
                    srcsys=>"W5BaseV1",
                    srcload=>$srcload,
                    dnsname=>$iprec->{dnsname},
                    system=>$iprec->{systemname}};
         $iprec->{netname}="0,HitNet" if ($iprec->{netname} eq "");
         if ($iprec->{netname} eq "0,HitNet"){
            my $id=$net->{name}->{'Deutsche Telekom HitNet'}->{id};
            if ($id ne ""){
               $newip->{'networkid'}=$id;
            }
         }
         elsif ($iprec->{netname} eq "65536,Kunden-/Insel-Netz"){
            $newip->{'networkid'}=1;
         }
         else{
            $newip->{'networkid'}=undef;
         }
         $newip->{'iscontrolpartner'}=1 if ($iprec->{typ}==0);
         my ($w5id)=$ip->ValidatedInsertOrUpdateRecord($newip,
                    {name=>\$newip->{name},cistatusid=>\'4'});
      }
   }
   $ip->SetFilter(srcload=>"\"<$srcload\"",srcsys=>\"W5BaseV1");
   $ip->ForeachFilteredRecord(sub{
       $ip->ValidatedDeleteRecord($_);
   });
}

sub LoadOsySystems
{
   my $self=shift;
   my $srcload=shift;

   if ($srcload eq ""){
      $srcload=$self->getParent->ExpandTimeExpression("now","en","GMT");
   }

   my $osydb=new kernel::database($self->getParent,"w5v1");
   my $sys=$self->getParent->getPersistentModuleObject("itil::system");
   my $ass=$self->getParent->getPersistentModuleObject("itil::asset");
   my $osr=$self->getParent->getPersistentModuleObject("itil::osrelease");
   my $hwm=$self->getParent->getPersistentModuleObject("itil::hwmodel");
   my $con=$self->getParent->getPersistentModuleObject("base::lnkcontact");
   my $newloc=$self->getParent->getPersistentModuleObject("base::location");
   my $oldloc=$self->getParent->getPersistentModuleObject("w5v1inv::location");
   $osr->SetCurrentView(qw(ALL));
   my $os=$osr->getHashIndexed(qw(name));
   $hwm->SetCurrentView(qw(ALL));
   my $hwmodel=$hwm->getHashIndexed(qw(name));
   if (!$osydb->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $osycmd="select hw.*,grp.name as editgroupname from hw ".
              "left outer join grp on hw.editgroup=grp.id ".
              "where hw.cistatus=4 and hw.name like '\%\%'";
   if (!$osydb->execute($osycmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$osycmd)});
   }
   while(my ($osyrec,$msg)=$osydb->fetchrow()){
      last if (!defined($osyrec));
      next if (!defined($osyrec->{editgroup}) ||
                $osyrec->{editgroup}==0 || $osyrec->{editgroup} eq "");
      #print STDERR Dumper($osyrec);
      my $g=$self->ImportGroup($osyrec->{editgroupname});
      my $osid=$os->{name}->{$osyrec->{osrelease}}->{id};
      my $hwmid=$hwmodel->{name}->{$osyrec->{model}}->{id};
      my $aid=$osyrec->{ager};
      $aid=$osyrec->{snr} if ($aid eq "");
      my $sysrec={name=>$osyrec->{name},
                  cpucount=>$osyrec->{cpucount},
                  memory=>$osyrec->{memory},
                  adminteamid=>$g->{grpid},
                  srcsys=>'W5BaseV1',
                  srcload=>$srcload,
                  mandatorid=>1168,
                  cistatusid=>'4',
                 };
      if (!($osyrec->{info}=~m/^\s*$/)){
         $sysrec->{comments}=UTF8toLatin1($osyrec->{info});
      }
      $sysrec->{isapplserver}=$osyrec->{is_server};
      $sysrec->{isworkstation}=$osyrec->{is_ws};
      $sysrec->{isprinter}=$osyrec->{is_printer};
      $sysrec->{osreleaseid}=$osid if ($osid!=0);
      $sysrec->{systemid}=$osyrec->{sger} if ($osyrec->{sger} ne "");
      if ($aid ne ""){
         $oldloc->SetFilter({id=>\$osyrec->{loc}});
         my ($lrec)=$oldloc->getOnlyFirst(qw(ALL));
         my $newloc=$newloc->getLocationByHash(label=>$lrec->{name},
                                               address1=>$lrec->{address1},
                                               location=>$lrec->{location},
                                               srcsys=>"W5BaseV1",
                                               srcid=>$lrec->{id},
                                               zipcode=>$lrec->{zipcode});
         my $assrec={name=>$aid,
                     srcsys=>'W5BaseV1',
                     srcload=>$srcload,
                     mandatorid=>1168,
                     room=>$osyrec->{raumnr},
                     serialno=>$osyrec->{snr},
                     systemhandle=>$osyrec->{swid},
                     cpuspeed=>$osyrec->{cputakt},
                     guardianteamid=>$g->{grpid},
                     rack=>$osyrec->{rackbez},
                     place=>$osyrec->{platz},
                     cistatusid=>'4',
                    };
         $assrec->{locationid}=$newloc if ($newloc!=0);
         $assrec->{hwmodelid}=$hwmid if ($hwmid!=0);
         my ($w5id)=$ass->ValidatedInsertOrUpdateRecord($assrec,
                            {name=>\$assrec->{name}});
         my $conrec={target=>'base::grp',refid=>$w5id,roles=>['write'],
                     parentobj=>'itil::asset',targetid=>$g->{grpid}};
         if (!defined($con->ValidatedInsertOrUpdateRecord($conrec,
                               {target=>\$conrec->{target},
                                refid=>\$conrec->{refid},
                                parentobj=>\$conrec->{parentobj},
                                targetid=>\$conrec->{targetid}}))){
            msg(ERROR,"failed to insert guardianteam=%s",Dumper($con));
         }
         $sysrec->{assetid}=$w5id;
      }
      my ($w5id)=$sys->ValidatedInsertOrUpdateRecord($sysrec,
                         {name=>\$sysrec->{name}});
      if ($g->{grpid}!=0){
         my $conrec={target=>'base::grp',refid=>$w5id,roles=>['write'],
                     parentobj=>'itil::system',targetid=>$g->{grpid}};
         if (!defined($con->ValidatedInsertOrUpdateRecord($conrec,
                               {target=>\$conrec->{target},
                                refid=>\$conrec->{refid},
                                parentobj=>\$conrec->{parentobj},
                                targetid=>\$conrec->{targetid}}))){
            msg(ERROR,"failed to insert adminteam=%s",Dumper($con));
         }
      }

   #   if (defined($g)){
   #      $sys_mandatorenv{mandatorid}=1168;
   #      $sys_mandatorenv{adminteamid}=$g->{grpid};
   #      $ass_mandatorenv{mandatorid}=1168;
   #      $ass_mandatorenv{guardianteamid}=$g->{grpid};
   #   }
   }
}


sub LoadLocation
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from sysloc";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{loc}=getModuleObject($self->Config,"base::location");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));
      my %newrec=(address1=>$rec->{strasse},
                  zipcode=>$rec->{plz},
                  label=>$rec->{callname},
                  refcode1=>"W5BaseV1-".$rec->{id},
                  roomexpr=>$rec->{roomexp},
                  location=>$rec->{ort},
                  country=>"DE",
                  cistatusid=>4,
                  srcload=>$loadstart,
                  owner=>$ownerid,
                  creator=>$ownerid,
                  mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                  cdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                  srcid=>$rec->{id},
                  srcsys=>"W5BaseV1",
                 );
      delete($newrec{zipcode}) if ($newrec{zipcode} eq "");
      delete($newrec{roomexpr}) if ($newrec{roomexpr} eq "");

      print Dumper(\%newrec);
      my $locid=$self->{loc}->getLocationByHash(%newrec);
     # $self->{sys}->ValidatedInsertOrUpdateRecord(\%newrec,
     #                       {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
   }
   # cleanup
   $self->{loc}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\"W5BaseV1");
   $self->{loc}->ForeachFilteredRecord(sub{
       $self->{loc}->ValidatedUpdateRecord($_,{cistatusid=>6},{id=>$_->{id}});
   });
   return({exicode=>0});
}


sub LoadModel
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select distinct ".
           "hwmodel.name,bchw.herstel,hwmodel.owner,hwmodel.mdate,hwmodel.id ".
           "from hwmodel left outer join bchw on bchw.model=hwmodel.name ".
           "order by hwmodel.name,bchw.herstel";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{mod}=getModuleObject($self->Config,"itil::hwmodel");
   $self->{prod}=getModuleObject($self->Config,"itil::producer");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));
      my %newrec=(name=>$rec->{name},
                  cistatusid=>4,
                  srcload=>$loadstart,
                  owner=>$ownerid,
                  creator=>$ownerid,
                  mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                  cdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                  srcid=>$rec->{id},
                  srcsys=>"W5BaseV1",
                 );
      my $prod=$rec->{herstel};
      if ($prod ne ""){
         $self->{prod}->SetFilter({name=>\$prod});
         my ($rec,$msg)=$self->{prod}->getOnlyFirst(qw(id));
         if (defined($rec)){
            $newrec{producerid}=$rec->{id};
         }
      }
      #print Dumper($rec);
      $self->{mod}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
   }
   # cleanup
   $self->{mod}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\"W5BaseV1");
   $self->{mod}->ForeachFilteredRecord(sub{
       $self->{mod}->ValidatedUpdateRecord($_,{cistatusid=>6},{id=>$_->{id}});
   });
   return({exicode=>0});
}


sub LoadCostCenter
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from bccocharge";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   $self->{co}=getModuleObject($self->Config,"finance::costcenter");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      next if ($rec->{name}=~m/gesperrt/);
      my $ownerid=$self->getUserIdByV1($rec->{owner});
      $ownerid=0 if (!defined($ownerid));
      my %newrec=(name=>$rec->{name},
                  fullname=>$rec->{longname},
                  id=>$rec->{id},
                  cistatusid=>4,
                  srcload=>$loadstart,
                  owner=>$ownerid,
                  creator=>$ownerid,
                  mdate=>scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
                  srcid=>$rec->{id},
                  srcsys=>"W5BaseV1",
                 );
      #print Dumper($rec);
      $self->{co}->ValidatedInsertOrUpdateRecord(\%newrec,
                            {srcid=>$newrec{srcid},srcsys=>$newrec{srcsys}});
      #exit(0);
   }
   # cleanup
   $self->{co}->SetFilter(srcload=>"\"<$loadstart\"");
   $self->{co}->ForeachFilteredRecord(sub{
       $self->{co}->ValidatedDeleteRecord($_);
   });

   return({exicode=>0});
}


sub LoadContact
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   $self->{con}=getModuleObject($self->Config,"base::lnkcontact");
   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->ResetFilter();
  # $appl->SetFilter(id=>\'1');
   foreach my $rec ($appl->getHashList(qw(id))){
      my %con=();
      my $cmd="select * from lnkcontact where app='bcapp' and ref='$rec->{id}'";
      if (!$db->execute($cmd)){
         return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
      }
      while(my ($rec,$msg)=$db->fetchrow()){
         last if (!defined($rec));
         my $user=$self->getUserIdByV1($rec->{user});
         $con{"base::user::$user"}={} if (!defined($con{"base::user::$user"}));
         my $con=$con{"base::user::$user"};
         $con->{target}='base::user';
         $con->{targetid}=$user;
         my $ownerid=$self->getUserIdByV1($rec->{owner});
         $ownerid=0 if (!defined($ownerid));
         $con->{creator}=$ownerid;
         $con->{refid}=$rec->{ref};
         $con->{parentobj}='itil::appl';
         $con->{srcid}=$rec->{id};
         $con->{srcsys}="W5BaseV1";
         $con->{srcload}=$loadstart;
         $con->{comments}=$rec->{typ};
         $con->{mdate}=scalar($app->ExpandTimeExpression($rec->{mdate},"en","GMT")),
         $con->{roles}=[] if (!defined($con->{roles}));
         my %ro=();
         foreach my $r (@{$con->{roles}}){
            $ro{$r}=1;
         }
         $ro{"businessemployee"}=1 if ($rec->{typ} eq "Betriebsteam");
         $ro{"developer"}=1        if ($rec->{typ} eq "Entwickler");
         $ro{"wbv"}=1 if ($rec->{typ} eq "WBV (Wirkbetriebsverantwortlicher)");
         $con->{roles}=[keys(%ro)];
      }
      my $cmd="select * from lnkaccess where app='bcapp' and ref='$rec->{id}'";
      if (!$db->execute($cmd)){
         return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
      }
      while(my ($rec,$msg)=$db->fetchrow()){
         last if (!defined($rec));
         my $user=$self->getUserIdByV1($rec->{user});
         next if ($user==0);
         $con{"base::user::$user"}={} if (!defined($con{"base::user::$user"}));
         my $con=$con{"base::user::$user"};
         $con->{target}='base::user';
         $con->{targetid}=$user;
         my $ownerid=$self->getUserIdByV1($rec->{owner});
         $ownerid=0 if (!defined($ownerid));
         $con->{creator}=$ownerid;
         $con->{refid}=$rec->{ref};
         $con->{parentobj}='itil::appl';
         $con->{srcsys}="W5BaseV1";
         $con->{srcload}=$loadstart;
         $con->{comments}="W5BaseV1 ACL";
         $con->{roles}=[] if (!defined($con->{roles}));
         my %ro=();
         foreach my $r (@{$con->{roles}}){
            $ro{$r}=1;
         }
         $ro{write}=1;
         $con->{roles}=[keys(%ro)];
      }
      foreach my $con (values(%con)){
         next if ($con->{targetid} eq "");
         if (!defined($self->{con}->ValidatedInsertOrUpdateRecord($con,
                               {target=>\$con->{target},
                                refid=>\$con->{refid},
                                parentobj=>\$con->{parentobj},
                                targetid=>\$con->{targetid}}))){
            msg(DEBUG,"fail=%s",Dumper($con));
         }
      }
   }
   # cleanup
   $self->{con}->SetFilter(srcload=>"\"<$loadstart\"",srcsys=>\"W5BaseV1");
   $self->{con}->ForeachFilteredRecord(sub{
       $self->{con}->ValidatedDeleteRecord($_);
   });


   return({exicode=>0});
}



sub LoadBTB
{
   my $self=shift;
   my $app=$self->getParent;

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $dbact=new kernel::database($self->getParent,"w5v1");
   if (!$dbact->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfact=getModuleObject($self->Config,"base::workflowaction");
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   my $cmd="select * from protokoll_header where prott='proto_bcapp'";
   #$cmd.=" and id in ('243462')";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   my $c=0;
   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      my %ref=Datafield2Hash($rec->{referenz});
      $rec->{referenz}=\%ref;
      msg(DEBUG,Dumper($rec));
      my @act;
      my $cmd="select * from protokoll_data where protid='$rec->{id}'";
      if ($dbact->execute($cmd)){
         while(my ($act,$msg)=$dbact->fetchrow()){
            last if (!defined($act));
            my %add=Datafield2Hash($rec->{addional});
            $act->{addional}=\%add;
            push(@act,$act);
         }
      }
      my %p=(class=>'AL_TCom::workflow::diary',
             step=>'base::workflow::diary::main');
      $p{name}=$rec->{filename}; 
      $p{stateid}=1; 
      $p{tcomcodrelevant}='no'; 
      $p{tcomworktime}='0'; 
      $p{mdate}=$app->ExpandTimeExpression($rec->{mdate},"en","CET","GMT"),
      $p{eventstart}=$app->ExpandTimeExpression($rec->{odate},"en","CET","GMT"),
      $p{createdate}=$app->ExpandTimeExpression($rec->{odate},"en","CET","GMT"),
      $p{eventend}=undef;
      $p{closedate}=undef;
      $p{srcsys}='W5BaseV1-BTB';
      $p{srcid}=$rec->{id};
      $p{id}=$rec->{id};
      $p{openusername}=$rec->{owner};
      $p{openuser}=$self->getUserIdByV1($rec->{owner});
      $p{owner}=$self->getUserIdByV1($rec->{owner});
      $p{creator}=$self->getUserIdByV1($rec->{owner});
      $p{editor}=$rec->{owner};
      $p{realeditor}=$rec->{owner};
      $p{srcload}=$loadstart;
      $p{mandatorid}=[200];
      $p{mandator}=['AL T-Com'];
      if ($rec->{referenz}->{conummer}->[0] ne ""){
         $p{involvedcostcenter}=$rec->{referenz}->{conummer}->[0];
      }
      if ($rec->{referenz}->{bcappw5baseid}->[0] ne ""){
         $p{affectedapplicationid}=$rec->{referenz}->{bcappw5baseid}->[0];
      }
      if ($rec->{referenz}->{anwendungsname}->[0] ne ""){
         $p{affectedapplication}=$rec->{referenz}->{anwendungsname}->[0];
      }
      if ($rec->{statuslevel} ne ""){
         if ($rec->{statuslevel}==0){
            $p{stateid}=4;
         }
         if ($rec->{statuslevel}==1){
            $p{stateid}=21;
            $p{step}='base::workflow::diary::wffinish';
         }
      }
      if ($p{stateid}!=21){    # autoclose operation
         foreach my $act (@act){
            my $d=$app->ExpandTimeExpression($act->{mdate},"en","CET","GMT");
            if (!defined($p{closedate}) || $d gt $p{closedate}){
               $p{closedate}=$d;
            }
         }
         $p{step}='base::workflow::diary::wffinish';
         $p{eventend}=$p{closedate};
         $p{stateid}=21;
      }
      my @l=$wf->ValidatedInsertOrUpdateRecord(\%p,{srcsys=>\$p{srcsys},
                                                    srcid=>\$p{srcid}});
      foreach my $act (@act){
         msg(DEBUG,Dumper($act));
         my $cdate=$act->{mdate};
         $cdate=$app->ExpandTimeExpression($cdate,"en","CET","GMT");
         my %act=(wfheadid=>$rec->{id},comments=>$act->{data},
                  cdate=>$cdate,
                  name=>'note',translation=>'base::workflow::diary',
                  srcid=>$act->{id},srcsys=>'W5BaseV1-BTB');
         if ($act->{mdate} ne ""){
            $act{mdate}=$app->ExpandTimeExpression($act->{mdate},"en",
                                                   "CET","GMT"),
         }
         $act{owner}=$self->getUserIdByV1($act->{owner});
         $act{creator}=$act{owner};
 
         my @l=$wfact->ValidatedInsertOrUpdateRecord(\%act,
                                                   {srcsys=>\$act{srcsys},
                                                    srcid=>\$act{srcid}});

      }
      $c++;
   }
   msg(ERROR,"Import=$c");
   return({exicode=>0});
}

sub LoadAccNo
{
   my $self=shift;
   my $app=$self->getParent;

   my $srcload;
   if ($srcload eq ""){
      $srcload=$self->getParent->ExpandTimeExpression("now","en","GMT");
   }
   my $acc=$self->getParent->getPersistentModuleObject("itil::lnkaccountingno");
   my $app=$self->getParent->getPersistentModuleObject("itil::appl");

   my $db=new kernel::database($self->getParent,"w5v1");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select * from bcacnummer";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }
   while(my ($arec,$msg)=$db->fetchrow()){
      last if (!defined($arec));
      $app->ResetFilter();
      $app->SetFilter({id=>\$arec->{bcapp}});
      my ($apprec,$msg)=$app->getOnlyFirst(qw(id));
      if (defined($apprec)){
         my $newacc={name=>$arec->{name},
                     comments=>$arec->{info}, 
                     applid=>$arec->{bcapp}, 
                     editor=>$arec->{owner},
                     realeditor=>$arec->{owner},
                     cdate=>scalar($app->ExpandTimeExpression($arec->{mdate},"en",
                                                       "CET","GMT")),
                     mdate=>scalar($app->ExpandTimeExpression($arec->{mdate},"en",
                                                       "CET","GMT")),
                     srcid=>$arec->{id},
                     srcsys=>"W5BaseV1",
                     srcload=>$srcload};
         my ($w5id)=$acc->ValidatedInsertOrUpdateRecord($newacc,
                    {name=>\$newacc->{name},applid=>\$newacc->{applid}});
      }
   }
   $acc->SetFilter(srcload=>"\"<$srcload\"",srcsys=>\"W5BaseV1");
   $acc->ForeachFilteredRecord(sub{
       $acc->ValidatedDeleteRecord($_);
   });
}



1;
