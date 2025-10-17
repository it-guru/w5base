package TASTEOS::tsossystemacl;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use TASTEOS::lib::Listedit;
use JSON;
@ISA=qw(TASTEOS::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(     
            name               =>'systemid',
            label              =>'SystemID'),

      new kernel::Field::Text(     
            name               =>'email',
            searchable         =>1,
            htmlwidth          =>'200px',
            label              =>'EMail'),

      new kernel::Field::Boolean(
            name              =>'readwrite',
            dataobjattr       =>'readwrite',
            label             =>'ReadWrite'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(systemid email readwrite));
   return($self);
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
   if ($self->IsMemberOf("admin")){
      return("default");
   }
   return(undef);
}



sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   $self->LastMsg(ERROR,"search not implemented");
   return(undef);
}





sub InsertRecord
{
   my $self=shift;
   my $newrec=shift;  # hash ref


   my %new;
   foreach my $k (keys(%$newrec)){
      my $dk=$k;
      $dk="systemId" if ($k eq "systemid");
      $dk="read-write" if ($k eq "readwrite");
      $new{$dk}=$newrec->{$k};
      $new{$dk}=$new{$dk}->[0] if (ref($new{$dk}) eq "ARRAY");
      if ($k eq "readwrite"){
         if ($new{$dk}){
            $new{$dk}="true";
         }
         else{
            $new{$dk}="false";
         }
      }
   }
   my $dbclass="systems/$new{systemId}/permissions";

   delete($new{systemId});


   my $d=$self->CollectREST(
      dbname=>'TASTEOS',
      requesttoken=>"INS.".$newrec->{email}.".".$newrec->{systemid}.time(),
      method=>'PUT',
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl.$dbclass;
         return($dataobjurl);
      },
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $h=['access-token'=>$apikey,
                 %new,
                 'Content-Type','application/json'];
         my %h=@$h;
         return($h);
      },
      preprocess=>sub{   # create a valid JSON response
         my $self=shift;
         my $d=shift;
         my $code=shift;
         my $message=shift;
         my $resp="{\"lastmsg\":\"OK\"}";
         return($resp);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "409"){  # 409 means, email is not in whitelist
            return({lastmsg=>'OK'},"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data TSOS response");
         return(undef);
      },
   );
   $self->LastMsg(INFO,$d->{lastmsg});
   return($d->{lastmsg});
}


sub UpdateRecord
{
   my $self=shift;
   my $newrec=shift; 
   my $flt=shift; 

   $self->LastMsg(ERROR,"update not implemented");
   return(undef);

#   my $dflt=$self->decodeFilter2Query4TASTEOS($flt);
#   my $id=$dflt->{id};
#
#   if ($id eq ""){
#      $self->LastMsg(ERROR,"update error - missing id");
#      return(undef);
#   }
#
#   my %upd=();
#   foreach my $k (keys(%$newrec)){
#      my $kk=$k;
#      $kk="systemId" if ($k eq "systemid");  # systemid->systemId map
#      $upd{$kk}=$newrec->{$k};
#   }
#
#
#   my $dbclass="machines/$id";
#
#   #printf STDERR ("fifi UpdateRecord: $dbclass %s\n",Dumper(\%upd));
#
#   my ($d,$code,$message)=$self->CollectREST(
#      dbname=>'TASTEOS',
#      requesttoken=>"UPD.".$id.".".time(),
#      method=>'PUT',
#      url=>sub{
#         my $self=shift;
#         my $baseurl=shift;
#         my $apikey=shift;
#         $baseurl.="/"  if (!($baseurl=~m/\/$/));
#         my $dataobjurl=$baseurl.$dbclass;
#         return($dataobjurl);
#      },
#      content=>sub{
#         my $self=shift;
#         my $baseurl=shift;
#         my $apikey=shift;
#         my $d=encode_json(\%upd);
#         #printf STDERR ("content=$d\n");
#         return($d);
#      },
#      headers=>sub{
#         my $self=shift;
#         my $baseurl=shift;
#         my $apikey=shift;
#         return(['access-token'=>$apikey,
#                 'Content-Type','application/json']);
#      },
#      preprocess=>sub{   # create a valid JSON response
#         my $self=shift;
#         my $d=shift;
#         my $code=shift;
#         my $message=shift;
#         my $resp="[]";
#         return($resp);
#      }
#   );
#   if ($code eq "200"){
#      return(1);
#   }
#   return(undef);
}


sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;  # hash ref

   $self->LastMsg(ERROR,"delete not implemented");
   return(undef);

#   my $dbclass="machines/$oldrec->{id}";
#
#   my ($d,$code,$message)=$self->CollectREST(
#      dbname=>'TASTEOS',
#      method=>'DELETE',
#      requesttoken=>"DEL.".$oldrec->{id},
#      url=>sub{
#         my $self=shift;
#         my $baseurl=shift;
#         my $apikey=shift;
#         $baseurl.="/"  if (!($baseurl=~m/\/$/));
#         my $dataobjurl=$baseurl.$dbclass;
#         return($dataobjurl);
#      },
#      headers=>sub{
#         my $self=shift;
#         my $baseurl=shift;
#         my $apikey=shift;
#         return(['access-token'=>$apikey,
#                 'machineId'=>$oldrec->{id},
#                 'Content-Type','application/json']);
#      },
#      preprocess=>sub{   # create a valid JSON response
#         my $self=shift;
#         my $d=shift;
#         $d=trim($d);
#         if ($d eq ""){
#            $d="0";
#         }
#         my $resp="{\"exitcode\":\"$d\"}";
#         return($resp);
#      }
#   );
#   if ($code eq "200"){
#      return(1);
#   }
#   return(undef);
}



1;
