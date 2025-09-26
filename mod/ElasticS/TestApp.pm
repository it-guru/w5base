package ElasticS::TestApp;
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web::Listedit;
use kernel::DataObj::ElasticSearch;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::ElasticSearch);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(     
            name          =>'id',
            searchable    =>0,
            htmlwidth     =>'90px',  
            group         =>'source',
            dataobjattr   =>'_id',
            label         =>'Id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name          =>'name',
            dataobjattr   =>'_source.name',
            ignorecase    =>1,
            label         =>'Name'),

      new kernel::Field::Text(
            name          =>'fullname',
            dataobjattr   =>'_source.fullname',
            ElasticType   =>'keyword',
            ignorecase    =>1,
            label         =>'Fullname'),

   );
   $self->setDefaultView(qw(id name fullname));
   $self->LimitBackend(100);
   return($self);
}


sub getESindexDefinition
{
   my $self=shift;

   my $indexDef={
      settings=>{
         number_of_shards=>1,
         number_of_replicas=>1
      },
      mappings=>{
         _meta=>{
            version=>10
         },
         properties=>{
            name    =>{type=>'text',
                       fields=> {
                           keyword=> {
                             type=> "keyword",
                             ignore_above=> 256
                           }
                         }
                       },
            fullname=>{type=>'text',
                       fields=> {
                           keyword=> {
                             type=> "keyword",
                             ignore_above=> 256
                           }
                         }
                       },
            lastUpdated=>{type=>'date'},
            dtLastLoad=>{type=>'date'}
         }
      }
   };

   return($indexDef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default");
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift;

   return(1);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}

sub isUploadValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



1;
