package tsacinv::osrelease;
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
use itil::lib::Listedit;
use tsacinv::lib::tools;

@ISA=qw(itil::lib::Listedit tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'ID',
                dataobjattr   =>'"id"'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'150px',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>'"name"'),

      new kernel::Field::Date(
                name          =>'mdate',
                sqlorder      =>'NONE',
                label         =>'Modification-Date',
                dataobjattr   =>'"mdate"'),

      new kernel::Field::Date(
                name          =>'mdaterev',
                sqlorder      =>'desc',
                uivisible     =>0,
                label         =>'Modification-Date reverse',
                dataobjattr   =>'"mdaterev"')
   );
   $self->setDefaultView(qw(linenumber name id mdate));
   $self->setWorktable("osrelease");
   return($self);
}


sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/osrelease.jpg?".$cgi->query_string());
}





sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef) if (!defined($rec));
   return("mapping") if ($self->IsMemberOf("admin"));
   return(undef);
}





1;
