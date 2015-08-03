package base::Reporter::ReporterMon;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use kernel::Reporter;
@ISA=qw(kernel::Reporter);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{fieldlist}=[qw(name id validto srcsys)];
   $self->{name}="Reporting-Server - Monitor";
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;

   return(60*48,['07:00','13:15','16:00']);    
}


sub isViewValid
{
   my $reporter=shift;
   my $self=shift;
   my $rec=shift;
   return(0) if (!$self->IsMemberOf("admin"));
   return(1);
}

#sub stderr             # for debugging 
#{
#   my $self=shift;
#   my $line=shift;
#   my $task=shift;
#   my $reporter=shift;
#   push(@{$task->{stderr}},$line);
#}




sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;

   my $o=getModuleObject($self->Config,"base::reportjob");
   $o->SetFilter({cistatusid=>\'4', validto=>"<now"});
   my $d;
   foreach my $rec ($o->getHashList(@{$self->{fieldlist}})){
      print(join(";",map({$rec->{$_}} @{$self->{fieldlist}}))."\n");
   }
   return(0);
}



sub onChange
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $msg="";
   my $old=CSV2Hash($oldrec->{textdata},"id");
   my $new=CSV2Hash($newrec->{textdata},"id");
   foreach my $id (keys(%{$new->{id}})){
      if (!exists($old->{id}->{$id})){
         my $m=$self->T('+ "%s" (%s) report job has invalid data');
         $msg.=sprintf($m."\n",$new->{id}->{$id}->{name},
                               $new->{id}->{$id}->{srcsys});
      }
   }
   if ($msg ne ""){
      $msg="Dear W5Base User,\n\n".
           "the following changes have been detected in the report:\n\n".
           $msg;
   }

   return($msg);
}



1;
