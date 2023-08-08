package itil::ipaddress;
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
use itil::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit itil::lib::Listedit
        kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'ipaddress.id'),

      new kernel::Field::Interface(
                name          =>'fullname',
                depend        =>['name'],
                label         =>'IP-Address Interface',
                searchable    =>0,
                onRawValue    =>sub{   # compress IPV6 Adresses
                   my $self=shift;
                   my $current=shift;
                   my $d=$current->{name};
                      $d=~s/0000:/0:/g;
                      $d=~s/:0000/:0/g;
                      $d=~s/(:)0+?([a-f1-9])/$1$2/gi;
                      $d=~s/^0+?([a-f1-9])/$1$2/gi;
                      $d=~s/:0:/::/gi;
                      $d=~s/:0:/::/gi;
                      $d=~s/:::::/:0:0:0:0:/gi;
                      $d=~s/::::/:0:0:0:/gi;
                      $d=~s/:::/:0:0:/gi;
                   return($d);
                }),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'IP-Address',
                dataobjattr   =>'ipaddress.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'60%',
                explore       =>100,
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'150px',
                explore       =>500,
                group         =>'relatedto',
                label         =>'assigned to System',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (!defined($current));
                   return(0) if ($current->{systemid} eq "");
                   return(1);
                },
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'systemid',
                selectfix     =>1,
                label         =>'SystemID',
                group         =>'relatedto',
                dataobjattr   =>'ipaddress.system'),
                                                  
      new kernel::Field::Link(
                name          =>'binnamekey',
                label         =>'Binary IP-Adress',
                group         =>'relatedto',
                dataobjattr   =>'ipaddress.binnamekey'),
                                                  
      new kernel::Field::Boolean(
                name          =>'is_primary',
                label         =>'is primary',
                htmldetail    =>1,
                searchable    =>0,
                group         =>'further',
                dataobjattr   =>'ipaddress.is_primary'),
                                                  
      new kernel::Field::Boolean(
                name          =>'is_notdeleted',
                label         =>'is notdeleted',
                htmldetail    =>1,
                searchable    =>0,
                group         =>'further',
                dataobjattr   =>'ipaddress.is_notdeleted'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'itclustsvc',
                htmlwidth     =>'150px',
                explore       =>600,
                group         =>'relatedto',
                label         =>'assigned to Cluster Service',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (!defined($current));
                   return(0) if ($current->{itclustsvcid} eq "");
                   return(1);
                },
                vjointo       =>'itil::lnkitclustsvc',
                vjoinon       =>['itclustsvcid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itclustsvcid',
                selectfix     =>1,
                label         =>'ClusterserviceID',
                group         =>'relatedto',
                dataobjattr   =>'ipaddress.lnkitclustsvc'),
                                                  
      new kernel::Field::Link(
                name          =>'furthersystemid',
                label         =>'SystemID for further informations',
                group         =>'further',
                dataobjattr   =>'ipaddress.system'
                ),
                                                  
      new kernel::Field::TextDrop(
                name          =>'systemlocation',
                htmlwidth     =>'280px',
                group         =>'further',
                htmldetail    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(0) if ($current->{systemid} eq "");
                   return(1);
                },
                label         =>'Systems location',
                vjointo       =>'itil::system',
                vjoinon       =>['furthersystemid'=>'id'],
                vjoindisp     =>'location'),

      new kernel::Field::TextDrop(
                name          =>'systemsystemid',
                htmlwidth     =>'280px',
                group         =>'further',
                htmldetail    =>0,
                readonly      =>1,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(0) if ($current->{systemid} eq "");
                   return(1);
                },
                label         =>'Systems SystemID',
                vjointo       =>'itil::system',
                vjoinon       =>['furthersystemid'=>'id'],
                vjoindisp     =>'systemid'),

      new kernel::Field::TextDrop(
                name          =>'systemcistatus',
                htmlwidth     =>'280px',
                group         =>'further',
                htmldetail    =>0,
                readonly      =>1,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(0) if ($current->{systemid} eq "");
                   return(1);
                },
                label         =>'Systems CI-Status',
                vjointo       =>'itil::system',
                vjoinon       =>['furthersystemid'=>'id'],
                vjoindisp     =>'cistatus'),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Applicationnames',
                group         =>'further',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                weblinkto     =>'NONE',
                vjointo       =>'itil::lnkapplip',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'ipaddressid'],
                vjoindisp     =>['appl']),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'further',
                htmldetail    =>0,
                readonly      =>1,
                vjointo       =>'itil::lnkapplip',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'ipaddressid'],
                vjoininhash   =>['appl','applid'],
                vjoindisp     =>['appl']),

      new kernel::Field::Text(
                name          =>'applcustomer',
                label         =>'Application Customer',
                readonly      =>1,
                htmldetail    =>0,
                weblinkto     =>'NONE',
                group         =>'further',
                vjointo       =>'itil::lnkapplip',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'ipaddressid'],
                vjoindisp     =>'customer'),

      new kernel::Field::Boolean(
                name          =>'ciactive',
                label         =>'relevant CI is alive',
                group         =>'further',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                dataobjattr   =>'(select '.
                   'if (system.id is not null,if (system.cistatus<6,1,0),'.
                   'if (lnkitclustsvc.id is not null,1, '.
                   'if (itcloudarea.id is not null,if (itcloudarea.cistatus<6,1,0),0))) '.
                   ' from ipaddress as ip '.
                   'left outer join system on system.id=ip.system '.
                   'left outer join lnkitclustsvc on '.
                         'lnkitclustsvc.id=ip.lnkitclustsvc '.
                   'left outer join itcloudarea on itcloudarea.id=ip.itcloudarea '.
                   'where ip.id=ipaddress.id limit 1)'),

      new kernel::Field::Text(
                name          =>'tsmemail',
                label         =>'Systems TSM E-Mail',
                group         =>'further',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(1) if (!exists($param{current}));
                   my $current=$param{current};

                   return(0) if ($current->{systemid} eq "");
                   return(1);
                },
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['furthersystemid'=>'systemid'],
                vjoindisp     =>['tsmemail']),

      new kernel::Field::Text(
                name          =>'class',
                label         =>'classification',
                group         =>'further',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'(select '.
                   'concat_ws(",",'.
                   'if (system.is_applserver=1,"\'APPL\'",NULL),'.
                   'if (system.id is null and lnkitclustsvc is not null,'.
                       '"\'CLUSTERPACKAGE\'",NULL),'.
                   'if (system.is_webserver=1,"\'WEBSRV\'",NULL), '.
                   'if (system.is_mailserver=1,"\'MAILSRV\'",NULL), '.
                   'if (system.is_router=1,"\'ROUTER\'",NULL), '.
                   'if (system.is_netswitch=1,"\'NETSWITCH\'",NULL), '.
                   'if (system.is_nas=1,"\'NAS\'",NULL), '.
                   'if (system.is_terminalsrv=1,"\'TS\'",NULL), '.
                   'if (system.is_loadbalacer=1,"\'LOADBALANCER\'",NULL), '.
                   'if (system.is_clusternode=1,"\'CLUSTERNODE\'",NULL), '.
                   'if (system.is_databasesrv=1,"\'DB\'",NULL)) '.
                   ' from ipaddress as ip '.
                   'left outer join system on system.id=ip.system '.
                   'left outer join lnkitclustsvc on '.
                         'lnkitclustsvc.id=ip.lnkitclustsvc '.
                   'where ip.id=ipaddress.id limit 1)'),

      new kernel::Field::Text(
                name          =>'tsm2email',
                label         =>'Systems deputy TSM E-Mail',
                group         =>'further',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(0) if ($current->{systemid} eq "");
                   return(1);
                },
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['furthersystemid'=>'systemid'],
                vjoindisp     =>['tsm2email']),

      new kernel::Field::Select(
                name          =>'network',
                htmleditwidth =>'280px',
                label         =>'Network',
                vjointo       =>'itil::network',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['networkid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'itcloudarea',
                group         =>'default',
                label         =>'CloudArea',
                htmldetail    =>'NotEmpty',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                vjointo       =>'itil::itcloudarea',
                vjoinon       =>['itcloudareaid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itcloudareaid',
                label         =>'CloudAreaID',
                selectfix     =>1,
                group         =>'default',
                dataobjattr   =>'ipaddress.itcloudarea'),
                                                  
      new kernel::Field::SubList(
                name          =>'dnsaliases',
                label         =>'DNS-Aliases',
                group         =>'dnsaliases',
                vjointo       =>'itil::dnsalias',
                vjoinon       =>['dnsname'=>'dnsname'],
                vjoinbase     =>{'cistatusid'=>"<=5"},
                vjoindisp     =>['fullname']),

      new kernel::Field::Link(
                name          =>'networkid',
                label         =>'NetworkID',
                dataobjattr   =>'ipaddress.network'),

      new kernel::Field::Interface(
                name          =>'networktag',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'NetworkTag',
                vjointo       =>'itil::network',
                vjoinon       =>['networkid'=>'id'],
                vjoindisp     =>'networktag'),

      new kernel::Field::Link(
                name          =>'uniqueflag',
                label         =>'UniqueFlag',
                dataobjattr   =>'ipaddress.uniqueflag'),
                                                  
      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>'DNS-Name',
                htmlwidth     =>'100px',
                dataobjattr   =>'ipaddress.dnsname'),

      new kernel::Field::Select(
                name          =>'type',
                htmleditwidth =>'190px',
                label         =>'Typ',
                default       =>1,
                transprefix   =>'iptyp.',
                value         =>[qw(0 1 2 3 4 5 8 9 6 7)],
                dataobjattr   =>'ipaddress.addresstyp'),

      new kernel::Field::Boolean(
                name          =>'is_monitoring',
                label         =>'use this ip for system monitoring',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(0) if ($param{current}->{itclustsvcid} ne "");
                   }
                   return(1);
                },
                depend        =>['itclustsvcid'],
                group         =>'default',
                dataobjattr   =>'ipaddress.is_monitoring'),
                                                  
      new kernel::Field::Text(
                name          =>'ifname',
                htmlwidth     =>'130px',
                label         =>'Interface name',
                dataobjattr   =>'ipaddress.ifname'),

      new kernel::Field::Text(
                name          =>'mac',
                label         =>'MAC-Address',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'(select macaddr '.
                   ' from sysiface  '.
                   'where sysiface.system=ipaddress.system and '.
                   'ipaddress.system is not null and '.
                   'sysiface.name=ipaddress.ifname limit 1)'),

      new kernel::Field::Text(
                name          =>'accountno',
                htmlwidth     =>'130px',
                label         =>'Account Number',
                dataobjattr   =>'ipaddress.accountno'),

      new kernel::Field::Link(
                name          =>'addresstyp',
                htmlwidth     =>'5px',
                dataobjattr   =>'ipaddress.addresstyp'),

      new kernel::Field::DynWebIcon(
                name          =>'webaddresstyp',
                searchable    =>0,
                depend        =>['type','name','dnsname'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $typeo=$self->getParent->getField("type");
                   my $d=$typeo->FormatedDetail($current,"AscV01");

                   my $ipo=$self->getParent->getField("dnsname");
                   my $ipname=$ipo->RawValue($current);
                   if ($ipname eq ""){
                      $ipo=$self->getParent->getField("name");
                      $ipname=$ipo->RawValue($current);
                   }
                   $ipname=~s/"//g;

                   my $e=$self->RawValue($current);
                   my $name=$self->Name();
                   my $app=$self->getParent();
                   if ($mode=~m/html/i){
                      return("<a href=\"ssh://$ipname\"><img ".
                         "src=\"../../itil/load/iptyp${e}.gif\" ".
                         "title=\"$d\" border=0></a>");
                   }
                   return($d);
                },
                dataobjattr   =>'ipaddress.addresstyp'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'ipaddress.cistatus'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'ipaddress.comments'),

      new kernel::Field::Text(
                name          =>'shortcomments',
                label         =>'Short Comments',
                readonly      =>1,
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
                                   if ($current->{ifname} ne ""){
                                      if (length($d)){
                                         $d.=" ";
                                      }
                                      $d.="(".$current->{ifname}.")";
                                   }
                                   return($d);
                                },
                depend        =>['comments','ifname']),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                dataobjattr   =>'ipaddress.additional'),

      new kernel::Field::SubList(
                name          =>'ipnets',
                label         =>'IP-Networks',
                group         =>'ipnets',
                vjointo       =>'itil::lnkipaddressipnet',
                vjoinbase     =>[{ipnetcistatusid=>"<=4",
                                  activesubipnets=>'0'}],
                vjoinon       =>['id'=>'ipaddressid'],
                vjoindisp     =>['ipnetname','ipnet']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'ipaddress.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'ipaddress.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'ipaddress.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'ipaddress.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'ipaddress.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'ipaddress.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'ipaddress.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'ipaddress.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'ipaddress.realeditor'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'ipaddress.lastqcheck'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"ipaddress.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(ipaddress.id,35,'0')")
   );
   $self->{history}={
      insert=>[
         'local',
         {dataobj=>'itil::system', id=>'systemid',
          field=>'name',as=>'ipaddresses'}
      ],
      update=>[
         'local',
         {dataobj=>'itil::system', id=>'systemid'}
      ],
      delete=>[
         {dataobj=>'itil::system', id=>'systemid',
          field=>'fullname',as=>'ipaddresses'}
      ]
   };
   $self->setDefaultView(qw(name system dnsname cistatus mdate));
   $self->setWorktable("ipaddress");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/ipaddress.jpg?".$cgi->query_string());
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::ipaddress");
}


