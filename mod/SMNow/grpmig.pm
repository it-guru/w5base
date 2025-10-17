package SMNow::grpmig;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
            name          =>'sm9_name',
            label         =>'SM9Group'),

      new kernel::Field::Text(     
            name          =>'group_name',
            label         =>'Group-Name'),

      new kernel::Field::Text(     
            name          =>'migrate_group',
            label         =>'Migrate-Group'),

      new kernel::Field::Text(     
            name          =>'migstate',
            dataobjattr   =>'migration_state',
            label         =>'MigState'),

      new kernel::Field::Boolean(     
            name          =>'problem',
            RestFilterType=>'SYSPARMQUERY',
            label         =>'Problem'),

      new kernel::Field::Text(     
            name          =>'golive',
            dataobjattr   =>'go_live_inm',
#            RestFilterType=>'SYSPARMQUERY',   # funktioniert mit der SNow API
#            RestSoftFilter=>0,                # nicht korrekt
#            dayonly       =>1,
            label         =>'go life'),

      new kernel::Field::Number(     
            name          =>'sys_mod_count',
            RestFilterType=>'SYSPARMQUERY',
            label         =>'SysModCount'),

      new kernel::Field::MDate(     
            name          =>'sys_updated_on',
            RestFilterType=>'SYSPARMQUERY',
            RestSoftFilter=>0,
            label         =>'Modification-Date')

   );
   $self->setDefaultView(qw(sm9_name group_name migrate_group migstate
                            problem golive 
                            sys_updated_on));
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
   my $dummyAddr="now/table/x_dtitg_user_mange_group_migration?".
                 "sysparm_fields=sys_id&".
                 "sysparm_query=sys_id%3D000000000000000000000000000000000";

   my $d=$self->CollectREST(
      dbname=>$credentialName,
      timeout=>5,
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
      $self->LastMsg(ERROR,"fail to REST Ping to SMNow");
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
      "now/table/x_dtitg_user_mange_group_migration",  # Path-Templ with var
      $filterset,
      {  
        initQueryParam=>{
          'sysparm_input_display_value'=>"false"
        }
      }
   );
   #msg(INFO,"restFinalAddr=$restFinalAddr");
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
         if (ref($data) eq "HASH" && exists($data->{result}) &&
             ref($data->{result}) eq "ARRAY"){
            $data=$data->{result};
         }
         elsif(ref($data) eq "HASH"){
            $data=[$data];
         }
         map({
            $_=FlattenHash($_);
            #if (exists($_->{go_live_inm}) && $_->{go_live_inm} ne ""){
            #   if ($_->{go_live_inm}=~m/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/){
            #      $_->{go_live_inm}.=" 00:00:00";
            #   }
            #}
            foreach my $k (keys(%$constParam)){
               if (!exists($_->{$k})){
                  $_->{$k}=$constParam->{$k};
               }
            }
         } @$data);
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
   if (!defined(Query->Param("search_migstate"))){
     Query->Param("search_migstate"=>"MERGE MIGRATED OMITTED");
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
