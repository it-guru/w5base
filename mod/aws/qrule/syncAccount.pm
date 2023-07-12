package aws::qrule::syncAccount;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This QualityRule compares a W5Base/Darwin CloudArea to AWS Account.

=head3 IMPORTS


=head3 HINTS

[en:]


[de:]



=cut

#######################################################################
#
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
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   return(undef,undef) if ($rec->{cloud} ne "AWS");
   #return(undef,undef) if ($rec->{cistatusid}<4);
   return(undef,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   my $awsaccountid=$rec->{srcid};
   my $awsregion='eu-central-1';   # aktuell wird nur EINE Region gesynct

   my $app=getModuleObject($self->getParent->Config(),"itil::appl");
   $app->SetFilter({id=>\$rec->{applid}});
   my ($arec)=$app->getOnlyFirst(qw(id cistatusid));

   if (!defined($arec)){
      push(@qmsg,"invalid application reference");
   }
   else{
      if ($arec->{cistatusid} ne "4" &&
          $arec->{cistatusid} ne "3"){
          push(@qmsg,"invalid CI-State for application");
      }
   }
  
   { 
      my $chk=getModuleObject($self->getParent->Config(),"aws::account");
      if ($chk->isSuspended()){
         return(undef,{qmsg=>'suspended'});
      }
      $chk->SetFilter({accountid=>$awsaccountid});
      my @acc=$chk->getHashList(qw(accountid));
      if ($#acc==-1){
         push(@qmsg,"AWS account invalid or not accessable");
      }
   }
   


   if ($#qmsg==-1){
      my $ipobj=getModuleObject($self->getParent->Config(),"itil::ipaddress");
      my $netIf=getModuleObject($self->getParent->Config(),
                                "aws::NetworkInterface");
      $netIf->SetFilter({
         accountid=>$awsaccountid,
         isremote=>"0",
         region=>$awsregion
      });
      my @netif=$netIf->getHashList(qw(id ipadresses));
      my %allip;
      my %delip;
      my %updip;
      foreach my $if (@netif){
         foreach my $iprec (@{$if->{ipadresses}}){
            $allip{$iprec->{name}}={
               name=>$iprec->{name},
               id=>$if->{id},
               netareatag=>$iprec->{netareatag}
            };
         }
      }
      #printf STDERR ("netif=%s\n",Dumper(\@netif));




      my $par=getModuleObject($self->getParent->Config(),"aws::system");

      $par->SetFilter({accountid=>$awsaccountid,region=>$awsregion});

      my @l=$par->getHashList(qw(id cdate));

      my @id;
      my %srcid;
      my $awssyscount=0;
      foreach my $irec (@l){
         push(@id,$irec->{id});
         $srcid{$irec->{id}.'@'.$awsaccountid.'@'.$awsregion}={
            cdate=>$irec->{cdate}
         };
         $awssyscount++;
      }
      my $sys=getModuleObject($self->getParent->Config(),"itil::system");

      $sys->SetFilter([
         {
            srcid=>[keys(%srcid)]
         },
         {
            srcid=>"i-*".'@'..$awsaccountid.'@'.$awsregion,
            cistatusid=>"<6"
         },
         {
            itcloudareaid=>\$rec->{id},
            cistatusid=>"<6"
         }]
      );
      my @cursys=$sys->getHashList(qw(id srcid cistatusid itcloudareaid));

      my @delsys;
      my @inssys;
      my @updsys;

      foreach my $sysrec (@cursys){
         my $srcid=$sysrec->{srcid};
         if (exists($srcid{$srcid})){
            if ($sysrec->{cistatusid} ne "4" ||
                $sysrec->{itcloudareaid} ne $rec->{id}){
               $srcid{$srcid}->{op}="upd";
            }
            else{
               $srcid{$srcid}->{op}="ok";
            }
         }
      }
      foreach my $sysrec (@cursys){
         my $srcid=$sysrec->{srcid};
         if (!exists($srcid{$srcid}->{op})){
            push(@delsys,$srcid);
         }
      }
      foreach my $srcid (keys(%srcid)){
         if (!exists($srcid{$srcid}->{op})){
            push(@inssys,$srcid);
         }
         elsif($srcid{$srcid}->{op} eq "upd"){
            push(@updsys,$srcid);
         }
      }

      if ($#updsys!=-1){
         $sys->ResetFilter();
         $sys->SetFilter({srcsys=>'AWS',srcid=>\@updsys});
         foreach my $oldrec ($sys->getHashList(qw(ALL))){
            my $op=$sys->Clone();
            my $newTempName=$oldrec->{srcid};
            $newTempName=~s/\@.*$//;  # get an sure not used name
            # if a logical system should be reactivate, it is posible
            # the name is already used by an other system - with the 
            # newTempName this Problem gets resolved.
            $op->ValidatedUpdateRecord($oldrec,{
                 name=>$newTempName,
                 cistatusid=>'4',
                 itcloudareaid=>$rec->{id}
            },{id=>$oldrec->{id}});
         }
      }

      #printf STDERR ("AWS:delsys=%s\n",Dumper(\@delsys));
      if (keys(%srcid) &&   # ensure, restcall get at least one result
          $#delsys!=-1){
         $sys->ResetFilter();
         $sys->SetFilter(srcid=>\@delsys);
         my $op=$sys->Clone();
         foreach my $rec ($sys->getHashList(qw(ALL))){
            $op->ValidatedUpdateRecord($rec,{cistatusid=>6},{id=>\$rec->{id}});
         }
      }

      $par->ResetFilter();
      foreach my $srcid (@inssys){
         push(@qmsg,"import $srcid");
         $par->Import({importname=>$srcid});
      }
      delete($rec->{ipaddresses}); # reload ips
      #printf STDERR ("AWS:allip=%s\n",Dumper(\%allip));
      #printf STDERR ("AWS:ipaddresses=%s\n",Dumper($rec->{ipaddresses}));


      my $net=getModuleObject($self->getParent->Config(),"itil::network");
      my $netarea={};
      if (defined($net)){
         $netarea=$net->getTaggedNetworkAreaId();
      }

      foreach my $iprec (@{$rec->{ipaddresses}}){
         if ($iprec->{srcsys} eq "AWS"){
            my $ip=$iprec->{name};
            if (exists($allip{$ip})){
               my $directFound=0;
               foreach my $chkiprec (@{$rec->{ipaddresses}}){
                  if ($chkiprec->{name} eq $iprec->{name} && 
                      ($iprec->{systemid} ne "" ||
                       $iprec->{itclustsvcid} ne "")){
                     $directFound++;
                  }
               }
               if ($directFound){
                  delete($allip{$ip});
               }
            }
         }
      }


      foreach my $iprec (@{$rec->{ipaddresses}}){
         if ($iprec->{srcsys} eq "AWS"){
            my $ip=$iprec->{name};
            if (exists($allip{$ip})){
               if  (!defined($iprec->{systemid}) &&
                    !defined($iprec->{itclustsvcid})){
                  if ($iprec->{networkid} ne 
                      $netarea->{$allip{$ip}->{netareatag}}){

                     $iprec->{NetareaTag}=$allip{$ip}->{netareatag};
                     $ipobj->switchSystemIpToNetarea({$ip=>$iprec},undef,
                                                     $netarea,\@qmsg);
                  }
                  delete($allip{$ip});
               }
               else{
                  $delip{$iprec->{id}}=$iprec;
               }
            }
            else{
               if (!defined($iprec->{systemid}) &&
                   !defined($iprec->{itclustsvcid})){
                  $delip{$iprec->{id}}=$iprec;
               }
            }
         }
      }




      #my $dummy={
      #   name=>"1.2.3.4",
      #   netareatag=>"CNDTAG"
      #};
      #$allip{$dummy->{name}}=$dummy;

      if (keys(%allip) || keys(%delip)){
         foreach my $iprec (values(%allip)){
            my $rec={
               name         =>$iprec->{name},
               cistatusid   =>"4",
               srcsys       =>"AWS",
               type         =>"1",
               itcloudareaid=>$rec->{id},
               networkid    =>$netarea->{ISLAND}
            };
            if ($rec->{cistatusid}==4){  # native IPs only on active CloudAreas
               my $newid=$ipobj->ValidatedInsertRecord($rec);
               push(@qmsg,"added: ".$iprec->{name});
            }
            else{
               push(@qmsg,"reject import: ".$iprec->{name});
            }
            if ($awssyscount<50){
               $checksession->{EssentialsChangedCnt}++;
            }
         }
         foreach my $iprec (values(%delip)){
            if ($ipobj->ValidatedUpdateRecord($iprec,{cistatusid=>6},
                  {id=>$iprec->{id}})){
               push(@qmsg,"deleted: ".$iprec->{name});
            }
         }
      }
   }

   my @result=$self->HandleQRuleResults("AWS",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
