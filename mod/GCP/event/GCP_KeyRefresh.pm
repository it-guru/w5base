package GCP::event::GCP_KeyRefresh;
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
use MIME::Base64;
use Encode qw(encode);
use IPC::Run qw( start pump finish timeout );
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub genKeyPair
{
   my $self=shift;
   my $priv_key=shift;
   my $pub_key=shift;

   $$priv_key="xx";

   my $tempdir=tempdir('openssl_tmp_XXXXX',CLEANUP=>0,TMPDIR=>1);
   msg(INFO,"tempdir for openssl operation: $tempdir");

   my $priv_keyfile=$tempdir."/private_key.pem";
   my $pub_keyfile=$tempdir."/public_key.pem";


   msg(INFO,"openssl privkey: $priv_keyfile");
   msg(INFO,"openssl pubkey:  $pub_keyfile");

   my @cmd=("openssl","req",
                      "-x509","-nodes","-newkey","rsa:4096",
                      "-days","90",
                      "-keyout",$priv_keyfile, "-out",$pub_keyfile,
                      "-subj","/CN=unused"
   );

   my ($in,$out,$err);
   if (my $h=start(\@cmd,\$in,\$out,\$err,timeout(10))){
      while( my $p=pump($h)){
      #   printf STDERR ("p=%s\n",$p);
      }
      finish($h);
      if (open(F,'<',$priv_keyfile)){
         $$priv_key=join("",<F>);
         close(F);
         if (open(F,'<',$pub_keyfile)){
            $$pub_key=join("",<F>);
            close(F);
            return(1);
         }
      }
   }
   return(0);
}


sub GCP_KeyRefresh
{
   my $self=shift;
   my $keyfile=shift;

   if (($keyfile eq "") || 
       (! -f $keyfile ) ||
       (! -r $keyfile)){
      return({exitcode=>1,exitmsg=>"invalid keyfile '$keyfile'"});
   }
   
   my $priv_key;
   my $pub_key;
   $self->genKeyPair(\$priv_key,\$pub_key);

   if ($priv_key eq "" || $pub_key eq ""){
      return({
         exitcode=>12,
         exitmsg=>"fail to create key pair with openssl"
      });
   }

   #   printf STDERR ("priv_key:%s\n",$priv_key);
   my $o=getModuleObject($self->Config,"GCP::project");
   my $credentialName=$o->getCredentialName();
   my $Authorization=$o->getAuthorizationToken($credentialName,1);

   #msg(INFO,"Authorization: $Authorization");
   if ($Authorization eq ""){
      return({
         exitcode=>42,
         exitmsg=>"Authorization to GCP failed"
      });
   }

   my $qRec={
      publicKeyData=>GCP::lib::Listedit::oneLineBase64($pub_key)
   };

   my $data;
   eval('use JSON; $data=JSON->new->utf8->encode($qRec);');
   return(undef) if ($data eq "");

   my $ServiceProject="de0360-prd-w5base-darwin";
   my $ServiceAccount="w5base-darwin-access\@".
                      "de0360-prd-w5base-darwin.iam.gserviceaccount.com";


   my $d=$o->CollectREST(
      dbname=>$credentialName,
      useproxy=>1,
      method=>'GET',
      url=>sub{
         my $self=shift;
         my $baseurl="https://iam.googleapis.com/";
         my $dataobjurl=$baseurl."v1/projects/".$ServiceProject."/".
                                 "serviceAccounts/".$ServiceAccount.
                                 "/keys";
         return($dataobjurl);
      },
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $headers=['Authorization'=>$Authorization,
                      'Content-Type'=>'application/json'];
 
         return($headers);
      },
#      onfail=>sub{
#         my $self=shift;
#         my $code=shift;
#         my $statusline=shift;
#         my $content=shift;
#         my $reqtrace=shift;
#
#         if ($code eq "400"){
#            return("200");
#         }
#
#         msg(ERROR,$reqtrace);
#         $self->LastMsg(ERROR,"unexpected data GCP response");
#         return(undef);
#      }
#
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;

         return($data->{keys});
      }
   );
   if (ref($d) eq "ARRAY"){
      my @k;
      my @keyList=@$d;
      my $c=0;
      foreach my $CheckKey (@keyList){
         #printf STDERR ("CheckKey=%s\n",Dumper($CheckKey));
         next if ($CheckKey->{keyType} ne "USER_MANAGED");
         my $vTo=$CheckKey->{validBeforeTime};
         my $validtill;
         if ($vTo ne ""){
            $validtill=$o->ExpandTimeExpression($vTo,"en","GMT","GMT");
            next if ($validtill eq "");
         }
         my $d=CalcDateDuration(NowStamp("en"),$validtill);
         $c++;
         push(@k,{
            count=>$c,
            name=>$CheckKey->{name},
            days=>$d->{totaldays},
            validtill=>$validtill
         });
         #printf STDERR ("t=%s\n",$validtill);
      }
      @k=sort({$b->{days}<=>$a->{days}} @k);
      #printf STDERR ("k=%s\n",Dumper(\@k));

      for(my $c=6;$c<=$#k;$c++){
         my $drop=$k[$c];
         msg(INFO,"drop $drop->{name}");

         my $d=$o->CollectREST(
            dbname=>$credentialName,
            useproxy=>1,
            method=>'DELETE',
            url=>sub{
               my $self=shift;
               my $baseurl="https://iam.googleapis.com/";
               my $dataobjurl=$baseurl."v1/".$drop->{name};
               return($dataobjurl);
            },
            headers=>sub{
               my $self=shift;
               my $baseurl=shift;
               my $apikey=shift;
               my $headers=['Authorization'=>$Authorization,
                            'Content-Type'=>'application/json'];
        
               return($headers);
            }
         );
         #print STDERR Dumper($drop);
      }
   }

   my $d=$o->CollectREST(
      dbname=>$credentialName,
      useproxy=>1,
      method=>'POST',
      url=>sub{
         my $self=shift;
         my $baseurl="https://iam.googleapis.com/";
         my $dataobjurl=$baseurl.
                        "v1/projects/".$ServiceProject."/".
                        "serviceAccounts/".$ServiceAccount.
                        "/keys:upload";
         return($dataobjurl);
      },
      data=>$data,
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $headers=['Authorization'=>$Authorization,
                      'Content-Type'=>'application/json'];
 
         return($headers);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "400"){
            my $msg=$statusline;

            my $j;
            if ($content=~m/^{/){
               eval('use JSON;my $J=new JSON;$j=$J->decode($content)');
            }
            if (defined($j)){
               if (exists($j->{error}->{message})){
                  $msg=$j->{error}->{message};
               }
            }

            $self->SilentLastMsg(ERROR,$msg." - while new key upload");
            return("200");
         }

         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data GCP response");
         return(undef);
      }

     # success=>sub{  # DataReformaterOnSucces
     #    my $self=shift;
     #    my $data=shift;
#
#         return([]);
#      }
   );
   if (ref($d) eq "HASH" && 
       exists($d->{name}) && $d->{name} ne ""){
      msg(INFO,"new key stored in GCP as $d->{name}");

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
               printf $keyfileFH ("#GCP name : %s\n",$d->{name});
               @curVal=grep(/^(DATAOBJCONNECT|DATAOBJUSER)/,@curVal);
               push(@curVal,'DATAOBJPASS['.$credentialName.']="'."\n");
               push(@curVal,map({$_."\n"} split("\n",$priv_key)));
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
