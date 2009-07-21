package W5Kernel;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
             &trim &rtrim &ltrim
             &msg &ERROR &WARN &DEBUG &INFO &OK
             );

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
   return("") if ($type eq "DEBUG" && $W5V2::Debug==0);
   my $d;
   foreach my $linemsg (split(/\n/,$msg)){
      $d.=sprintf("%-6s %s\n",$type.":",$linemsg);
   }
   print STDERR $d;
   return($d);
}




sub ltrim
{
  return(undef) if (!defined($_[0]));
  if (ref($_[0]) eq "SCALAR"){
     return(undef) if (!defined(${$_[0]}));
     ${$_[0]}=~s/\s*$//;
     return(${$_[0]});
  }
  $_[0]=~s/^\s*//;
  return($_[0]);
}

sub rtrim
{
  return(undef) if (!defined($_[0]));
  if (ref($_[0]) eq "SCALAR"){
     return(undef) if (!defined(${$_[0]}));
     ${$_[0]}=~s/\s*$//;
     return(${$_[0]});
  }
  $_[0]=~s/\s*$//;
  return($_[0]);
}

sub trim
{
  return(undef) if (!defined($_[0]));
  ltrim($_[0]);
  rtrim($_[0]);
  if (ref($_[0])){
     return(${$_[0]});
  }
  return($_[0]);
}




1;
