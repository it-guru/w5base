package TeamLeanIX::org;
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
            ElasticType   =>'keyword',
            ignorecase    =>1,
            label         =>'Name'),

      new kernel::Field::Text(     
            name          =>'parentId',
            dataobjattr   =>'_source.parentId',
            ignorecase    =>1,
            label         =>'parentId'),

      new kernel::Field::Textarea(
            name          =>'description',
            dataobjattr   =>'_source.description',
            searchable    =>0,
            label         =>'description'),
   );
   $self->setDefaultView(qw(id name parentId));
   $self->LimitBackend(1000);
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TeamLeanIX");
}



sub ORIGIN_Load
{
   my $self=shift;
   my $loadParam=shift;

   my $credentialName="ORIGIN_".$self->getCredentialName();
   my $indexname=$self->ESindexName();
   my $opNowStamp=NowStamp("ISO");

   my ($res,$emsg)=$self->ESrestETLload({
        settings=>{
           number_of_shards=>1,
           number_of_replicas=>1
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
              lastUpdated=>{type=>'date'},
              dtLastLoad=>{type=>'date'}
           }
        }
      },sub {
         my ($session,$meta)=@_;
         my $ESjqTransform="if (length == 0) ".
                           "then ".
                           " { index: { _id: \"__noop__\" } }, ".
                           " { fullname: \"noop\" } ".
                           "else .[] |".
                           "select(".
                           " (.id | type == \"string\") and ".
                           " (.id != null) and  ".
                           " (.id != \"\") ".
                           ") |".
                           "{ index: { _id: .id } } , ".
                           "(. + {dtLastLoad: \$dtLastLoad, ".
                           "fullname: (.id+\": \" +.name)}) ".
                           "end";

         return($self->ORIGIN_Load_BackCall(
             "/v1/orgs",$credentialName,$indexname,$ESjqTransform,$opNowStamp,
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
      msg(ERROR,"something went wrong '$res' in ".$self->Self());
   }
   msg(INFO,"ESrestETLload result=".Dumper($res));
   return($res,$emsg);
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


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/ipaddress.jpg?".$cgi->query_string());
#}


1;
