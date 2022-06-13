package leanix::Relation;
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

     new kernel::Field::Text(
            name              =>'type',
            searchable        =>'0',
            label             =>'type'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     
            name              =>'fromId',
            group             =>'from',
            label             =>'fromId'),

      new kernel::Field::Text(     
            name              =>'typeFromFS',
            group             =>'from',
            label             =>'typeFromFS'),

      new kernel::Field::Text(     
            name              =>'toId',
            group             =>'to',
            label             =>'toId'),

      new kernel::Field::Text(     
            name              =>'typeToFS',
            group             =>'to',
            label             =>'typeToFS'),

      new kernel::Field::Text(     
            name              =>'dataobjToFS',
            group             =>'to',
            label             =>'dataobjToFS'),

      new kernel::Field::Text(     
            name              =>'displayNameToFS',
            group             =>'to',
            label             =>'displayNameToFS'),

      new kernel::Field::MultiDst(     
            name              =>'displayNameTo',
            group             =>'to',
            htmlwidth         =>'300px',
            dst               =>[
                                'leanix::BusinessCapability'=>'displayName',
                                'leanix::Application'=>'displayName',
                                'leanix::Process'=>'displayName',
                                ],
            label             =>'displayNameTo',
            dsttypfield       =>'dataobjToFS',
            dstidfield        =>'toId'),

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
      "services/pathfinder/v1/factSheets/{fromId}/relations",
      "fromId",
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
         #  printf STDERR ("rawRec=%s\n",Dumper($dBlockData));
         foreach my $dRec (@{$dBlockData}){
            my $rec={
               id=>$dRec->{id},
               fromId=>$dRec->{fromId},
               toId=>$dRec->{toId},
               type=>$dRec->{type},
               typeToFS=>$dRec->{typeToFS},
               dataobjToFS=>"leanix::".$dRec->{typeToFS},
               displayNameToFS=>$dRec->{displayNameToFS},
               displayNameTo=>$dRec->{displayNameToFS},
            };
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
   return(qw(header default from to source));
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
#}


1;
