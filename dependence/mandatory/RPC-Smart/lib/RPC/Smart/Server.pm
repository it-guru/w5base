package RPC::IPC;
use IPC::SharedMem;
use Data::Dumper;

sub new
{
   my ($class,$size)=@_;
   my $self={size=>$size};
   $self->{mem}=new IPC::SharedMem(
       IPC_PRIVATE,
       $self->{size},
       IPC_CREAT|IPC_EXCL|0600
   );
   $self->{mem}->attach();
   $self->{mem}->remove();
   return(bless($self,$class));
}


sub store
{
   my $self=shift;
   my $string=shift;

   $self->{mem}->write($string,0,$self->{size});
}

sub fetch
{
   my $self=shift;
   my $string=shift;

   my $s=$self->{mem}->read(0,$self->{size});
   return($s);
}


sub DESTROY
{
   my $self=shift;
   
   $self->{mem}->detach();
   my $bk=$self->{mem}->remove();
   return(0);
}


package RPC::Smart::Server;
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

$VERSION = '1.3';

use 5.006_001;
use strict;
use vars qw(@ISA %tasks @EXPORT @EXPORT_OK);
use Exporter;
use Net::Server::Multiplex;
use XML::Smart;
use Data::Dumper;
use RPC::Smart;
use POSIX;
use Net::Server::SIG qw(register_sig check_sigs);

@ISA=qw(Net::Server::Multiplex RPC::Smart);
@EXPORT_OK=qw(async);
@EXPORT=qw(async);


sub checkMethod
{
   my $self=shift;
   my $mux=shift;
   my $io=shift;
   my $XML=shift;
   my $resXML=shift;

   #printf STDERR ("check method '%s'\n",$XML->{method});
   return(1);
}

sub validateXML
{
   my $self=shift;
   my $pXMLscalar=shift;

   return(1);
}

sub configure
{
  my $self = shift;
  
  $self->{server}->{check_for_dequeue}=1;
  return($self->SUPER::configure(@_));
} 

sub getTasksHash
{
   my $self = shift;
   return(\%tasks);
}


sub run_dequeue
{
   my $self = shift;
   my $tasks=$self->getTasksHash();
   
   if (keys(%{$tasks})){
      foreach my $pid (keys(%{$tasks})){
         if (exists($tasks->{$pid}->{end})){
            if ($tasks->{$pid}->{end}<time()-60){
               #printf STDERR ("run_dequeue PID $pid cleanup:%s\n",
               #               Dumper($tasks->{$pid}));
               delete($tasks->{$pid});
            }
         }
      }
      #printf STDERR ("run_dequeue:%s\n",Dumper(\%tasks));
   }
   else{
     # printf STDERR (".\n");
   }
   return(1);
} 

#######################################################################
#
#   Extension for IO::Multiplex
#
sub mux_close
{
  my $self = shift;
  my $mux  = shift;
  my $fh   = shift;
  my $in_ref = shift;  # Scalar reference to the input
  
  #printf STDERR ("#################### By By ######################\n");
  
  return($self->SUPER::mux_close($mux,$fh,$in_ref));
} 


sub mux_input
{
   my $self=shift;
   my $mux=shift;
   my $io=shift;
   my $d=shift;
   my $process=0;

   #printf STDERR ("------------------------------------------------\n$$d\n");
   if (!($$d=~m/^\<\?xml/)){
      if ($$d=~m/\<\?xml/){
         $$d=~s/^.*(\<\?xml)/$1/;
      }
      else{
         $$d='';
      }
   }
   my $XML=new XML::Smart();
   if ($$d=~m/^\<\?xml.*/){
      if ($$d=~m/^(\<\?[^\>]+?\?\>\s*){0,2}\<root>/m &&
          $$d=~m/\<\/root\>/){
         $$d=~s/<\/root\>.*$/<\/root\>/m;
         #printf STDERR ("fifi d=%s\n",$$d);
         if ($self->validateXML($$d)){ 
            my  $XML;
            eval {
                $XML=new XML::Smart($$d);
            };
            my $result=$@;
            if ($result eq ""){
               my $resXML=new XML::Smart();
               foreach my $callXML ($XML->{root}->nodes){
                  if (!$self->checkMethod($mux,$io,$callXML,$resXML)){
                     push(@{$XML->{root}},{exitcode=>128,
                                           result=>'Invalid method'}) ;
                  }
                  else{
                     $self->callMethod($mux,$io,$callXML,$resXML);
                  }
               }
               #my $data=$resXML->data;
               #$data=~s/^1//;;  # mystery bug seems to came from XML::Smart
               print(scalar($resXML->data));
            }
            else{
               $XML=new XML::Smart();
               $result=~s/\s*$//;
               push(@{$XML->{root}},{exitcode=>255,result=>$result}) ;
               print $XML->data;
               printf STDERR ("ERROR in XML\n");
            }
         }
         $$d='';
      }
   }
}  