sub prepareToWasted
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{srcid}=undef;
   $newrec->{srcload}=undef;

   my $id=effVal($oldrec,$newrec,"id");

   #my $o=getModuleObject($self->Config,"itil::system");
   #if (defined($o)){
   #   $o->BulkDeleteRecord({xxxxxxxx=>\$id});
   #}

   return(1);   # if undef, no wasted Transfer is allowed
}


sub isIpInNet
{
   my $self=shift;
   my $ip=shift;
   my @networks=@_;

   my $iobj=$self->IpDecode($ip);

   foreach my $net (@networks){
       my $nobj=$self->IpDecode($net);
       if ($nobj->{prefix6}){
          my $nbase2=substr($nobj->{base2},0,$nobj->{prefix6});
          my $ibase2=substr($iobj->{base2},0,$nobj->{prefix6});
          if ($nbase2 eq $ibase2){
             return(1);
          }
       }
   }
   return(0);
}


sub Ipv6Expand
{
   my $self=shift;
   my $ip=shift;

   my $orgip=$ip;

   my @unformat;


   if (1){ # Handling for muliple 0 blocks in :: sequence
      $ip.="0" if ($ip=~m/:$/);
      my @blks=split(/:/,$ip);
      my $n=$#blks+1;
      if ($n<8){
         my $miss=8-$n;
         my $addblks=":0" x ($miss+1);
         $ip=~s/::/$addblks:/;
      }
      # verify expand:
      my @blks=split(/:/,$ip);
      if ($#blks!=7){
         msg(ERROR,"ipv6 Expand error: $orgip");
         Stacktrace(1);
         return(undef);
      }
   }

   foreach my $okt (split(/:/,$ip)){
      push(@unformat,sprintf("%04x",hex($okt)));
   }
   my $name=lc(join(":",@unformat));
   return($name);
}


