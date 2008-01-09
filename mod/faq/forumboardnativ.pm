package faq::forumboardnativ;
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
use faq::forumboard;
use faq::lib::forum;
@ISA=qw(faq::forumboard);



sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'topiccount',
                label         =>'Topic-Count',
                searchable    =>0,
                group         =>'stat',
                readonly      =>1,
                sqlorder      =>'none',
                dataobjattr   =>'count(forumtopic.id)'),
                                    
      new kernel::Field::Text(
                name          =>'entrycount',
                label         =>'Entry-Count',
                group         =>'stat',
                searchable    =>0,
                readonly      =>1,
                sqlorder      =>'none',
                dataobjattr   =>'count(forumentry.id)'),

      new kernel::Field::Date(
                name          =>'lastentrymdate',
                label         =>'Last-Entry Date',
                group         =>'stat',
                searchable    =>0,
                readonly      =>1,
                sqlorder      =>'none',
                dataobjattr   =>'max(forumentry.modifydate)'),
                                    
      new kernel::Field::Text(
                name          =>'lastentry',
                label         =>'Last-Entry ID',
                searchable    =>0,
                group         =>'stat',
                weblinkto     =>'faq::forumentry',
                weblinkon     =>['lastentry'=>'id'],
                readonly      =>1,
                sqlorder      =>'none',
                dataobjattr   =>'max(forumentry.id)'),

      new kernel::Field::Text(
                name          =>'lastworkershort',
                label         =>'Lastworker surname',
                group         =>'stat',
                searchable    =>0,
                depend        =>['lastentry'],
                onRawValue    =>\&faq::lib::forum::getShortLastworker,
                readonly      =>1,
                sqlorder      =>'none'));
                                    
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join forumtopic ".
          "on forumboard.id=forumtopic.forumboard ".
          " left outer join forumentry ".
          "on forumtopic.id=forumentry.forumtopic ";

   return($from);
}

sub SecureSetFilter
{
   my $self=shift;

   my $bo0=$self->getPersistentModuleObject("faq::forumboard");
   $bo0->SecureSetFilter();
   my @boids=map({$_->{id}} $bo0->getHashList(qw(id)));
   return($self->SUPER::SetFilter([{id=>\@boids}],@_));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return(undef);
}



1;