sub max_async
{
   my $self=shift;
   my $n=shift;

   if (defined($n)){
      $self->{max_async}=$n;
   }
   return($n);
}


sub async
{
   my $self=shift;
   my $proc=shift;
   my %param=@_;
   my $tasks=$self->getTasksHash();
   if (defined($self->{max_async}) &&
       keys(%{$tasks})>$self->{max_async}){
      return({result=>'no task space left',exitcode=>1});
   }
   my $taskenv={
      start=>time(),
      timeout=>$param{timeout},
      ipc=>new RPC::IPC(8192)
   };
   foreach my $k (keys(%param)){
      next if (exists($taskenv->{$k}));
      $taskenv->{$k}=$param{$k};
   }
   my $pid=fork();
   if ($pid==0){
      %{$tasks}=(); # reset tasks hash in child process (prevent cleanups)
      {  # cleanup paren multiplex server
         if (defined($self->{mux})){
            foreach my $fhs (%{$self->{mux}->{_fhs}}){
               $self->{mux}->_removeTimer($fhs);
               if (exists($self->{mux}->{_fhs}->{"$fhs"}->{inbuffer})){
                  delete($self->{mux}->{_fhs}->{"$fhs"}->{inbuffer});
               }
               if (exists($self->{mux}->{_fhs}->{"$fhs"}->{outbuffer})){
                  delete($self->{mux}->{_fhs}->{"$fhs"}->{outbuffer});
               }
               if (exists($self->{mux}->{_fhs}->{"$fhs"}->{fileno})){
     # mal ein Test    POSIX::close($self->{mux}->{_fhs}->{"$fhs"}->{fileno});
               }
            }
         }
         delete($self->{Server}); 
         $self->{mux}->endloop() if (defined($self->{mux}) && 
                                     $self->{mux}->can('endloop'));
         #foreach my $sock (@{$self->{server}->{sock}}){
         #   $sock->close();
         #}
         #$self->{server}->{sock}=[];
         delete($self->{server}); 
         #delete($self->{mux}); 
      }
      #printf STDERR ("fifi %s\n",Dumper($self));
      #printf STDERR ("fifi %s\n",join(",",keys(%$self)));
      register_sig(PIPE => 'DEFAULT',
                   INT  => 'DEFAULT',
                   TERM => 'DEFAULT',
                   QUIT => 'DEFAULT',
                   HUP  => 'DEFAULT',
                   CHLD => 'IGNORE');
      for(my $f=4;$f<255;$f++){
         POSIX::close($f);
      }
      $self->{taskenv}=$taskenv;
      $self->{ipc}=$taskenv->{ipc};
      $|=1;
      my $reshash=&{$proc}();
      exit(-1) if (!defined($reshash));
      if (ref($reshash) ne "HASH"){
         $reshash={exitcode=>$reshash};
      }
      #printf STDERR ("reshash=%s self=$self ipc=$self->{ipc}\n",
      #               Dumper($reshash));
      $self->ipcStore($reshash);
      exit($reshash->{exitcode}) if (exists($reshash->{exitcode}));
      exit(0);
   }
   if ($pid>0){
      $tasks->{$pid}=$taskenv;
   }
   return({AsyncID=>$pid,exitcode=>0});
}

sub ipcStore
{
   my $self=shift;
   my $val=shift;

   return(undef) if (!defined($self->{ipc}));
   return(undef) if (!ref($val));
   my $store=Dumper($val);
   if (length($store)>=8192-128){
      printf STDERR ('ERROR: ipcStore result from async job larger '.
                     'then 8192 Bytes');
      $store=Dumper({exitcode=>2048,msg=>'ERROR: ipcStore result to large'});
   }
   $self->{ipc}->store($store);
   return(1);
}


sub sig_chld {
  while((my $pid=waitpid(-1, POSIX::WNOHANG()))>0){
     $tasks{$pid}->{end}=time();
     $tasks{$pid}->{exitcode}=$?;
     #printf STDERR ("gestorben:$pid\n");
  }
  $SIG{CHLD} = \&sig_chld;
}


