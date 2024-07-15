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
   local $SIG{INT}; # try fix signal INT problem DBD::Oracle

   my $parent=$self->getParent();

   my @PosibleDBname=($self->{dbname});

   if (defined($parent)){
      my $s=$parent->Self;
      if ($s ne ""){
         unshift(@PosibleDBname,$s);
         if ($s=~m/::/){
            $s=~s/^([^:]+)::.*$/$1::*/;
            unshift(@PosibleDBname,$s);
         }
      }
   }
   if ($#PosibleDBname>0){
      DBCHKNAME: foreach my $chkName (@PosibleDBname){
         if (ref($p{dbconnect}) eq "HASH" && 
             exists($p{dbconnect}->{$chkName})){
            $self->{dbname}=$chkName; #dbname after check prio handling
            last DBCHKNAME;
         }
      }
   }

   if (defined($parent)){
      # check if DATAOBJCONNECT is "overwrited" defined for current object
      # witch allows to make some special objects writealbe on readonly envs
      my $s=$parent->Self;
   }
   my $dbname=$self->{dbname};
   
   foreach my $v (qw(dbconnect dbuser dbpass dbschema)){
      if ((ref($p{$v}) ne "HASH" || !defined($p{$v}->{$dbname})) && 
          $v ne "dbschema"){
         my $msg=sprintf("Connect(%s): essential information '%s' missing",
                    $dbname,$v);
         msg(ERROR,$msg);
         return(undef,$msg);
      }
      if (defined($p{$v}->{$dbname}) && $p{$v}->{$dbname} ne ""){
         $self->{$v}=$p{$v}->{$dbname};
      }
   }
   $ENV{NLS_LANG}="German_Germany.WE8ISO8859P15"; # for oracle connections
   my $BackendSessionName=$self->getParent->BackendSessionName();
   $BackendSessionName="default" if (!defined($BackendSessionName));
   if (defined($Apache::DBI::VERSION)){
      $self->{'db'}=DBI->connect($self->{dbconnect},
                                 $self->{dbuser},
                                 $self->{dbpass},{mysql_enable_utf8 => 0});
      if (defined($self->{'db'})){
         if ($self->{'db'}->{private_inW5Transaction}){
            $self->{'db'}->{AutoCommit}=0;
         }
      }
      if ($DBI::errstr ne ""){
         msg(ERROR,"connect problem on ".
                   "handle '$dbname' err='$DBI::errstr'");
      }
   }
   else{
      if (
         # ($self->{dbconnect}=~m/^dbi:odbc:/i) ||  # try to allow odbc and
         # ($self->{dbconnect}=~m/^dbi:db2:/i) ||   # db2 via connect_cached
          ($BackendSessionName eq "ForceUncached")){  
         $self->{'db'}=DBI->connect(
            $self->{dbconnect},
            $self->{dbuser},$self->{dbpass},{ }
         );
         #msg(INFO,"use NOT cached datbase connection in $self");
         if (defined($self->{'db'})){
            if ($self->{'db'}->{private_inW5Transaction} ne ""){
               $self->{'db'}->{AutoCommit}=0;
            }
         }
      }
      else{
         my $private_foo_cachekey=$dbname."-".$$.".".$BackendSessionName;
         my @connectParam=(
            $self->{dbconnect},$self->{dbuser},$self->{dbpass},{
               mysql_enable_utf8 => 0,
               mysql_auto_reconnect=>1,
               AutoCommit=>1,
               RaiseError=>0,            
               PrintError=>0,            
               private_foo_cachekey=>$private_foo_cachekey
            }
         );
         $self->{'db'}=DBI->connect_cached(@connectParam);
         if (!defined($self->{'db'})){
            my $sRetry=1;
            if (lc($self->getParent->Config->Param('SilentRetryDataObjConnect'))
                 eq "no"){
               $sRetry=0;
            }
            msg(WARN,"1st retry connect to $dbname") if (!$sRetry);
            sleep(1);
            $self->{'db'}=DBI->connect_cached(@connectParam);
            if (!defined($self->{'db'})){
               msg(WARN,"2nd retry connect to $dbname") if (!$sRetry);
               sleep(3);
               $self->{'db'}=DBI->connect_cached(@connectParam);
               if (defined($self->{'db'})){
                  msg(WARN,"2nd retry got success to $dbname") if (!$sRetry);
               }
            }
            else{
               msg(WARN,"1st retry got success to $dbname") if (!$sRetry);
            }
         }
         if (defined($self->{'db'})){
            if ($self->{'db'}->{private_inW5Transaction} ne ""){
               $self->{'db'}->{AutoCommit}=0;
            }
         }
      }
   }
   $self->{parentlabel}=$self->getParent->Self()."-".$dbname;

   if (!defined($self->{'db'})){
      if ($self->{dbconnect}=~m/oracle/i){
         if ($ENV{ORACLE_HOME} ne ""){
            msg(ERROR,"env ORACLE_HOME='$ENV{ORACLE_HOME}'");
         }
         if ($ENV{NLS_LANG} ne ""){
            msg(ERROR,"env NLS_LANG='$ENV{NLS_LANG}'");
         }
      }
      my $msg=sprintf("Connect(%s): DBI '%s'",$dbname, $self->getErrorMsg());
      msg(ERROR,$msg);
      return(undef,$msg);
   }
   else{
      $self->{isConnected}=1;
   }

   # to prevent "no select statement currently executing" errors in mod_perl
   # enviroment, set exec_direct on ODBC connections
   $self->{db}->{odbc_exec_direct}=1;
   $self->{db}->{RaiseError}=0;
   $self->{db}->{PrintError}=0;

   if (uc($self->DriverName()) eq "ORACLE"){   # needed for primaryreplkey tech.
      $self->{db}->{InactiveDestroy}=1; # try to fix W5Reporter ORA-03114
      $self->do("alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS'");
   }


   if (exists($self->{dbschema})){
      if (($self->{dbconnect}=~m/^dbi:pg:/i)){
         my $schemacmd="set schema '$self->{dbschema}'";
         if (!($self->do($schemacmd))){
            my $msg=sprintf("Connect(%s): can't set current_schema to '%s'",
                       $dbname,$self->{dbschema});
            msg(ERROR,$msg);
            return(undef,$msg);
         }
         else{
            my $parent=$self->getParent->Self();
            #msg(INFO,"schema on $dbname set: $schemacmd; for $parent");
         }

      }
      else{
         $self->do("alter session set sort_area_size=524288000");
         my $schemacmd="alter session set current_schema=$self->{dbschema}";
         if (!($self->do($schemacmd))){
            my $msg=sprintf("Connect(%s): can't set current_schema to '%s'",
                       $dbname,$self->{dbschema});
            msg(ERROR,$msg);
            return(undef,$msg);
         }
         else{
            my $parent=$self->getParent->Self();
            #msg(INFO,"schema on $dbname set: $schemacmd; for $parent");
         }
      }
   }
   return(undef) if (!defined($self->{'db'}));
   #
   #  setting the DBI parameters for the created
   #  child session
   #
   $self->{'db'}->{'FetchHashKeyName'}="NAME_lc";
   $self->{'db'}->{'LongTruncOk'} = 1;
   if (uc($self->DriverName()) eq "ODBC"){   # problem with MSSQL freetds.
      $self->{'db'}->{'LongReadLen'} = 8192;
   }
   else{
      $self->{'db'}->{'LongReadLen'} = 128000;
   }

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
       if (defined($self->{fixrowcount})){ # for DB2 or schrott like that
          return($self->{fixrowcount});
       }
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

   if ($self->DriverName() eq "odbc"){
      if (my ($n)=$$cmd=~m/\s+limit\s+(\d+)/){
         $self->{softlimit}=$n;
         $$cmd=~s/\s+limit\s+(\d+)//;
      }
   }
}


