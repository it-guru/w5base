package kernel::FileTransfer;
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
#
use strict;
use vars qw(@ISA);
use kernel;
use kernel::App;
@ISA    = qw(kernel::App);


sub new
{
   my $type=shift;
   my $self={name=>$_[1],Config=>$_[0]->Config()};

   $self->{evalmode}=0;
   if (defined($_[2]) && $_[2] eq "1"){
      $self->{evalmode}=1;   # any errors are dont break application
   }

   $self=bless($self,$type);
   $self->setParent($_[0]);
 
   return($self);
}

sub errno    ## last error number  (in evalmode)
{
   my $self=shift;

}

sub errstr  ## last error string  (in evalmode)
{
   my $self=shift;

   return($self->{errstr});
}

sub Connect
{
   my $self=shift;
   my %p;
   my $name=$self->{name};

   $p{user}=$self->Config->Param('DATAOBJUSER');
   $p{pass}=$self->Config->Param('DATAOBJPASS');
   $p{serv}=$self->Config->Param('DATAOBJSERV');
   $p{base}=$self->Config->Param('DATAOBJBASE');

   foreach my $v (qw(serv user pass)){
      if ($v eq "serv"){ #since sftp mode, only serv is generel mandatory
         if (ref($p{$v}) ne "HASH" || !defined($p{$v}->{$name})){
            if ($self->{evalmode}){
               $self->{errno}=1;
               $self->{errstr}=sprintf("Connect(%s): ".
                                       "essential information '%s' missing",
                                       $name,$v);
               return(undef);
            }
            return(undef,
                   msg(ERROR,"Connect(%s): essential information '%s' missing",
                       $name,$v));
         }
      }
      $self->{$v}=$p{$v}->{$name};
   }
   $self->{base}=$p{base}->{$name};

   if ($self->{serv}=~m#^ftp://#){
      $self->{mode}="ftp";
      $self->{serv}=~s#^ftp://##;
   }
   elsif($self->{serv}=~m#^sftp://#){
      $self->{mode}="sftp";
      $self->{serv}=~s#^sftp://##;
   }
   elsif($self->{serv}=~m#^scp://#){
      $self->{mode}="scp";
      $self->{serv}=~s#^scp://##;
   }
   else{
      $self->{mode}="ftp";
   }

   $self->{initdir}=undef;
   if ($self->{serv}=~m/\//){
      $self->{initdir}=$self->{serv};
      $self->{initdir}=~s/^[^\/]+//;
      $self->{serv}=~s/\/.*$//;
   }
   

   if ($self->{mode} eq "sftp"){
      my $comObj;
      my %param=(host=>$self->{serv});
      if ($self->{user} ne ""){
         $param{user}=$self->{user};
      }
      eval('
         use Net::SFTP::Foreign;
         $comObj=do{
            local $SIG{TERM} = "IGNORE";
            local $SIG{PIPE} = "IGNORE";
            Net::SFTP::Foreign->new(%param);
         };
      ');
      if (!defined($comObj) || $@ ne ""){
         msg(ERROR,"fail to Connect communication Endpoint for $self->{mode} ".
                   "on $name");
         return(undef);
      }
      $self->{$self->{mode}}=$comObj;
      if (defined($self->{initdir})){
         $self->Cd($self->{initdir});
      }
      return(1);

   }
   if ($self->{mode} eq "ftp"){
      my %param=(Passive=>1);
      #$param{Debug}=1 if ($W5V2::Debug==1);
      my $comObj;
      eval('
         use Net::FTP;
         $comObj=Net::FTP->new($self->{serv},%param);
      ');
      if (!defined($comObj) || $@ ne ""){
         msg(ERROR,"fail to Connect communication Endpoint for $self->{mode} ".
                   "on $name");
         return(undef);
      }

      $self->{$self->{mode}}=$comObj;
      if (defined($self->{$self->{mode}})){
         if (!($self->{$self->{mode}}->login($self->{user},$self->{pass}))){
            return(undef);
         }
         if (defined($self->{base}) && $self->{base} ne ""){
            if (!$self->{$self->{mode}}->cwd($self->{base})){
               return(undef,
                   msg(ERROR,
                       "FTP:$name can't change dir to '%s'",$self->{base}));
            }
         }
      }
      if (defined($self->{initdir})){
         $self->Cd($self->{initdir});
      }
      return(1) if (defined($self->{$self->{mode}}));
   }


   return(undef);
}

sub Put
{
   my $self=shift;
   my $local=shift;
   my $remote=shift;
   if (! -f ($local)){
      msg(ERROR,"file $local does not exists");
      return(undef);
   }
   if ($self->{mode} eq "sftp"){
      my $s=$self->{$self->{mode}}->put($local,$remote);
      if (!defined($s)){
         $self->{errstr}=$self->{$self->{mode}}->error;
         if ($self->{evalmode}){
            return(undef);
         }
         msg(ERROR,$self->errstr());
         return(undef);
      } 
      return(1);
   }
   elsif ($self->{mode} eq "ftp"){
      return($self->{$self->{mode}}->put($local,$remote));
   }
   else{
      $self->{errstr}="missing connect call or invalid protocol";
      if ($self->{evalmode}){
         return(undef);
      }
      msg(ERROR,$self->errstr());
      return(undef);
   }
   return(undef);
}

sub Get
{
   my $self=shift;
   my $remote=shift;
   my $local=shift;
   if ($self->{mode} eq "sftp"){
      my $s=$self->{$self->{mode}}->get($remote,$local);
      if (!defined($s)){
         $self->{errstr}=$self->{$self->{mode}}->error;
         if ($self->{evalmode}){
            return(undef);
         }
         msg(ERROR,$self->errstr());
         return(undef);
      } 
      return(1);
   }
   elsif ($self->{mode} eq "ftp"){
      return($self->{$self->{mode}}->get($remote,$local));
   }
   else{
      $self->{errstr}="missing connect call or invalid protocol";
      if ($self->{evalmode}){
         return(undef);
      }
      msg(ERROR,$self->errstr());
      return(undef);
   }
   return(undef);
}

sub Cd
{
   my $self=shift;
   my $remote=shift;
   if ($self->{mode} eq "ftp"){
      return($self->{$self->{mode}}->cwd($remote));
   }
   if ($self->{mode} eq "sftp"){
      return($self->{$self->{mode}}->setcwd($remote));
   }
   return(undef);
}

sub Exists
{
   my $self=shift;
   my $remote=shift;  # entry

   if ($self->{mode} eq "ftp"){
      my $ls=$self->{$self->{mode}}->ls($remote);
      if (!defined($ls) ||
          (ref($ls) eq "ARRAY" && $#{$ls}==-1)){
         return(0);
      }
      return(1);
   }
   if ($self->{mode} eq "sftp"){
      my $s=$self->{$self->{mode}}->stat($remote);
      if (!defined($s)){
         return(0);
      }
      return(1);
   }
   return(undef);
}

sub Ls
{
   my $self=shift;
   my $remote=shift;  # entry

   if ($self->{mode} eq "ftp"){
      $self->{$self->{mode}}->ls($remote);
   }
}

sub Disconnect
{
   my $self=shift;
   if ($self->{mode} eq "ftp"){
      $self->{$self->{mode}}->quit();
      return(1);
   }
   if ($self->{mode} eq "sftp"){
      $self->{$self->{mode}}->disconnect();
      return(1);
   }
   return(undef);
}



1;
