package base::event::dbdump;
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
use Data::Dumper;
use kernel;
use kernel::Event;
use IPC::Open3;
use IO::Handle;
use IO::Select;
use Compress::Zlib;
use Date::Calc qw( Today_and_Now
                   Week_of_Year
                   Day_of_Week_to_Text
                   Delta_YMDHMS
                   Delta_DHMS
                   Day_of_Week );
use File::Path;
@ISA=qw(kernel::Event);
my ($prog);
my $starttime=sprintf("%04d-%02d-%02d %02d:%02d:%02d",Today_and_Now);
my @prog=qw(mysql mysqldump);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;
   $self->RegisterEvent("tinyDBDump","tinyDBDump");
   return(1);
}

sub tinyDBDump
{
   my $self=shift;
   my %param=@_;
   check_db($self,$param{db},$param{host});
   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->ResetFilter();
   $appl->SetFilter(name=>'SEPT');
   $appl->SetCurrentOrder("NONE");
#   $appl->SetCurrentView(qw(id,name,systems));
   my $view=$appl->getHashList(qw(id name systems));
#   msg(DEBUG,Dumper(\%param));
   process_engine($self,$param{db},$param{host}); 
   return(0);
}

sub process_engine
{
   my $self=shift;
   my $db=shift;
   my $host=shift;
   my $mydsel=new IO::Select();
   my $mydrdr=new IO::Handle();
   my $myderr=new IO::Handle();
   my (@ready,@myderr,@gz);

   my $mysqldump_pid=open3(undef,$mydrdr,$myderr,
                     "$prog->{mysqldump} -h $host -c -t $db appl");
                      $mydsel->add($myderr);
   $mydsel->add($myderr);
   # check for mysqldump errors
   @ready = $mydsel->can_read(0.5);
   foreach my $fh (@ready){
      while (my $data=<$fh>){
         push(@myderr,$data);
      }
   }
   # print mysqldump errors
   if ($#myderr != -1){
      foreach my $fi (@myderr){
         if ($fi){
            msg(ERROR,"$fi");
         }
      }
      @ready=[];
   }
   my $gz=gzopen("/tmp/anonym_db_dump.sql.gz", "w9");
   while(my $line=<$mydrdr>){
#       msg(DEBUG,"$line");
       $gz->gzwrite("$line");
   }
   $gz->gzclose();
}

sub check_db
{
   my $self=shift;
   my $db=shift;
   my $host=shift;
 
   if (!$db){
      msg("ERROR","database is not given!");
      exit(1);
   }
   # check database is usable
   local(*R, *E);
   open3(undef,*R,*E,"$prog->{mysql} -h $host $db");
   wait();
   if ($? != 0){
      msg(ERROR,"source database $db ".
                "not useable or not found on host=$host, rc=".$?);
      exit(1);
   }
   close(R);
 
   # clear mysql cache
   system("$prog->{mysql} -h $host -e 'flush logs' $db") == 0 
           or die("system command -mysql flush logs- failed:$?");
   system("$prog->{mysql} -h $host -e 'flush tables' $db") == 0 
           or die("system command -mysql flush tables- failed:$?");
   msg(DEBUG,"logs on db=$db host=$host flushed");
   
}

# find progamms
foreach my $p (@prog){
   my $found=0;
   foreach my $path (split(/:/,$ENV{PATH})){
      if ( -x "$path/$p"){
         $found++;
         $prog->{$p}="$path/$p";
      }

   }
   die("programm $p not found") if (!$found);
}

1;

