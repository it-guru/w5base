# This is the w5agent kernel
package w5agent;

my %config;

sub readConfigIPC
{
   %config=();
   my $buff;
   shmread($ENV{W5CFGIPCID}, $buff, 0, 4096) || die "$!";
printf("fifi buf=$buff\n");
   substr($buff, index($buff, "\0")) = '';
   eval($buff);
}



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
