package kernel::DataObj::ShellConnectJSON;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::Static;

use JSON;
use Text::ParseWords;

use POSIX ":sys_wait_h";
use xIPC::Open3;    # needed because original IPC::Open3 did not untied STDERR

@ISA = qw(kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}


sub shellDataCollector
{
   my $self=shift;
   my $cmd=shift;
   my $arg=shift;
   my %param=@_;

   my @cmd=($cmd);
   if (ref($arg) eq "ARRAY" && $#{$arg}!=-1){
      push(@cmd,@$arg);
   }
   if (!defined($param{timeout})){
      $param{timeout}=60.0;
   }
   my ($stdin, $stdout, $stderr);
   {
      my $pid=open3($stdin,$stdout,$stderr,@cmd);
      if (defined($param{stdin})){
         &{$param{stdin}}($stdin);
      }
      my $sel = new IO::Select; # create a select object
      $sel->add($stdout,$stderr); # and add the fhs
    
      # $sel->can_read will block until there is data available
      # on one or more fhs
      while(my @ready = $sel->can_read($param{timeout})) {
       # now we have a list of all fhs that we can read from
       foreach my $fh (@ready) { # loop through them
           my $line;
           my $len;

           LINEREAD: while($sel->can_read(0.0)){
               my $linelen=0;
               CHAR: while (my $clen=sysread($fh, my $nextbyte,1)){ 
                  die() if ($clen==0);
                  last LINEREAD if ($clen==0);
                  last LINEREAD if ($nextbyte eq "");
                  $line.=$nextbyte; 
                  $linelen++;
                  last CHAR if $nextbyte eq "\n"; 
               }
               last LINEREAD if ($linelen==0);
           }
           if (defined($line)){
              $len=length($line);
           }

           if (! defined($len)){
               # There was an error reading
               return();
               #die "Error from child: $!\n";
           } elsif ($len == 0){
               # Finished reading from this FH because we read
               # 0 bytes.  Remove this handle from $sel.  
               # we will exit the loop once we remove all file
               # handles ($outfh and $errfh).
               $sel->remove($fh);
               next;
           } else { # we read data alright
               if($fh == $stdout) {
                   if (defined($param{stdout})){
                      &{$param{stdout}}($line);
                   }
               } elsif($fh == $stderr) {
                   if (defined($param{stdout})){
                      &{$param{stderr}}($line);
                   }
               } else {
                   die "Shouldn't be here\n";
               }
           }
        }
     }
   }
}










sub data
{
   my $self=shift;
   my $filterset=shift;

   my @view=$self->GetCurrentView();
   my @result;

   my $configTag=$self->getConfigParameterTag($filterset);
   my ($connect,$pass,$user,$base)=$self->GetRESTCredentials($configTag);
   my @arg=quotewords('\s+',1,$base);

   my $method=$self->getShellParameterList($filterset);

   my $json="";
   $self->shellDataCollector($connect,[@arg,$method],
      stdin=>sub{   # sender
         my $stdin=shift;
         printf $stdin ("%s\n",$user);
         printf $stdin ("%s\n",$pass);
      },
      stdout=>sub{   # stdout
         my $line=shift;
         $json.=$line;
      },
      stderr=>sub{   # stderr
         my $line=shift;
         msg(ERROR,$line);
      },
      timeout=>10
   );
   if ($json eq ""){
      $self->LastMsg(ERROR,"no JSON data response from backend");
      return(undef);
   }
   else{
      my $d;
      eval('$d=decode_json($json);');
      if ($@ ne ""){
         msg(ERROR,$@);
         msg(ERROR,$json);
         $self->LastMsg(ERROR,"backend data JSON structure error");
         return(undef);
      }
      else{
         return($self->reformatExternal($d));
      }
   }
   return(\@result);
}





1;
