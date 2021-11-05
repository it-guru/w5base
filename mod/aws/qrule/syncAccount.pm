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
   return(undef,undef) if ($rec->{cistatusid}<4);

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
      foreach my $irec (@l){
         push(@id,$irec->{id});
         $srcid{$irec->{id}.'@'.$awsaccountid.'@'.$awsregion}={
            cdate=>$irec->{cdate}
         };
      }
      my $sys=getModuleObject($self->getParent->Config(),"itil::system");

      $sys->SetFilter([
         {
            srcid=>[keys(%srcid)]
         },
         {
            srcid=>"i-*".'@'..$awsaccountid.'@'.$awsregion,
            cistatusid=>"<6"
         }]
      );
      my @cursys=$sys->getHashList(qw(id srcid cistatusid));

      my @delsys;
      my @inssys;
      my @updsys;

      foreach my $sysrec (@cursys){
         my $srcid=$sysrec->{srcid};
         if (exists($srcid{$srcid})){
            if ($sysrec->{cistatusid} ne "4"){
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

      $par->ResetFilter();
      foreach my $srcid (@inssys){
         push(@qmsg,"import $srcid");
         $par->Import({importname=>$srcid});
      }
      if (keys(%srcid) &&   # ensure, restcall get at least one result
          $#delsys!=-1){
         $sys->ResetFilter();
         $sys->SetFilter(srcid=>\@delsys);
         my $op=$sys->Clone();
         foreach my $rec ($sys->getHashList(qw(ALL))){
            $op->ValidatedUpdateRecord($rec,{cistatusid=>6},{id=>\$rec->{id}});
         }
      }
      delete($rec->{ipaddresses}); # reload ips
      #printf STDERR ("allip=%s\n",Dumper(\%allip));
      #printf STDERR ("ipaddresses=%s\n",Dumper($rec->{ipaddresses}));
      foreach my $iprec (@{$rec->{ipaddresses}}){
         if ($iprec->{srcsys} eq "AWS"){
            my $ip=$iprec->{name};
            if (exists($allip{$ip})){
               delete($allip{$ip});
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
         my $net=getModuleObject($self->getParent->Config(),"itil::network");
         my $netarea={};
         if (defined($net)){
            $netarea=$net->getTaggedNetworkAreaId();
         }
         foreach my $iprec (values(%allip)){
            my $rec={
               name         =>$iprec->{name},
               cistatusid   =>"4",
               srcsys       =>"AWS",
               type         =>"1",
               itcloudareaid=>$rec->{id},
               networkid    =>$netarea->{ISLAND}
            };
            my $newid=$ipobj->ValidatedInsertRecord($rec);
            if ($newid ne ""){
               $ipobj->ResetFilter();
               $ipobj->SetFilter({id=>\$newid});
               printf STDERR ("fifi newid=%s\n",$newid); 
               my ($oldrec)=$ipobj->getOnlyFirst(qw(ALL));
               if ($oldrec->{networkid} ne $netarea->{$iprec->{netareatag}}){
                 # TODO:
                 # $oldrec->{NetareaTag}=$iprec->{networktag};
                 # $ipobj->switchSystemIpToNetarea($oldrec,undef,
                 #                                 $netarea,\@qmsg);
               }

               #if (exists($netarea->{$iprec->{netareatag}})){
               #   $rec->{NetareaTag}=$netarea->{$iprec->{netareatag}};
               #}
            }
         }
         foreach my $iprec (values(%delip)){
            $ipobj->ValidatedUpdateRecord($iprec,{cistatusid=>6},
                  {id=>$iprec->{id}}
            );
         }
      }
      #printf STDERR ("need to ins=%s\n",Dumper(\%allip));
   }

   my @result=$self->HandleQRuleResults("AWS",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
