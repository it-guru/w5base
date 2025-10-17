package tsacinv::mandator;
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
use kernel::Field;
use base::mandator;
use tsacinv::lib::tools;

@ISA=qw(base::mandator tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Boolean(  name       =>'doexport',
                                   label      =>'AC Config-Item Export active',
                                   default    =>'1',
                                   searchable =>0,
                                   group      =>'acrelation',
                                   container  =>'additional'),

      new kernel::Field::TextDrop( name       =>'defaultassignment',
                                   label      =>'AC Default Config Assignment',
                                   group      =>'acrelation',
                                   vjointo    =>'tsacinv::group',
                                   vjoinon    =>['defaultassignmentid'=>
                                                 'lgroupid'],
                                   vjoindisp     =>'name'),

      new kernel::Field::Link(     name       =>'defaultassignmentid',
                                   label      =>'AC Default Assignment ID',
                                   searchable =>0,
                                   group      =>'acrelation',
                                   container  =>'additional'),

   );
   $self->setDefaultView(qw(id name));
   $self->{history}={
      update=>[
         'local'
      ]
   };
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default acrelation source));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","acrelation","source","history");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef) if (!defined($rec));
   my @l=$self->SUPER::isWriteValid($rec);
   if ($self->IsMemberOf("admin")){
      push(@l,"acrelation");
      @l=grep(!/^default$/,@l);
      @l=grep(!/^contacts$/,@l);
   }
   return(@l);
}  
   
sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/mandator.jpg?".$cgi->query_string());
}
         



1;