sub IpDecode
{
   my $self=shift;
   my $ip=shift;
   my %param=@_;
   my %d;
   if (!exists($param{IPv4})){
      $param{IPv4}=1;
   }
   if (!exists($param{IPv6})){
      $param{IPv6}=1;
   }
   if (!exists($param{prefix})){
      $param{prefix}=1;
   }
   $d{input}=$ip;

   if ($param{prefix}){
      if (my ($prefix)=$ip=~m/\/([0-9]+)$/){
         $ip=~s/\/[0-9]+$//;
         $d{prefix}=$prefix;
      }
   }
   my $ip6str;
   if ($param{IPv4}){
      if (my ($o1,$o2,$o3,$o4)=$ip=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/){
         $d{format}="IPv4";
         $d{ip}=sprintf('%d.%d.%d.%d',$o1,$o2,$o3,$o4);
         $ip6str="0000:0000:0000:0000:0000:ffff:".
                 unpack("H2",pack('C',$o1)).
                 unpack("H2",pack('C',$o2)).":".
                 unpack("H2",pack('C',$o3)).
                 unpack("H2",pack('C',$o4));
         if ($d{prefix}){
            $d{prefix4}=$d{prefix};
            $d{prefix6}=$d{prefix}+(16*6);
         }
      }
   }
   if ($param{IPv6}){
      if ($ip=~m/:/){
         $ip6str=$self->Ipv6Expand($ip);
         $d{ip}=$ip6str;
         if ($d{prefix}){
            $d{prefix4}=$d{prefix};
            $d{prefix6}=$d{prefix};
         }
      }
   }
   if ($ip6str ne ""){
      $d{ip6str}=$ip6str;
      my $binkey6;
      foreach my $okt (split(/:/,$ip6str)){
         $binkey6.=unpack("B16",pack("H4",$okt));
      }
      $d{base2}=$binkey6;
   }

   return(\%d);
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orignew=shift;
   
   return(1) if (effChangedVal($oldrec,$newrec,"cistatusid")==7);

   my $cistatusid=trim(effVal($oldrec,$newrec,"cistatusid"));
   if (!defined($cistatusid) || $cistatusid==0){
      $newrec->{cistatusid}=4;
   }


   #
   # Generierung der Typ Flags (Eindeutigkeitssicherung)
   #
   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
   my $is_primary=effVal($oldrec,$newrec,"is_primary");
   my $is_notdeleted=effVal($oldrec,$newrec,"is_notdeleted");
   my $type=effVal($oldrec,$newrec,"type");
   if ($type eq ""){  # if no type is specified - use secondary
      $newrec->{type}=1;
      $type=1;
   }
   if ($type eq "0" && $is_primary ne "1"){
      $newrec->{is_primary}=1;
   }
   if ($type ne "0" && $is_primary ne ""){
      $newrec->{is_primary}=undef;
   }
   if ($cistatusid<=5 && $is_notdeleted ne "1"){
      $newrec->{is_notdeleted}=1;
   }
   if ($cistatusid>5 && $is_notdeleted ne ""){
      $newrec->{is_notdeleted}=undef;
   }
   my $is_monitoring=effVal($oldrec,$newrec,"is_monitoring");
   if ($is_monitoring ne "1" && $is_monitoring ne "" &&
       defined($oldrec) && ($oldrec->{is_monitoring} ne "0" && 
                            $oldrec->{is_monitoring} ne "")){
      $newrec->{is_monitoring}=undef;
   }
   if ($newrec->{is_monitoring} eq "0"){
      $newrec->{is_monitoring}=undef;
      $orignew->{is_monitoring}=undef;
   }
   ##################################################################



   my $name=trim(effVal($oldrec,$newrec,"name"));
   my $binnamekey="";
   $name=~s/\s//g;
   my $ip6str="";
   if ($cistatusid<=5){
      $name=~s/\[\d*\]$//;
   }

   if ($name=~m/\./){
      $name=~s/^[0]+([1-9])/$1/g;
      $name=~s/\.[0]+([1-9])/.$1/g;
   }
   my $chkname=lc($name);
   if ($cistatusid>5){
      $chkname=~s/\[\d+\]$//;
   }

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
      my @unformat;
      foreach my $okt (split(/:/,$chkname)){
         push(@unformat,sprintf("%04x",hex($okt)));
      }
      $name=lc(join(":",@unformat));
      $ip6str=$name;
   }
   else{
      msg(ERROR,"invalid IP-Address write request for '$chkname'");
      $self->LastMsg(ERROR,$self->T($errmsg,"itil::lib::Listedit"));
      return(0);
   }
   if (!$self->isValidClientIP($name)){
      $self->LastMsg(ERROR,$self->T("invalid Client IP Address - Blacklisted"));
      return(0);
   }

   foreach my $okt (split(/:/,$ip6str)){
      $binnamekey.=unpack("B16",pack("H4",$okt));
   }
   if ($oldrec->{binnamekey} ne $binnamekey){
      $newrec->{'binnamekey'}=$binnamekey;
   }
   if ($oldrec->{name} ne lc($name)){
      $newrec->{'name'}=lc($name);
   }

   #######################################################################
   # unique IP-Handling
   if (!defined($oldrec) || exists($newrec->{networkid})){
      $newrec->{'uniqueflag'}=1;
      my $networkid=effVal($oldrec,$newrec,"networkid");
      if ($networkid eq ""){
         $self->LastMsg(ERROR,"no network specified");
         printf STDERR ("DEBUG: newrec=%s\n",Dumper($newrec));
         return(0);
      }
      my $n=getModuleObject($self->Config,"itil::network");
      $n->SetFilter({id=>\$networkid,cistatusid=>[3,4]});
      my ($nrec,$msg)=$n->getOnlyFirst(qw(uniquearea));
      if (!defined($nrec)){
         $self->LastMsg(ERROR,"no networkid specified");
         return(0);
      }
      if (!$nrec->{uniquearea}){
         $newrec->{'uniqueflag'}=undef;
      }
   }


   if (exists($newrec->{'dnsname'})){
      my $dnsname=lc(trim(effVal($oldrec,$newrec,"dnsname")));
      $dnsname=~s/[^a-z0-9\[\]]*$//;
      $dnsname=~s/^[^a-z0-9]*//;
      $newrec->{'dnsname'}=$dnsname;
      if ($dnsname ne ""){
         if (($dnsname=~m/\s/) || !($dnsname=~m/.+\..+/)){
            $self->LastMsg(ERROR,"invalid dns name");
            return(0);
         }
      }
      $newrec->{'dnsname'}=undef if ($newrec->{'dnsname'} eq "");
   }

   my $accountno=trim(effVal($oldrec,$newrec,"accountno"));
   if ($accountno=~m/\s/){
      $self->LastMsg(ERROR,"invalid account number specified");
      return(0);
   }

