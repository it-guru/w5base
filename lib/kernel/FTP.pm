package kernel::FTP;
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
use Net::FTP;
use Data::Dumper;
use kernel;
use kernel::App;
@ISA    = qw(kernel::App Net::FTP);


sub new
{
   my $type=shift;
   my $self={name=>$_[1],Config=>$_[0]->Config()};

   $self=bless($self,$type);
   $self->setParent($_[0]);
 
   return($self);
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

   foreach my $v (qw(user pass serv)){
      if (ref($p{$v}) ne "HASH" || !defined($p{$v}->{$name})){
         return(undef,
                msg(ERROR,"Connect(%s): essential information '%s' missing",
                    $name,$v));
      }
      $self->{$v}=$p{$v}->{$name};
   }
   $self->{base}=$p{base}->{$name};
   my %param=(Passive=>1);
   #$param{Debug}=1 if ($W5V2::Debug==1);
   $self->{ftp}=Net::FTP->new($self->{serv},%param);
   if (defined($self->{ftp})){
      if (!($self->{ftp}->login($self->{user},$self->{pass}))){
         return(undef);
      }
      if (defined($self->{base}) && $self->{base} ne ""){
         if (!$self->{ftp}->cwd($self->{base})){
            return(undef,
                msg(ERROR,"FTP:$name can't change dir to '%s'",$self->{base}));
         }
      }
   }
   return(1) if (defined($self->{ftp}));
   return(undef);
}

sub Put
{
   my $self=shift;
   my $local=shift;
   my $remote=shift;
   return($self->{ftp}->put($local,$remote));
}

sub Get
{
   my $self=shift;
   my $remote=shift;
   my $local=shift;
   return($self->{ftp}->get($remote,$local));
}

sub Cd
{
   my $self=shift;
   my $remote=shift;
   $self->{ftp}->cwd($remote);
}

sub Dir
{
   my $self=shift;
   my $remote=shift;
   $self->{ftp}->dir($remote);
}

sub Disconnect
{
   my $self=shift;
   $self->{ftp}->quit();
}



1;
