package AL_TCom::event::CreatePlasmaTRQ;
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


   $self->RegisterEvent("CreatePlasmaTRQ","CreatePlasmaTRQ");
   return(1);
}

sub CreatePlasmaTRQ
{
   my $self=shift;
   my %param=@_;

   if ($param{debug}){
      eval('use SOAP::Lite +trace=>"all";');
   }
   else{
      eval('use SOAP::Lite;');
   }

   delete($ENV{HTTP_PROXY});
   delete($ENV{http_proxy});

   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
   my $wsuser=$self->Config->Param("WEBSERVICEUSER");
   my $wspass=$self->Config->Param("WEBSERVICEPASS");
   $wsuser=$wsuser->{plasma} if (ref($wsuser) eq "HASH");
   $wspass=$wspass->{plasma} if (ref($wspass) eq "HASH");
   $wsproxy=$wsproxy->{plasma} if (ref($wsproxy) eq "HASH");

   return({exitcode=>0,msg=>'ok - no interface defined'}) if ($wsproxy eq "");
   return({exitcode=>0,msg=>'ok - only ins send'}) if ($param{'op'} ne "ins");

   msg(DEBUG,"wsproxy='%s' wsuser='%s' wspass='%s'",$wsproxy,$wsuser,$wspass);
#   sub SOAP::Transport::HTTP::Client::get_basic_credentials {
#printf STDERR ("fifi get_basic_credentials\n");
#       return $wsuser => $wspass;
#   }


   my $wf=getModuleObject($self->getParent->Config(),"base::workflow"); 
   $wf->SetFilter({id=>\$param{'id'}});
   my @fieldlist=qw(involvedcustomer affectedapplication
                                    srcid name eventstart eventend
                                    wffields.changefallback
                                    wffields.changedescription);
   @fieldlist=qw(ALL);
   my ($WfRec)=$wf->getOnlyFirst(@fieldlist);
   my $involvedcustomer=$WfRec->{involvedcustomer};
   $involvedcustomer=[$involvedcustomer] if (ref($involvedcustomer) ne "ARRAY");
   if (!grep(/^DTAG\.ACTIVEBILLING.*/,@$involvedcustomer)){
      return({exitcode=>0,
              msg=>'no trigger needed'});
   }


   if ($param{'op'} eq "ins"){

      # ------------------ location check -----------------------
      my $location="Bamberg";
      my @location=$self->listPosibleValues($wsproxy,"standort");
      msg(INFO,"location: ".join(",",@location));
      foreach my $chk (@location){
         my $qchk=quotemeta($chk);
         if (grep(/$qchk/,$WfRec->{changedescription}) ||
             grep(/$qchk/,$WfRec->{name})){
            $location=$chk;
            last;
         }
      }
      msg(INFO,"use standort: ".$location);
      # ---------------------------------------------------------

      # ------------------ Urgency check ------------------------
      my @changeart=$self->listPosibleValues($wsproxy,"changeart");
      my $changeart=$changeart[0]; # 0= Change 1 = Emergency Change
      $changeart="Change" if ($changeart eq "");
      msg(INFO,"changeart: ".join(",",@changeart));
      if (grep(/normal/i,@{$WfRec->{additional}->{ServiceCenterUrgency}})){
         $changeart=$changeart[0];
      }
      if (grep(/emergency/i,@{$WfRec->{additional}->{ServiceCenterUrgency}})){
         $changeart=$changeart[1];
      }
      msg(INFO,"use changeart: ".$changeart);
      # ---------------------------------------------------------

      # ------------------ Impact  check ------------------------
      my @impakt=$self->listPosibleValues($wsproxy,"impakt");
      msg(INFO,"impakt: ".join(",",@impakt));
      my $impact=$impakt[0];
      if (grep(/none/i,@{$WfRec->{additional}->{ServiceCenterImpact}})){
         $impact=$impakt[0];
      }
      if (grep(/low/i,@{$WfRec->{additional}->{ServiceCenterImpact}})){
         $impact=$impakt[1];
      }
      if (grep(/medium/i,@{$WfRec->{additional}->{ServiceCenterImpact}})){
         $impact=$impakt[2];
      }
      if (grep(/hight/i,@{$WfRec->{additional}->{ServiceCenterImpact}})){
         $impact=$impakt[3];
      }
      if (grep(/critical/i,@{$WfRec->{additional}->{ServiceCenterImpact}})){
         $impact=$impakt[4];
      }
      msg(INFO,"use impact: ".$impact);
      # ---------------------------------------------------------
      
      # ------------------ FBB user check -----------------------
      my $fbbuser="unknown";
      if (my ($wiwid)=$WfRec->{openusername}=~m/^wiw\/(.+)$/){
         $fbbuser=$wiwid;
      }

      # ---------------------------------------------------------

      my $changenummer=$WfRec->{srcid};
      $changenummer=~s/^CHM//;
      $changenummer=~s/^T-CHM//;

      my $from=$wf->ExpandTimeExpression($WfRec->{eventstart},
                                         "SOAP","GMT","CET");
      my $to  =$wf->ExpandTimeExpression($WfRec->{eventend},
                                         "SOAP","GMT","CET");
#      my @d;
#      push(@d,\SOAP::Data->name("anwendung")
#                         ->type("xsd:string")
#                         ->value("aa","bb"));
#
#      push(@d,\SOAP::Data->name("grund")
#                          ->type("xsd:string")
#                          ->value("is hal su"));
#

      my $d={
             'changeart'   =>$changeart,
             'changenummer'=>$changenummer,
             'bezugsnummer'=>$changenummer,
             'impakt'      =>$impact,
             'bezeichnung' =>$WfRec->{name},
             'anwendungen' =>{
                'anwendung'  =>SOAP::Data
                                   ->value(@{$WfRec->{affectedapplication}})
             },
             'standort'    =>SOAP::Data
                                 ->type("xsd:string")
                                 ->value($location),
             'grund'       =>SOAP::Data
                                 ->type("xsd:string")
                                 ->value($WfRec->{changedescription}),
             'fallback'    =>SOAP::Data
                                 ->type("xsd:string")
                                 ->value($WfRec->{changefallback}),
             'geplanteAktivitaeten'=>SOAP::Data
                                 ->type("xsd:string")
                                 ->value($WfRec->{changedescription}),
             'terminzeitraum'=>{ 
                'DatumNach'  =>$to,
                'DatumVon'   =>$from
             },
             'auswirkungen'  =>'???',
             'bearbeiterFBB' =>$fbbuser,
             'email'         =>'null@null.com'
      };

      my $method = SOAP::Data->name('TRQAnlegen');

      my $requestPossibleValues=\SOAP::Data->name("request")
                                         ->type("")
                                         ->value($d);
      my $RequestData=SOAP::Data->name("RequestData")
                                ->type("")
                                ->value($requestPossibleValues);
    
    
      my $callname=$method->name;

      my $soap=SOAP::Lite->proxy($wsproxy)
             ->on_action(sub{'"urn:PegaRULES:SOAP:DTAGZBBCPLASMADarwinTrigger:'.
                             'DarwinTriggerMain#'.$callname.'"'});
      my $res;
      eval('$res=$soap->call($callname=>$RequestData);'); 
      if (!defined($res) || ($@=~m/Connection refused/)){
         msg(DEBUG,$@);
         return({exitcode=>10,
                 msg=>'can not connect to Plasma - Connection refused'});
      }

      if ($res->fault){
         $self->Log(ERROR,"trigger","Plasma: WF:%d = %s ",$param{id},
                          $res->fault->{faultstring});
         return({exitcode=>2,msg=>$res->fault->{faultstring}});
      }

      my $r=$res->result();
      msg(DEBUG,"exitcode=".$r->{response}->{exitcode});
      if ($r->{response}->{exitcode} ne "0"){
         my $msg=$r->{response}->{msglog};
         $msg=join("\n",@{$msg}) if (ref($msg) eq "ARRAY");
         msg(ERROR,"d=".Dumper($d));
         msg(ERROR,"msg=".$msg);
         return({exitcode=>-1,msg=>'ERROR create TRQ for '.$WfRec->{srcid}});
         
      }
      else{
         msg(DEBUG,"TRQ successfuly - ".$r->{response}->{rqnummer});
         return({exitcode=>0,msg=>'TRQ:'.$r->{response}->{rqnummer}.
                                  " created"});
      }
   }
   return({exitcode=>0,msg=>'ok - only ins need action'});
}


sub listPosibleValues
{
   my $self=shift;
   my $wsproxy=shift;
   my $name=shift;

   my $requestPossibleValues=\SOAP::Data->name("requestPossibleValues")
                                      ->type("")
                                      ->value({fieldname=>$name});
   my $RequestData=SOAP::Data->name("RequestData")
                             ->type("")
                             ->value($requestPossibleValues);
   my $method = SOAP::Data->name('getPossibleValues');


   my $callname=$method->name;
   my $soap=SOAP::Lite->proxy($wsproxy)
          ->on_action(sub{'"urn:PegaRULES:SOAP:DTAGZBBCPLASMADarwinTrigger:'.
                          'DarwinTriggerMain#'.$callname.'"'});
   my $res;
   eval('$res=$soap->call($callname,$RequestData);'); 
   msg(DEBUG,$@);
   my @l;
   my $r=$res->result;
   if (ref($r) eq "HASH" && ref($r->{responsePossibleValues}) eq "HASH" &&
       ref($r->{responsePossibleValues}->{possiblevalues}) eq "ARRAY"){
      @l=@{$r->{responsePossibleValues}->{possiblevalues}};
   }
   return(@l);
}





1;