#   msg(INFO,sprintf("iprec=%s\n",Dumper($newrec)));

   if (!defined($oldrec) && !exists($newrec->{'type'}) &&
                            !exists($newrec->{'addresstyp'})){
      $newrec->{'addresstyp'}=1;
   }
   return(0) if (!($self->isParentSpecified($oldrec,$newrec)));
   #return(1) if ($self->IsMemberOf("admin"));
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name","dnsname"));

   return(1);
}

sub isParentSpecified
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $itclustsvcid=effVal($oldrec,$newrec,"itclustsvcid");
   my $systemid=effVal($oldrec,$newrec,"systemid");
   my $itcloudareaid=effVal($oldrec,$newrec,"itcloudareaid");
   if ($systemid<=0 && $itclustsvcid <=0 && $itcloudareaid<=0){
      $self->LastMsg(ERROR,"invalid parent object reference specified");
      return(0);
   } 
   if (!($self->isParentWriteable($systemid,$itclustsvcid,$itcloudareaid))){
      return(0);
   }
   return(1);

}





sub isParentWriteable
{
   my $self=shift;
   my $systemid=shift;
   my $itclustsvcid=shift;
   my $itcloudareaid=shift;

   return(
      $self->isParentOPvalid("write",$systemid,$itclustsvcid,$itcloudareaid)
   );
}

