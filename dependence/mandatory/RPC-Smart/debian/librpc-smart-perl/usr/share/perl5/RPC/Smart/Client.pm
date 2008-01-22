package RPC::Smart::Client;
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

$VERSION = '1.0';

use 5.006_001;

use strict;
use vars qw(@ISA $AUTOLOAD);
use XML::Smart;
use Data::Dumper;
use IO::Socket;
use RPC::Smart

@ISA=qw(RPC::Smart);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   $self->{PeerAddr}='localhost' if (!defined($self->{PeerAddr}));
   $self->{PeerPort}='20203'     if (!defined($self->{PeerPort}));
   $self->{Proto}='tcp'          if (!defined($self->{Proto}));

   return($self);
}

sub Connect
{
   my $self=shift;

   return($self->{sock}=IO::Socket::INET->new(%{$self}));
}

sub Disconnect
{
   my $self=shift;

   delete($self->{sock});
}

sub Call
{
   my $self=shift;
   my $method=shift;
   my $XML=new XML::Smart();
   my $param;
   if (ref($_[0]) eq "HASH"){
      $param=$_[0];
   }
   else{
      $param=[@_];
   }
   $self->Connect() if (!defined($self->{sock}));
   return(undef) if (!$self->{sock});
   $XML->{root}{call}{method}=$method;
   $XML->{root}{call}{param}=$param;
   my $sock=$self->{sock};
   printf("%s",$XML->data);
   printf $sock ("%s",$XML->data);

   my $result='';
   while(my $l=<$sock>){
      $result.=$l;
      last if ($l=~m/<root\s[^\>]*\/\>/);
      last if ($l=~m/<\/root\>/);
   }
   $XML=undef;
   return(undef) if ($result eq "");
   eval {$XML=new XML::Smart($result);};
   if ($@ ne ""){
      return({exitcode=>1,result=>"protocol error: '$result'"});
   }
   $XML=$XML->{root};
   my $h=$XML->tree()->{'root'}->{'call'};
   if (ref($h) ne "HASH" || keys(%$h)<1){
      return({exitcode=>1,result=>"unexpected rpc xml result"});
   }
   my %f=%{RPC::Smart::HashPack($XML->tree()->{'root'}->{'call'})};
   return(\%f);
}

sub AUTOLOAD
{
   my $self=shift;

   my $program = $AUTOLOAD;
   $program =~ s/.*::rpc/rpc/;
   if (!($program=~m/^rpc/)){
      die("undefined method '$AUTOLOAD'");
   }
   return($self->Call($program,@_));
}




















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
