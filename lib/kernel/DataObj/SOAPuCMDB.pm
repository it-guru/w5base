package kernel::DataObj::SOAPuCMDB;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use lib('/opt/uCMDB/perl-api');
use strict;
use vars qw(@ISA);
use kernel;
use kernel::DataObj;
use Time::HiRes qw(gettimeofday tv_interval);
use Text::ParseWords;
use WebService::uCMDB;
use UNIVERSAL;
@ISA    = qw(kernel::DataObj UNIVERSAL);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   return($self);
}

sub AddSoapPartner
{
   my $self=shift;
   my $partnername=shift;
   my $ucmdbobject=shift;
   my $debug=0;

   return($self->{SOAP}) if (defined($self->{SOAP}));

   my %p=();

   $p{WEBSERVICEUSER}=$self->Config->Param('WEBSERVICEUSER');
   $p{WEBSERVICEPASS}=$self->Config->Param('WEBSERVICEPASS');
   $p{WEBSERVICEPROXY}=$self->Config->Param('WEBSERVICEPROXY');


   foreach my $v (qw(WEBSERVICEUSER WEBSERVICEPASS WEBSERVICEPROXY)){
      if (ref($p{$v}) ne "HASH" || !defined($p{$v}->{$partnername}) ||
          $p{$v}->{$partnername} eq ""){
         my $msg="missing essential config parameter $v for $partnername";
         return("InitERROR",$msg);
      }
      $p{$v}=$p{$v}->{$partnername};
   }
   my $px=$p{WEBSERVICEPROXY};

   my ($proto,$host,$port,$path,$loginuser,$loginpass);
   if (my ($p1,$p2,$p3,$p4)=$px=~m#^([a-z]+)://([^:]+):(\d+)(/.*)$#){
      $proto=$p1;
      $host=$p2;
      $port=$p3;
      $path=$p4;
   }
   $loginuser=$p{WEBSERVICEUSER};
   $loginpass=$p{WEBSERVICEPASS};

   if (0){
      msg(ERROR,"SOAPuCMDB - Adapter");
      msg(ERROR,"SOAPuCMDB : user='$loginuser'");
      msg(ERROR,"SOAPuCMDB : pass='$loginpass'");
      msg(ERROR,"SOAPuCMDB : proto = $proto");
      msg(ERROR,"SOAPuCMDB : host  = $host ");
      msg(ERROR,"SOAPuCMDB : port  = $port ");
      msg(ERROR,"SOAPuCMDB : path  = $path ");
   }
   $self->{SOAP}=new WebService::uCMDB::Adapter(

      debug=>$debug, user=>$loginuser, password=>$loginpass,
      application=>"W5Base($ENV{REMOTE_USER})",

      host=>$host, port=>$port, proto=>$proto
   );
   if (!defined($self->{SOAP})){
      my $msg="can not create SOAP endpoint";
      return("InitERROR",$msg);
   }
   $self->{uCMDBobject}=$ucmdbobject;
   return($self->{SOAP});
}  

