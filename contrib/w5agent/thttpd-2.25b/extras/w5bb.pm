package w5bb;
use strict;
use W5AgentModule;
use POSIX;
use Date::Calc;
use vars qw(@ISA);
@ISA=qw(W5AgentModule);

my %Month=('jan'=> 1,'feb'=> 2,'mar'=> 3,'apr'=> 4,'may'=> 5,'jun'=> 6,
           'jul'=> 7,'aug'=> 8,'sep'=> 9,'oct'=>10,'nov'=>11,'dec'=>12);
       

sub new
{  
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{spool}=$w5agent::config{W5BBDIR}."/spool";
   $self->{db}=$w5agent::config{W5BBDIR}."/db";
   $self->{reject}=$w5agent::config{W5BBDIR}."/reject";
   if (!-d $self->{db}){
      mkdir($self->{db});
   }
   if (!-d $self->{reject}){
      mkdir($self->{reject});
   }

   return($self);
}

sub Main
{
   my $self=shift;

   #msg(DEBUG,"in Main of $self");
   foreach my $file ($self->loadMsgList()){
      $self->processMsg($file);
   }
}

sub processMsg
{
   my $self=shift;
   my $filename=shift;
   local *F;

   if (-f $filename){
      my $oldname=$filename;
      $oldname=~s/\.txt/.old/i;
      if (open(F,"<$filename")){
         while(my $line=$self->readLine(\*F)){
         #   msg(DEBUG,"line=$line");
            if ($line=~m/^combo\s*$/){
               msg(DEBUG,"BBMSG:combo mode active");
            }
            if (my ($BBMSG,$host,$msgtype,$color,$shortdesc)=
                $line=~m/^(page|status)\s+(\S+)\.(\S+)\s+(\S+)\s+(.*)$/){
               $host=~s/,/\./g; 
               my %BBMSG=(msg=>$BBMSG,
                          msgtype=>$msgtype,
                          src=>$oldname,
                          color=>$color,
                          host=>$host,
                          shortdescription=>$shortdesc);
               if ($self->ValidateMessage(\%BBMSG)){
                  $self->StoreMessage(\%BBMSG,\*F);
               }
            }
            if (my ($BBMSG,$host,$msgtype)=
                $line=~m/^(notes|data)\s+(\S+)\.(\S+)\s+(.*)$/){
               $host=~s/,/\./g; 
               my %BBMSG=(msg=>$BBMSG,
                          msgtype=>$msgtype,
                          src=>$oldname,
                          host=>$host);
               if ($self->ValidateMessage(\%BBMSG)){
                  $self->StoreMessage(\%BBMSG,\*F);
               }
            }
         }
         close(F);
         msg(DEBUG,"file $filename processed");
      }
      else{
         msg(ERROR,"open $filename : $!");
      }
      my $oldname=$filename;
      $oldname=~s/\.txt/.old/i;
      rename($filename,$oldname);
   }
}

sub readLine
{
   my $self=shift;
   local *F=shift;
   my $line=<F>;
   return($line);
}

sub read2whiteLine
{
   my $self=shift;
   local *F=shift;
   my $line=<F>;
   return(undef) if ($line=~m/^\s*$/);
   return($line);
}


sub ValidateMessage
{
   my $self=shift;
   my $msg=shift;

   if (!defined($msg->{date}) && defined($msg->{shortdescription})){
      if (my ($sendstring,$wday,$mon,$day,$h,$m,$s,$tz,$y,$rest)=
          $msg->{shortdescription}=~
 m/^((\S+)\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\S+)\s+(\d{2,4}))\s+(.*)$/){
         msg(DEBUG,"sendstring=%s",$sendstring);
         if (my $d=$self->interpreteDate($mon,$day,$h,$m,$s,$tz,$y)){
            $msg->{time}=$d;
            $msg->{time}->{sendstring}=$sendstring;
         }
         else{
            msg(DEBUG,"invalid date format");
            return(0);
         }
         $msg->{shortdescription}=$rest;
      }
   }
   my @path=split(/\./,$msg->{host});
   return(0) if ($#path<=1);
   if ($msg->{msg} eq "status" ||
       $msg->{msg} eq "notes"  ||
       $msg->{msg} eq "page"   ||
       $msg->{msg} eq "data"){
      $msg->{storedir}=join("/",reverse(@path)).'/'.$msg->{msg};
   }
   else{
      return(0);
   }
   msg(DEBUG,"%s",Dumper("msg",$msg));
   return(1);
}

