package SMNow::sys_user_group;
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
use JSON;
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::REST);

#
# ServiceNow API:
# https://docs.servicenow.com/de-DE/bundle/xanadu-api-reference/page/integrate/inbound-rest/concept/c_TableAPI.html
#
#

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
            name          =>'sys_id',
            RestFilterType=>'SYSPARMQUERY',
            label         =>'SysID'),

      new kernel::Field::Text(     
            name          =>'name',
            RestFilterType=>'SYSPARMQUERY',
            label         =>'group name'),

      new kernel::Field::Interface(     
            name          =>'fullname',
            RestFilterType=>'SYSPARMQUERY',
            dataobjattr   =>'name',
            label         =>'full group name'),

      new kernel::Field::Text(     
            name          =>'manager',
            dataobjattr   =>'manager',
            RestSoftFilter=>0,       # because return matches not query string
            searchable    =>0,
            label         =>'manager'),

      new kernel::Field::Text(     
            name          =>'deputy',
            dataobjattr   =>'u_deputy',
            RestSoftFilter=>0,       # because return matches not query string
            searchable    =>0,
            label         =>'deputy'),

      new kernel::Field::Boolean(     
            name          =>'active',
            searchable    =>'0',
            dataobjattr   =>'active',
            label         =>'active'),

      new kernel::Field::Text(     
            name          =>'type',
            RestFilterType=>'SYSPARMQUERY',
            RestSoftFilter=>0,       # because return matches not query string
            dataobjattr   =>'type',
            label         =>'type'),

      new kernel::Field::Text(     
            name          =>'email',
            dataobjattr   =>'email',
            label         =>'E-Mail'),

      new kernel::Field::Textarea(     
            name          =>'description',
            label         =>'description'),

      new kernel::Field::Number(     
            name          =>'sys_mod_count',
            RestFilterType=>'SYSPARMQUERY',
            label         =>'SysModCount'),

      new kernel::Field::MDate(     
            name          =>'mdate',
            RestFilterType=>'SYSPARMQUERY',
            RestSoftFilter=>0,
            dataobjattr   =>'sys_updated_on',
            label         =>'Modification-Date'),

      new kernel::Field::Text(
                name          =>'srcsys',
                label         =>'Source-System',
                dataobjattr   =>'source'),

   );
   $self->setDefaultView(qw(name sys_id type manager deputy sys_updated_on srcsys));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("SMNOW");
}

sub getDummyRequest
{
   my $self=shift;

   my $credentialName=$self->getCredentialName();
   my $dummyAddr="now/table/sys_user_group?".
                 "sysparm_fields=sys_id&".
                 "sysparm_query=name%3Dadmin";

   my $d=$self->CollectREST(
      dbname=>$credentialName,
      timeout=>15,
      retry_count=>3,
      retry_interval=>30,
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apiuser=shift;
         my $headers=[Authorization =>'Basic '.
                                      encode_base64($apiuser.':'.$apikey)];

         return($headers);
      },
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apipass=shift;
         my $dataobjurl=$baseurl.$dummyAddr;
         #$dataobjurl=~s/smnow.telekom.de/smnow.telekom.de:444/g;
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
         return(undef);
      },
   );

   return($d);
}


sub Ping
{
   my $self=shift;

   my $errors;
   my $d;
   # Ping is for checking backend connect, without any error displaying ...
   {
      open local(*STDERR), '>', \$errors;
      eval('
       $d=$self->getDummyRequest();
      ');
   }
   if ((!defined($d) ||
         ref($d) ne "HASH" ||
        !exists($d->{result}) ||
         ref($d->{result}) ne "ARRAY") && !$self->LastMsg()){
      #$self->LastMsg(ERROR,"fail to REST Ping to SMNow");
      $d=undef;
   }
   if (!$self->LastMsg()){
      if ($errors){
         foreach my $emsg (grep(!/INFO:/,split(/[\n\r]+/,$errors))){
            $self->SilentLastMsg(ERROR,$emsg);
         }
      }
   }

   return(0) if (!defined($d));
   return(1);

}





sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my ($restFinalAddr,$requesttoken,$constParam)=$self->Filter2RestPath(
      "now/table/sys_user_group",  
      $filterset,
      { 
        initQueryParam=>{
          'sysparm_input_display_value'=>"false",
          'sysparm_display_value'=>"all",
          'sysparm_exclude_reference_link'=>"true",
          'sysparm_limit'=>"999999"
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
      timeout=>30,
      retry_count=>5,
      retry_interval=>30,
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apiuser=shift;
         my $headers=[Authorization =>'Basic '.
                                      encode_base64($apiuser.':'.$apikey)];

         return($headers);
      },
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apipass=shift;
         my $dataobjurl=$baseurl.$restFinalAddr;
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
         #print STDERR Dumper($data);
         if (ref($data) eq "HASH" && exists($data->{result}) &&
             ref($data->{result}) eq "ARRAY"){
            $data=$data->{result};
         }
         elsif(ref($data) eq "HASH"){
            $data=[$data];
         }
         #print STDERR Dumper($data->[0]);
         map({
            $_=FlattenHash($_);
            if (exists($_->{active}) && $_->{active} ne ""){
               if ($_->{active} eq "1" || lc($_->{active}) eq "true"){
                  $_->{active}=1;
               }
               else{
                  $_->{active}=0;
               }
            }
            if (exists($_->{type}) && $_->{type} ne ""){
               $_->{type}=[split(/\s*,\s*/,$_->{type})];
            }
            foreach my $k (keys(%$constParam)){
               if (!exists($_->{$k})){
                  $_->{$k}=$constParam->{$k};
               }
            }
         } @$data);
         #print STDERR Dumper($data);
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
   return(qw(header default source));
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_name"))){
     Query->Param("search_name"=>"DT.HUB.DE.DAR*");
   }
   if (!defined(Query->Param("search_type"))){
     Query->Param("search_type"=>"*52e03b172b703d10c0fb4cfbad01a081* ".
                                 "*0551bb172b703d10c0fb4cfbad01a0b0* ".
                                 "*d98b56fcfc8aded85dcff689977724aa* ".
                                 "*654da04a2b61651053504cfbad01a094* ".
                                 "*297a61de2b30fd90c0fb4cfbad01a086* ".
                                 "*dcd035702b1c3150c0fb4cfbad01a05b*");
   }
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