sub getSqlFields
{
   my $self=shift;
   my @view=$self->getCurrentView();
   my @flist=();
   my $idfield=$self->IdField();

   if (defined($idfield)){
      my $idname=$self->IdField->Name();
    
      if (!grep(/^$idname$/,@view)){ # unique id
         push(@view,$idname);        # should always
      }                              # be selected
   }
   foreach my $fieldname (@view){
      my $field=$self->getField($fieldname);
      if (defined($field->{depend})){
         if (ref($field->{depend}) ne "ARRAY"){
            $field->{depend}=[$field->{depend}];
         }
         foreach my $field (@{$field->{depend}}){
            push(@view,$field) if (!grep(/^$field$/,@view));
         }
      }
   }
   foreach my $fieldname (@view){
      my $field=$self->getField($fieldname);
      next if (!defined($field));
      my $selectfield=$field->getBackendName($self->{LDAP});
      if (defined($selectfield)){
         push(@flist,"$selectfield $fieldname");
      }
      #
      # dependencies solution on vjoins
      #
      if (defined($field->{vjoinon})){
         my $joinon=$field->{vjoinon}->[0];
         my $joinonfield=$self->getField($joinon);
         if (defined($joinonfield->{dataobjattr})){
            my $newfield=$joinonfield->{dataobjattr}." ".$joinon;
            if (!grep(/^$newfield$/,@flist)){
               push(@flist,$newfield);
            }
         }
      }
      #
      # dependencies solution on container
      #
      if (defined($field->{container})){
         my $contfield=$self->getField($field->{container});
         if (defined($contfield->{dataobjattr})){
            my $newfield=$contfield->{dataobjattr}." ".$field->{container}; 
            if (!grep(/^$newfield$/,@flist)){
               push(@flist,$newfield);
            }
         }
      }
   }
   return(@flist);
}





sub getFinalSOAPFilter
{
   my $self=shift;
   my @filter=@_;

   my %where;

   sub addToWhere
   {
      my $self=shift;
      my $name=shift;
      my $data=shift;
      my $where=shift;
      my %param=@_;

      if (ref($data) eq "ARRAY"){

      }
      else{
         $data=~s/\*/%/g;
      }
      if ($data=~m/^".*"$/){
         $data=~s/^"//;
         $data=~s/"$//;
      }

      $where->{$name}=$data;
   }

   foreach my $filter (@filter){
      #printf STDERR ("getFinalSOAPFilter: interpret $filter in object $self\n");
      #printf STDERR ("getFinalSOAPFilter: interpret %s\n",Dumper($filter));
      my @subflt=$filter;
      @subflt=@$filter if (ref($filter) eq "ARRAY");
      foreach my $filter (@subflt){
         my $subwhere="";
         foreach my $field (keys(%{$filter})){
            #msg(INFO,"getFinalLdapFilter: process field '$field'");
            my $fo=$self->getField($field);
            if (!defined($fo)){
               msg(ERROR,"getFinalLdapFilter: can't process unknown ".
                         "field '$field' - ignorring it");
               next;
            }
            if (defined($fo->{dataobjattr})){
               my $dataobjattr=$fo->{dataobjattr};
               #msg(INFO,"getFinalLdapFilter: process field '$field' ".
               #         "dataobjattr=$dataobjattr");
               if (ref($filter->{$field}) eq "ARRAY"){
                  $self->addToWhere($dataobjattr,$filter->{$field},\%where);
               }
               elsif (ref($filter->{$field}) eq "SCALAR"){
                  $self->addToWhere($dataobjattr,$filter->{$field},\%where);
               }
               elsif ($fo->Type()=~m/^.{0,1}Date$/){
                  $self->addToWhere($dataobjattr,$filter->{$field},\%where);
               }
               elsif (ref($filter->{$field}) eq "HASH"){
                  # spezial processing - not implemented at this time
                  msg(ERROR,"getSqlWhere: can't process HASH filter ".
                            "for '$field'");
               }
               elsif (!defined($filter->{$field})){
                  $self->addToWhere($dataobjattr,$filter->{$field},\%where);
               }
               else{
                  $self->addToWhere($dataobjattr,$filter->{$field},\%where);
                 # # scalar processing - lists an wildcards
                 # my @words=parse_line(',{0,1}\s+',0,$filter->{$field});
                 # AddOrList(\$subwhere,$fo,$dataobjattr,{wildcards=>1},@words);
               }
            }
         }
      }
   } 
   printf STDERR ("fifi SUBDUMP where: %s\n",Dumper(\%where));
   return(\%where);
}

sub getSOAPFilter
{
   my $self=shift;

   my $where=$self->getFinalSOAPFilter($self->getFilterSet());
   return($where);
}


