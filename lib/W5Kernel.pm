package W5Kernel;
use Exporter;
use Encode;
use strict;
use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(
             &trim &rtrim &ltrim &limitlen &in_array 
             &extractLanguageBlock
             &msg &sysmsg &ERROR &WARN &DEBUG &INFO &OK &UTF8toLatin1
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
   if ($W5V2::OperationContext eq "W5Server" && $type eq "INFO"){
      if ($W5V2::Debug==0){
         print $d;
      }
      else{
         print STDERR $d;
      }
   }
   else{
      print STDERR $d;
   }
   return($d);
}

sub sysmsg
{
   my $type=shift;
   my $msg=shift;
   $msg=~s/%/%%/g if ($#_==-1);
   $msg=sprintf($msg,@_);
   return("") if ($type eq "DEBUG" && $W5V2::Debug==0);

   my $priority;
   $priority="info"    if ($type eq "INFO");
   $priority="err"     if ($type eq "ERROR");
   $priority="warning" if ($type eq "WARN");
   $priority="debug"   if ($type eq "DEBUG");
   if (defined($priority)){
      eval('use Sys::Syslog(qw(openlog syslog closelog));
            openlog("W5Base","pid,cons,nowait","user");
            syslog($priority,$msg);
            closelog();');
   }
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

sub extractLanguageBlock
{
   my $d=shift;
   my $lang=shift;

   my %sets=();
   my $curlang="";
   if (ref($d) eq "ARRAY"){
      $d=join("\n",@$d);
   }
   foreach my $blk (split(/(\[[a-z]{1,3}:\]\s*\n)/,$d)){
      $blk=trim($blk);
      if (my ($newlang)=$blk=~m/^\[([a-z]+):\]$/){
         $curlang=$newlang;
      } 
      else{
         $sets{$curlang}.="\n" if ($sets{$curlang} ne "");
         $sets{$curlang}.=trim($blk);
      }
   }
   if (exists($sets{$lang})){
      return($sets{$lang});
   }
   elsif (exists($sets{''})){
      return($sets{''});
   }
   return($sets{'en'});
}

sub limitlen
{
   my $d=shift;
   my $maxlen=shift;
   my $usesoftbreak=shift;
   if (!defined($maxlen)){
      printf STDERR ("ERROR: invalid call to W5Kernel::limitlen\n");
      exit(-1);
   }
   $usesoftbreak=0 if (!defined($usesoftbreak));

   if (length($d)>$maxlen){
      if ($usesoftbreak){
         my $m=$maxlen-3;
         $m=0 if ($m<0);
         $d=substr($d,0,$m)."...";
         $d=substr($d,0,$maxlen);
      }
      else{
         $d=substr($d,0,$maxlen);
      }
   }
   return($d);

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
   $arr=[$arr] if (ref($arr) ne "ARRAY");
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