sub begin_work 
{
   my $self=shift;

   if ($self->{db}){
      if ($self->{db}->{AutoCommit}){
         $self->{W5Transaction}=$self->getParent()."-".time();
         $self->{db}->begin_work();
         # The private_inW5Transaction handling is neassesary, because 
         # Apache::DBI (or connect_cached) resets AutoCommit flag on
         # a reuse of the handle
         $self->{db}->{private_inW5Transaction}=$self->{W5Transaction};
         msg(INFO,"begin_work($self->{W5Transaction}) done in ");
      }
   }
}

sub commit 
{
   my $self=shift;

   if ($self->{db}){
      if ($self->{db}->{private_inW5Transaction} eq $self->{W5Transaction}){
         $self->{db}->commit();
         msg(INFO,"commit($self->{W5Transaction}) done in ");
         $self->{db}->{private_inW5Transaction}=undef;
      }
      else{
         msg(INFO,"skip commit(".$self->getParent->Self.")");
      }
   }
}

sub rollback 
{
   my $self=shift;

   if ($self->{db}){
      if ($self->{db}->{private_inW5Transaction} eq $self->{W5Transaction}){
         $self->{db}->rollback();
         msg(INFO,"rollback($self->{W5Transaction}) done in ");
         $self->{db}->{private_inW5Transaction}=undef;
      }
      else{
         msg(INFO,"skip rollback(".$self->getParent->Self.")");
      }
   }
}