sub callMethod
{
   my $self=shift;
   my $mux=shift;
   my $io=shift;
   my $XML=shift;
   my $resXML=shift;
   my $method=$XML->{method};
   my %param=();
   my $fres;
   my $realself=$self->{net_server};

   my $h=$XML->pointer()->{'param'};
   if (!ref($h)){
      $h=[$h];
   }
   my $result;
   if ($realself->can($method)){
      if (ref($h) eq "HASH"){
         %param=%{RPC::Smart::HashPack($h)};
         eval("\$fres=\$realself->$method(\\\%param,\$self,\$mux,\$io);");
      }
      if (ref($h) eq "ARRAY"){
         my @param=@{RPC::Smart::ArrayPack($h)};
         eval("\$fres=\$realself->$method(\@param);");
      }
      $result=$@;
   }
   else{
      $result="ERROR: unknown method '$method'";
   }
   if ($result eq ""){
      if (defined($fres) && ref($fres) eq "HASH"){
         push(@{$resXML->{root}},{call=>{exitcode=>0,%{$fres}}}) ;
      }
      else{
         push(@{$resXML->{root}},{call=>{exitcode=>128,
                                  result=>"method result unexpected"}});
      }
   }
   else{
      $result=~s/\s*$//;
      push(@{$resXML->{root}},{call=>{exitcode=>128,result=>$result}});
   }
}


#######################################################################






















1;
__END__

=head1 NAME

RPC::Smart::Server - Server class

=head1 SYNOPSIS

    use Data::Dumper;

    # simple procedural interface
    print Dumper($foo, $bar);


=head1 DESCRIPTION

Given a list of scalars or reference variables, writes out their contents in
perl syntax. The references can also be objects.  The contents of each
variable is output in a single Perl statement.  Handles self-referential
structures correctly.

Several styles of output are possible, all controlled by setting
the C<Indent> flag.  See L<Configuration Variables or Methods> below 
for details.


=head2 Methods

=over 4

=item I<PACKAGE>->new(I<ARRAYREF [>, I<ARRAYREF]>)

4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as

=item I<$OBJ>->Dump  I<or>  I<PACKAGE>->Dump(I<ARRAYREF [>, I<ARRAYREF]>)

4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as

=back

=head2 Functions

=over 4

=item Dumper(I<LIST>)

4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as
4ad7s65f3as7df37as54df7a6s54df76as54df765as4f7d6a54s76fd4as76df4as67df4as

=back

=head1 EXAMPLES

