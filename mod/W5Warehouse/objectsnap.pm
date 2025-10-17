package W5Warehouse::objectsnap;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'snapclass',
                label         =>'snapclass',
                dataobjattr   =>'snapclass'),

      new kernel::Field::Date(
                name          =>'dsnap',
                label         =>'snapdate',
                dataobjattr   =>'snapdate'),

      new kernel::Field::Text(
                name          =>'id',
                label         =>'id',
                dataobjattr   =>'id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'name',
                dataobjattr   =>'name'),

      new kernel::Field::Text(
                name          =>'dataobj',
                label         =>'dataobj',
                dataobjattr   =>'dataobj'),

      new kernel::Field::Text(
                name          =>'id',
                label         =>'id',
                dataobjattr   =>'id'),

      new kernel::Field::XMLInterface(
                name          =>'xrec',
                uivisible     =>1,
                label         =>'xmlrec',
                dataobjattr   =>'xmlrec'),

   );
   $self->{use_distinct}=0;
   $self->setWorktable("OBJECTSNAP");
   $self->setDefaultView(qw(snapclass dsnap id name dataobj));
   return($self);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   if ($self->IsMemberOf("admin")){
      return("ALL");
   }
   return();
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



sub SetFilter {
   my $self=shift;

   if (defined($self->{DB})){
      $self->{DB}->{db}->{LongReadLen}=4000000;
   }
   $self->SUPER::SetFilter(@_);
}


sub SnapStart
{
   my $self=shift;
   my $snapclass=shift;

   if ($self->doInitialize()){
      $self->{snapdate}=NowStamp("en");
      $self->{snapidbased}=1;
      $self->{snapclass}=$snapclass;
      my ($worktable,$workdb)=$self->getWorktable();
      $workdb->{AutoCommit}=0;
      $workdb->{db}->begin_work();
      my $insertcmd="insert into \"$worktable\" ".
                    "(id,name,dataobj,xmlrec,snapdate,snapclass) ".
                    "values(?,?,?,?,to_date(?,'YYYY-MM-DD HH24:MI:SS'),?)";
      $self->{insertcmdsth}=$workdb->{db}->prepare($insertcmd);
      my $finecmd="delete \"$worktable\" where ".
                  "snapdate<>to_date(?,'YYYY-MM-DD HH24:MI:SS') ".
                  " and snapclass=?";
      $self->{finecmdsth}=$workdb->{db}->prepare($finecmd);
      return(1);
   }
   return(undef);
}


sub SnapRecord
{
   my $self=shift;
   my $id=shift;
   my $name=shift;
   my $dataobj=shift;
   my $xmlrec=shift;
   my ($worktable,$workdb)=$self->getWorktable();

   my $xmltext=$xmlrec;

#   if (utf8::is_utf8($xmltext)){   # xml in W5W is always stored in Latin1
      $xmltext=UTF8toLatin1($xmltext);
#   }

   my $bk=$self->{insertcmdsth}->execute(
       $id,$name,$dataobj,$xmltext,
       $self->{snapdate},
       $self->{snapclass});
   if (!$bk){
      msg(ERROR,$DBI::errstr);
      die($DBI::errstr);
   }
   #my $rows=$self->{insertcmdsth}->rows();
}


sub SnapEnd
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $bk=$self->{finecmdsth}->execute($self->{snapdate},$self->{snapclass});
   if (!$bk){
      msg(ERROR,$DBI::errstr);
      die($DBI::errstr);
   }
   $workdb->{db}->commit();
}



1;
