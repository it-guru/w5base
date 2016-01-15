package W5Base::MySQL;
use strict;
use kernel;
use DBIx::MyServer;
use vars (qw(@ISA));
@ISA=qw(DBIx::MyServer);

use constant MYSERVER_PARENT => 100;

sub new
{
   my $type=shift;
   my %param=@_;
   my $parent;
   if (defined($param{parent})){
      $parent=$param{parent};
      delete($param{parent}); 
   }
   else{
      return(undef);
   }
   my $self=bless($type->SUPER::new(%param),$type);
   $self->setParent($parent);

   return($self);
}

sub getParent
{
   my $self=shift;
   return($self->[MYSERVER_PARENT]);
}

sub setParent
{
   my $self=shift;
   $self->[MYSERVER_PARENT]=$_[0];
}

sub authorize
{
   my $self=shift;
   my ($remote_host, $username, $database)=@_;
   my $uarec;

   my $ua=getModuleObject($self->getParent->Config,"base::useraccount");
   $ua->ResetFilter();
   $ua->SetFilter({account=>\$username});
   my $msg;
   ($uarec,$msg)=$ua->getOnlyFirst(qw(password userid));
   print STDERR "useraccount=".Dumper($uarec);
   if (!defined($uarec)){
      printf STDERR ("ERROR: user not found\n");
      return(undef);
   }
   if (!$self->passwordMatches('123456')){
      printf STDERR ("ERROR: password not match\n");
      return(undef);
   }
   printf STDERR ("=========== authorized fine =============\n");
   return(1);
}


package base::W5Server::mysql;
use strict;
use Socket;
use kernel;
use kernel::W5Server;
use vars (qw(@ISA));
@ISA=qw(kernel::W5Server);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub process
{
   my $self=shift;

   eval('use DBIx::MyServer;');

#
# This is a simple MySQL lisener that opens a listening socket on port $port. If DBIx::MyParse
# is installed, the query is parsed and the parse tree is returned to the client. If this module
# is not present, the query is simply echoed back to the client.
#

my $port = '33306';
my $database = 'myecho';
my $table = 'mytable';
my $field = 'myfield';
no strict;

socket(SERVER_SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
setsockopt(SERVER_SOCK, SOL_SOCKET, SO_REUSEADDR, pack("l", 1));
bind(SERVER_SOCK, sockaddr_in($port, INADDR_ANY)) || die "bind: $!";
listen(SERVER_SOCK,1);

print localtime()." [$$] Please use `mysql --host=127.0.0.1 --port=$port` to connect.\n";

while (1) {
   if (my $remote_paddr = accept(my $remote_socket, SERVER_SOCK)){
      my $myserver = W5Base::MySQL->new( 'socket' => $remote_socket ,
                                         'parent' => $self->getParent);
      
    #  $myserver->sendServerHello();   # Those three together are identical to
    #  my ($user,$database)=$myserver->readClientHello();
      if ($myserver->handshake()){
       #  $myserver->sendOK();      # which uses the default authorize() handler
         my $pid=fork();
         if ($pid==0){
            while (1) {
               my ($command, $data) = $myserver->readCommand();
               print localtime()." [$$] Command: $command; User $user; Data: $data\n";
               if (
                  (not defined $command) ||
                  ($command == DBIx::MyServer::COM_QUIT)
               ) {
                  last;
               } elsif ($command == 3) {
                  $myserver->sendDefinitions([$myserver->newDefinition( name => 'field' )]);
                  if ($data eq 'show tables') {
                     $myserver->sendRows([]);
                  }
                  elsif ($data eq 'select chief of developers') {
                     $myserver->sendRows([['vogler hartmut']]);
                  }
                  elsif ($data eq 'show databases') {
                     $myserver->sendRows([]);
                  }
                  elsif ($data eq 'select @@version_comment limit 1') {
                     $myserver->sendRows([['W5Base']]);
                  }
                  else{
                     $myserver->sendRows([['jo']]);
                  }
               } else {
                  $myserver->sendErrorUnsupported($command);
               }
            }
            exit(0);
         }
      }
	}
}

}

1;