Run these code snippets to get a quick feel for the behavior of this
module.  When you are through with these examples, you may want to
add or change the various configuration variables described above,
to see their behavior.  (See the testsuite in the Data::Dumper
distribution for more examples.)


    use Data::Dumper;

    package Foo;
    sub new {bless {'a' => 1, 'b' => sub { return "foo" }}, $_[0]};

    package Fuz;                       # a weird REF-REF-SCALAR object
    sub new {bless \($_ = \ 'fu\'z'), $_[0]};

    package main;
    $foo = Foo->new;
    $fuz = Fuz->new;
    $boo = [ 1, [], "abcd", \*foo,
             {1 => 'a', 023 => 'b', 0x45 => 'c'}, 
             \\"p\q\'r", $foo, $fuz];

    ########
    # simple usage
    ########

    $bar = eval(Dumper($boo));
    print($@) if $@;
    print Dumper($boo), Dumper($bar);  # pretty print (no array indices)

    $Data::Dumper::Terse = 1;          # don't output names where feasible
    $Data::Dumper::Indent = 0;         # turn off all pretty print
    print Dumper($boo), "\n";

    $Data::Dumper::Indent = 1;         # mild pretty print
    print Dumper($boo);

    $Data::Dumper::Indent = 3;         # pretty print with array indices
    print Dumper($boo);

    $Data::Dumper::Useqq = 1;          # print strings in double quotes
    print Dumper($boo);

    $Data::Dumper::Pair = " : ";       # specify hash key/value separator
    print Dumper($boo);


    ########
    # recursive structures
    ########

    @c = ('c');
    $c = \@c;
    $b = {};
    $a = [1, $b, $c];
    $b->{a} = $a;
    $b->{b} = $a->[1];
    $b->{c} = $a->[2];
    print Data::Dumper->Dump([$a,$b,$c], [qw(a b c)]);


    $Data::Dumper::Purity = 1;         # fill in the holes for eval
    print Data::Dumper->Dump([$a, $b], [qw(*a b)]); # print as @a
    print Data::Dumper->Dump([$b, $a], [qw(*b a)]); # print as %b


    $Data::Dumper::Deepcopy = 1;       # avoid cross-refs
    print Data::Dumper->Dump([$b, $a], [qw(*b a)]);


    $Data::Dumper::Purity = 0;         # avoid cross-refs
    print Data::Dumper->Dump([$b, $a], [qw(*b a)]);

    ########
    # deep structures
    ########

    $a = "pearl";
    $b = [ $a ];
    $c = { 'b' => $b };
    $d = [ $c ];
    $e = { 'd' => $d };
    $f = { 'e' => $e };
    print Data::Dumper->Dump([$f], [qw(f)]);

    $Data::Dumper::Maxdepth = 3;       # no deeper than 3 refs down
    print Data::Dumper->Dump([$f], [qw(f)]);


    ########
    # object-oriented usage
    ########

    $d = Data::Dumper->new([$a,$b], [qw(a b)]);
    $d->Seen({'*c' => $c});            # stash a ref without printing it
    $d->Indent(3);
    print $d->Dump;
    $d->Reset->Purity(0);              # empty the seen cache
    print join "----\n", $d->Dump;


    ########
    # persistence
    ########

    package Foo;
    sub new { bless { state => 'awake' }, shift }
    sub Freeze {
        my $s = shift;
	print STDERR "preparing to sleep\n";
	$s->{state} = 'asleep';
	return bless $s, 'Foo::ZZZ';
    }

    package Foo::ZZZ;
    sub Thaw {
        my $s = shift;
	print STDERR "waking up\n";
	$s->{state} = 'awake';
	return bless $s, 'Foo';
    }

    package Foo;
    use Data::Dumper;
    $a = Foo->new;
    $b = Data::Dumper->new([$a], ['c']);
    $b->Freezer('Freeze');
    $b->Toaster('Thaw');
    $c = $b->Dump;
    print $c;
    $d = eval $c;
    print Data::Dumper->Dump([$d], ['d']);


    ########
    # symbol substitution (useful for recreating CODE refs)
    ########

    sub foo { print "foo speaking\n" }
    *other = \&foo;
    $bar = [ \&other ];
    $d = Data::Dumper->new([\&other,$bar],['*other','bar']);
    $d->Seen({ '*foo' => \&foo });
    print $d->Dump;


    ########
    # sorting and filtering hash keys
    ########

    $Data::Dumper::Sortkeys = \&my_filter;
    my $foo = { map { (ord, "$_$_$_") } 'I'..'Q' };
    my $bar = { %$foo };
    my $baz = { reverse %$foo };
    print Dumper [ $foo, $bar, $baz ];

    sub my_filter {
        my ($hash) = @_;
        # return an array ref containing the hash keys to dump
        # in the order that you want them to be dumped
        return [
          # Sort the keys of %$foo in reverse numeric order
            $hash eq $foo ? (sort {$b <=> $a} keys %$hash) :
          # Only dump the odd number keys of %$bar
            $hash eq $bar ? (grep {$_ % 2} keys %$hash) :
          # Sort keys in default order for all other hashes
            (sort keys %$hash)
        ];
    }

=head1 BUGS

Due to limitations of Perl subroutine call semantics, you cannot pass an
array or hash.  Prepend it with a C<\> to pass its reference instead.  This
will be remedied in time, now that Perl has subroutine prototypes.
For now, you need to use the extended usage form, and prepend the
name with a C<*> to output it as a hash or array.

C<Data::Dumper> cheats with CODE references.  If a code reference is
encountered in the structure being processed (and if you haven't set
the C<Deparse> flag), an anonymous subroutine that
contains the string '"DUMMY"' will be inserted in its place, and a warning
will be printed if C<Purity> is set.  You can C<eval> the result, but bear
in mind that the anonymous sub that gets created is just a placeholder.
Someday, perl will have a switch to cache-on-demand the string
representation of a compiled piece of code, I hope.  If you have prior
knowledge of all the code refs that your data structures are likely
to have, you can use the C<Seen> method to pre-seed the internal reference
table and make the dumped output point to them, instead.  See L<EXAMPLES>
above.

The C<Useqq> and C<Deparse> flags makes Dump() run slower, since the
XSUB implementation does not support them.

SCALAR objects have the weirdest looking C<bless> workaround.

Pure Perl version of C<Data::Dumper> escapes UTF-8 strings correctly
only in Perl 5.8.0 and later.

=head2 NOTE

Starting from Perl 5.8.1 different runs of Perl will have different
ordering of hash keys.  The change was done for greater security,
see L<perlsec/"Algorithmic Complexity Attacks">.  This means that
different runs of Perl will have different Data::Dumper outputs if
the data contains hashes.  If you need to have identical Data::Dumper
outputs from different runs of Perl, use the environment variable
PERL_HASH_SEED, see L<perlrun/PERL_HASH_SEED>.  Using this restores
the old (platform-specific) ordering: an even prettier solution might
be to use the C<Sortkeys> filter of Data::Dumper.

=head1 AUTHOR

Vogler Hartmut          it@guru.de

Copyright (c) 2006 All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 1.0  (2006/05/24)

=head1 SEE ALSO

perl(1)

=cut
