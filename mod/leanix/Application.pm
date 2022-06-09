package leanix::Application;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use leanix::lib::Listedit;
use JSON;
@ISA=qw(leanix::lib::Listedit);

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
            label             =>'ID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Link(     
            name              =>'fullname',
            label             =>'fullname'),

      new kernel::Field::Text(     
            name              =>'displayName',
            label             =>'displayName'),

      new kernel::Field::Text(     
            name              =>'name',
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'type',
            searchable        =>'0',
            label             =>'type'),

      new kernel::Field::Text(     
            name              =>'ictoid',
            label             =>'ICTO-ID'),

      new kernel::Field::Text(     
            name              =>'alias',
            label             =>'Alias'),

      new kernel::Field::Text(     
            name              =>'tags',
            group             =>'tags',
            label             =>'tags'),

      new kernel::Field::Text(     
            name              =>'lxState',
            searchable        =>'0',
            label             =>'State'),

      new kernel::Field::SubList(
                name          =>'relations',
                label         =>'Relations',
                searchable    =>0,
                group         =>'relations',
                vjointo       =>\'leanix::Relation',
                vjoinon       =>['id'=>'fromId'],
                vjoindisp     =>['typeToFS','displayNameToFS','type']),

      new kernel::Field::MDate(
            name              =>'mdate',
            group             =>'source',
            label             =>'Modification-Date',
            searchable        =>0,  # das tut noch nicht
            dataobjattr       =>'updatedAt'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id displayName));

   return($self);
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $Authorization=$self->getLeanIXAuthorizationToken();

   if (!defined($Authorization)){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"unknown getLeanIXAuthorizationToken problem");
      }
      return(undef);
   }

   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4LeanIX(
      "Application",
      "id",
      $filterset
   );
   my $cursor;
   my $d=[];
   do{
      my $dBlock=$self->CollectREST(
         requesttoken=>$requesttoken.":".$cursor,
         dbname=>'leanix',
         useproxy=>1,
         url=>sub{
            my $self=shift;
            my $baseurl=shift;
            my $apikey=shift;
            $baseurl.="/"  if (!($baseurl=~m/\/$/));
            my $dataobjurl=$baseurl.$dbclass;
            if ($cursor ne ""){
            #   $dataobjurl=~s/\?.*$//;
               $dataobjurl.="&cursor=".$cursor;
            }
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
  # print STDERR Dumper($data);
            if (ref($data) eq "HASH" && exists($data->{content})){
               return($data);
            }
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
            $self->LastMsg(ERROR,"unexpected data TPC project response");
            return(undef);
         }
      );
      if (exists($dBlock->{data})){
         my $dBlockData=$dBlock->{data};
         $dBlockData=[$dBlockData] if (ref($dBlockData) ne "ARRAY");
         #if ($#{$dBlockData}==0){
         #   printf STDERR ("rawRec=%s\n",Dumper($dBlockData));
         #}
         foreach my $dRec (@{$dBlockData}){
            $self->ExternInternTimestampReformat($dRec,"updatedAt");
            my @tags;
            my %tags;
            foreach my $r (@{$dRec->{tags}}){
               my $key=$r->{name};
               if ($r->{tagGroup}->{shortName} ne ""){
                  $key=$r->{tagGroup}->{shortName}.": ".$key;
               }
               $tags{$key}++;
            }
            @tags=sort(keys(%tags));


            my $rec={
               id=>$dRec->{id},
               displayName=>$dRec->{displayName},
               name=>$dRec->{name},
               type=>$dRec->{type},
               tags=>\@tags,
               lxState=>$dRec->{lxState},
               fullname=>$dRec->{type}.": ".$dRec->{displayName},
               updatedAt=>$dRec->{updatedAt}
            };
            foreach my $fld (@{$dRec->{fields}}){
               if ($fld->{name} eq "alias"){
                  $rec->{alias}=$fld->{data}->{value};
               }
               if ($fld->{name} eq "externalId"){
                  $rec->{ictoid}=$fld->{data}->{externalId};
               }
            }
            push(@{$d},$rec);
         }
      }
      if (exists($dBlock->{cursor})){
         $cursor=$dBlock->{cursor};
      }
      else{
         $cursor=undef;
      }
      if ($#{$d}>=$dBlock->{total}-1){
         $cursor=undef;
      }
   }while($cursor ne "");


 

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
   return(qw(header default tags relations source));
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
#}


1;
