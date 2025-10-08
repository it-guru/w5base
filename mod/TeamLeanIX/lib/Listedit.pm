package TeamLeanIX::lib::Listedit;
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
use tardis::lib::Listedit;
use Text::ParseWords;
use Digest::MD5 qw(md5_base64);
@ISA=qw(tardis::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


sub ORIGIN_Load_BackCall
{
   my $self=shift;
   my $originSubPath=shift;
   my $credentialName=shift;
   my $indexname=shift;
   my $ESjqTransform=shift;
   my $opNowStamp=shift;

   my $session=shift;
   my $meta=shift;
   
   my ($baseurl,$apikey,$apiuser)=$self->GetRESTCredentials($credentialName);
   my $Authorization=$self->getTardisAuthorizationToken($credentialName);
   
   #msg(INFO,"ORIGIN_Load: Tardis Authorization=$Authorization");
   my $dtLastLoad;
   if (exists($meta->{dtLastLoad})){
      $dtLastLoad=$self->ExpandTimeExpression($meta->{dtLastLoad},
                                              "en","GMT","GMT");
   }
   if ($dtLastLoad ne ""){
      my $d=CalcDateDuration($dtLastLoad,NowStamp("en"));
      if ($d->{totalminutes}>120){   # do a full load, if last load
         $dtLastLoad=undef;          # is older then 120min.
      }
      my $MetalastEScleanupIndex=$meta->{lastEScleanupIndex};
      my $lastEScleanupIndex=$self->ExpandTimeExpression(
                         $MetalastEScleanupIndex,"en","GMT","GMT");
      if ($lastEScleanupIndex ne ""){ 
         my $d=CalcDateDuration($lastEScleanupIndex,NowStamp("en"));
         if (defined($d)){
            if ($d->{totalminutes}>240){   # do a full load, if last
               $dtLastLoad=undef;          # fullload is older then 4h
            }
            msg(INFO,"lastEScleanupIndex=$lastEScleanupIndex - ".
                      int($d->{totalminutes})."min. old");
         }
         else{
            msg(WARN,"lastEScleanupIndex=$lastEScleanupIndex - broken!");
         }
      }
      else{
         $dtLastLoad=undef;
      }
   }
   if (exists($session->{loadParam}->{full}) &&
       $session->{loadParam}->{full}==1){
      msg(WARN,"inititiate full load by loadParam");
      $dtLastLoad=undef;
   }
 
   if (($baseurl=~m#/$#)){
      $baseurl=~s#/$##; 
   }
   #msg(INFO,"ORIGIN_Load: baseurl=$baseurl");
   my $restOriginFinalAddr=$baseurl.$originSubPath;
   if ($dtLastLoad ne ""){
      msg(INFO,"ESrestETLload: DeltaLoad since $meta->{dtLastLoad}");
      $restOriginFinalAddr.="?lastUpdated=$meta->{dtLastLoad}";
   }
   else{
      msg(INFO,"ESrestETLload: load with EScleanupIndex");
      msg(INFO,"ESrestETLload: EScleanupIndex 1: opNowStamp=$opNowStamp");

      if (1){ # due problems in T.EAM, we delete records after 1 days 
              # without  update
         msg(INFO,"ESrestETLload: EScleanupIndex substract 1d from opNowStamp");
         $opNowStamp=$self->ExpandTimeExpression($opNowStamp."-1d",
                                                 "ISO","GMT","GMT");
      }
      msg(INFO,"ESrestETLload: EScleanupIndex 2: opNowStamp=$opNowStamp");

      $session->{EScleanupIndex}={
          bool=>{
            should=>[
               {
                 range=>{
                    dtLastLoad=>{
                       lt=>$opNowStamp
                    }
                 }
               },
               {
                 match=>{
                    _id=>'__noop__'
                 }
               }
            ],
            'minimum_should_match'=>'1'
          } 
      };
   }
   msg(INFO,"ORIGIN_Load: restOriginFinalAddr=$restOriginFinalAddr");
   
   my @restOriginHeaders=(
       'Authorization'=>$Authorization
   );
   return("GET",$restOriginFinalAddr,\@restOriginHeaders,$ESjqTransform);
}






1;
