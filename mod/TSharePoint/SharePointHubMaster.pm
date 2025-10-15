package TSharePoint::SharePointHubMaster;
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
            name          =>'shortname',
            dataobjattr   =>'_source.Hub_name_short',
            ignorecase    =>1,
            label         =>'Short Name'),

      new kernel::Field::Text(     
            name          =>'name',
            dataobjattr   =>'_source.Hub_name_medium',
            ignorecase    =>1,
            label         =>'Name'),

      new kernel::Field::Text(     
            name          =>'hubid',
            dataobjattr   =>'_source.{Name}',
            ignorecase    =>1,
            label         =>'HUB-ID'),

      new kernel::Field::Text(     
            name          =>'domainid',
            dataobjattr   =>'_source.Domain_ID',
            group         =>'domain',
            ignorecase    =>1,
            label         =>'Domain-ID'),

      new kernel::Field::Text(     
            name          =>'domain',
            dataobjattr   =>'_source.Domain_name_long',
            group         =>'domain',
            ignorecase    =>1,
            label         =>'Domain-Name'),

      new kernel::Field::Text(     
            name          =>'sdcid',
            dataobjattr   =>'_source.SDC_ID',
            group         =>'domain',
            ignorecase    =>1,
            label         =>'SDC-ID'),

      new kernel::Field::Text(
            name          =>'fullname',
            dataobjattr   =>'_source.Hub_name_long',
            ignorecase    =>1,
            label         =>'Fullname'),

      new kernel::Field::Text(
            name          =>'boit',
            dataobjattr   =>'_source.BO_IT',
            ignorecase    =>1,
            label         =>'BO-IT'),

      new kernel::Field::Text(
            name          =>'boit_email',
            dataobjattr   =>'_source.BO_x0020_IT.Email',
            ignorecase    =>1,
            label         =>'BO-IT EMail'),

      new kernel::Field::Text(
            name          =>'internalid',
            dataobjattr   =>'_source.ItemInternalId',
            group         =>'source',
            ignorecase    =>1,
            label         =>'InternalID'),

      new kernel::Field::Text(
            name          =>'author_email',
            dataobjattr   =>'_source.Author.Email',
            group         =>'source',
            ignorecase    =>1,
            label         =>'Author EMail'),

      new kernel::Field::Text(
            name          =>'editor_email',
            dataobjattr   =>'_source.Editor.Email',
            group         =>'source',
            ignorecase    =>1,
            label         =>'Editor EMail'),

      new kernel::Field::Date(
            name          =>'srcload',
            history       =>0,
            group         =>'source',
            label         =>'Source-Load',
            dataobjattr   =>'_source.dtLastLoad'),

      new kernel::Field::CDate(
            name          =>'cdate',
            group         =>'source',
            label         =>'Creation-Date',
            dataobjattr   =>'_source.Created'),

      new kernel::Field::MDate(
            name          =>'mdate',
            group         =>'source',
            label         =>'Modification-Date',
            dataobjattr   =>'_source.Modified'),

   );
   $self->setDefaultView(qw(shortname hubid domainid sdcid fullname boit));
   $self->LimitBackend(10000);
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
   return(qw(header default domain));
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
   if (defined($rec) || !$self->IsMemberOf(["support","admin"])){
      return(undef);

   }
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
   return(1);
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
            version=>12
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



sub JsonObjectLoad_FullLoad
{
   my $self=shift;
   my $filename=shift;
   my $orgFilename=shift;

   my $credentialName="ORIGIN_".$self->getCredentialName();
   my $indexname=$self->ESindexName();
   my $opNowStamp=NowStamp("ISO");

   if ($W5V2::OperationContext ne "W5Server"){
      my @wrgrp=$self->isWriteValid();
      if (!in_array(\@wrgrp,[qw(ALL default)])){
         printf("%s",msg(ERROR,"no write access to JsonObjectLoad_FullLoad"));
         return(undef);
      }
   }
   else{
      msg(INFO,"allow access by W5V2::OperationContext");
   }

   my ($res,$emsg)=$self->ESrestETLload($self->getESindexDefinition(),
      sub {
         my ($session,$meta)=@_;
         my $ESjqTransform=
             "if (length == 0) then ".
                " { index: { _id: \"__noop__\" } }, ".
                " { fullname: \"noop\" } ".
                "else  .[] | ".
                "select(".
                " (.\"{Identifier}\" != null) and  ".
                " (.\"{Identifier}\" != \"\") ".
                ") |".
                "{ index: { _id: (.\"{Identifier}\" | ".
                   "gsub(\"\%252\"; \":\")) ".
                   "}".
                " } , ".
                "(. + {dtLastLoad: \$dtLastLoad, ".
                "fullname: (\": \" +.\"{name}\")}) ".
             "end";
         return("SHELL","cat '$filename'",[],$ESjqTransform);
      },$indexname,{
        jq=>{
          arg=>{
             dtLastLoad=>$opNowStamp
          }
        }
      }
   );
   if (ref($res) eq "HASH"){
      msg(INFO,"ESrestETLload: ".Dumper($res));
      print(msg(INFO,"_bulk ElasticSearch load ".$res->{items}.
                     " items loaded from $orgFilename"));
   }
   else{
      print(msg(ERROR,"_bulk ElasticSearch fail res=$res ;emsg=$emsg"));
      return(undef);
   }
   return($res->{items});
}

sub ESprepairRawResult
{
   my $self=shift;
   my $data=shift;

   my @result;
   map({
      $_=FlattenHash($_);
   } @$data);
   return(\@result);
}




1;
