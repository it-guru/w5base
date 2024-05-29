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

printf STDERR ("fifi cred=%s\n",$cred);

   my $obj=Paws->service('IAM',
               credentials=>$cred
   );

printf STDERR ("fifi obj=%s\n",$obj);

   my $ListAccessKeysResponse=$obj->ListAccessKeys();

printf STDERR ("fifi ListAccessKeysResponse=%s\n",$ListAccessKeysResponse);

   my $AccessKeyMetadata = $ListAccessKeysResponse->AccessKeyMetadata;

printf STDERR ("fifi AccessKeyMetadata=%s\n",Dumper($AccessKeyMetadata));

   my $AccessKey;
   eval('
     my $AccessKeyResp=$obj->CreateAccessKey(UserName=>"darwin_read_metadata");
     $AccessKey=$obj->AccessKey();
   ');
   if ($@){
      my @msg=grep(!/^\s*$/,split(/[\r\n]+/,$@));
      my $msg=shift(@msg);
      printf STDERR ("msg=%s\n",$msg);
   }


   exit(1) if (!defined($AccessKey));
   

#   if ($priv_key eq "" || $pub_key eq ""){
#      return({
#         exitcode=>12,
#         exitmsg=>"fail to create key pair with openssl"
#      });
#   }

   my $credentialName="aws";

   my $d;

















   if (ref($d) eq "HASH" && 
       exists($d->{name}) && $d->{name} ne ""){
      msg(INFO,"new key stored in AWS as $d->{name}");

      my $tempkeyfile=$keyfile;
      my $ts=NowStamp();
      if ($tempkeyfile=~m/\.[^\/]+$/){
         $tempkeyfile=~s/(\.[^\/]+)$/.$ts$1/x;
      }
      else{
         $tempkeyfile.=".".$ts;
      }
      #msg(INFO,"tempkeyfile=$tempkeyfile");
     
      if (open(my $tempkeyfileFH,">", $tempkeyfile )){
         if (open(my $keyfileFH,'<',$keyfile)){
            my @curVal=<$keyfileFH>;
            print $tempkeyfileFH (join("",@curVal));
            close($keyfileFH);
            if (open(my $keyfileFH,'>',$keyfile)){
               printf $keyfileFH ("#NEW Generated: %s\n",$ts);
               printf $keyfileFH ("#AWS name : %s\n",$d->{name});
               @curVal=grep(/^(DATAOBJCONNECT|DATAOBJUSER)/,@curVal);
               push(@curVal,'DATAOBJPASS['.$credentialName.']="'."\n");
      #         push(@curVal,map({$_."\n"} split("\n",$priv_key)));
               push(@curVal,'"'."\n");
     
               print $keyfileFH (join("",@curVal));
               close($keyfileFH);
               return({exitcode=>0,exitmsg=>'ok - key '.$d->{name}.' stored'});
            }
            else{
               unlink($tempkeyfile);
               return({
                  exitcode=>12,
                  exitmsg=>"error opening '$keyfile' for writing : $!"
               });
            }
         }
         else{
            return({
               exitcode=>11,
               exitmsg=>"error opening '$keyfile' for reading : $!"
            });
         }
         close($tempkeyfileFH);
      }
      else{
         return({
            exitcode=>10,
            exitmsg=>"error opening '$tempkeyfile' for writing : $!"
         });
      }
   }
   my $msg=join("\n",$self->LastMsg());
   if ($msg eq ""){
      $msg="unkown problem";
   }
   return({exitcode=>1,exitmsg=>$msg});
}

1;