sub UpdateRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   my @updfilter=@_;   # update filter
   $self->LastMsg(ERROR,"LDAP:UpdateRecord not implemented");
   return(undef);
}

sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $dropid=$oldrec->{$self->IdField->Name()};
   $self->LastMsg(ERROR,"LDAP:DeleteRecord not implemented");
   return(undef);
}

sub InsertRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   my $idfield=$self->IdField->Name();
   $self->LastMsg(ERROR,"LDAP:InsertRecord not implemented");
   return(undef);
}



sub tieRec
{
   my $self=shift;
   my $rec=shift;
   
   my %rec;
   my $view=[$self->getCurrentView()];

   my $idfield=$self->IdField();

   if (defined($idfield)){
      my $idname=$self->IdField->Name();
      if (!grep(/^$idname$/,@$view)){ # unique id
         push(@$view,$idname);        # should always
      }                              # be selected
   }

   my $trrec={};
   foreach my $fname (@{$view}){
      my $fobj=$self->getField($fname);
      next if (!defined($fobj));
      if (exists($fobj->{dataobjattr}) && 
          exists($rec->{attr}->{$fobj->{dataobjattr}})){
         $trrec->{$fname}=$rec->{attr}->{$fobj->{dataobjattr}};
      }
      if (defined($fobj->{depend})){
         if (ref($fobj->{depend}) ne "ARRAY"){
            $fobj->{depend}=[$fobj->{depend}];
         }
         foreach my $field (@{$fobj->{depend}}){
            my $dfobj=$self->getField($field);
            if (defined($dfobj->{dataobjattr})){
               $trrec->{$field}=$rec->{attr}->{$dfobj->{dataobjattr}};
            }
         }
      }
   }




   tie(%rec,'kernel::DataObj::SOAPuCMDB::rec',$self,$trrec,$view);
   return(\%rec);
   return(undef);
   
}  

sub Rows 
{
    my $self=shift;

    return(undef);
}


sub finish
{
   my $self=shift;

   $self->{currentSet}=undef;
   return(1);
}

sub getOnlyFirst
{
   my $self=shift;
   if (ref($_[0]) eq "HASH"){
      $self->SetFilter($_[0]);
      shift;
   }
   my @view=@_;
   $self->SetCurrentView(@view);
   $self->Limit(1,1);
   my @res=$self->getFirst();
   $self->finish();
   return(@res);
}

