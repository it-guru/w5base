package aws::event::AWS_KeyRefresh;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use File::Temp qw(tempdir);
use Encode qw(encode);
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub AWS_KeyRefresh
{
   my $self=shift;
   my $keyfile=shift;

   if (($keyfile eq "") || 
       (! -f $keyfile ) ||
       (! -r $keyfile)){
      return({exitcode=>1,exitmsg=>"invalid keyfile '$keyfile'"});
   }

   my $o=getModuleObject($self->Config,"aws::account");
   my ($cred,$ua)=$o->GetCred4AWS();

   my $obj=Paws->service('IAM', credentials=>$cred);

   my $ListAccessKeysResponse=$obj->ListAccessKeys();
   my $AccessKeyMeta=$ListAccessKeysResponse->AccessKeyMetadata;

   my $UserName;
   my $ActiveCount=0;
   my $KeyCount=0;
   my $newestActive;
   my $newCreatedAccessKey;

   my @curKeys=sort({$b->{CreateDate} cmp $a->{CreateDate}} @{$AccessKeyMeta});

   foreach my $curKeyRec (@curKeys){
      $UserName=$curKeyRec->{UserName};
      $ActiveCount++ if ($curKeyRec->{Status} eq "Active");
      $KeyCount++;
      if ($curKeyRec->{Status} eq "Active" && !defined($newestActive)){
         $newestActive=$curKeyRec;
      }
      if ($curKeyRec->{Status} eq "Inactive"){
         msg(INFO,"Cleanup needed for key ".$curKeyRec->{AccessKeyId});
         msg(INFO,"inactive rec=".Dumper($curKeyRec));
         my $bk=$obj->DeleteAccessKey(
            'AccessKeyId'=>$curKeyRec->{AccessKeyId},
            'UserName'=>$curKeyRec->{UserName}
         );  
         return({exitcode=>0,
                 exitmsg=>'cleanup (bk='.$bk.') is enough for today'});
      }
   }

   msg(INFO,"AccessKeys=".Dumper(\@curKeys));
   msg(INFO,"newestActive=".Dumper($newestActive));

   if ($KeyCount<=1){
      msg(INFO,"try to add new Access key with pAWS CreateAccessKey=");
      eval('
        my $AccessKeyResp=$obj->CreateAccessKey(UserName=>$UserName);
        $newCreatedAccessKey=$AccessKeyResp->AccessKey();
      ');
      if ($@){
         my @msg=grep(!/^\s*$/,split(/[\r\n]+/,$@));
         my $msg=shift(@msg);
         printf STDERR ("msg=%s\n",$msg);
      }
      if (defined($newCreatedAccessKey)){
         msg(INFO,"new created AccessKey=".Dumper($newCreatedAccessKey));
      }
      else{
         return({exitcode=>1,
                 exitmsg=>'ERROR - fail to create new AccessKeyId'});
      }
   }

   my $credentialName="aws";

   my $tempkeyfile=$keyfile;
   my $ts=NowStamp();
   if ($tempkeyfile=~m/\.[^\/]+$/){
      $tempkeyfile=~s/(\.[^\/]+)$/.$ts$1/x;
   }
   else{
      $tempkeyfile.=".".$ts;
   }
   msg(INFO,"keyfile=$keyfile");
   msg(INFO,"tempkeyfile=$tempkeyfile");

   my $keyFileChanged=0;

   if (open(my $keyfileFH,'<',$keyfile)){
      my @curVal=<$keyfileFH>;
      my @orgcurVal=@curVal;
      close($keyfileFH);
      @curVal=grep(/^(DATAOBJ)/,@curVal);
      my $storedDATAOBJUSER;
      foreach my $line (@curVal){
         if (my ($v)=$line=~m/^DATAOBJUSER\[$credentialName\]="([^"]*)"\s*$/){
            $storedDATAOBJUSER=$v;
         }
      }
      #if (!defined($newCreatedAccessKey) && defined($newestActive)){
      #   if ($newestActive->{AccessKeyId} ne $storedDATAOBJUSER){ 
      #      # someone have created on key in the AWS - but we haven't stored
      #      # the key in our config. We treat them as new created
      #      msg(INFO,"found manuelly created key - and use them as newCreated");
      #      $newCreatedAccessKey=$newestActive;
      #   }
      #}

      if (defined($newCreatedAccessKey)){
         msg(INFO,"build new curVal for ".$newCreatedAccessKey->{AccessKeyId});
         @curVal=grep(!/^DATAOBJUSER\[$credentialName\]/,@curVal);
         push(@curVal,"DATAOBJUSER[$credentialName]=\"".
                       $newCreatedAccessKey->{AccessKeyId}.
                      "\"\n");
         @curVal=grep(!/^DATAOBJPASS\[$credentialName\]/,@curVal);
         push(@curVal,"DATAOBJPASS[$credentialName]=\"".
                       $newCreatedAccessKey->{SecretAccessKey}.
                      "\"\n");
         unshift(@curVal,"#NEW Generated: ".$ts."\n");
         unshift(@curVal,"#AWS AccessKeyId: ".
                         $newCreatedAccessKey->{AccessKeyId}."\n");
         push(@curVal,"\n");
         $keyFileChanged++;
      }
      else{
         msg(INFO,"newest=".$newestActive->{AccessKeyId});
         msg(INFO,"curused=".$storedDATAOBJUSER);


         if ($storedDATAOBJUSER ne ""){
            foreach my $curKeyRec (@curKeys){
               if (defined($curKeyRec) && 
                   $curKeyRec->{AccessKeyId} ne $storedDATAOBJUSER){
                  msg(INFO,"do DeleteAccessKey unused key ".
                           $curKeyRec->{AccessKeyId});
                  my $bk=$obj->DeleteAccessKey(
                     'AccessKeyId'=>$curKeyRec->{AccessKeyId},
                     'UserName'=>$curKeyRec->{UserName}
                  );  
                  msg(INFO,"DeleteAccessKey bk=$bk");
                  return({exitcode=>0,exitmsg=>'ok - drop unused key '.
                                               $curKeyRec->{AccessKeyId}.
                                               ' done'});
               }
            }
         }
      }
      if ($keyFileChanged){
         msg(INFO,"waiting 10sec to ensure key is working");
         sleep(10);
         msg(INFO,"try to store orgcurVal in $tempkeyfile");
         if (open(my $tempkeyfileFH,">", $tempkeyfile )){
            print $tempkeyfileFH (join("",@orgcurVal));
            close($tempkeyfileFH);
            msg(INFO,"try to store new curVal in $keyfile");
            if (open(my $keyfileFH,'>',$keyfile)){
               print $keyfileFH (join("",@curVal));
               close($keyfileFH);
               return({exitcode=>0,exitmsg=>'ok - new key stored'});
            }
            else{
               $self->LastMsg(ERROR,"fail to re overwrite $keyfile");
            }
         }
	      else{
            return({exitcode=>1,
                    exitmsg=>'fail to open tempkeyfile '.$tempkeyfile
            });
         }
      }
      else{
         return({exitcode=>0,exitmsg=>'ok - nothing to do'});
      }
   }
   my $msg=join("\n",$self->LastMsg());
   if ($msg eq ""){
      $msg="unkown problem";
   }
   return({exitcode=>1,exitmsg=>$msg});
}

1;
