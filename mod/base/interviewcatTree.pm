package base::interviewcatTree;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'id',
                label         =>'ID',
                dataobjattr   =>'interviewcat.id'),

      new kernel::Field::Text(
                name          =>'start_up_id',
                label         =>'Start_upsearch_ID'),

      new kernel::Field::Text(
                name          =>'start_down_id',
                label         =>'Start_downsearch_ID'),

      new kernel::Field::Text(
                name          =>'level',
                label         =>'parent Level',
                selectfix     =>1,
                dataobjattr   =>'(@entryLevel:=@entryLevel+1)'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'interviewcat.name'),

      new kernel::Field::Text(
                name          =>'label',
                label         =>'Label',
                readonly      =>1,
                searchable    =>0,
                depend        =>['name_label','name'],
                onRawValue    =>sub{
                     my $self=shift;
                     my $current=shift;
                     my $lang=$self->getParent->Lang();

                     if ($current->{'name_label'} ne ""){
                        my $l=extractLangEntry($current->{'name_label'},
                               $lang,80,0);
                        return($l) if (!($l=~m/^\s*$/));
                     }
                     if ($current->{'name'} ne ""){
                        return($current->{'name'});
                     }
                     return("?");
                }),

      new kernel::Field::Text(
                name          =>'name_label',
                label         =>'Name Label',
                readonly      =>1,
                searchable    =>0,
                dataobjattr   =>'interviewcat.frontlabel'),

      new kernel::Field::Group(
                name          =>'mgrgroup',
                AllowEmpty    =>1,
                label         =>'Manager group',
                vjoinon       =>'mgrgroupid'),

      new kernel::Field::Link(
                name          =>'mgrgroupid',
                dataobjattr   =>'interviewcat.mgrgroup'),

   );
   $self->setDefaultView(qw(linenumber id level name name_label label));
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   if ($mode eq "select" && $#filter==0 && ref($filter[0]) eq "HASH" &&
       keys(%{$filter[0]})==1 && exists($filter[0]->{start_up_id})){
      my $start_up_id=$filter[0]->{start_up_id};
      $start_up_id=$start_up_id->[0] if (ref($start_up_id) eq "ARRAY");
      $start_up_id=$$start_up_id     if (ref($start_up_id) eq "SCALAR");
      $start_up_id="UNDEF" if ($start_up_id eq "");
      my $from=<<EOF;

(SELECT    
        \@id AS id, 
        \@id := IF(\@id IS NOT NULL, (SELECT parentID 
                                    FROM interviewcat WHERE id = \@id),
                  NULL) AS parentID
        FROM interviewcat, 
             (SELECT \@id := '$start_up_id', \@entryLevel:=0) AS vars
        WHERE
            \@id IS NOT NULL
    ) AS dat JOIN interviewcat ON dat.id = interviewcat.id

EOF
      return($from);
   }
   if ($mode ne ""){
      $self->LastMsg(ERROR,"not supported query mode=".$mode);
   }
   return("interviewcat");
}

sub getSqlOrder
{
   my $self=shift;
   return("level desc");

}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}





1;
