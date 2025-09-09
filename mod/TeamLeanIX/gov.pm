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
use kernel::DataObj::REST;
use tardis::lib::Listedit;
use JSON;
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::REST tardis::lib::Listedit);


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
            dataobjattr   =>'governanceUniqueId',
            label         =>'Id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name          =>'name',
            dataobjattr   =>'name',
            RestFilterType=>'SIMPLE',
            ignorecase    =>1,
            label         =>'Name'),

      new kernel::Field::Text(     
            name          =>'ictoNumber',
            dataobjattr   =>'ictoNumber',
            label         =>'ictoNumber'),

      new kernel::Field::Date(     
            name          =>'lifecycle_active',
            dataobjattr   =>'lifecycle.active',
            searchable    =>0,
            dayonly       =>1,
            label         =>'Active'),

      new kernel::Field::Text(     
            name          =>'lifecycle_status',
            dataobjattr   =>'lifecycle.status',
            searchable    =>0,
            ignorecase    =>1,
            label         =>'Status'),

      new kernel::Field::Date(     
            name          =>'lifecycle_endOfLife',
            dataobjattr   =>'lifecycle.endOfLife',
            searchable    =>0,
            dayonly       =>1,
            label         =>'endOfLife'),

      new kernel::Field::Textarea(     
            name          =>'description',
            dataobjattr   =>'description',
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
            name          =>'orgs',
            label         =>'Orgs',
            group         =>'orgs',
            searchable    =>0,
            vjointo       =>'TeamLeanIX::org',
            vjoinon       =>['relatedOrganizationIds'=>'id'],
            vjoindisp     =>['name']),

      new kernel::Field::Text(     
            name          =>'relatedOrganizationIds',
            dataobjattr   =>'relatedOrganizationIds',
            label         =>'relatedOrganizationIds'),

      new kernel::Field::Text(     
            name          =>'tags',
            dataobjattr   =>'tags',
            label         =>'Tags'),

      new kernel::Field::MDate(
            name              =>'mdate',
            group             =>'source',
            label             =>'Modification-Date',
            searchable        =>0,  # das tut noch nicht
            dataobjattr       =>'lastUpdated'),

   );
   $self->setDefaultView(qw(id ictoNumber name mdate));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TeamLeanIX");
}



#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_cidr"))){
#     Query->Param("search_cidr"=>'10.161.62.20');
#   }
#   if (!defined(Query->Param("search_customer"))){
#     Query->Param("search_customer"=>'CN-DTAG');
#   }
#}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();
   my $Authorization=$self->getTardisAuthorizationToken($credentialName);
   return(undef) if (!defined($Authorization));


   my ($restFinalAddr,$requesttoken,$constParam)=$self->Filter2RestPath(
      ["/v1/govs/{id}",
       "/v1/govs"],
      $filterset,
      {
        initQueryParam=>{
#          'none'=>"1"
        }
      }
   );
   msg(INFO,"restFinalAddr=$restFinalAddr");
   if (!defined($restFinalAddr)){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"unknown error while create restFinalAddr");
      }
      return(undef);
   }

   my $d=$self->CollectREST(
      dbname=>$credentialName,
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apiuser=shift;
         my $headers=['Authorization'=>$Authorization];
         return($headers);
      },
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apipass=shift;
         my $dataobjurl=$baseurl.$restFinalAddr;
         msg(INFO,"dataobjurl=$dataobjurl");
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
         print STDERR Dumper($data);
         if (ref($data) eq "HASH" && exists($data->{governanceUniqueId})){
            $data=[$data];
         }
         #print STDERR Dumper($data->[0]);
         map({
            $_=FlattenHash($_);
            if (exists($_->{lastUpdated}) && $_->{lastUpdated} ne ""){
               $_->{lastUpdated}=~s/^
                                    ([0-9]{4})-([0-9]{2})-([0-9]{2})
                                    T
                                    ([0-9]{2}):([0-9]{2}):([0-9]{2})\.[0-9]+Z$
                                   /$1-$2-$3 $4:$5:$6/x;
            }
            if (exists($_->{'lifecycle.active'}) && 
                $_->{'lifecycle.active'} ne ""){
               $_->{'lifecycle.active'}.=" 12:00:00";
            }
            if (exists($_->{'lifecycle.endOfLife'}) && 
                $_->{'lifecycle.endOfLife'} ne ""){
               $_->{'lifecycle.endOfLife'}.=" 12:00:00";
            }
         } @$data);
         print STDERR Dumper($data);
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
   return(qw(header default orgs contacts  source));
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
