package TeamLeanIX::app;
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
use TeamLeanIX::lib::Listedit;
use JSON;
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::ElasticSearch
        TeamLeanIX::lib::Listedit);


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

      new kernel::Field::Interface(
            name          =>'fullname',
            dataobjattr   =>'_source.fullname',
            ElasticType   =>'keyword',
            ignorecase    =>1,
            label         =>'Fullname'),


      new kernel::Field::Date(
            name          =>'lifecycle_active',
            dataobjattr   =>'_source.lifecycle.active',
            dayonly       =>1,
            label         =>'Active'),

      new kernel::Field::Text(
            name          =>'lifecycle_status',
            dataobjattr   =>'_source.lifecycle.status',
            searchable    =>0,
            ignorecase    =>1,
            label         =>'Status'),

      new kernel::Field::Date(
            name          =>'lifecycle_endOfLife',
            dataobjattr   =>'_source.lifecycle.endOfLife',
            dayonly       =>1,
            label         =>'endOfLife'),

      new kernel::Field::Textarea(
            name          =>'description',
            dataobjattr   =>'_source.description',
            searchable    =>0,
            label         =>'description'),



      new kernel::Field::Text(     
            name          =>'ictoNumber',
            dataobjattr   =>'_source.ictoNumber',
            weblinkto     =>'TeamLeanIX::gov',
            weblinkon     =>['ictoNumber'=>'ictoNumber'], 
            label         =>'ictoNumber'),

      new kernel::Field::Text(     
            name          =>'applicationType',
            dataobjattr   =>'_source.applicationType',
            label         =>'applicationType'),

      new kernel::Field::Text(     
            name          =>'tags',
            dataobjattr   =>'source_tags',
            label         =>'Tags'),
   );
   $self->setDefaultView(qw(id ictoNumber applicationType name));
   $self->LimitBackend(1000);
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TeamLeanIX");
}

sub getESindexDefinition
{
   my $self=shift;
   my $indexDef={
      settings=>{
         number_of_shards=>1,
         number_of_replicas=>1,
         analysis=>{
            normalizer=> {
              lowercase_normalizer=> {
                type=>"custom",
                filter=>["lowercase"]
              }
            }
         }
      },
      mappings=>{
         _meta=>{
            version=>11
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
            ictoNumber=>{type=>'text',
                       fields=> {
                           keyword=> {
                             type=> "keyword",
                             ignore_above=> 256,
                             normalizer=> "lowercase_normalizer"
    
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



sub ORIGIN_Load
{
   my $self=shift;
   my $loadParam=shift;

   my $credentialName="ORIGIN_".$self->getCredentialName();
   my $indexname=$self->ESindexName();
   my $opNowStamp=NowStamp("ISO");

   my ($res,$emsg)=$self->ESrestETLload($self->getESindexDefinition(),
      sub {
         my ($session,$meta)=@_;
         my $ESjqTransform="if (length == 0) ".
                           "then ".
                           " { index: { _id: \"__noop__\" } }, ".
                           " { fullname: \"noop\" } ".
                           "else  .[] | ".
                            "select(".
                            " (.applicationUniqueId | type == \"string\") and ".
                            " (.applicationUniqueId != null) and  ".
                            " (.applicationUniqueId != \"\") ".
                            ") |".
                            "{ index: { _id: .applicationUniqueId } } , ".
                            "(. + {dtLastLoad: \$dtLastLoad, ".
                            "fullname: (.ictoNumber+\": \" +.name)}) ".
                            "end";

         return($self->ORIGIN_Load_BackCall(
             "/v1/apps",$credentialName,$indexname,$ESjqTransform,$opNowStamp,
             $session,$meta)
         );
      },$indexname,{
        session=>{loadParam=>$loadParam},
        jq=>{
          arg=>{
             dtLastLoad=>$opNowStamp
          }
        }
      }
   );
   if (ref($res) ne "HASH"){
      Stacktrace(1);
      msg(ERROR,"something ($emsg) went wrong '$res' in ".$self->Self());
   }
   msg(INFO,"ESrestETLload result=".Dumper($res));
   return($res,$emsg);

}




sub ESprepairRawRecord
{
   my $self=shift;
   my $rec=shift;

   foreach my $f (qw(_source.lifecycle.endOfLife
                     _source.lifecycle.phaseOut
                     _source.lifecycle.active)){
      if (exists($rec->{$f}) && $rec->{$f} ne ""){
         $rec->{$f}.=" 12:00:00";
      }
   }
}














sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default component network subnet vlan source));
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
   return(undef);
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