sub interpreteDate
{
   my $self=shift;
   my ($mon,$day,$h,$m,$s,$tz,$y)=@_;
   if (!($mon=~/^\d+$/)){
      $mon=$Month{lc($mon)};
   }
   return(undef) if (!defined($mon) || $mon<1 || $mon>12);
   return(undef) if (!defined($h) || $h<0 || $h>23);
   return(undef) if (!defined($m) || $m<0 || $m>59);
   return(undef) if (!defined($s) || $s<0 || $s>59);
   return(undef) if (!defined($day) || $day<1 || $day>31);
   ############################# Timezone converion ########################
   $y-=1900;
   $mon--;
   my $oldtz=$ENV{TZ};
   if ($tz ne ""){
      $ENV{TZ}=$tz;
      POSIX::tzset();
   }
   my $time_t;
   $time_t=POSIX::mktime($s,$m,$h,$day,$mon,$y);
   #$time_t=Date::Calc::Mktime($y,$mon,$day,$h,$m,$s);
   $ENV{TZ}=$oldtz;
   POSIX::tzset();
   #########################################################################
   my $normt={};
   $normt->{utc}=scalar(localtime($time_t));
   $normt->{time_t}=$time_t;
   return($normt);
}

sub StoreMessage
{
   my $self=shift;
   my $msg=shift;
   my $FRAW=shift;
   local *FOUT;

   my $dir="/state/".$msg->{storedir};
   msg(DEBUG,"store message at %s",$dir);
   if (! -d $self->{db}.$dir){
      my $tp;
      foreach my $d (split(/\//,$dir)){
         $tp.=$d;
         mkdir($self->{db}.$tp) if (! -d $self->{db}.$tp);
         msg(DEBUG,"mkdir %s",$self->{db}.$tp);
         $tp.="/";
      }
   }
   if ($msg->{msg} eq "status" ||
       $msg->{msg} eq "page"   ||
       $msg->{msg} eq "notes"){
      if (open(FOUT,">".$self->{db}.$dir."/".$msg->{msgtype}.".xml")){
         print FOUT hash2xml({},{header=>1});
         print FOUT "<root>";
         print FOUT hash2xml({head=>$msg},{header=>0});      
         print FOUT "<body>";
         msg(DEBUG,"start transfer of body");
         my $line;
         my $lineno;
         while($line=$self->readLine($FRAW)){
            last if (!($line=~m/^\s*$/));
         }
         if ($line ne ""){
            $lineno++;
            print FOUT XmlQuote($line);
            while($line=$self->read2whiteLine($FRAW)){
               $lineno++;
               msg(DEBUG,"transfer line $lineno");
               print FOUT XmlQuote($line);
            }
         }
         msg(DEBUG,"end transfer of body");
         print FOUT "</body>";
         print FOUT "</root>";
         close(FOUT);
      }
   }
   msg(DEBUG,"store message finished");
}


sub loadMsgList
{
   my $self=shift;

   my @flist;

   if (-d $self->{spool}){
      #msg(DEBUG,"spool OK");
      if (opendir(D,$self->{spool})){
         foreach my $msg (sort(grep { !/^\./ } grep { /\.txt$/ } readdir(D))){
            push(@flist,$self->{spool}."/".$msg);
         }
      }
   }
   else{
      msg(ERROR,"can not access spool directory '%s'",$self->{spool});
   }
   return(@flist);
}

