package kernel::Input::JsonObjectLoad;

use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;
use Fcntl 'SEEK_SET';
use File::Temp(qw(tempfile));


@ISA=qw(kernel::Universal);
   
sub new
{  
   my $type=shift;
   my $parent=shift;
   my $self=bless({@_},$type);

   $self->setParent($parent);
   return($self);
}


sub getIconName
{
   my $self=shift;
   return("none");
}





sub SetInput
{
   my $self=shift;
   my $app=$self->getParent()->getParent();
   my $file=shift;
  
   my $firstline;
   my $orgFilename=sprintf("%s",$file);
   my ($objectLoader)=$orgFilename=~m/\.([a-z]+).json$/i;

   msg(INFO,"SetInput in ".$self->Self());


   if ($objectLoader ne "" && ($orgFilename=~m/.json$/)){
      msg(INFO,"SetInput in ".$self->Self()." objectLoader=$objectLoader");
      my $loaderMethod="JsonObjectLoad_".$objectLoader;
      msg(INFO,"SetInput check loaderMethod $loaderMethod in $app");
      if ($app->can($loaderMethod)){
         msg(INFO,"SetInput method loaderMethod $loaderMethod found");
         my $buffer;
         sysseek($file,0,SEEK_SET);
         print msg(INFO,"JSON FullLoad document detected");
         my ($fh, $filename) = tempfile("tempXXXX",DIR=>'/tmp');
#         my $filename="/tmp/last.Input.".$$.".bin";
#         my $fh;
#         open($fh,">$filename");

         my $size;
         my $blk=1024;
         my $max=2048000;
         if ($app->IsMemberOf("admin")){
            $max=$max*10;
         }
         my ($w,$r);
         while($r=sysread($file,$buffer,$blk)){
            my $w=syswrite($fh,$buffer,$r);
            if ($r!=$w){
               $size=0;
               last;
            }
            else{
               $size+=$w;
               last if ($size>$max);
            }
         }
         close($fh);
         print msg(INFO,"tempfile = $filename");
         $self->{currentloaderMethod}=$loaderMethod;
         $self->{currentFilename}=$filename;
         $self->{currentOrgFilename}=$orgFilename;
         
      }

      return(1);
   }

   return(undef) if ($firstline eq "");
}

sub Process
{
   my $self=shift;
   my $app=$self->getParent()->getParent();

   my $loaderMethod=$self->{currentloaderMethod};
   print(msg(INFO,"loaderMethod Process handler in ".$self->Self()));
   $app->$loaderMethod($self->{currentFilename},$self->{currentOrgFilename});
}


# store the Callback - but do not use it.
sub SetCallback
{
   my $self=shift;
   my $callback=shift;

   $self->{Callback}=$callback;
}


   
1;
