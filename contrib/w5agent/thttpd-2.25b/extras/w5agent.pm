# This is the w5agent kernel
package w5agent;


package W5AgentModule;

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);

   return($self);
}

sub PreFork
{
   my ($self)=@_;
   return(1);
}

sub Startup
{
   my ($self)=@_;
   return(1);
}

sub ReConfigure
{
   my ($self)=@_;
   return(1);
}

sub Main
{
   my ($self)=@_;
   return(1);
}

sub MainLoop
{
   my ($self)=@_;
   while(1){
      sleep(1);
      $self->Main();
   }
   return(1);
}

sub Shutdown
{
   my ($self)=@_;
   return(1);
}

1;
