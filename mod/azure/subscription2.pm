sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(TriggerEndpoint),$self->SUPER::getValidWebFunctions());
}

#
# Endpoint URL to handle Trigger Events from Azure Cloud
#

sub TriggerEndpoint
{
   my $self=shift;
   my %param;

   $param{charset}="UTF8";

   my $q=Query->MultiVars();

   delete($q->{MOD});
   delete($q->{FUNC});
   print $self->HttpHeader("application/javascript",%param);

   my $json=new JSON;
   $json->utf8(1);

   my $d=$json->pretty->encode({
      request=>$q,
      handler=>$self->Self,
      exitcode=>0,
      ptimestamp=>NowStamp(),
      exitmsg=>'OK'
   });
   print $d;
   return(0);
}





