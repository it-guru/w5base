package W5Kernel;
use Exporter;
use Encode;
use strict;
use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(
             &trim &rtrim &ltrim &limitlen &in_array &array_insert
             &first_index &base36
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
   my $u="";
   foreach my $linemsg (split(/\n/,$msg)){
      $d.=sprintf("%-6s %s%s\n",$type.":",$linemsg,$u);
   }
   if (($W5V2::OperationContext eq "W5Server" ||
        $W5V2::OperationContext eq "W5Replicate") && $type eq "INFO"){
      if ($W5V2::Debug==0){
         if ( -t STDOUT ){
            print $d;  # ich denke, das ist besser
         }
      }
      else{
         my $dout=$d;
         if ($ENV{REMOTE_USER} ne ""){
            $dout=~s/\n/ ($ENV{REMOTE_USER})\n/g;
         }
         print STDERR $dout;
      }
   }
   else{
      my $dout=$d;
      if ($ENV{REMOTE_USER} ne ""){
         $dout=~s/\n/ ($ENV{REMOTE_USER})\n/g;
      }
      print STDERR $dout;
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


sub base36
{
  my ($val) = @_;
  my $symbols=join('','0'..'9','A'..'Z');
  my $b36='';
  while($val){
    $b36=substr($symbols,$val % 36,1).$b36;
    $val=int($val/36);
  }
  return($b36||'0');
}




sub ltrim
{
  return(undef) if (!defined($_[0]));
  if (ref($_[0]) eq "SCALAR"){
     return(undef) if (!defined(${$_[0]}));
     ${$_[0]}=~s/[\s\xa0]*$//;
     return(${$_[0]});
  }
  $_[0]=~s/^[\s\xa0]*//;
  return($_[0]);
}

sub rtrim
{
  return(undef) if (!defined($_[0]));
  if (ref($_[0]) eq "SCALAR"){
     return(undef) if (!defined(${$_[0]}));
     ${$_[0]}=~s/[\s\xa0]*$//;
     return(${$_[0]});
  }
  $_[0]=~s/[\s\xa0]*$//;
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
      if (my ($newlang)=$blk=~m/^\[([a-z]+):\]\s*$/){
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
   if (ref($search_for) eq "ARRAY" && ref($search_for->[0]) eq "HASH"){
      # search in array of hashes ($search_for must be array of hashes)
      my $found=0;
      foreach my $chkrec (@$arr){
         if (ref($chkrec) eq "HASH"){
            foreach my $matchrec (@{$search_for}){
               foreach my $mkey (keys(%$matchrec)){
                  next if (!exists($chkrec->{$mkey}));
                  if (ref($matchrec->{$mkey}) eq "SCALAR"){
                     if (${$matchrec->{$mkey}} eq $chkrec->{$mkey}){
                        $found++;
                     }
                  }
               }
            }
         }
      }
      return($found);
   }
   else{
      my %items;
      map({$items{$_}++} @$arr); # create a hash out of the array values
      if (ref($search_for) eq "ARRAY"){
         foreach my $search_for_loop (@$search_for){
            return(1) if (exists($items{$search_for_loop}));
         }
         return(0);
      }
      return(exists($items{$search_for})?1:0);
   }
   return(0);
}

sub array_insert
{
   my ($arr,$ankerPos,$ins,$rel)=@_;

   $rel="AfterOrEnd" if ($rel eq "");

   if ($rel eq "AfterOrEnd"){
      my $inserti=$#{$arr};
      for(my $c=0;$c<=$#{$arr};$c++){
         $inserti=$c+1 if ($arr->[$c] eq $ankerPos);
      }
      my @temparr=@$arr;
      splice(@$arr,
             $inserti,
             $#{$arr}-$inserti,($ins,@temparr[$inserti..($#{$arr})]));
   }
}


sub first_index
{
    my $f = shift;

    foreach my $i (0 .. $#_)
    {
        local *_ = \$_[$i];
        if (ref($f)){
           return($i) if $f->();
        }
        else{
           return($i) if ($_ eq $f);
        }
    }
    return(-1);
}















1;
