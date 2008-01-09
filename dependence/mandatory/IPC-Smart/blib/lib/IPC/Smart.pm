package IPC::Smart;

use strict;
use Carp;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD );
use subs qw( IPC_CREAT IPC_EXCL IPC_RMID IPC_STAT IPC_PRIVATE
             GETVAL SETVAL GETALL SEM_UNDO LOCK_EX LOCK_SH LOCK_UN LOCK_NB );

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT    = qw( );
@EXPORT_OK = qw( IPC_CREAT IPC_EXCL IPC_RMID IPC_STATE IPC_PRIVATE
                 GETVAL SETVAL GETALL SEM_UNDO LOCK_EX LOCK_SH LOCK_UN 
                 LOCK_NB);
%EXPORT_TAGS = ( all    => [qw( IPC_CREAT IPC_EXCL IPC_RMID IPC_PRIVATE
                                LOCK_EX LOCK_SH LOCK_UN LOCK_NB )],
                 lock    => [qw( LOCK_EX LOCK_SH LOCK_UN LOCK_NB )],
                 'flock' => [qw( LOCK_EX LOCK_SH LOCK_UN LOCK_NB )],
               );
Exporter::export_ok_tags('all', 'lock', 'flock');                
	
$VERSION = '0.10.1';

sub new {
  my $class = shift;
  my $self = {};
  $class = ref $class || $class;
  bless $self, $class;

  my $args = $class->_rearrange_args([qw( size nolocking )], \@_);

  $self->_initialize($args) or return undef;

  $self;
}

sub _initialize {
  my $self = shift;
  my $args = shift;

  foreach(qw( nolocking )) {
    $args->{$_} = 1 if lc $args->{$_} eq 'yes';
    $args->{$_} = 0 if lc $args->{$_} eq 'no';
  }
  $args->{nolocking}=0 if (!defined($args->{nolocking}));
  $self->{size}        = $args->{size}  || 0;
  $self->{flags} = (IPC_CREAT|IPC_EXCL)|0600;
  $self->{share} = new_share(IPC_PRIVATE, $self->{size}, 
                             $self->{flags} ,$args->{nolocking})
    or return undef; 

  1;
}

sub _rearrange_args {
  my ($self, $names, $params) = @_;
  my (%hash, %names);

  return \%hash unless (@$params);

  unless ($params->[0] =~ /^-/) {
    croak "unexpected number of parameters" unless (@$names == @$params);
    $hash{ @$names } = @$params;
    return \%hash;
  }

  %names = map { $_ => 1 } @$names;

  while(@$params) {
    my $param = lc substr(shift @$params, 1);
    exists $names{ $param } or croak "unexpected parameter '-$param'";
    $hash{ $param } = shift @$params;
  }                                  

  return \%hash;
}      

sub store {
  my $self = shift;
 
  if (write_share($self->{share}, $_[0], length $_[0]) < 0) {
    croak "IPC::Smart store() error: $!";
  }
  1;
}

sub fetch { 
  my $self = shift;

  my $str = read_share( $self->{share} );
  defined $str or croak "IPC::Smart fetch() error: $!";
  $str;
}

sub lock {
  my $self = shift;

  my $response = smart_lock($self->{share}, shift());
  return undef if ($response == -1);
  return 0     if ($response == 1); # operation failed due to LOCK_NB 
  1;
}

sub unlock {
  my $self = shift;

  return undef if (smart_unlock($self->{share}) < 0);
  1;
}

# DEPRECATED -- Use lock() and unlock() instead.
sub shlock   { shift()->lock(@_) }
sub shunlock { shift()->unlock(@_) }

sub version { smart_version( shift()->{share} ) }

sub key       { shift()->{key} }
sub create    { shift()->{create} }
sub exclusive { shift()->{exclusive} }
sub flags     { shift()->{flags} }
sub mode      { shift()->{mode} }
sub size      { shift()->{size} }

sub watched {
  my $self = shift;

  my $count = smart_watched ( $self->{share} );
  return undef if $count < 0;
  $count;
}

sub num_segments {
  my $self = shift;

  my $count = smart_num_segments( $self->{share} );
  return undef if $count < 0;
  $count;
}

sub destroy {
  my $self = shift;

  return(@_ ? $self->{'destroy'} = shift : $self->{'destroy'});
}

sub DESTROY {
  my $self = shift;
  destroy_share( $self->{share}, 1 ) if $self->{share};
}

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Smart macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap IPC::Smart $VERSION;

1;

__END__

=head1 NAME

IPC::Smart - Shm interface to talk between parent and daughter processes

=head1 SYNOPSIS

  use IPC::Smart;

  $share = new IPC::Smart(-size=>100) or die $!;
  $share->store("This is stored in shared memory");
  $str = $share->fetch;
  if (fork()==0){
     # in the daughter
     $share->store("This is my verbose message");
  }
  sleep(1);
  printf("Message from process=%s\n",$share->fetch);

=head1 DESCRIPTION

IPC::Smart provides a very smart interface to shared memory, allowing
data to be efficiently communicated between processes.  It is derived
from the module IPC::ShareLite.

System must support SysV IPC (shared memory and semaphores) in order to 
use this module.

IPC::Smart provides an abstraction of the shared memory and
semaphore facilities of SysV IPC, allowing the storage of arbitrarily
large data; the module automatically acquires and removes shared memory
segments as needed.  Storage and retrieval of data is atomic, and
locking functions are provided for higher-level synchronization.

In many respects, this module is similar to IPC::Shareable.  However,
IPC::Smart does not provide a tied interface, does not 
(automatically) allow the storage of variables, and is written in C
for additional speed.

