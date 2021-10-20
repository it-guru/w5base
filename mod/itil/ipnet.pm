package itil::ipnet;
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
use strict;
use vars qw(@ISA);
use kernel;
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);



   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'ipnet.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'200px',
                label         =>'IP-Network name',
                htmldetail    =>0,
                dataobjattr   =>"concat(network.name,': ',".
                                "concat(ipnet.label,' (', ".
                                "ipnet.name,'/',".
                                "ipnet.netmask,')'))"), 

      new kernel::Field::Text(
                name          =>'label',
                htmlwidth     =>'120px',
                label         =>'IP-Network name',
                dataobjattr   =>'ipnet.label'), 

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'120px',
                label         =>'IP-Network Adress',
                dataobjattr   =>'ipnet.name'),

      new kernel::Field::Text(
                name          =>'netmask',
                htmlwidth     =>'120px',
                label         =>'Netmask',
                dataobjattr   =>'ipnet.netmask'),

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
                dataobjattr   =>'ipnet.cistatus'),

      new kernel::Field::Select(
                name          =>'network',
                htmleditwidth =>'280px',
                label         =>'Network',
                vjointo       =>'itil::network',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['networkid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Contact(
                name          =>'ipnetresp',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                label         =>'IP-Net responsible',
                vjoinon       =>'ipnetrespid'),

      new kernel::Field::Interface(
                name          =>'ipnetrespid',
                dataobjattr   =>'ipnet.ipnetresp'),

      new kernel::Field::Contact(
                name          =>'ipnetresp2',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                label         =>'IP-Net responsible deputy',
                vjoinon       =>'ipnetresp2id'),

      new kernel::Field::Interface(
                name          =>'ipnetresp2id',
                dataobjattr   =>'ipnet.ipnetresp2'),

      new kernel::Field::Contact(
                name          =>'techcontact',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                label         =>'technical contact',
                vjoinon       =>'techcontactid'),

      new kernel::Field::Interface(
                name          =>'techcontactid',
                dataobjattr   =>'ipnet.techcontact'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'ipnet.description'),

      new kernel::Field::SubList(
                name          =>'pipnets',
                label         =>'parent IP-Networks',
                group         =>'pipnets',
                htmldetail    =>'NotEmpty',
                vjointo       =>'itil::lnkipnetipnet',
                vjoinbase     =>[{pipnetcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'ipnetid'],
                vjoindisp     =>['pipnet','pipnetname']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::Number(
                name          =>'activeipaddresses',
                label         =>'active IP-Addesses',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (!defined($current));
                   return(1);
                },
                readonly      =>1,
                group         =>'status',
                uploadable    =>0,
                dataobjattr   =>"(select count(*) from ipaddress ".
                                "where ipnet.network=ipaddress.network ".
                                "and ipaddress.binnamekey like ".
                                "ipnet.binnamekey ".
                                "and ipaddress.cistatus=4)"),

      new kernel::Field::Number(
                name          =>'activesubipnets',
                label         =>'active Sub-IP-Nets',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (!defined($current));
                   return(1);
                },
                readonly      =>1,
                uploadable    =>0,
                group         =>'status',
                dataobjattr   =>"(select count(*) from ipnet subipnet ".
                                "where ipnet.network=subipnet.network ".
                                "and subipnet.binnamekey like ".
                                "ipnet.binnamekey ".
                                "and subipnet.cistatus=4 ".
                                "and ipnet.id<>subipnet.id)"),

      new kernel::Field::Link(
                name          =>'networkid',
                label         =>'NetworkID',
                dataobjattr   =>'ipnet.network'),

      new kernel::Field::Interface(
                name          =>'binnamekey',
                label         =>'Binary IP-Net',
                selectfix     =>1,
                dataobjattr   =>'ipnet.binnamekey'),

      new kernel::Field::Number(
                name          =>'hostbitcount',
                label         =>'Host bit count',
                group         =>'status',
                dataobjattr   =>"length(".
                                 "replace(".
                                  "replace(ipnet.binnamekey,'1',''),'0',''))"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'ipnet.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'ipnet.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'ipnet.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'ipnet.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'ipnet.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'ipnet.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'ipnet.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'ipnet.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'ipnet.realeditor'),
   

   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{CI_Handling}={uniquename=>"fullname",
                         activator=>["admin","w5base.itil.ipnet"],
                         uniquesize=>120};
   $self->setDefaultView(qw(name netmask fullname cistatus mdate));
   $self->setWorktable("ipnet");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default pipnets contacts status control misc source));
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable ".
      "left outer join network on $worktable.network=network.id ";
   return($from);
}






sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/ip_network.jpg?".$cgi->query_string());
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;


   my $networkid=effVal($oldrec,$newrec,"networkid");
   my $ipnetid;
   my $ipWriteOk=0;
   if (defined($oldrec)){
      $ipnetid=$oldrec->{id};
      if ($self->isWriteOnIpNetValid($ipnetid)){
         $ipWriteOk++;
      }
   }
   if (!$ipWriteOk && !$self->isWriteOnNetworkValid($networkid)){
      $self->LastMsg(ERROR,
              "no write access, to modify ip-networks in selected networkarea");
      return(0);
   }


   my $name=trim(effVal($oldrec,$newrec,"name"));
   my $binnamekey="";
   $name=~s/\s//g;
   my $ip6str="";

   if ($name=~m/\./){
      $name=~s/^[0]+([1-9])/$1/g;
      $name=~s/\.[0]+([1-9])/.$1/g;
   }
   my $chkname=lc($name);

   my $errmsg;
   my $type=$self->IPValidate($chkname,\$errmsg);
   if ($type eq "IPv4"){
      my ($o1,$o2,$o3,$o4)=$chkname=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
      $ip6str="0000:0000:0000:0000:0000:ffff:".
              unpack("H2",pack('C',$o1)).
              unpack("H2",pack('C',$o2)).":".
              unpack("H2",pack('C',$o3)).
              unpack("H2",pack('C',$o4));
   }
   elsif ($type eq "IPv6"){
       $ip6str=$chkname;
   }
   else{
      $self->LastMsg(ERROR,$self->T($errmsg,"itil::lib::Listedit"));
      return(0);
   }

   foreach my $okt (split(/:/,$ip6str)){
      $binnamekey.=unpack("B16",pack("H4",$okt));
   }


   my $netmaskip6str="";
   my $netmaskbinnamekey="";
   my $netmask=trim(effVal($oldrec,$newrec,"netmask"));

   if (my ($bits)=$netmask=~m/^\/([0-9]+)$/){
      if (($type eq "IPv4" &&
           ($bits<=1 || $bits>32)) ||
          ($type eq "IPv6" &&
           ($bits<=1 || $bits>128))){
         $self->LastMsg(ERROR,"netmask bits out of range");
         return(0);
      } 
      else{
         # rewrite short netmask to full notation
         if ($type eq "IPv4"){
            my $bitstr=("1" x $bits ).("0" x (32-$bits));
            $netmask=join(".",map({oct("0b".$_)} unpack("(A8)*",$bitstr)));
         }
         if ($type eq "IPv6"){
            my $bitstr=("1" x $bits ).("0" x (128-$bits));
            $netmask=join(":",map({
                                 sprintf("%04x",oct("0b".$_))
                             } unpack("(A16)*",$bitstr)));
         }
      }
      $newrec->{netmask}=$netmask;
      $orgrec->{netmask}=$netmask;
   }
   my $netmasktype;
   if ($netmask eq "255.255.255.255"){ # IPv4 Host-Only Netmask
      $netmasktype="IPv4";
   }
   elsif ($netmask eq "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"){ # IPv6 Host
      $netmasktype="IPv6";
   }
   else{
      $netmasktype=$self->IPValidate($netmask,\$errmsg);
   }

   if ($netmasktype eq "IPv4"){
      my ($o1,$o2,$o3,$o4)=$netmask=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
      $netmaskip6str="0000:0000:0000:0000:0000:ffff:".
              unpack("H2",pack('C',$o1)).
              unpack("H2",pack('C',$o2)).":".
              unpack("H2",pack('C',$o3)).
              unpack("H2",pack('C',$o4));
   }
   elsif ($netmasktype eq "IPv6"){
       $netmaskip6str=$netmask;
   }
   else{
      $self->LastMsg(ERROR,$self->T($errmsg,"itil::lib::Listedit"));
      return(0);
   }

   foreach my $okt (split(/:/,$netmaskip6str)){
      $netmaskbinnamekey.=unpack("B16",pack("H4",$okt));
   }

   if ($type ne $netmasktype){
      $self->LastMsg(ERROR,"netmask type an network type did not match");
      return(0);
   }
   if (length($binnamekey) != length($netmaskbinnamekey)){
      $self->LastMsg(ERROR,"binnamekey structure missmatsch");
      return(0);
   }
   my $modnetmaskbinnamekey=$netmaskbinnamekey;
   $modnetmaskbinnamekey=~s/0+$//;
   my $netmaskl=length($modnetmaskbinnamekey);
   my $networkl=length($binnamekey);
   my $netbinkey=substr($binnamekey,0,$netmaskl).("_" x ($networkl-$netmaskl));

   $binnamekey=$netbinkey;

#printf STDERR ("fifi networklen=%d\n",$networkl-$netmaskl);
#printf STDERR ("fifi netmask=$netmask \n");
#printf STDERR ("ipnet: $binnamekey\n");
#printf STDERR ("mask : $netmaskbinnamekey\n");
#printf STDERR ("key  : $netbinkey\n");

   if ($oldrec->{binnamekey} ne $binnamekey){
      $newrec->{'binnamekey'}=$binnamekey;
   }
   if ($oldrec->{name} ne lc($name)){
      $newrec->{'name'}=lc($name);
   }






   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   if (!defined($rec)){
      return("default");
   }
   else{
      my $ipnetid=$rec->{id};
      if ($self->isWriteOnIpNetValid($ipnetid)){
         return("default","contacts");
      }
      my $networkid=$rec->{networkid};
      if ($self->isWriteOnNetworkValid($networkid)){
         return("default","contacts");
      }
   }
   return();
}


1;
