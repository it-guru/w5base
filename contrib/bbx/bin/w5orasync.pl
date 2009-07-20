#!/usr/bin/env perl 
use strict;
use lib qw(../lib ../../lib ../../../lib);
use Getopt::Long;
use W5Kernel;
use W5FastConfig;
use W5Base::API;
use DBI;
use Data::Dumper qw(Dumper);
use vars qw( $opt_v $opt_v $opt_h $opt_c $appname);

#######################################################################
# INIT
#######################################################################
my @ARGV_bak=@ARGV;
$appname="w5orasync";
exit(1) if (!GetOptions('verbose'=>\$opt_v,
                        'debug'=>\$opt_v,
                        'help'=>\$opt_h,
                        'config=s'=>\$opt_c));
$W5V2::Debug=0; $W5V2::Debug=1 if ($opt_v);
if (defined($opt_h)){ help(); exit(1); }

$0=$main::appname;
my @argv=@ARGV;
@ARGV=@ARGV_bak;
my $configname=$opt_c;

my $cfg=new W5FastConfig('sysconfdir'=>'/etc');
if (!$cfg->readconfig($configname)){
   msg(ERROR,"can't read configfile '%s'",$configname);
   exit(1);
}
#######################################################################
msg(INFO,$cfg->Dumper());
#######################################################################

#######################################################################
my $base=$cfg->Param("W5BaseURL");
my $loginuser=$cfg->Param("W5BaseUSER");
my $loginpass=$cfg->Param("W5BasePASS");
my $lang="en";
my $apidebug=0;

msg(INFO,"try to connect to w5base");
my $Config=createConfig($base,$loginuser,$loginpass,$lang,$apidebug);
if (!defined($Config)){
   msg(ERROR,"base url or username/password is not valid");exit(1);
}
else{
   msg(DEBUG,"create of config ok");
}


msg(INFO,"try to connect to database");
my $dbconnect=$cfg->Param("ORACONNECT");
my $dbuser=$cfg->Param("ORAUSER");
my $dbpass=$cfg->Param("ORAPASS");
my $dst=DBI->connect($dbconnect,$dbuser,$dbpass,{mysql_enable_utf8=>0,
                                                 AutoCommit=>0});
if (!$dst){
   msg(ERROR,$DBI::errstr);
   exit(1);
}



foreach my $syncobj (@argv){
   # select starttime from oracle database for cleanup
   my @l=$dst->getHashList("select ".
                           "to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') NOW ".
                           "from dual");
   my $start=$l[0]->{'NOW'};
   my $obj=getModuleObject($Config,$syncobj);
   msg(INFO,"obj=$obj");

   my $idname;  # load fields list from w5base
   my @fields;
   if (@fields=$obj->showFields()){
      foreach my $field (@fields){
         if ($field->{longtype} eq "kernel::Field::Id"){
            $idname=$field->{name};
         }
      }
   }

   # create oracle database tablename
   my $dbtable=$syncobj;
   $dbtable=~s/:/_/g;

   # check exists of dbtable in current oracle database
   my $sth=$dst->table_info(undef,'%',uc($dbtable));
   my @table=$sth->getHashList();
   if ($#table!=0){
       msg(ERROR,"table $dbtable not found or name not unique");
       exit(1);
   }
   my $dbtable=join(".",$table[0]->{'TABLE_SCHEM'},$table[0]->{'TABLE_NAME'});
   my $sth=$dst->column_info($table[0]->{'TABLE_CAT'},
                             $table[0]->{'TABLE_SCHEM'},
                             $table[0]->{'TABLE_NAME'},'%');
   my @column=$sth->getHashList();
   my @view;
   foreach my $col (@column){
      if (lc($col->{COLUMN_NAME}) ne "w5lastsync"){
         push(@view,lc($col->{COLUMN_NAME}));
      }
   }
   
#   printf STDERR ("fifi t=%s\n",Dumper(\@table));
#   printf STDERR ("fifi c=%s\n",Dumper(\@column));
#   printf STDERR ("fifi v=%s\n",Dumper(\@view));

   if (!defined($idname)){
      msg(ERROR,"can not identify unique field in $syncobj");
      exit(1);
   }


   foreach my $rec ($obj->getHashList(@view)){
      if (!($dst->InsertOrUpdate($dbtable,$idname,$rec))){
         msg(ERROR,$DBI::errstr);
         exit(1);
      }
   }
   $dst->doCmd("delete from $dbtable where w5lastsync<".
               "to_date(?,'YYYY-MM-DD HH24:MI:SS')",$start);
}
$dst->commit();
$dst->disconnect();



#######################################################################
sub help
{
   printf STDERR ("Usage: $main::appname -c {config} [-v]\n");
}
#######################################################################

package DBI::st;

sub getHashList
{
   my $self=shift;
   my @bind=@_;
   my @l;

   if ($self->execute(@bind)){
      while(my $dbrec=$self->fetchrow_hashref()){
         push(@l,$dbrec);
      }
      return(@l);
   }
   return(undef);
}

package DBI::db;
use W5Kernel;

sub getHashList
{
   my $self=shift;
   my $cmd=shift;
   if (my $sth=$self->prepare($cmd)){
      return($sth->getHashList(@_));
   }
   return(undef);
}   

sub InsertOrUpdate
{
   my $self=shift;
   my $dbtable=shift;
   my $idname=shift;
   my $rec=shift;

   my $cmd="select * from $dbtable where $idname=?";
   my $idval=$rec->{$idname};
   my @curlist=$self->getHashList($cmd,$idval);
   my @view=keys(%$rec);
   if ($#curlist==0){     # do an update
      my (@v,@values);
      foreach my $fieldname (@view){
         push(@values,$rec->{$fieldname});
         push(@v,"$fieldname=?");
      }
      my $v=join(",",@v);
      my $updcmd="update $dbtable set $v where $idname=?";
   #   msg(INFO,"upd: $updcmd");
      return($self->doCmd($updcmd,@values,$idval));
   }
   elsif ($#curlist==-1){ # do an insert
      my @values=map({$rec->{$_}} @view);
      my @place=map({'?'} @view);
      my $inscmd="insert into $dbtable (".join(",",@view,"w5lastsync").") ".
                 "values(".join(",",@place,'sysdate').")";
   #   msg(INFO,"ins: $inscmd");
      return($self->doCmd($inscmd,@values));
   }
   else{
      msg(ERROR,"ganz scheisse!");
      exit(-12356);
   }
   return(undef);
}   
sub doCmd
{
   my $self=shift;
   my $cmd=shift;
   if (my $sth=$self->prepare($cmd)){
      return($sth->execute(@_));
   }
   return(undef);
}   
