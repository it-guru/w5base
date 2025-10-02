package kernel::Input;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
#
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
   $self->{InpFormat}=[icon_xls=>'XlsV01',icon_xml=>'XMLV01'];

   my $instdir=$parent->Config->Param("INSTDIR");
   my $handlerdir=$instdir."/lib/kernel/Input";
   if (opendir(DH,$handlerdir)){
      my @mods=grep({ -f "$handlerdir/$_" &&
                      $_=~m/\.pm$/ &&
                      !($_=~m/^\./) } readdir(DH));
      @mods=map({$_=~s/\.pm$//;$_} @mods);
      $self->{InpFormat}=[];

      foreach my $f (@mods){
         my $o;
         my $ico;
         eval("use kernel::Input::$f;".
              "\$o=new kernel::Input::$f(\$parent,{});".
              "\$ico=\$o->getIconName();");
         if ($@ ne ""){
            msg(ERROR,"can't use module '%s'","kernel::Input::".$f);
            printf STDERR ("%s\n",$@);
            next;
         }
         if (!defined($o)){
            msg(ERROR,"can't $o create object of '%s'","kernel::Input::".$f);
            next;
         }
         push(@{$self->{InpFormat}},$ico=>$f);
      }
      closedir(DH);
   }

   $self->{debug}=0 if (!defined($self->{debug}));
   return($self);
}

sub SetInput
{
   my $self=shift;
   my $input=shift;


   $self->{IN}=$input if (ref($input) eq "Fh" || 
                          ref($input) eq "CGI::File::Temp");
   $self->{FORMAT}=undef;
   return(undef);
}


sub isFormatUseable
{
   my $self=shift;

   msg(INFO,"isFormatUseable");
   if (ref($self->{IN}) eq "Fh" || 
       ref($self->{IN}) eq "CGI::File::Temp"){
      my @formats=@{$self->{InpFormat}};
      msg(INFO,"Checking formats");
      while(my $ico=shift(@formats)){
         my $f=shift(@formats);
         msg(INFO,"Checking format $f");
         my $o;
         $f=~s/[^a-z0-9:_]//gi;
         eval("use kernel::Input::$f;".
              "\$o=new kernel::Input::$f(\$self,debug=>\$self->{debug});");
         if ($@ eq ""){
            sysseek($self->{IN},0,SEEK_SET);
            seek($self->{IN},0,0);
            if ($o->SetInput($self->{IN})){
               $self->{FORMAT}=$o;
               return(1);
            }
         }
         else{
            my $msg=$@;
            msg(ERROR,"object kernel::Input::$f not useable\n$msg");
         }
      }
   }
   else{
      msg(ERROR,"no filehandle in '$self->{IN}'\n");
   }
   return(undef);
}


sub SetCallback
{
   my $self=shift;
   my $callback=shift;

   return(undef) if (!defined($self->{FORMAT}));
   return($self->{FORMAT}->SetCallback($callback));

}
sub Process
{
   my $self=shift;

   return(undef) if (!defined($self->{FORMAT}));
   return($self->{FORMAT}->Process());

}



1;