sub execute 
{
   my $self=shift;
   my($statement, $attr, @bind_values) = @_;

   #if (length($statement)>(1024*1024*5) ){
   #   msg(ERROR,"oversized (>1M) Statement $statement\n");
   #   Stacktrace();
   #}
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
       if (ref($self->{'db'}) eq "HASH"){
          printf STDERR ("$self->{'db'} contains HASH - this is bad!\n");
          print STDERR Dumper($self->{'db'});
          die(); 
       }
       delete($self->{fixrowcount});
       if (($self->DriverName() eq "db2"    # result of DB2 rows is not correct
            && $statement=~m/^select/i)){
          my $cnt=$self->{'db'}->prepare("select count(*) from ($statement)",
                                         $attr);
          if (defined($cnt)){  # check if there is a memory problem in statement
             if ($cnt->execute(@bind_values)){
                my $h=$cnt->fetchrow_arrayref();
                if (ref($h) eq "ARRAY"){
                   $self->{fixrowcount}=$h->[0]; 
                }
             }
          }
       }
       $self->{sth}=$self->{'db'}->prepare($statement,$attr);
       if (!($self->{sth})){
          msg(ERROR,$DBI::errstr); # for Oracle Syntax fehler
          return(undef,$DBI::errstr);
       }
       if ($self->{sth}->execute(@bind_values)){
          return($self->{sth});
       }
       if ($self->getParent->Config->Param("W5BaseOperationMode") eq "dev"){
          printf STDERR ("ERROR: execute='%s'\n",$statement);
          printf STDERR ("ERROR database::execute '%s'\n",$DBI::errstr);
       }
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
   return() if (!defined($self->{db}));
   my $driver=$self->{db}->{Driver};
   if (defined($driver)){
      my $name=lc($driver->{Name});
      if ($name eq "odbc"){
         # maybee special addons f.e. as .mssql extensions
      }
      return($name);
   }
   return();
}

sub Ping
{
   my $self=shift;
   my $bk=$self->{db}->ping();
 #  if ($bk){  # check if session realy ok
 #     if (lc($self->DriverName()) eq "oracle"){
 #        return(0);
 #     }
 #  }
   return($bk);
}


sub quotemeta
{
   my $self=shift;
   my $str=shift;
   utf8::downgrade($str,1);
   #Stacktrace() if (ref($self->{db}) ne "CODE");
   print STDERR Dumper($self->{db}) if (ref($self->{db}) eq "HASH");
   Stacktrace() if (ref($self->{db}) eq "HASH");
   return($self->{db}->quote($str));
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
   if ($DBI::err){
      if ($DBI::errstr ne ""){
         msg(ERROR,"DB Error - fetchrow_hashref err='$DBI::errstr'");
      }
      return(undef,1);
   }
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

   if ($ENV{REMOTE_USER} ne ""){
      $cmd.=" /* W5BaseUser: $ENV{REMOTE_USER}($$) */";
   }
   if ($self->{'db'}){
      if (my $rows=$self->{'db'}->do($cmd,{},@_)){
         return($rows); # return of "0E0" means not lines effedted (see DBI)
      }
      else{
         # hide Error-Message, if deadlockHandler Handler flag is set (this
         # means deadlocks are handled from caller method)
         if (!exists($self->{deadlockHandler}) ||
             !($DBI::errstr=~m/^Deadlock found when trying to get lock/)){
            msg(ERROR,"do('%s') rows='$rows' result $DBI::errstr",$cmd);
         }
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

