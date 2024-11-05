package azure::event::AZURE_KeyRefresh;
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

sub AZURE_KeyRefresh
{
   my $self=shift;
   my $keyfile=shift;

   if (($keyfile eq "") || 
       (! -f $keyfile ) ||
       (! -r $keyfile)){
      return({exitcode=>1,exitmsg=>"invalid keyfile '$keyfile'"});
   }

   my $o=getModuleObject($self->Config,"azure::subscription");
   my $Authorization=$o->getAzureAuthorizationToken({
     resource=>undef,
     scope=>"https://app-regeneratesptoken-telit.azurewebsites.net/.default",
   });


   exit(1) if (!defined($Authorization));
   
   msg(INFO,"Authorization: ".$Authorization);

   my $credentialName="AZURE";

   my $curSecretId=$self->Config->Param("DATAOBJSECRETID");
   if (ref($curSecretId) eq "HASH"){
      $curSecretId=$curSecretId->{$credentialName};
   }
   msg(INFO,"curSecretId=".$curSecretId);

   my $KeyApiBaseURL="https://app-regeneratesptoken-telit.azurewebsites.net/".
                     "api/RegenerateSPToken";

   my $cgi;

   # hier kann irgendwann ein Key-Cleanup eingebaut werden, d.h. wenn
   # curSecretId ne "", dann kann purgeOldKeys=true und ex muss dann
   # die curSecretId in der Query uebergeben werden, damit diese NICHT
   # gepurged wird. Das werd ich dann in ein paar Tagen mal aktivieren, wenns
   # ohne den Purge stabil laeuft.

   if ($curSecretId ne ""){
      $cgi=new CGI({purgeOldKeys=>"True",skipPurgeById=>$curSecretId});
      #$cgi=new CGI({purgeOldKeys=>"False"});
   }
   else{
      $cgi=new CGI({purgeOldKeys=>"False"});
   }

   #######################################################################

   my $KeyApiQueryString=$cgi->query_string();
   my $KeyApiRequestUrl=$KeyApiBaseURL.'?'.$KeyApiQueryString;

   #msg(INFO,"QueryString=".$KeyApiQueryString);
   msg(INFO,"KeyApiRequestUrl=".$KeyApiRequestUrl);

   my $d=$o->CollectREST(
      dbname=>$credentialName,
      useproxy=>1,
      method=>'GET',
      url=>$KeyApiRequestUrl,
      headers=>sub{
         my $self=shift;
         my $headers=['Authorization'=>$Authorization,
                      'Content-Type'=>'application/json'];

         return($headers);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         return($data);
      }
   );



   if (ref($d) eq "HASH" && 
       exists($d->{secret}) && $d->{secret} ne "" &&
       exists($d->{secretId}) && $d->{secretId} ne ""){
      msg(INFO,"new key stored in AZURE as $d->{secretId}");

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
               printf $keyfileFH ("#AZURE name : %s\n",$d->{secretId});
               @curVal=grep(/^(DATAOBJCONNECT|DATAOBJBASE|DATAOBJUSER)/,
                            @curVal);
               push(@curVal,'DATAOBJPASS['.$credentialName.']="'.
                                         $d->{secret}."\"\n");
               push(@curVal,'DATAOBJSECRETID['.$credentialName.']="'.
                                         $d->{secretId}."\"\n");
               push(@curVal,"\n");
     
               print $keyfileFH (join("",@curVal));
               close($keyfileFH);
               return({exitcode=>0,exitmsg=>'ok - key '.$d->{secretId}.
                                            ' stored'});
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
