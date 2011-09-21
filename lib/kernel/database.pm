package kernel::database;
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
use DBI;
use vars qw(@ISA);
use strict;
use kernel;
use Scalar::Util qw(weaken);
use kernel::Universal;

@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my $parent=shift;
   my $name=shift;
   my $self=bless({},$type);

   $self->setParent($parent);
   
   $self->{dbname}=$name;
   $self->{isConnected}=0;
   

   return($self);
}



sub Connect
{
   my $self=shift;
   my %p=();
  
   if ($self->{isConnected}){
      return($self->{'db'});
   }
   $p{dbconnect}=$self->getParent->Config->Param('DATAOBJCONNECT');
   $p{dbuser}=$self->getParent->Config->Param('DATAOBJUSER');
   $p{dbpass}=$self->getParent->Config->Param('DATAOBJPASS');
   $p{dbschema}=$self->getParent->Config->Param('DATAOBJBASE');

   if (my $parent=$self->getParent()){
      # check if DATAOBJCONNECT is "overwrited" defined for current object
      # witch allows to make some speical objects writealbe on readonly envs
      my $s=$parent->Self;
      if (ref($p{dbconnect}) eq "HASH" && exists($p{dbconnect}->{$s})){
         $self->{dbname}=$s; # using parent object name as dbname
      }
   }
   my $dbname=$self->{dbname};
   
   foreach my $v (qw(dbconnect dbuser dbpass dbschema)){
      if ((ref($p{$v}) ne "HASH" || !defined($p{$v}->{$dbname})) && 
          $v ne "dbschema"){
         return(undef,
                msg(ERROR,"Connect(%s): essential information '%s' missing",
                    $dbname,$v));
      }
      if (defined($p{$v}->{$dbname}) && $p{$v}->{$dbname} ne ""){
         $self->{$v}=$p{$v}->{$dbname};
      }
   }
   #msg(DEBUG,"fifi %s",Dumper($self));
   $ENV{NLS_LANG}="German_Germany.WE8ISO8859P15"; # for oracle connections
   if (defined($Apache::DBI::VERSION)){
      $self->{'db'}=DBI->connect($self->{dbconnect},
                                 $self->{dbuser},
                                 $self->{dbpass},{mysql_enable_utf8 => 0});
   }
   else{
      if ($self->{dbconnect}=~m/^dbi:odbc:/i){  # cached funktioniert nicht
         $self->{'db'}=DBI->connect(            # mit ODBC verbindungen
            $self->{dbconnect},$self->{dbuser},$self->{dbpass},{
                         private_foo_cachekey=>$self.time()});
         msg(INFO,"use NOT cached datbase connection on ODBC");
      }
      else{
         $self->{'db'}=DBI->connect_cached(
            $self->{dbconnect},$self->{dbuser},$self->{dbpass},{
               mysql_enable_utf8 => 0,
               private_foo_cachekey=>$dbname."-".$$
            });
      }
   }
   $self->{parentlabel}=$self->getParent->Self()."-".$dbname;

   if (!$self->{'db'}){
      if ($self->{dbconnect}=~m/oracle/i){
         if ($ENV{ORACLE_HOME} ne ""){
            msg(ERROR,"env ORACLE_HOME='$ENV{ORACLE_HOME}'");
         }
         if ($ENV{NLS_LANG} ne ""){
            msg(ERROR,"env NLS_LANG='$ENV{NLS_LANG}'");
         }
      }
      return(undef,msg(ERROR,"Connect(%s): DBI '%s'",$dbname,
                       $self->getErrorMsg()));
   }
   else{
      $self->{isConnected}=1;
   }

   # to prevent "no select statement currently executing" errors in mod_perl
   # enviroment, set exec_direct on ODBC connections
   $self->{db}->{odbc_exec_direct}=1;

   if (exists($self->{dbschema})){
      $self->do("alter session set sort_area_size=524288000");
      my $schemacmd="alter session set current_schema=$self->{dbschema}";
      if (!($self->do($schemacmd))){
         return(undef,
                msg(ERROR,"Connect(%s): can't set current_schema to '%s'",
                    $dbname,$self->{dbschema}));
         return(undef);
      }
      else{
         my $parent=$self->getParent->Self();
         #msg(INFO,"schema on $dbname set: $schemacmd; for $parent");
      }
   }
   #
   #  setting the DBI parameters for the created
   #  child session
   #
   $self->{'db'}->{'FetchHashKeyName'}="NAME_lc";
   $self->{'db'}->{'LongTruncOk'} = 1;
   $self->{'db'}->{'LongReadLen'} = 128000;

   return($self->{'db'});
}

