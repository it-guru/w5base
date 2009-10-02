package BCBS::event::loaddata;
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
use kernel;
use kernel::Event;
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


   $self->RegisterEvent("loadbcbs","LoadBCBS");
   return(1);
}

sub LoadBCBS
{
   my $self=shift;
   my $loadstart=$self->getParent->ExpandTimeExpression("now","en","GMT");
   my $srcsys="AC_BCBS";
   my $app=$self->getParent();

   msg(INFO,"loading data for BCBS from AssetManager to W5Base");
   msg(INFO,"loadstart = $loadstart");


   my $man=getModuleObject($self->Config,"base::mandator");
   my $wiw=getModuleObject($self->Config,"tswiw::user");
   $man->SetFilter({name=>\'AL DTAG'});
   my ($manrec,$msg)=$man->getOnlyFirst("grpid");
   my $mandatorid=$manrec->{grpid};

   my $grp=getModuleObject($self->Config,"base::grp");
   my $customerid=$grp->TreeCreate("DTAG.ACTIVEBILLING");
   my $businessteam=$grp->TreeCreate("DTAG.TSI.ITO.CSS.AO.DTAG.BILLING");



   my $lnkaccountno=getModuleObject($self->Config,"itil::lnkaccountingno");
   my $lnkappl=getModuleObject($self->Config,"itil::lnkapplsystem");
   my $location=getModuleObject($self->Config,"base::location");
   my $aappl=getModuleObject($self->Config,"tsacinv::appl");
   my $asystem=getModuleObject($self->Config,"tsacinv::system");
   my $aasset=getModuleObject($self->Config,"tsacinv::asset");
   my $alocation=getModuleObject($self->Config,"tsacinv::location");
   my $appl=getModuleObject($self->Config,"AL_TCom::appl");
   my $sys=getModuleObject($self->Config,"AL_TCom::system");
   my $asset=getModuleObject($self->Config,"AL_TCom::asset");
   $aappl->SetFilter({assignmentgroup=>['BPO.BCBS','CSS.TCOM.BILLING'],
                      name=>["ADS WIRK","REO WIRK","DWH AW WIRK"],
                      status=>['IN OPERATION']});
   $aappl->SetCurrentView(qw(ALL));
   my $agcount=0;
   if (my ($rec,$msg)=$aappl->getFirst()){
       agloop: while(defined($rec)){
         my %systemid;
         my %systemidcomments;
         my %assetid;
         last if (!defined($rec));
         my $semw5baseid=$wiw->GetW5BaseUserID($rec->{sememail});
         if (!defined($semw5baseid) && $rec->{semldapid} ne ""){
            $semw5baseid=$wiw->GetW5BaseUserID($rec->{semldapid});
         }
         my $tsmw5baseid=$wiw->GetW5BaseUserID($rec->{tsmemail});
         if (!defined($tsmw5baseid) && $rec->{tsmldapid} ne ""){
            $tsmw5baseid=$wiw->GetW5BaseUserID($rec->{tsmldapid});
         }
         my $databossid=$semw5baseid;
         if ($databossid eq ""){
            $databossid=$semw5baseid;
         }
         if ($databossid eq ""){
            my $acgroup=getModuleObject($self->getParent->Config,
                                        "tsacinv::group");
            $acgroup->SetFilter({lgroupid=>\$rec->{lassignmentid}});
            my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
            if (defined($acgrouprec)){
               if ($acgrouprec->{supervisorldapid} ne "" ||
                   $acgrouprec->{supervisoremail} ne ""){
                  my $importname=$acgrouprec->{supervisorldapid};
                  if ($importname eq ""){
                     $importname=$acgrouprec->{supervisoremail};
                  }
                  my $bossid=$wiw->GetW5BaseUserID($importname);
                  if (defined($bossid)){
                     $databossid=$bossid;
                  }
               }
            }
         }
         my $name=$rec->{name};
         $name=~s/[^a-z0-9_-]/_/gi;
 

         msg(INFO,"load name=$rec->{name} id=$rec->{id}");
         msg(INFO,"load name        = '$name'");
         msg(INFO,"load sememail    = $rec->{sememail} ($semw5baseid)");
         msg(INFO,"load tsmemail    = $rec->{tsmemail} ($tsmw5baseid)");
         msg(INFO,"load databossid  = ($databossid)");
         if ($databossid eq ""){
            exit(1);
         }

         my $criticality=$rec->{criticality};
         $criticality="CR".$criticality;
         my $issoxappl=$rec->{issoxappl};
         $issoxappl=0 if (lc($issoxappl) eq "no");
         $issoxappl=1 if ($issoxappl ne "0");
         my $newrec={name=>$name,
                     mandatorid=>$mandatorid,
                     conumber=>$rec->{conumber},
                     applid=>$rec->{applid},
                     description=>UTF8toLatin1($rec->{description}),
                     applnumber=>$rec->{ref},
                     applgroup=>"BCBS",
                     criticality=>$criticality,
                     customerprio=>$rec->{customerprio},
                     acinmassingmentgroup=>$rec->{iassignmentgroup},
                     cistatusid=>4,
                     issoxappl=>$issoxappl,
                     srcid=>$rec->{id},
                     srcsys=>$srcsys,
                     srcload=>$loadstart,
                     semid=>$semw5baseid,
                     tsmid=>$tsmw5baseid,
                     businessteamid=>$businessteam,
                     responseteamid=>$businessteam,
                     databossid=>$databossid};
         $newrec->{conumber}=~s/^0+//g;
         if ($rec->{customer}=~m/ACTIVEBILLING/){
            $newrec->{customerid}=$customerid;
         }
         my ($agid)=$appl->ValidatedInsertOrUpdateRecord($newrec,
                        {srcid=>\$newrec->{srcid},srcsys=>\$newrec->{srcsys}});
         if (defined($agid) && $agid ne ""){
            msg(INFO,"now process realtions name=$rec->{name} id=$agid");
            my $accountno=$rec->{accountno};
            my @accountno=grep(!/^\s*$/,split(/\s*;\s*/,$accountno));
            foreach my $accountno (@accountno){
               my $newrec={name=>$accountno,
                           applid=>$agid,
                           srcsys=>$srcsys,
                           srcid=>$accountno."-".$agid,
                           srcload=>$loadstart};
               $lnkaccountno->ValidatedInsertOrUpdateRecord($newrec,
                       {srcid=>\$newrec->{srcid},srcsys=>\$newrec->{srcsys}});
            }
            foreach my $sysrec (@{$rec->{systems}}){
               $systemid{$sysrec->{systemid}}->{$agid}->{$rec->{usage}}++;
               $systemidcomments{$sysrec->{systemid}}=$sysrec->{comments};
            }
         }
         #if ($agcount++>5){
         #   last agloop;
         #}
         my $asys=getModuleObject($self->Config,"tsacinv::system");
         $asys->SetFilter({systemid=>[keys(%systemid)]});
         $asys->SetCurrentView(qw(systemid assetassetid));
         if (my ($rec,$msg)=$asys->getFirst()){
            assetloop: while(defined($rec)){
               $assetid{$rec->{assetassetid}}->{$rec->{systemid}}++;
               ($rec,$msg)=$asys->getNext();
               last if (!defined($rec));
            }
         }
       
         foreach my $assetid (keys(%assetid)){
            $aasset->SetFilter({assetid=>[$assetid]});
            my ($aassetrec,$msg)=$aasset->getOnlyFirst("ALL");

            my $assetrec={name=>$assetid,cistatusid=>4,
                          mandatorid=>$mandatorid,
                          cpucount=>$aassetrec->{cpucount},
                          memory=>$aassetrec->{memory},
                          allowifupdate=>1,
                          room=>$aassetrec->{room},
                          serialno=>$aassetrec->{serialno},
                          guardianid=>$databossid,
                          comments=>'Initial load for BCBS '.
                                    'while merge to AL DTAG',
                          srcsys=>$srcsys,srcid=>$assetid};

            if ($aassetrec->{locationid} ne ""){  # find a w5base location
               $alocation->ResetFilter();
               $alocation->SetFilter({locationid=>\$aassetrec->{locationid}});
               my ($lrec,$msg)=$alocation->getOnlyFirst("ALL");
               if ($lrec->{address1} ne ""){
                  my $label="";
                  my %newrec=(address1=>$lrec->{address1},
                              label=>$label,
                              zipcode=>$lrec->{zip},
                              country=>$lrec->{country},
                              location=>$lrec->{location},
                              refcode2=>"AC-".$lrec->{locationid},
                              cistatusid=>4,
                              srcload=>$loadstart,
                              owner=>0,
                              creator=>0,
                              mdate=>scalar($app->ExpandTimeExpression(
                                            $lrec->{mdate},"en","GMT")),
                              cdate=>scalar($app->ExpandTimeExpression(
                                            $lrec->{mdate},"en","GMT")),
                              srcsys=>"AC",
                            );
                           #  srcid=>$rec->{locationid},
                  $newrec{country}="DE" if ($newrec{country} eq "");
                  delete($newrec{zipcode}) if ($newrec{zipcode} eq "");
                  delete($newrec{roomexpr}) if ($newrec{roomexpr} eq "");
                  my $locid=$location->getLocationByHash(%newrec);
                  print Dumper(\%newrec);
                  #exit(0);
                  $assetrec->{locationid}=$locid;
               }
            }

            $asset->ResetFilter();
            $asset->SetFilter({name=>\$assetrec->{name},
                               srcsys=>"!$srcsys"});
            my ($oldassetrec,$msg)=$asset->getOnlyFirst("id");
            if (!defined($oldassetrec)){
               $asset->ValidatedInsertOrUpdateRecord($assetrec,
                                                     {name=>\$assetrec->{name}});
            }
         }
         foreach my $systemid (keys(%systemid)){
            $asystem->SetFilter({systemid=>[$systemid]});
            my ($asystemrec,$msg)=$asystem->getOnlyFirst("ALL");
            my $systemname=$asystemrec->{systemname};
            $systemname=$systemid if ($systemname eq "");
            $systemname=lc($systemname); 
            printf STDERR ("==> systemname=$systemname systemid=$systemid\n");
            my $systemrec={name=>$systemname,cistatusid=>4,
                          mandatorid=>$mandatorid,
                          systemid=>$systemid,
                          allowifupdate=>1,
                          cpucount=>$asystemrec->{cpucount},
                          memory=>$asystemrec->{memory},
                          comments=>'Initial load for BCBS '.
                                    'while merge to AL DTAG',
                          srcsys=>$srcsys,srcid=>$systemid};
            if ($asystemrec->{assetassetid} ne ""){
               $systemrec->{asset}=$asystemrec->{assetassetid};
            }

            $sys->ResetFilter();
            $sys->SetFilter({systemid=>\$systemid,
                             srcsys=>"!$srcsys"});
            my ($oldsystemrec,$msg)=$sys->getOnlyFirst("id");
            my $w5systemid;
            if (!defined($oldsystemrec)){
               ($w5systemid)=$sys->ValidatedInsertOrUpdateRecord($systemrec,
                                         {systemid=>\$systemid});
            }
            else{
               $w5systemid=$oldsystemrec->{id};
            }
            my $lnkrec={applid=>$agid,
                        systemid=>$w5systemid,
                        comments=>$systemidcomments{$systemid}
                       };
            $lnkappl->ValidatedInsertOrUpdateRecord($lnkrec,
               {applid=>\$lnkrec->{applid},systemid=>\$lnkrec->{systemid}});
            
            
         }
         printf STDERR ("result=%s\n",Dumper(\%systemid));
         printf STDERR ("result=%s\n",Dumper(\%assetid));
         printf STDERR ("=============================================\n");
         #sleep(1);


         ($rec,$msg)=$aappl->getNext();
         last if (!defined($rec));
      }
      
   }
   


   return({exitcode=>0});
}


sub getUseridByPosix
{
   my $self=shift;
   my $posix=shift;

   my $u=getModuleObject($self->Config,"base::user");
   $u->SetFilter({posix=>\$posix});
   my ($urec,$msg)=$u->getOnlyFirst("userid");
   if (!defined($urec)){
      msg(ERROR,"uiserid not found");
      exit(1);
   }
   return($urec->{userid}); 
}


1;
