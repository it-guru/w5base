package itil::costcenter;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use finance::costcenter;
@ISA=qw(finance::costcenter);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::SubList(    name       =>'applications',
                                     label      =>'Applications',
                                     group      =>'applications',
                                     vjointo    =>'itil::appl',
                                     vjoinon    =>['name'=>'conumber'],
                                     vjoindisp  =>['name'],
                                     vjoinbase  =>[{cistatusid=>'<=4'}]),
   );
   $self->setDefaultView(qw(linenumber name cistatus fullname mdate));
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/costcenter.jpg?".$cgi->query_string());
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));

   my @l=$self->SUPER::isViewValid($rec);
   if (defined($rec) && $rec->{cistatusid}>2 && $rec->{cistatusid}<6){
      push(@l,"applications");
   }
   return(@l);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


#sub ValidateDelete
#{
#   my $self=shift;
#   my $rec=shift;
#
#   if ($#{$rec->{applications}}!=-1){
#      $self->LastMsg(ERROR,
#          "delete only posible, if there are no application relations");
#      return(0);
#   }
#
#   return(return($self->SUPER::ValidateDelete($rec)));
#}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default itsem delmgmt applications contacts control 
             misc source));
}  


   








1;
