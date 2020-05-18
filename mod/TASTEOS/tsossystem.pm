package TASTEOS::tsossystem;
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
      new kernel::Field::Id(     
            name              =>'id',
            searchable        =>1,
            htmldetail        =>'NotEmpty',
            label             =>'SystemID'),

      new kernel::Field::Text(     
            name              =>'name',
            searchable        =>1,
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'ictoNumber',
            searchable        =>1,
            label             =>'ICTO-ID'),

      new kernel::Field::Text(     
            name              =>'description',
            searchable        =>1,
            label             =>'Description'),

      new kernel::Field::SubList(
                name          =>'machines',
                label         =>'Machines',
                group         =>'machines',
                searchable    =>0,
                vjointo       =>'TASTEOS::tsosmachine',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['name','id']),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name ictoNumber description));
   return($self);
}

sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $filter=$filterset->{FILTER}->[0];
   my $query=$self->decodeFilter2Query4TASTEOS($filter);

   my $dbclass="icto/system-metadata";

   my $d=$self->CollectREST(
      dbname=>'TASTEOS',
      requesttoken=>"SEARCH.".time(),
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
         my $headers=['access-token'=>$apikey,
                      'Content-Type'=>'application/json'];
 
         return($headers);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "ARRAY"){
            return($data);
         }
         else{
            $self->LastMsg(ERROR,"unexpected data structure from REST call");
         }
         return(undef);
      }
   );
   return($d);
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


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (effVal($oldrec,$newrec,"name") eq ""){
      $self->LastMsg(ERROR,"invalid name specified");
      return(undef);
   }

   return(1);
}

sub InsertRecord
{
   my $self=shift;
   my $newrec=shift;  # hash ref

   my $dbclass="systems";

   my $d=$self->CollectREST(
      dbname=>'TASTEOS',
      method=>'POST',
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
         return(['access-token'=>$apikey,
                 'name'=>$newrec->{name},
                 'icto'=>$newrec->{ictoNumber},
                 'description'=>$newrec->{description},
                 'Content-Type','application/json']);
      },
      preprocess=>sub{   # create a valid JSON response
         my $self=shift;
         my $d=shift;
         $d=trim($d);
         $d=~s/'//g;
         $d=~s/"//g;
         my $resp="{\"systemid\":\"$d\"}";
         return($resp);
      }
   );

   return($d->{systemid});
}


sub UpdateRecord
{
   my $self=shift;
   my $newrec=shift; 
   my $flt=shift; 

   my $dflt=$self->decodeFilter2Query4TASTEOS($flt);
   my $id=$dflt->{id};

   if ($id eq ""){
      $self->LastMsg(ERROR,"update error - missing id");
      return(undef);
   }

   my %upd=();
   foreach my $k (keys(%$newrec)){
      my $dstk=$k;
      $dstk="icto" if ($dstk eq "ictoNumber");
      $upd{$dstk}=$newrec->{$k};
   }


   my $dbclass="systems/$id";

   my ($d,$code,$message)=$self->CollectREST(
      dbname=>'TASTEOS',
      requesttoken=>"UPD.".$id.".".time(),
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
         return(['access-token'=>$apikey,
                 %upd,
                 'Content-Type','application/json']);
      },
      preprocess=>sub{   # create a valid JSON response
         my $self=shift;
         my $d=shift;
         my $code=shift;
         my $message=shift;
         my $resp="[]";
         return($resp);
      }
   );
   if ($code eq "200"){
      return(1);
   }
   return(undef);
}


sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;  # hash ref

   my $dbclass="systems/$oldrec->{id}";

   my ($d,$code,$message)=$self->CollectREST(
      dbname=>'TASTEOS',
      method=>'DELETE',
      requesttoken=>"DEL.".$oldrec->{id},
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
         return(['access-token'=>$apikey,
                 'Content-Type','application/json']);
      },
      preprocess=>sub{   # create a valid JSON response
         my $self=shift;
         my $d=shift;
         $d=trim($d);
         if ($d eq ""){
            $d="0";
         }
         my $resp="{\"exitcode\":\"$d\"}";
         return($resp);
      }
   );
   if ($code eq "200"){
      return(1);
   }
   return(undef);
}











1;
