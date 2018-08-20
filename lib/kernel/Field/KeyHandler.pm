package kernel::Field::KeyHandler;
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
use kernel::database;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{uivisible}=0;
   $self->{isinitialized}=0;
   return($self);
}

sub Initialize
{
   my $self=shift;
   $self->{db}=new kernel::database($self->getParent,$self->{dataobjname});
   if ($self->{db}->Connect()){
      $self->{isinitialized}=1;
   }
   else{
      msg(ERROR,"failed to connect database '%s' for field '%s'",
          $self->{dataobjname},$self->{name});
   }
}


sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $name=$self->Name();
   if (!defined($current->{$name})){
      my $keytab=$self->{tablename};
      my $res={};
      $self->Initialize() if (!($self->{isinitialized}));
      my $id=$current->{$self->getParent->IdField->Name()};
      return($res) if (!defined($id));
      my $cmd="select name,fval from $keytab where id='$id'";
      $self->getParent->Log(INFO,"sqlread",$cmd);
      my @l=$self->{db}->getHashList($cmd);
      foreach my $rec (@l){
         $res->{$rec->{name}}=[] if (!defined($res->{$rec->{name}}));
         push(@{$res->{$rec->{name}}},$rec->{fval});
      }
      foreach my $k (keys(%{$res})){
         $res->{$k}=[sort(@{$res->{$k}})];
      }
      $current->{$name}=$res;
   }
   return($current->{$name});
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $myname=$self->Name();
   my ($oldval,$newval);
   $oldval=$oldrec->{$myname} if (defined($oldrec) &&
                                  exists($oldrec->{$myname}));
   $newval=$newrec->{$myname} if (defined($newrec) &&
                                  exists($newrec->{$myname}));
   my $keytab=$self->{tablename};
   my $nowstamp=NowStamp();
   #printf STDERR ("fifi FinishWrite keyhandler %s my newval=%s\n",Dumper($newrec),Dumper($newval));
   $self->Initialize() if (!($self->{isinitialized}));
   my $idfield=$self->getParent->IdField()->Name();
   my $id;
   if (defined($newrec->{$idfield})){
      $id=$newrec->{$idfield};
   }
   else{
      $id=$oldrec->{$idfield};
   }
   return(undef) if (!defined($id));
   $newval={} if (ref($newval) ne "HASH");
   my $cleanupcmd="delete from $keytab where ";
   my @insvar=qw(name fval id createdate editor realeditor);


   my @cleanuprest=();
   my @insertvalue=();
   my %insdata=(id=>$id,
                createdate=>$nowstamp,
                editor=>$ENV{REMOTE_USER},
                realeditor=>$ENV{REAL_REMOTE_USER});
   my %upddata=%insdata;
   my $updneed=0;
   if (!defined($insdata{editor})){
      $insdata{editor}="system/".$ENV{USER};
   }
   if (!defined($insdata{realeditor})){
      $insdata{realeditor}="system/".$ENV{USER};
   }
   if (defined($self->{extselect})){
      foreach my $k (keys(%{$self->{extselect}})){
         my $val;
         next if ($k eq "trange");
         if (exists($newrec->{$k})){
            $val=$newrec->{$k};
            $updneed=1 if (!defined($oldrec->{$k}) ||
                           $oldrec->{$k} ne $newrec->{$k});
         }
         elsif(defined($oldrec->{$k}) || exists($oldrec->{$k})){
            $val=$oldrec->{$k};
         }
         else{
            msg(ERROR,"no completly extended selection specivied");
            msg(ERROR,"missing %s in %s for %s",$k,$self,$self->Name());
            return({});
         } 
         push(@insvar,$self->{extselect}->{$k});
         $insdata{$self->{extselect}->{$k}}=$val;
         $upddata{$self->{extselect}->{$k}}=$val;
      }
   }
   my $insertcmd="insert into $keytab (".join(",",@insvar).") values ";
   foreach my $k (keys(%{$newval})){
      $insdata{name}=$k;

      my %data;
      if (ref($newval->{$k}) eq "ARRAY"){
         foreach my $data (@{$newval->{$k}}){
            $data{lc($data)}=$data if (!exists($data{lc($data)}));
         }
      }
      else{
         if (defined($newval->{$k})){
            $data{lc($newval->{$k})}=$newval->{$k};
         }
      }
      my $newk=lc(join("|",sort(values(%data))));
      my $oldk=$oldrec->{$k};
      $oldk=join("|",sort(@{$oldk})) if (ref($oldk) eq "ARRAY");
      $oldk=lc($oldk);
      if ($oldk ne $newk){
         push(@cleanuprest,"(id='$id' and name='$k')");
         foreach my $data (keys(%data)){
            $insdata{fval}=$data{$data};
            my $cmd="(".join(",",map({$self->{db}->quotemeta($insdata{$_})}
                                     @insvar)).")";
            push(@insertvalue,$cmd);
         }
      }
   }
   if ($#cleanuprest!=-1){
      $cleanupcmd.=join(" or ",@cleanuprest);
      $self->{db}->do($cleanupcmd);
      #msg(INFO,"KeyHandler:cleanupd %s",$cleanupcmd);
      $self->getParent->Log(INFO,"sqlwrite",$cleanupcmd);
   }
   if ($#insertvalue!=-1){
      $insertcmd.=join(",",@insertvalue);
      $self->{db}->do($insertcmd);
      #msg(INFO,"KeyHandler:insertcmd %s",$insertcmd);
      $self->getParent->Log(INFO,"sqlwrite",$insertcmd);
   }
   if ($updneed){
      my @vars=grep(!/^id$/,keys(%upddata));
      my $cmd="update $keytab set ".
              join(",",map({$_."=".$self->{db}->quotemeta($upddata{$_})} @vars)).
              " where id='".$upddata{id}."'";
      $self->{db}->do($cmd);
      #msg(INFO,"KeyHandler:updatecmd %s",$cmd);
      $self->getParent->Log(INFO,"sqlread",$cmd);
   }
   #msg(INFO,"KeyHandler:FinishWrite %s",Dumper($newval));
   # preparing the hash - > todo

   return(undef);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   my $idfield=$self->getParent->IdField()->Name();
   my $keytab=$self->{tablename};

   $self->Initialize();
   my $db=$self->{db};
   my $id=$oldrec->{$idfield};
   if (defined($id)){
      my $cleanupcmd="delete from $keytab where id='$id'";
      $self->{db}->do($cleanupcmd);
      msg(INFO,"KeyHandler:cleanupd %s",$cleanupcmd);
   }
   return(undef);
}

sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   return(undef);
}











1;