sub getFirst
{
   my $self=shift;
   my @fieldlist=$self->getFieldList();
   my @attr=();

   if (!defined($self->{SOAP})){
      return(undef,msg(ERROR,"no SOAP connection"));
   }
#   my @sqlcmd=($self->getLdapFilter());
   my $baselimit=$self->Limit();
   $self->Context->{CurrentLimit}=$baselimit if ($baselimit>0);
   my $t0=[gettimeofday()];


   my @view=$self->getCurrentView();

   foreach my $fullfieldname (@view){
      my ($container,$fieldname)=(undef,$fullfieldname);
      if ($fullfieldname=~m/^\S+\.\S+$/){
         ($container,$fieldname)=split(/\./,$fullfieldname);
      }
      my $field=$self->getField($fieldname);
      if (defined($field->{depend})){
         if (ref($field->{depend}) ne "ARRAY"){
            $field->{depend}=[$field->{depend}];
         }
         foreach my $field (@{$field->{depend}}){
            push(@view,$field) if (!grep(/^$field$/,@view));
         }
      }
   }

   my @attrview=@view;
   my $idfield=$self->IdField();
   if (defined($idfield)){
      my $idname=$self->IdField->Name();

      if (!grep(/^$idname$/,@attrview)){ # unique id
         push(@attrview,$idname);        # should always
      }                              # be selected
   }





   #printf STDERR ("fifi --------- %s\n",join(",",@attrview));
   foreach my $field (@attrview){
      my $fobj=$self->getField($field);
      next if (!defined($fobj));
      if (defined($fobj->{dataobjattr})){
         push(@attr,$fobj->{dataobjattr});
      }
   }

   my $soapfilter=$self->getSOAPFilter();

   printf STDERR ("call getFilteredCIs at object '%s'\n",$self->{uCMDBobject});
   printf STDERR ("     attr: %s\n",join(",",@attr));
   printf STDERR ("     flt: %s\n",Dumper($soapfilter));

   my $uCMDBobject=$self->{uCMDBobject};
   if (!exists($soapfilter->{__LinkedToID}) &&
       ref($uCMDBobject) eq "ARRAY"){
      $uCMDBobject=$uCMDBobject->[0];

   }


   my $sth=$self->{SOAP}->getFilteredCIs($uCMDBobject,\@attr,$soapfilter);
   my $t=tv_interval($t0,[gettimeofday()]);
   my $p=$self->Self();
   my $msg=sprintf("time=%0.4fsec;mod=$p",$t);
   $msg.=";user=$ENV{REMOTE_USER}" if ($ENV{REMOTE_USER} ne "");
   msg(INFO,"uCMDB SOAP call Time attrs=%s ($msg)",
            join(",",@attr));
   if ($sth->success() && ($self->{currentSet}=$sth->result())){
      $self->{currentRecord}=undef;
      if ($self->{_LimitStart}>0){
         for(my $c=0;$c<$self->{_LimitStart}-1;$c++){
            my $temprec=$self->{currentSet}->();
            last if (!defined($temprec));
         }
      }
      my $temprec=$self->{currentSet}->();
      if ($temprec){
         $temprec=$self->tieRec($temprec);
      }
      return($temprec);

   }
   return(undef,"ERROR - not found");

}

sub getNext
{
   my $self=shift;

   #
   # dafür werd ich vermutlich ein anderen Paging-Verfahren benötigen,
   # da die Satzanzahl nicht ermittelt werden kann.

#   if (defined($self->Context->{CurrentLimit})){
#      $self->Context->{CurrentLimit}--;
#      if ($self->Context->{CurrentLimit}<=0){
#         while(my $temprec=$self->{currentSet}->()){
#         }
#         return(undef,"Limit reached");
#      }
#   }
   my $temprec=$self->{currentSet}->();
   if ($temprec){
      $temprec=$self->tieRec($temprec);
   }
   return($temprec);
}

sub ResolvFieldValue
{
   my $self=shift;
   my $name=shift;

   my $current=$self->{'LDAP'}->getCurrent();
   return($current->{$name});
}





package kernel::DataObj::SOAPuCMDB::rec;
use strict;
use kernel::Universal;
use vars qw(@ISA);
use Tie::Hash;

@ISA=qw(Tie::Hash kernel::Universal);

sub getParent
{
   return($_[0]->{Parent});
}

sub TIEHASH
{
   my $type=shift;
   my $parent=shift;
   my $rec=shift;
   my $view=shift;
   my $self=bless({Parent=>$parent,Rec=>$rec,View=>$view},$type);
   $self->setParent($parent);
   return($self);
}

sub FIRSTKEY
{
   my $self=shift;


   $self->{'keylist'}=[@{$self->{View}}];
   return(shift(@{$self->{'keylist'}}));
}

sub EXISTS
{
   my $self=shift;
   my $key=shift;

   return(grep(/^$key$/,@{$self->{View}}) ? 1:0);
}

sub NEXTKEY
{
   my $self=shift;
   return(shift(@{$self->{'keylist'}}));
}

sub FETCH
{
   my $self=shift;
   my $key=shift;

   return($self->{Rec}->{$key}) if (exists($self->{Rec}->{$key}));
   my $field=$self->getParent->getField($key);
   return(undef) if (!defined($field));
   return($field->RawValue($self->{Rec}));
}


sub STORE
{
   my $self=shift;
   my $key=shift;
   my $val=shift;

   $self->{Rec}->{$key}=$val; 
}
1;
