package W5Kernel;
use Exporter;
use Encode;
@ISA = qw(Exporter);
@EXPORT = qw(
             &trim &rtrim &ltrim &in_array
             &msg &ERROR &WARN &DEBUG &INFO &OK &UTF8toLatin1
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
  if (my $reft=ref($_[0])){
     if ($reft eq "HASH"){
        foreach my $k (keys(%{$_[0]})){
           $_[0]->{$k}=trim($_[0]->{$k});
        }
        return($_[0]);
     }
  }
  ltrim($_[0]);
  rtrim($_[0]);
  if (ref($_[0])){
     return(${$_[0]});
  }
  return($_[0]);
}

sub UTF8toLatin1
{
   my $dd=shift;
   if ($dd=~m/\xC3/){
      utf8::decode($dd);
   }
   if (utf8::is_utf8($dd)){
      utf8::downgrade($dd,1);
      $dd=~s/\x{201e}/"/g;
      $dd=~s/\x{2022}/*/g;
      $dd=~s/\x{2013}/|/g;
      eval('decode_utf8($dd,0);$dd=encode("iso-8859-1", $dd);');
      if ($@ ne ""){ # now i need to be harder!
         $dd=~s/[^[:ascii:]äöüßÄÖÜ]/?/g;
      }
   }
   return($dd);
}

sub in_array
{
   my ($arr,$search_for) = @_;
   my %items = map {$_ => 1} @$arr; # create a hash out of the array values
   if (ref($search_for) eq "ARRAY"){
      foreach my $search_for_loop (@$search_for){
         return(1) if (exists($items{$search_for_loop}));
      }
      return(0);
   }
   return (exists($items{$search_for}))?1:0;
}






1;
