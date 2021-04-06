package itil::network;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'network.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'network.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'network.cistatus'),

      new kernel::Field::Boolean(
                name          =>'uniquearea',
                label         =>'IP-Numbering unique',
                dataobjattr   =>'network.uniquearea'),


      new kernel::Field::TextURL(
                name          =>'probeipurl',
                label         =>'ProbeIP URL',
                dataobjattr   =>'network.probeipurl'),

      new kernel::Field::Text(
                name          =>'probeipproxy',
                label         =>'ProbeIP Proxy',
                dataobjattr   =>'network.probeipproxy'),

      new kernel::Field::Text(
                name          =>'networktag',
                label         =>'Network tag',
                maxlength     =>20,
                htmleditwidth =>'100px',
                dataobjattr   =>'network.tagname'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'network.comments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'network.additional'),

      new kernel::Field::Number(
                name          =>'activeipnets',
                label         =>'active IP-Networks',
                readonly      =>1,
                uploadable    =>0,
                dataobjattr   =>"(select count(*) from ipnet ".
                                "where network.id=ipnet.network ".
                                "and ipnet.cistatus=4)"),

      new kernel::Field::Number(
                name          =>'activeipaddresses',
                label         =>'active IP-Addesses',
                readonly      =>1,
                uploadable    =>0,
                dataobjattr   =>"(select count(*) from ipaddress ".
                                "where network.id=ipaddress.network ".
                                "and ipaddress.cistatus=4)"),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoininhash   =>['mdate','targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"network.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(network.id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'network.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'network.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'network.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'network.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'network.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'network.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'network.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'network.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'network.realeditor'),
   

   );
   $self->setDefaultView(qw(name cistatus mdate));
   $self->setWorktable("network");
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.itil.network"],
                         uniquesize=>255};
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/ip_network.jpg?".$cgi->query_string());
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }


   return(1);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (exists($newrec->{networktag})){
      $newrec->{networktag}=uc($newrec->{networktag});
      $newrec->{networktag}=~s/[^a-z0-9]//gi;
      $newrec->{networktag}=undef if ($newrec->{networktag} eq "");
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }


   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default","contacts") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   return(undef);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{name},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}

sub findNetworkAreaId
{
   my $self=shift;
   my $param=shift;
   my @expression=@_;

   if (!exists($self->{findNetworkAreaCache}) ||
       $self->{findNetworkAreaCache}->{time}<time()-10){

      $self->ResetFilter();
      my @netlist=$self->getHashList(qw(name id));
      my $r={
         time=>time(),
         netlist=>\@netlist
      };
      $self->{findNetworkAreaCache}=$r;
   }
   for(my $loop=0;$loop<=1;$loop++){
      foreach my $exp (@expression){
         foreach my $netrec (@{$self->{findNetworkAreaCache}->{netlist}}){
            if ($exp eq $netrec->{name}){
               return($netrec->{id});
            }
         }
      }
      if ($param->{addDefaultIsland}){
         push(@expression,"Island-Net/Customer-LAN");
         push(@expression,"Insel-Netz/Kunden-LAN");
      }
   }


   return(undef);
}

sub getTaggedNetworkAreaId
{
   my $self=shift;
   my %netarea=();

   $self->ResetFilter();
   $self->SetFilter({cistatusid=>'4'});
   $self->SetCurrentView(qw(name id networktag));
   my $i=$self->getHashIndexed("networktag");

   foreach my $tag (keys(%{$i->{networktag}})){
      $netarea{$tag}=$i->{networktag}->{$tag}->{id};
   }

   return(\%netarea);
}






1;
