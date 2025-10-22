package base::usermodusage;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'userid',
                label         =>'UserID',
                dataobjattr   =>'usermodusage.userid'),

      new kernel::Field::Contact(
                name          =>'contact',
                readonly      =>1,
                vjoinon       =>'userid',
                label         =>'Contact',
                dataobjattr   =>'contact.fullname'),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                dataobjattr   =>'contact.email'),


      new kernel::Field::Text(
                name          =>'logonmonth',
                label         =>'Logon Month',
                dataobjattr   =>'usermodusage.ymonth'),

      new kernel::Field::Text(
                name          =>'module',
                label         =>'Module',
                dataobjattr   =>'usermodusage.module'),

      new kernel::Field::Number(
                name          =>'cnt',
                label         =>'Count',
                dataobjattr   =>'usermodusage.cnt'),
   );
   $self->setDefaultView(qw(userid contact email logonmonth module cnt));
   $self->setWorktable("usermodusage");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();

   my $from="$worktable";
   $from.=" left outer join contact on usermodusage.userid=contact.userid";
   return($from);
}


sub Validate
{
   my ($self,$oldrec,$newrec)=@_;
   return(1);
}


sub initSearchQuery
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();
   if (!defined(Query->Param("search_userid"))){
     Query->Param("search_userid"=>
                  "\"$userid\"");
   }
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf(["admin","support"])){
      my $userid=$self->getCurrentUserId();
      my @addflt=({userid=>\$userid});
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}




sub isViewValid
{
   my ($self,$rec)=@_;
   return("ALL");
}

sub isWriteValid
{
   my ($self,$rec)=@_;
   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/env.jpg?".$cgi->query_string());
}



1;
