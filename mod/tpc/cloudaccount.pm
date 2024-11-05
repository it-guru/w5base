package tpc::cloudaccount;
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
use tpc::lib::Listedit;
use JSON;
@ISA=qw(tpc::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(     
            name              =>'id',
            group             =>'source',
            htmldetail        =>'NotEmpty',
            label             =>'CloudAccountID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'name',
            ignorecase        =>1,
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'cloudAccountControlHostName',
            ignorecase        =>1,
            label             =>'cloudAccountControlHostName'),

      new kernel::Field::Text(     
            name              =>'cloudAccountType',
            ignorecase        =>1,
            label             =>'cloudAccountType'),

      new kernel::Field::Container(
            name              =>'cloudAccountProperties',
            label             =>'cloudAccountProperties',
            uivisible         =>sub{
               my $self=shift;
               return(1) if ($self->getParent->IsMemberOf("admin"));
               return(0);
            },
            searchable        =>0),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name cloudAccountType cloudAccountControlHostName));

   return($self);
}

sub getCredentialName
{
   my $self=shift;

   return("TPX");
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my $Authorization=$self->getVRealizeAuthorizationToken($credentialName);

   if (!defined($Authorization)){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"unknown getVRealizeAuthorizationToken problem");
      }
      return(undef);
   }

   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4vRealize(
      "cloud-accounts","id",
      $filterset
   );
   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      retry_count=>3,
      retry_interval=>10,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."iaas/".$dbclass;
         return($dataobjurl);
      },

      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $headers=['Authorization'=>$Authorization,
                      'Content-Type'=>'application/json'];
 
         return($headers);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{content})){
            $data=$data->{content};
         }
         if (ref($data) ne "ARRAY"){
            $data=[$data];
         }
         map({
            $_->{cloudAccountControlHostName}=undef;
            if (ref($_->{cloudAccountProperties}) eq "HASH"){
               $_->{cloudAccountControlHostName}=
                   $_->{cloudAccountProperties}->{hostName};
            }

         } @$data);
         return($data);
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
         $self->LastMsg(ERROR,"unexpected data TPC cloudaccount response");
         return(undef);
      }
   );

   #printf STDERR ("p=%s\n",Dumper($d)) if (ref($d) eq "ARRAY" && $#{$d}==0);

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

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default));
}


1;
