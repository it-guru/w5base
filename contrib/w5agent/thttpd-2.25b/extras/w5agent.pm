# This is the w5agent kernel
package w5agent;
use Data::Dumper;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&Dumper &ERROR &OK &WARN &DEBUG &INFO &msg);

sub Dumper { return(Data::Dumper::Dumper(@_)); }

sub readConfigIPC
{
   my %config=();
   my $buff;
   shmread($ENV{W5CFGIPCID}, $buff, 0, 4096) || die "$!";
   substr($buff, index($buff, "\0")) = '';
   eval($buff);
   if ($@ eq ""){
      %w5agent::config=%config;
   }
   else{
      msg(ERROR,"can't load config from IPC shared memory");
      exit(-1);
   }
}

sub ERROR() {return("ERROR")}
sub OK()    {return("OK")}
sub WARN()  {return("WARN")}
sub DEBUG() {return("DEBUG")}
sub INFO()  {return("INFO")}

sub msg
{
   my $type=shift;
   my $msg=shift;
   $msg=~s/%/%%/g if ($#_==-1);
   $msg=sprintf($msg,@_);
   return("") if ($type eq "DEBUG" && !($w5agent::config{DEBUG}));
   my $d;
   foreach my $linemsg (split(/\n/,$msg)){
      $d.=sprintf("%-6s %s\n",$type.":",$linemsg);
   }
   if ($type eq "ERROR" || $type eq "DEBUG" || $type eq "WARN"){
      print STDERR $d;
   }
   return($d);
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
