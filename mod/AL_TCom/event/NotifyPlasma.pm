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

   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
   $wsproxy=$wsproxy->{plasma} if (ref($wsproxy) eq "HASH");
   return({exitcode=>0,msg=>'ok'}) if ($wsproxy eq "");
   msg(DEBUG,"wsproxy='%s'",$wsproxy);
   my $method = SOAP::Data->name('CreateNewWork');

   my %tr=('id'     =>'WF_ID');
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
   my $wf=getModuleObject($self->getParent->Config(),"base::workflow"); 
   $wf->SetFilter({id=>\$param{'id'}});
   my ($WfRec)=$wf->getOnlyFirst(qw(involvedcustomer));
   my $involvedcustomer=$WfRec->{involvedcustomer};
   $involvedcustomer=[$involvedcustomer] if (ref($involvedcustomer) ne "ARRAY");
   if (!grep(/^DTAG\.ACTIVEBILLING.*/,@$involvedcustomer)){
      return({exitcode=>0,
              msg=>'no trigger needed'});
   }

   my $soap=SOAP::Lite->proxy($wsproxy)
            ->on_action(sub{'"urn:PegaRULES:SOAP:DTAGZBBCPLASMADarwinTrigger:DarwinTriggerMain#CreateNewWork"'});
   my $res;
   eval('$res=$soap->call($method=>@SOAPparam);'); 
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
   $self->Log(INFO,"trigger","Plasma: WF:%d = %s ",$param{id},$res->result());
   msg(DEBUG,"Plasma result=%s",$res->result());
   return({exitcode=>0,msg=>'ok'});
}





1;