sub finish 
{
    my $self=shift;

    if (defined($self->{sth})){
       $self->{sth}->finish();
    }
    return();
}


sub rows 
{
    my $self=shift;

    if (defined($self->{sth})){
       return($self->{sth}->rows());
    }
    return(undef);
}


sub getErrorMsg
{
   return($DBI::errstr);
}

sub checksoftlimit
{
   my $self=shift;
   my $cmd=shift;
   delete($self->{softlimit});

   if ($self->DriverName() eq "ODBC"){
      if (my ($n)=$$cmd=~m/\s+limit\s+(\d+)/){
         $self->{softlimit}=$n;
         $$cmd=~s/\s+limit\s+(\d+)//;
      }
   }
}


sub execute 
{
   my $self=shift;
   my($statement, $attr, @bind_values) = @_;

   if (lc($self->DriverName()) eq "mysql"){
      if ($ENV{REMOTE_USER} ne ""){  # ATTETION: MSSQL produces some errors
         $statement.=" /* W5BaseUser: $ENV{REMOTE_USER}($$) ".  # with
                     "$self->{parentlabel} */";                 # comments!
      }
      if ($attr->{unbuffered}){
         $attr->{mysql_use_result}=1;
      }
      else{
         $attr->{mysql_use_result}=0;
      }
   }
   delete($attr->{unbuffered});
   
   if ($self->{db}){
       $self->{sth}=$self->{'db'}->prepare($statement,$attr);
       #printf STDERR ("fifi $c->{$self->{dataobjattr}}->{sth}\n");
       if (!($self->{sth})){
          return(undef,$DBI::errstr);
       }
       if ($self->{sth}->execute(@bind_values)){
          return($self->{sth});
       }
       printf STDERR ("ERROR: execute='%s'\n",$statement);
       printf STDERR ("ERROR database::execute '%s'\n",$DBI::errstr);
   }
   return(undef);
}

sub getHashList
{
   my $self=shift;
   my $cmd=shift;
   my @l;

   if ($self->execute($cmd)){
      while(my $h=$self->fetchrow()){
         push(@l,$h);
      }
   }
   return(@l) if (wantarray());
   return(\@l);
}


sub getArrayList
{
   my $self=shift;
   my $cmd=shift;
   my @l;

   my ($sth,$errstr)=$self->execute($cmd);
   if (defined($sth)){
      while(my $h=$self->{'sth'}->fetchrow_arrayref()){
         push(@l,$h);
      }
   }
   else{
      msg(ERROR,$errstr." while execute $cmd");
   }
   return(@l) if (wantarray());
   return(\@l);
}

sub DriverName
{
   my $self=shift;
   return($self->{db}->{Driver}->{Name});
}

sub Ping
{
   my $self=shift;
   return($self->{db}->ping());
}


sub quotemeta
{
   my $self=shift;
   my $str=shift;
   utf8::downgrade($str,1);
   return($self->{db}->quote($str));
}

sub DriverName
{
   my $self=shift;

   return(lc($self->{db}->{Driver}->{Name}));
}

sub dbname
{
   my $self=shift;
   return($self->{dbname});
}
   
sub isConnected
{
   my $self=shift;
   return($self->{isConnected});
}
   
sub fetchrow
{
   my $self=shift;

   if (defined($self->{softlimit})){
      $self->{softlimit}--;
      if ($self->{softlimit}<0){
         delete($self->{softlimit});
         return(undef);
      }
   }
   if (!defined($self->{'sth'})){
      return(undef,1);
   }
   $self->{'current'}=$self->{'sth'}->fetchrow_hashref();
   return($self->{'current'});
}

sub getCurrent
{
   my $self=shift;
   return($self->{'current'});
}

sub do
{
   my $self=shift;
   my $cmd=shift;

   $cmd.=" /* W5BaseUser: $ENV{REMOTE_USER}($$) */" if ($ENV{REMOTE_USER} ne "");
   if ($self->{'db'}){
      if (my $rows=$self->{'db'}->do($cmd,{},@_)){
         return($rows); # return of "0E0" means not lines effedted (see DBI)
      }
      else{
         msg(ERROR,"do('%s') rows='$rows' result $DBI::errstr",$cmd);
      }
   }
   return(undef);
}

sub Disconnect
{
   my $self=shift;
   if (defined($Apache::DBI::VERSION)){
      $self->{'db'}->disconnect() if (defined($self->{'db'}));;;
   }
}

sub DESTROY
{
   my $self=shift;
   $self->{'sth'}->finish()    if (defined($self->{'sth'}));;
   if (defined($Apache::DBI::VERSION)){
      $self->{'db'}->disconnect() if (defined($self->{'db'}));
   }
}



1;

