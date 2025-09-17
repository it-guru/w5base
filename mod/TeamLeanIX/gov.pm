package TeamLeanIX::gov;
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
            group         =>'source',
            dataobjattr   =>'_id',
            label         =>'Id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Interface(     
            name          =>'fullname',
            dataobjattr   =>'_source.fullname',
            ElasticType   =>'keyword',
            ignorecase    =>1,
            label         =>'Fullname'),

      new kernel::Field::Text(     
            name          =>'name',
            ElasticType   =>'keyword',
            dataobjattr   =>'_source.name',
            ignorecase    =>1,
            label         =>'Name'),

      new kernel::Field::Text(     
            name          =>'ictoNumber',
            caseignore    =>1,
            dataobjattr   =>'_source.ictoNumber',
            label         =>'ictoNumber'),

      new kernel::Field::Date(     
            name          =>'lifecycle_active',
            dataobjattr   =>'_source.lifecycle.active',
            dayonly       =>1,
            label         =>'Active'),

      new kernel::Field::Text(
            name          =>'organisation',
            label         =>'Organisation',
            group         =>'orgs',
            depend        =>['orgs'],
            onRawValue    =>sub{
               my $self=shift;
               my $current=shift;

               my $fld=$self->getParent->getField("orgs",$current);
               my $orgs=$fld->RawValue($current);

               my @orgnames;
               if (ref($orgs) eq "ARRAY"){
                  foreach my $orgrec (@{$orgs}){
                     push(@orgnames,$orgrec->{name});
                  }
               }
               @orgnames=sort(@orgnames);
               return($orgnames[0]);
            }),

      new kernel::Field::Group(
            name          =>'orgarea',
            readonly      =>1,
            group         =>'orgs',
            label         =>'mapped W5Base-OrgArea',
            vjoinon       =>'orgareaid'),

      new kernel::Field::Link(
            name          =>'orgareaid',
            label         =>'OrgAreaID',
            group         =>'orgs',
            depend        =>['organisation'],
            onRawValue    =>sub{
               my $self=shift;
               my $current=shift;
               my $grp=getModuleObject($self->getParent->Config,
                                           "base::grp");
               my $newrec={};
               my $d;
               $newrec->{fullname}=$current->{organisation};
               my @grpid=$grp->getIdByHashIOMapped(
                            $self->getParent->Self,
                            $newrec,DEBUG=>\$d);
               if ($#grpid>=0){
                  return($grpid[0]);
               }
               return();
            }),

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

      new kernel::Field::SubList(
            name          =>'contacts',
            label         =>'Contacts',
            searchable    =>0,
            group         =>'contacts',
            vjointo       =>'TeamLeanIX::lnkcontact_gov',
            vjoinon       =>['id'=>'id'],
            vjoindisp     =>['email','name','role'],
            vjoininhash   =>['name','role','email']),

      new kernel::Field::SubList(
            name          =>'apps',
            label         =>'Apps',
            group         =>'apps',
            searchable    =>0,
            vjointo       =>'TeamLeanIX::app',
            vjoinon       =>['ictoNumber'=>'ictoNumber'],
            vjoindisp     =>['id','applicationType','name']),

      new kernel::Field::SubList(
            name          =>'orgs',
            label         =>'Orgs',
            group         =>'orgs',
            searchable    =>0,
            vjointo       =>'TeamLeanIX::org',
            vjoinon       =>['relatedOrganizationIds'=>'id'],
            vjoindisp     =>['name']),

      new kernel::Field::Text(     
            name          =>'relatedOrganizationIds',
            searchable    =>0,
            dataobjattr   =>'_source.relatedOrganizationIds',
            label         =>'relatedOrganizationIds'),

      new kernel::Field::Text(     
            name          =>'tags',
            searchable    =>0,
            dataobjattr   =>'_source.tags',
            label         =>'Tags'),

      new kernel::Field::Date(
            name          =>'srcload',
            history       =>0,
            group         =>'source',
            label         =>'Source-Load',
            dataobjattr   =>'_source.dtLastLoad'),

      new kernel::Field::MDate(
            name          =>'mdate',
            group         =>'source',
            label         =>'Modification-Date',
            dataobjattr   =>'_source.lastUpdated'),

   );
   $self->setDefaultView(qw(id ictoNumber name lifecycle_status 
                            lifecycle_endOfLife mdate));
   $self->LimitBackend(10000);
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

   my $credentialName="ORIGIN_".$self->getCredentialName();
   my $indexname=$self->ESindexName();
   my $opNowStamp=NowStamp("ISO");

   my ($res,$emsg)=$self->ESrestETLload({
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
              version=>14
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
      },sub {
         my ($session,$meta)=@_;

         if ($session->{loopCount}==0){
            $session->{LastRequest}=0;
            my $ESjqTransform=".[] |".
                            "{ index: { _id: .governanceUniqueId } } , ".
                            "(. + {dtLastLoad: \$dtLastLoad, ".
                            "fullname: (.ictoNumber+\": \" +.name)})";

            return($self->ORIGIN_Load_BackCall(
                "/v1/govs",$credentialName,$indexname,
                           $ESjqTransform,$opNowStamp,
                $session,$meta)
            );
         }
         elsif ($session->{loopCount}==1){
            $session->{LastRequest}=1;
            my $ESjqTransform="if (length == 0) ".
                              "then ".
                              " { index: { _id: \"__noop__\" } }, ".
                              " { fullname: \"noop\" } ".
                              "else .[] |".
                              "select(".
                              " (.externalId | type == \"string\") and ".
                              " (.externalId | startswith(\"SPL-\")) ".
                              ") |".
                              "{ index: { _id: .platformUniqueId } } , ".
                              "(. + {".
                              "dtLastLoad: \$dtLastLoad, ".
                              "fullname: (.externalId+\": \" +.name),".
                              "ictoNumber: .externalId ".
                              "}) ".
                              "end";

            return($self->ORIGIN_Load_BackCall(
                "/v1/platforms",$credentialName,$indexname,
                           $ESjqTransform,$opNowStamp,
                $session,$meta)
            );
         }
         return(undef);
      },$indexname,{
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
   return($res,$emsg);
}




sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my $indexname=$self->ESindexName();

   my ($restFinalAddr,$requesttoken,$constParam,$data)=
      $self->Filter2RestPath(
         $indexname,$filterset
   );
   if (!defined($restFinalAddr)){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"unknown error while create restFinalAddr");
      }
      return(undef);
   }
   #printf STDERR ("ESquery=%s\n\n",$data);

   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      data=>$data,
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apiuser=shift;
         my $headers=[
            Authorization =>'Basic '.encode_base64($apiuser.':'.$apikey)
         ];
         if ($data ne ""){
            push(@$headers,"Content-Type","application/json");
         }
         return($headers);
      },
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apipass=shift;
         my $dataobjurl=$baseurl.$restFinalAddr;
         msg(INFO,"ESqueryURL=$dataobjurl");
         return($dataobjurl);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "404"){  # 404 bedeutet nicht gefunden
            return([],"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data from backend %s",$self->Self());
         return(undef);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
   #      print STDERR Dumper($data);
         if (ref($data) eq "HASH"){
            if (exists($data->{hits})){
               if (exists($data->{hits}->{hits})){
                  $data=$data->{hits}->{hits};
               }
            }
            else{
               $data=[$data]
            }
         }
         #print STDERR Dumper($data->[0]);
         map({
            $_=FlattenHash($_);
            foreach my $f (qw(_source.lifecycle.endOfLife 
                              _source.lifecycle.phaseOut
                              _source.lifecycle.active)){
               if (exists($_->{$f}) && $_->{$f} ne ""){
                  $_->{$f}.=" 12:00:00";
               }
            }
         } @$data);
   #      print STDERR Dumper($data->[0]);
         return($data);
      }
   );

   return($d);
}





sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default orgs apps contacts  source));
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
