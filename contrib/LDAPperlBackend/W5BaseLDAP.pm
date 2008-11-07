package W5BaseLDAP;
use Data::Dumper;
sub new
{
        my $class = shift;
        my $this = {};
        bless $this, $class;
        print STDERR "Posix Var " . BUFSIZ . " and " . FILENAME_MAX . "\n";
    #    eval('use Data::Dumper;');
    #    printf STDERR ("fifi err=%s\n",$@);
        return $this;
}

sub bind
{
   my $self=shift;
   
   print STDERR "Here in bind self=$self\n";
   return 0;
}
sub unbind
{
        print STDERR "Here in unbind\n";
        return 0;
}
sub config
{
        print STDERR "Here in config\n";
        return 0;
}
sub init
{
        print STDERR "Here in init\n";
        return 0;
}
1;