sub isParentReadable
{
   my $self=shift;
   my $systemid=shift;
   my $itclustsvcid=shift;
   my $itcloudareaid=shift;

   return($self->isParentOPvalid("read",$systemid,$itclustsvcid,$itcloudareaid));

}

sub isParentOPvalid
{
   my $self=shift;
   my $mode=shift;
   my $systemid=shift;
   my $itclustsvcid=shift;
   my $itcloudareaid=shift;

   if ($systemid ne ""){
      my $p=$self->getPersistentModuleObject("itil::system");
      my $idname=$p->IdField->Name();
      my %flt=($idname=>\$systemid);
      $p->ResetFilter();
      if ($mode eq "write"){ 
         $p->SetFilter(\%flt);
      }
      else{
         $p->SecureSetFilter(\%flt,\%flt);  # do not use isDirectHandling
      }
      my @l=$p->getHashList(qw(ALL));

      if ($#l!=0){
         if ($mode eq "write"){
            $self->LastMsg(ERROR,"invalid system reference to systemid=".
                                 $systemid);
         }
         return(0);
      }
      my @blkl;
      if ($mode eq "write"){ 
         @blkl=$p->isWriteValid($l[0]);
      }
      if ($mode eq "read"){ 
         @blkl=$p->isViewValid($l[0]);
      }
      if ($self->isDataInputFromUserFrontend()){
         if (!grep(/^ALL$/,@blkl) && !grep(/^ipaddresses$/,@blkl)){
            return(0);
         }
      }
   }
   if ($itclustsvcid ne ""){
      my $p=$self->getPersistentModuleObject("itil::lnkitclustsvc");
      my $idname=$p->IdField->Name();
      my %flt=($idname=>\$itclustsvcid);
      if ($mode eq "write"){ 
         $p->SetFilter(\%flt);
      }
      else{
         $p->SecureSetFilter(\%flt,\%flt);  # do not use isDirectHandling
      }
      my @l=$p->getHashList(qw(ALL));
      if ($#l!=0){
         if ($mode eq "write"){
            $self->LastMsg(ERROR,"invalid itclust reference to itclustsvc=".
                                 $itclustsvcid);
         }
         return(0);
      }
      my @blkl;
      if ($mode eq "write"){ 
         @blkl=$p->isWriteValid($l[0]);
      }
      if ($mode eq "read"){ 
         @blkl=$p->isViewValid($l[0]);
      }
      if ($self->isDataInputFromUserFrontend()){
         if (!grep(/^ALL$/,@blkl) && !grep(/^ipaddresses$/,@blkl)){
            $self->LastMsg(ERROR,"no access") if ($mode eq "write");
            return(0);
         }
      }
   }
   if ($itclustsvcid eq "" && $systemid eq ""){
      if ($itcloudareaid ne ""){
         my $p=$self->getPersistentModuleObject("itil::itcloudarea");
         my $idname=$p->IdField->Name();
         my %flt=($idname=>\$itcloudareaid);
         if ($mode eq "write"){ 
            $p->SetFilter(\%flt);
         }
         else{
            $p->SecureSetFilter(\%flt,\%flt);  # do not use isDirectHandling
         }
         my @l=$p->getHashList(qw(ALL));
         if ($#l!=0){
            if ($mode eq "write"){
               $self->LastMsg(ERROR,
                              "invalid CloudArea reference to CloudAreaID=".
                              $itcloudareaid);
               return(0);
            }
         }
         my $itcloudid=$l[0]->{cloudid};
         my $pp=$self->getPersistentModuleObject("itil::itcloud");
         my $idname=$pp->IdField->Name();
         my %flt=($idname=>\$itcloudid);
         if ($mode eq "write"){ 
            $pp->SetFilter(\%flt);
         }
         else{
            $pp->SecureSetFilter(\%flt,\%flt);  # do not use isDirectHandling
         }
         my @l=$pp->getHashList(qw(ALL));
         if ($#l!=0){
            if ($mode eq "write"){
               $self->LastMsg(ERROR,
                              "invalid cloud reference to CloudAreaID=".
                              $itcloudareaid);
               return(0);
            }
         }
         my @blkl;
         if ($mode eq "write"){ 
            @blkl=$pp->isWriteValid($l[0]);
         }
         if ($mode eq "read"){ 
            @blkl=$pp->isViewValid($l[0]);
         }
         if ($self->isDataInputFromUserFrontend()){
            if (!grep(/^ALL$/,@blkl) && !grep(/^default$/,@blkl)){
               $self->LastMsg(ERROR,"no access") if ($mode eq "write");
               return(0);
            }
            return(1) if ($mode eq "read");
         }
      }
      else{
         $self->LastMsg(ERROR,"doa felt woas") if ($mode eq "write");
         return(0);
      }
   }
   return(1);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt)){
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);

   }
   return($self->SetFilter(@flt));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @def=("header","default","qc");
   return(@def) if (!defined($rec));
   return(qw(header default)) if (defined($rec) && $rec->{cistatusid}==7);
   push(@def,"source");
   if ($self->IsMemberOf("admin") ||
       $self->IsMemberOf("w5base.itil.ipaddress.read") ||
       $self->isParentReadable($rec->{systemid},$rec->{itclustsvcid},
                               $rec->{itcloudareaid})){
      push(@def,"history");
      push(@def,"ipnets");
      push(@def,"relatedto","further");
      push(@def,"dnsaliases",) if ($rec->{dnsname} ne "");
   }
   else{
      return();
   }
   return(@def);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   if (defined($rec)){
      return("default","relatedto") if ($self->IsMemberOf("admin"));
      return(undef) if (!$self->isParentSpecified($rec));
   }

   return("default","relatedto");
}

