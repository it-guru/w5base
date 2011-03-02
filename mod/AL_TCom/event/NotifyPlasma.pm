package AL_TCom::event::NotifyPlasma;
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
#use SOAP::Lite +trace=>'all';
use SOAP::Lite;
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


   $self->RegisterEvent("NotifyPlasma","NotifyPlasma");
   return(1);
}

sub NotifyPlasma
{
   my $self=shift;
   my %param=@_;

   delete($ENV{HTTP_PROXY});
   delete($ENV{http_proxy});

   msg(DEBUG,"NotifyPlasma: start of NotifyPlasma");
   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
   $wsproxy=$wsproxy->{plasma} if (ref($wsproxy) eq "HASH");
   return({exitcode=>0,msg=>'ok - no interface defined'}) if ($wsproxy eq "");
   return({exitcode=>1,msg=>'fail - no id'}) if ($param{'id'} eq "");

   my $wf=getModuleObject($self->getParent->Config(),"base::workflow"); 
   $wf->SetFilter({id=>\$param{'id'}});
   my ($WfRec)=$wf->getOnlyFirst(qw(involvedcustomer affectedapplication));
   my $involvedcustomer=$WfRec->{involvedcustomer};
   $involvedcustomer=[$involvedcustomer] if (ref($involvedcustomer) ne "ARRAY");
   if (!grep(/^DTAG\.ACTIVEBILLING.*/,@$involvedcustomer)){
      return({exitcode=>0,
              msg=>'no trigger needed'});
   }

   #######################################################################
   #
   # temp verify, if application SDM_TEST is affected - only this
   # events should be transfered
   #
#   my $affectedapplication=$WfRec->{affectedapplication};
#   $affectedapplication=[$affectedapplication] if (ref($affectedapplication) ne "ARRAY");
#   if (!grep(/^(SDM_TEST|FAKT_WIRK|SPRING_WIRK)$/,@$affectedapplication)){
#      return({exitcode=>0,
#              msg=>'no trigger needed - no SDM_TEST|FAKT_WIRK|SPRING_WIRK'});
#   }
#   laut Anforderung ...
#   https://darwin.telekom.de/darwin/auth/base/workflow/ById/12990592790001
#   ... soll die Schnittstelle nun für alle ActiveBilling Anwendungen
#   aktiviert werden.
   #######################################################################

   msg(DEBUG,"NotifyPlasma: wsproxy='%s'",$wsproxy);
   if ($param{'op'} eq "ins"){
   #   printf STDERR ("fifi param=%s\n",Dumper(\%param));


   }



   my $method = SOAP::Data->name('CreateNewWork');

   my %tr=('id'     =>'WF_ID','sclass'=>'WF_CLASS');
   my @SOAPparam;
   my $FoundData;
   foreach my $k (keys(%tr)){
      if ($param{$k} ne ""){
         push(@SOAPparam,SOAP::Data->name($tr{$k})
                                   ->type("")->value($param{$k}));
         $FoundData++;
      }
   }
   if (!$FoundData || $param{id} eq ""){
      return({exitcode=>11,
              msg=>'no data specified'});
   }
   msg(DEBUG,"NotifyPlasma: call ready");
   my $soap=SOAP::Lite->proxy($wsproxy)
            ->on_action(sub{'"urn:PegaRULES:SOAP:DTAGZBBCPLASMADarwinTrigger:'.
                            'DarwinTriggerMain#CreateNewWork"'});
   my $res;
   eval('$res=$soap->call($method=>@SOAPparam);'); 
   if (!defined($res) || ($@=~m/Connection refused/)){
      msg(DEBUG,$@);
      return({exitcode=>10,
              msg=>'can not connect to Plasma - Connection refused'});
   }

   if ($res->fault){
      my $fstring=$res->fault->{faultstring};
      msg(DEBUG,$fstring);
      $fstring=~s/\n/  /g;
      $self->Log(ERROR,"trigger","Plasma: WF:%d = %s ",$param{id},$fstring);
      return({exitcode=>2,msg=>"unexpected result from Plasma"});
   }





   $self->Log(INFO,"trigger","Plasma: WF:%d = %s ",$param{id},$res->result());
   msg(DEBUG,"Plasma result=%s",$res->result());
   return({exitcode=>0,msg=>'ok'});
}





1;