Construct an IPC::Smart object by calling its constructor:

	$share = new IPC::Smart( -size=> 1024) or die $!;

Once an instance has been created, data can be written to shared memory
by calling the store() method:

	$share->store("This is going in shared memory");

Retrieve the data by calling the fetch() method:

	$str = $share->fetch();

The store() and fetch() methods are atomic; any processes attempting
to read or write to the memory are blocked until these calls finish.
However, in certain situations, you'll want to perform multiple
operations atomically.  Advisory locking methods are available for 
this purpose.

An exclusive lock is obtained by calling the lock() method:

	$share->lock();

Happily, the lock() method also accepts all of the flags recognized
by the flock() system call.  So, for example, you can obtain a
shared lock like this:

	$share->lock( LOCK_SH );

Or, you can make either type of lock non-blocking:

	$share->lock( LOCK_EX|LOCK_NB );

Release the lock by calling the unlock() method:

	$share->unlock;

=head1 METHODS

=over 4

=item new($size)

This is the constructor for IPC::Smart.  It accepts both 
the positional and named parameter calling styles.

$size specifies the shared memory segment size, in bytes.
The default size is 65,536 bytes, which is fairly portable.  
Linux, as an example, supports segment sizes of 4 megabytes.

The constructor returns the undefined value on error.

=item store( $scalar )

This method stores $scalar into shared memory.  $scalar may be
arbitrarily long.  Shared memory segments are acquired and
released automatically as the data length changes.
The only limits on the amount of data are the system-wide
limits on shared memory pages (SHMALL) and segments (SHMMNI)
as compiled into the kernel. 

Note that unlike IPC::Shareable, this module does not automatically
allow variables to be stored.  Serializing all data is expensive, and
is not always necessary.  If you need to store a variable, you should
employ the Storable module yourself.  For example:

        use Storable qw( freeze thaw );
        ...
	$hash = { red => 1, white => 1, blue => 1 };
        $share->store( freeze( $hash ) );
        ...
        $hash = thaw( $share->fetch );

The method raises an exception on error.

=item fetch()

This method returns the data that was previously stored in
shared memory.  The empty string is returned if no data was
previously stored.

The method raises an exception on error.

=item lock( $type )

Obtains a lock on the shared memory.  $type specifies the type
of lock to acquire.  If $type is not specified, an exclusive
read/write lock is obtained.  Acceptable values for $type are
the same as for the flock() system call.  The method returns
true on success, and undef on error.  For non-blocking calls
(see below), the method returns 0 if it would have blocked.

Obtain an exclusive lock like this:
	
	$share->lock( LOCK_EX ); # same as default 

Only one process can hold an exclusive lock on the shared memory at
a given time.

Obtain a shared lock this this:

	$share->lock( LOCK_SH );

Multiple processes can hold a shared lock at a given time.  If a process
attempts to obtain an exclusive lock while one or more processes hold
shared locks, it will be blocked until they have all finished.

Either of the locks may be specified as non-blocking:

	$share->lock( LOCK_EX|LOCK_NB );
        $share->lock( LOCK_SH|LOCK_NB );
  
A non-blocking lock request will return 0 if it would have had to
wait to obtain the lock.    

Note that these locks are advisory (just like flock), meaning that
all cooperating processes must coordinate their accesses to shared memory
using these calls in order for locking to work.  See the flock() call for 
details.

Locks are inherited through forks, which means that two processes actually
can possess an exclusive lock at the same time.  Don't do that.

The constants LOCK_EX, LOCK_SH, LOCK_NB, and LOCK_UN are available
for import:

	use IPC::Smart qw( :lock );

Or, just use the flock constants available in the Fcntl module.

=item unlock()

Releases any locks.  This is actually equivalent to:

	$share->lock( LOCK_UN );

The method returns true on success and undef on error.

=back

=head1 PERFORMANCE

For a rough idea of the performance you can expect, here are some
benchmarks.  The tests were performed using the Benchmark module
on a Cyrix PR166+ running RedHat Linux 5.2 with the 2.0.36 kernel,
perl 5.005_02 using perl's malloc, and the default shared memory
segment size.  Each test was run 5000 times.

 	DATA SIZE (bytes)	TIME (seconds)	Op/Sec

 store	16384			2		2500
 fetch	16384			2		2500

 store	32768			3		1666	
 fetch	32768			3		1666	

 store	65536			6		833
 fetch	65536			5		1000	

 store	131072			12		416	
 fetch	131072			12		416	

 store	262144			28		178	
 fetch  262144			27		185	

 store	524288			63		79	
 fetch  524288			61		81	

Most of the time appears to be due to memory copying.  
Suggestions for speed improvements are welcome.

=head1 PORTABILITY

The module should compile on any system with SysV IPC and
an ANSI C compiler, and should compile cleanly with the
-pedantic and -Wall flags.

The module has been tested under Solaris, FreeBSD, and Linux.
Testing on other platforms is needed.  

If you encounter a compilation error due to the definition
of the semun union, edit the top of smart.c and undefine
the semun definition.  And then please tell me about it.

I've heard rumors that a SysV IPC interface has been 
constructed for Win32 systems.  Support for it may be
added to this module.

IPC::Smart does not understand the shared memory
data format used by IPC::Shareable.  

=head1 AUTHOR

Copyright 1998-2002, Maurice Aubrey E<lt>maurice@hevanet.comE<gt>. 
All rights reserved.

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself. 

=head1 CREDITS

Special thanks to Benjamin Sugars for developing the IPC::Shareable
module.

See the Changes file for other contributors.

=head1 SEE ALSO

L<IPC::Shareable>, ipc(2), shmget(2), semget(2), perl.

=cut