sub getRecordHtmlIndex
{ 
   my $self=shift;

   return; 
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default relatedto dnsaliases ipnets further source));
}

sub switchSystemIpToNetarea
{
   my $self=shift;

   my $netIpDst=shift;
   my $refid=shift;
   my $netarea=shift;
   my $qmsg=shift;

   my $islandid=$netarea->{ISLAND};

   foreach my $ip (keys(%$netIpDst)){
      if (exists($netIpDst->{$ip}->{NetareaTag})){
         $netIpDst->{$ip}->{networkid}=
              $netarea->{$netIpDst->{$ip}->{NetareaTag}};
         if (!exists(
              $netarea->{$netIpDst->{$ip}->{NetareaTag}})){
            push(@$qmsg,"invalid netarea switch tag ".
                        "'$netIpDst->{$ip}->{NetareaTag} in ip=$ip");
         }
         delete($netIpDst->{$ip}->{NetareaTag});
      }
      if ($netIpDst->{$ip}->{networkid} eq ""){
         msg(ERROR,"invalid networkid while SwitchToTargetNet on IP $ip");
         delete($netIpDst->{$ip});
      }
   }
   if (keys(%$netIpDst)){
      $self->ResetFilter();
      $self->SetFilter({ name=>[keys(%$netIpDst)], cistatusid=>"<6" });
      $self->SetCurrentView(qw(id name systemid networkid));
      my $curiplist=$self->getHashIndexed("id");
      foreach my $curip (values(%{$curiplist->{id}})){
         if (exists($netIpDst->{$curip->{name}})){
            if ($curip->{systemid} ne $refid){
               if ($curip->{networkid} ne $islandid){
                  delete($netIpDst->{$curip->{name}});
                  push(@$qmsg,"can not assign network area to: $curip->{name}");
               }  # switch is not posibile, becaus IP already
            }     # assigend
            elsif ($curip->{networkid} eq
                   $netIpDst->{$curip->{name}}->{networkid}){
               delete($netIpDst->{$curip->{name}}); 
            }     # ip is already in correct network
            else{
               $netIpDst->{$curip->{name}}->{id}=$curip->{id};
               $netIpDst->{$curip->{name}}->{name}=$curip->{name};
            }
         }
      }
      # process networkarea switches
      foreach my $ipupd (keys(%$netIpDst)){
         next if (!exists($netIpDst->{$ipupd}->{id}));
         $self->ValidatedUpdateRecord(
            $curiplist->{id}->{$netIpDst->{$ipupd}->{id}},
            { networkid=>$netIpDst->{$ipupd}->{networkid} },
            {id=>\$netIpDst->{$ipupd}->{id}}
         );
      }
   }
}



1;
