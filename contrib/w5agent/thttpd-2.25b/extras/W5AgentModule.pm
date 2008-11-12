# This is the w5agent kernel
package W5AgentModule;
use Data::Dumper;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(&Dumper &ERROR &OK &WARN &DEBUG &INFO &msg &hash2xml &XmlQuote);


sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);

   return($self);
}

sub Startup
{
   my ($self)=@_;
   sleep(5);
   return(1);
}

sub ReConfigure
{
   my ($self)=@_;
   return(1);
}

sub Main
{
   my ($self)=@_;
   return(1);
}

sub MainLoop
{
   my ($self)=@_;
   while(1){
      sleep(1);
      $self->Main();
   }
   return(1);
}

sub Shutdown
{
   my ($self)=@_;
   return(1);
}

sub Dumper { 
   $Data::Dumper::Terse=0;
   $Data::Dumper::Indent=1;
   if (!ref($_[0])){
      $Data::Dumper::Varname=shift;
      $Data::Dumper::Terse=1;
      return('$'.$Data::Dumper::Varname.'='.Data::Dumper::Dumper(@_));
   }
   return(Data::Dumper::Dumper(@_)); 
}

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
   return("") if ($type eq "DEBUG" && !($w5agent::config{DEBUG}));
   my $d;
   foreach my $linemsg (split(/\n/,$msg)){
      $d.=sprintf("%-6s %s\n",$type.":",$linemsg);
   }
   if ($type eq ERROR || $type eq DEBUG || $type eq WARN){
      print STDERR $d;
   }
   return($d);
}


########################################################################
# hash2xml
sub unHtml
{
   my $d=shift;
   $d=~s/<br>/\n/g;

   return($d);
}

sub XmlQuote
{
   my $org=shift;
   $org=unHtml($org);
   $org=~s/&/&amp;/g;
   $org=~s/</&lt;/g;
   $org=~s/>/&gt;/g;
   utf8::encode($org);
   return($org);
}

sub hash2xml {
  my ($request,$param,$parentKey,$depth) = @_;
  my $xml="";
  $param={} if (!defined($param) || ref($param) ne "HASH");
  $depth=0 if (!defined($depth));

  sub indent
  {
     my $n=shift;
     my $i="";
     for(my $c=0;$c<$n;$c++){
        $i.=" ";
     }
     return($i);
  }
  return($xml) if (!ref($request));
  if (ref($request) eq "HASH"){
     foreach my $k (keys(%{$request})){
        if (ref($request->{$k}) eq "HASH"){
           $xml.=indent($depth).
                 "<$k>\n".hash2xml($request->{$k},$param,$k,$depth+1).
                 indent($depth)."</$k>\n";
        }
        elsif (ref($request->{$k}) eq "ARRAY"){
           foreach my $subrec (@{$request->{$k}}){
              if (ref($subrec)){
                 $xml.=indent($depth).
                       "<$k>\n".hash2xml($subrec,$param,$k,$depth+1).
                       indent($depth)."</$k>\n";
              }
              else{
                 $xml.=indent($depth)."<$k>".XmlQuote($subrec)."</$k>\n";
              }
           }
        }
        else{
           my $d=$request->{$k};
           if (!($d=~m#^<subrecord>#m)){  # prevent double quoting
              $d=XmlQuote($d);
           }
           else{
              $d="\n".join(">\n",map({indent($depth).$_} split(">\n",$d))).
                      ">\n";
           }
           $xml.=indent($depth)."<$k>".$d."</$k>\n";
        }
     }
  }
  if (ref($request) eq "ARRAY"){
     foreach my $d (@{$request}){
        if (ref($d)){
           $xml.=hash2xml($d,$param,$parentKey,$depth+1);;
        }
        else{
           if (!($d=~m#^<subrecord>#m)){  # prevent double quoting
              $d=XmlQuote($d);
           }
           else{
              $d="\n".join(">\n",map({indent($depth).$_} split(">\n",$d))).
                      ">\n";
           }
           $xml.=indent($depth)."<$parentKey>".$d."</$parentKey>\n";
        }
     }
  }
  if ($depth==0 && $param->{header}==1){
     my $encoding="UTF-8";
     $xml="<?xml version=\"1.0\" encoding=\"$encoding\" ?>\n\n".$xml;
  }
  return $xml;
}





1;
