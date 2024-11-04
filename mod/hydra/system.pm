package hydra::system;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use itil::system;
use tardis::lib::Listedit;
@ISA=qw(itil::system tardis::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Boolean(
                name          =>'foundinhydra',
                label         =>'is system found in hydra',
                depend        =>[qw(name applications ipaddresses
                                    isprod istest isdevel iseducation
                                    isapprovtest isreference iscbreakdown
                                    isapplserver isworkstation isinfrastruct 
                                    isprinter   
                                    isbackupsrv isdatabasesrv iswebserver 
                                    ismailserver
                                    isrouter
                                    isnetswitch isterminalsrv isnas
                                    isloadbalacer isclusternode isembedded)],
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                allowempty    =>1,
                onRawValue    =>\&doQueryHydra),
   );
   $self->setDefaultView(qw(name cistatus mdate foundinhydra));

   return($self);
}


sub doQueryHydra
{
   my $self=shift;
   my $rec=shift;
   my $p=$self->getParent();
   return(undef) if (!defined($rec));
   my $c=$self->Cache();
   my $credentialName="HYDRAatTARDIS";

   my $id=$rec->{id};
   my $systemname=$rec->{name};
   my $systemid=$rec->{systemid};
   my $isclusternode=$rec->{isclusternode};

   my $ipadressesfld=$self->getParent->getField("ipaddresses",$rec);
   my $ipadresses=$ipadressesfld->RawValue($rec);

   my $applicationsfld=$self->getParent->getField("applications",$rec);
   my $applications=$applicationsfld->RawValue($rec);

   my $Authorization=$p->getTardisAuthorizationToken($credentialName);

   #msg(INFO,"Authorization: ".$Authorization);

   my $requesttoken="HOST.".$rec->{id};

   my $qRec={};

   $qRec->{systemname}=$rec->{name};

   $qRec->{opmode}={};
   foreach my $v (qw(isprod istest isdevel iseducation 
                     isapprovtest isreference iscbreakdown)){
      $qRec->{opmode}->{$v}=$rec->{$v};
   }

   $qRec->{systemclass}={};
   foreach my $v (qw(isapplserver isworkstation isinfrastruct isprinter
                     isbackupsrv isdatabasesrv iswebserver ismailserver
                     isrouter
                     isnetswitch isterminalsrv isnas 
                     isloadbalacer isclusternode isembedded)){
      $qRec->{systemclass}->{$v}=$rec->{$v};
   }

   $qRec->{ipaddress}=[];
   foreach my $iprec (@{$ipadresses}){
      push(@{$qRec->{ipaddress}},{
         name=>$iprec->{name},
         networktag=>$iprec->{networktag}
      });
   }
   if ($#{$qRec->{ipaddress}}==-1){
      return(0); # queries without IP-Adresses are sensless
   }             # Info from Guo Chuan per Mail

   my $effectiveprio=99;
   foreach my $arec (@{$applications}){
      if ($arec->{applcustomerprio}<$effectiveprio){
         $effectiveprio=$arec->{applcustomerprio}; 
      }
   }
   $qRec->{effectiveprio}=$effectiveprio;





   my $data;
   eval('use JSON; $data=encode_json($qRec);');
   return(undef) if ($data eq "");

   if ($p->Config->Param("W5BaseOperationMode") eq "dev"){
      #printf STDERR ("$@ qRec=%s\n",$data);
   }

   my $d=$p->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      retry_count=>3,
      retry_interval=>30,
      method=>'POST',
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."darwin/log-events";
         if ($p->Config->Param("W5BaseOperationMode") eq "dev"){
            #msg(INFO,"Call:".$dataobjurl);
         }
         return($dataobjurl);
      },
      data=>$data,
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
         return($data);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "503" || $code eq "500"){  # wengen IF Instabilität
            return({found=>undef},"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data Hydra response");
         return(undef);
      }
   );

   if (ref($d) eq "HASH" &&
       exists($d->{checktstamp}) &&
       exists($d->{found}) &&
       $d->{found}==1){
      return(1);
   }
   if (ref($d) eq "HASH" &&
       exists($d->{found}) &&
       !defined($d->{found})){
      return(undef);
   }
   return(0);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub extractAutoDiscData      # SetFilter Call ist Job des Aufrufers
{
   my $self=shift;
   my @res=();

   $self->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         if ($rec->{foundinhydra}){
            # at this point, there can be nativ scandata be patched to correct
            # scan informations!
            my $version="1.0.0";
            $version=~s/-.*$//;  # remove package version
            my $nowstamp=NowStamp("en");
            my %e=(
               section=>'SOFTWARE',
               scanname=>"Hydra_LogServer_Config",
               scanextra2=>$version,
               quality=>100,
               forcesysteminst=>1,
               allowautoremove=>1,
               processable=>1,
               backendload=>$nowstamp,
               autodischint=>$self->Self.": ".$rec->{id}
            );
            push(@res,\%e);
         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   return(@res);
}














1;
