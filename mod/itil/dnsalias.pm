package itil::dnsalias;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
                dataobjattr   =>'dnsalias.id'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Alias (CNAME)',
                dataobjattr   =>'dnsalias.dnsalias'),

      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>'IP-DNS-Name',
                dataobjattr   =>'dnsalias.dnsname'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                default       =>4,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0 AND <7"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'dnsalias.cistatus'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'dnsalias.comments'),

      new kernel::Field::Text(
                name          =>'shortcomments',
                label         =>'Short Comments',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                htmlwidth     =>'190px',
                onRawValue    =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   my $d=$current->{comments};
                                   $d=~s/\n/ /g;
                                   $d=substr($d,0,24);
                                   if (length($current->{comments})>
                                       length($d)){
                                      $d.="...";
                                   }
                                   return($d);
                                },
                depend        =>['comments']),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                forwardSearch =>1,
                vjointo       =>'itil::system',
                vjoinon       =>['dnsname'=>'dnsnamelist'],
                vjoindisp     =>['name'],
                vjoininhash   =>['name','systemid']),

      new kernel::Field::SubList(
                name          =>'itclustsvc',
                label         =>'Cluster Services',
                group         =>'itclustsvc',
                forwardSearch =>1,
                vjointo       =>'itil::lnkitclustsvc',
                vjoinon       =>['dnsname'=>'dnsnamelist'],
                vjoindisp     =>['fullname','name'],
                vjoininhash   =>['fullname','name','id']),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                htmldetail    =>0,
                group         =>'ipaddresses',
                forwardSearch =>1,
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['dnsname'=>'dnsname'],
                vjoindisp     =>['name']),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"dnsalias.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(dnsalias.id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'dnsalias.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'dnsalias.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'dnsalias.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'dnsalias.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'dnsalias.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'dnsalias.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'dnsalias.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'dnsalias.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'dnsalias.realeditor'),
   

   );
   $self->setDefaultView(qw(fullname dnsname cistatus mdate));
   $self->setWorktable("dnsalias");
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $cistatusid=trim(effVal($oldrec,$newrec,"cistatusid"));
   if (!defined($cistatusid) || $cistatusid==0){
      $newrec->{cistatusid}=4;
   }

   my $dnsalias=effVal($oldrec,$newrec,"fullname");
   if(!($dnsalias=~m/^([\w,-]+\.)+[a-zA-Z]{2,5}(\[\d\]){0,1}$/ && 
        !($dnsalias=~m/\s/))){
      $self->LastMsg(ERROR,"invalid dns-alias");
      return(0);
   }
   if (lc($dnsalias) ne $dnsalias){
      $newrec->{fullname}=lc($dnsalias);
      $dnsalias=$newrec->{fullname};
   }
   if (exists($newrec->{dnsname})){
      $newrec->{dnsname}=lc($newrec->{dnsname});
   }
   
   my $dnsname=effVal($oldrec,$newrec,"dnsname");
   my $name=getModuleObject($self->Config,"itil::ipaddress");
   $name->ResetFilter();
   $name->SetFilter({dnsname=>\$dnsname});
   my ($rec,$msg)=$name->getOnlyFirst(qw(ALL));
   if(!(defined($rec))){
      $self->LastMsg(ERROR,"no IP-DNS-Name specified or no such entry found");
      return(0);
   }else{
      if (!$self->isParentWriteable($oldrec,$dnsname)){
         $self->LastMsg(ERROR,"no write access on respective system");
         return(0);
      }
   }
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"fullname"));

   return(1);
}

sub isParentWriteable
{
   my $self=shift;
   my $rec=shift;
   my $dnsname=shift;

   my $ipaddr=getModuleObject($self->Config,"itil::ipaddress");
   my %flt=("dnsname"=>\$dnsname);
   $ipaddr->SetFilter(\%flt);
   my @ipaddrlist=$ipaddr->getHashList(qw(systemid itclustsvcid));
   
   my $sys=getModuleObject($self->Config,"itil::system");
   my $isv=getModuleObject($self->Config,"itil::lnkitclustsvc");
   my $idname=$sys->IdField->Name();
   my $sysfound=0;
   my $isvfound=0;
   foreach my $iprec (@ipaddrlist){
      if ($iprec->{systemid} ne "" && $iprec->{itclustsvcid} eq ""){
         $sys->SetFilter({$idname=>\$iprec->{systemid}});
         my ($sysrec)=$sys->getOnlyFirst(qw(ALL));
         if (defined($sysrec)){
            $sysfound++;
            my @write=$sys->isWriteValid($sysrec);
            if ($self->isDataInputFromUserFrontend()){
               if (grep(/^ALL$/,@write) || grep(/^ipaddresses$/,@write)){
                  return(1);
               }
            }
         }
      }
      if ($iprec->{systemid} eq "" && $iprec->{itclustsvcid} ne ""){
         $isv->SetFilter({id=>\$iprec->{itclustsvcid}});
         my ($isvrec)=$isv->getOnlyFirst(qw(ALL));
         if (defined($isvrec)){
            $isvfound++;
            my @write=$isv->isWriteValid($isvrec);
            if ($self->isDataInputFromUserFrontend()){
               if (grep(/^ALL$/,@write) || grep(/^ipaddresses$/,@write)){
                  return(1);
               }
            }
         }
      }
   }
   if(defined($rec) && !$sysfound && !$isvfound){
      return(1) if ($rec->{owner}==$self->getCurrentUserId());
   }
   return(0);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if (defined($rec)){
      return("default") if ($self->IsMemberOf("admin"));
      if (!$self->isParentWriteable($rec,$rec->{dnsname})){
         $self->LastMsg(ERROR,
                        "no system found or no permission to access system");
         return(undef);
      }
   }

   return("default");
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default ipaddresses systems itclustsvc source));
}



sub getRecordHtmlIndex
{ return(); }




1;
